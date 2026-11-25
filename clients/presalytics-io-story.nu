# Auto-generated client for Story v0.3.1
# Source: https://api.apis.guru/v2/specs/presalytics.io/story/0.3.1/openapi.json
# Auth: --token flag or $env.STORY_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/story"
  token_env_var: "STORY_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/story"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["change" "create" "delete" "fire"] }
def accept-completer [] { ["application/vnd.openxmlformats-officedocument.presentationml.presentation" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/vnd.openxmlformats-officedocument.wordprocessingml.document"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    story-get: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: list<record>, is_public: bool, ooxml_documents: list<record>, outline: string, outline_history: list<record>, revision: int, title: string>"
    story-post: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>"
    cache-nonce-get: "string"
    collaborators-post: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>"
    get-environment: "record"
    story-post-file: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>"
    story-post-file-json: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>"
    story-permission-types-get: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>"
    session-id-get: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>>"
    sessions-id-views-get: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>"
    sessions-id-views-post: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>"
    views-id-get: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>"
    story-id-get: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>"
    story-id-put: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>"
    story-id-analytics: "string"
    story-id-collaborators-get: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>"
    story-id-collaborators-post: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>"
    story-id-collaborators-inactive-post: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>"
    story-id-collaborators-userid-get: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>"
    story-id-collaborators-userid-put: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>"
    story-id-events-get: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, attributes: string, chat_prompt: string, conversation_id: string, dom_selectors: string, is_chat_hidden: bool, is_notify_enabled: bool, name: string>"
    story-id-events-post: "record"
    story-id-file-post: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>"
    story-id-file-ooxmlautomationid-get: "binary"
    story-id-messages-get: "table<body: string, id: string, remote: bool, timestamp: string, userId: string, userName: string>"
    story-id-outline-get: "string"
    story-id-public: "string"
    story-id-reveal: "string"
    story-id-sessions-get: "table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: list<record>>"
    story-id-session-post: "record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>>"
    story-id-status-get: "record<status: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["story-get" "story-post" "cache-post" "cache-nonce-get" "collaborators-post" "get-environment" "story-post-file" "story-post-file-json" "spec-no-tags" "story-outline-schema" "story-permission-types-get" "session-id-delete" "session-id-get" "sessions-id-views-get" "sessions-id-views-post" "views-id-delete" "views-id-get" "story-id-delete" "story-id-get" "story-id-put" "story-id-analytics" "story-id-collaborators-get" "story-id-collaborators-post" "story-id-collaborators-userid-permissiontype-get" "story-id-collaborators-inactive-post" "story-id-collaborators-userid-delete" "story-id-collaborators-userid-get" "story-id-collaborators-userid-put" "story-id-events-get" "story-id-events-post" "story-id-file-post" "story-id-file-ooxmlautomationid-delete" "story-id-file-ooxmlautomationid-get" "story-id-messages-get" "story-id-messages-post" "story-id-outline-get" "story-id-outline-post" "story-id-public" "story-id-reveal" "story-id-sessions-get" "story-id-session-post" "story-id-status-get" "commands"] | sort) } | get name | first)
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

# Story: Get List of User Stories
#
# GET /
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: list<record>, is_public: bool, ooxml_documents: list<record>, outline: string, outline_history: list<record>, revision: int, title: string>
# operationId: story_get
export def "story-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/"
    query: [{name: include_relationships, var: include_relationships}, {name: include_outline, var: include_outline}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_relationships: $include_relationships, include_outline: $include_outline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Upload
#
# POST /
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>
# operationId: story_post
export def "story-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
  --outline: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: include_outline, var: include_outline}]
    body: {content_type: "application/json", kind: json, fields: [{name: outline, var: outline}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_outline: $include_outline, outline: $outline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cache: Store Subdocument
#
# POST /cache
# operationId: cache_post
export def "cache-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-user-id: string # format: uuid
  --nonce: string # format: uuid
  --subdocument: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/cache"
    body: {content_type: "application/json", kind: json, fields: [{name: current_user_id, var: current_user_id}, {name: nonce, var: nonce}, {name: subdocument, var: subdocument}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    current_user_id: $current_user_id, nonce: $nonce, subdocument: $subdocument
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cache: Get Subdocument
#
# GET /cache/{nonce}
# Returns: string
# operationId: cache_nonce_get
export def "cache-nonce-get" [
  nonce: string
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
    path: "/cache/{nonce}"
    path_params: [{name: nonce, var: nonce}]
    accept: ["text/html"]
    ok: [200]
    auth: bearer
  } {
    nonce: $nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collborators: Bulk Update (Admin Only)
#
# POST /collaborators
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>
# operationId: collaborators_post
export def "collaborators-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --lead-id: int # format: int32
  --user-id: string # format: uuid
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collaborators"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: lead_id, var: lead_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active: $active, lead_id: $lead_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Environment: Get
#
# GET /environment/
# Returns: record
# operationId: get_environment
export def "get-environment" [
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
    path: "/environment/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Upload a File
#
# POST /file
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>
# operationId: story_post_file
export def "story-post-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
  --file: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file"
    query: [{name: include_outline, var: include_outline}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_outline: $include_outline, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Upload a File (base64)
#
# POST /file/json
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>
# operationId: story_post_file_json
export def "story-post-file-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
  --content-length: int
  --file: string
  --file-name: string
  --mimetype: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file/json"
    query: [{name: include_outline, var: include_outline}]
    body: {content_type: "application/json", kind: json, fields: [{name: content_length, var: content_length}, {name: file, var: file}, {name: file_name, var: file_name}, {name: mimetype, var: mimetype}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_outline: $include_outline, content_length: $content_length, file: $file, file_name: $file_name, mimetype: $mimetype
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specification: No tags
#
# GET /no_tags_spec
# operationId: spec_no_tags
export def "spec-no-tags" [
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
    path: "/no_tags_spec"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Outline Schema
#
# GET /outline-schema/{schema_version}/story-outline.json
# operationId: story_outline_schema
export def "story-outline-schema" [
  schema_version: string
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
    path: "/outline-schema/{schema_version}/story-outline.json"
    path_params: [{name: schema_version, var: schema_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permissions: List Permission Types
#
# GET /permission_types
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>
# operationId: story_permission_types_get
export def "story-permission-types-get" [
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
    path: "/permission_types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sessions: Delete by Id
#
# DELETE /sessions/{session_id}
# operationId: session_id_delete
export def "session-id-delete" [
  session_id: string
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
    method: delete
    path: "/sessions/{session_id}"
    path_params: [{name: session_id, var: session_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sessions: Get
#
# GET /sessions/{session_id}
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>>
# operationId: session_id_get
export def "session-id-get" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sessions/{session_id}"
    path_params: [{name: session_id, var: session_id}]
    query: [{name: include_relationships, var: include_relationships}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    session_id: $session_id, include_relationships: $include_relationships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Views: List Session Views
#
# GET /sessions/{session_id}/views
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>
# operationId: sessions_id_views_get
export def "sessions-id-views-get" [
  session_id: string
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
    path: "/sessions/{session_id}/views"
    path_params: [{name: session_id, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Views: Create A Session View
#
# POST /sessions/{session_id}/views
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>
# operationId: sessions_id_views_post
export def "sessions-id-views-post" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-m-secs: int
  --additional: string
  end_time: string # format: date-time
  page_number: int
  start_time: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sessions/{session_id}/views"
    path_params: [{name: session_id, var: session_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeMSecs, var: active_m_secs}, {name: additional, var: additional}, {name: endTime, var: end_time}, {name: pageNumber, var: page_number}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    session_id: $session_id, active_m_secs: $active_m_secs, additional: $additional, end_time: $end_time, page_number: $page_number, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Views: Delete by Id
#
# DELETE /views/{view_id}
# operationId: views_id_delete
export def "views-id-delete" [
  view_id: string
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
    method: delete
    path: "/views/{view_id}"
    path_params: [{name: view_id, var: view_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Views: Get View
#
# GET /views/{view_id}
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>
# operationId: views_id_get
export def "views-id-get" [
  view_id: string
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
    path: "/views/{view_id}"
    path_params: [{name: view_id, var: view_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Delete by Id
#
# DELETE /{id}
# operationId: story_id_delete
export def "story-id-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Get by Id
#
# GET /{id}
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>
# operationId: story_id_get
export def "story-id-get" [
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
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
  --qp-full: oneof<nothing, bool> # Pull a story object with associated collaborator user, permission, and session data(faster if cached from prior api call) (spec name: full)
  --refresh-cache: oneof<nothing, bool> # Force the api reload the `Story full` object
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_relationships, var: include_relationships}, {name: include_outline, var: include_outline}, {name: full, var: qp_full}, {name: refresh_cache, var: refresh_cache}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_relationships: $include_relationships, include_outline: $include_outline, qp_full: $qp_full, refresh_cache: $refresh_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Modify
#
# PUT /{id}
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>
# operationId: story_id_put
export def "story-id-put" [
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
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
  --created-at: string # format: date-time
  --created-by: string # format: uuid
  --body-id: string # format: uuid (spec name: id)
  --updated-at: string # format: date-time
  --updated-by: string # format: uuid
  --collaborators: list # item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, active?: bool, email?: string, lead_id?: int, name?: string, permission_type?: record, permission_type_id?: string, story_id?: string, user_id?: string}
  --is-public: oneof<nothing, bool>
  --ooxml-documents: list # item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, delete_target_on_story_delete?: bool, ooxml_automation_id?: string, story_id?: string}
  --outline: string # nullable
  --outline-history: list # item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, collaborator_user_id?: string, outline?: string, revision_number?: int, story_id?: string}
  --revision: int # format: Int32
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_outline, var: include_outline}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: created_by, var: created_by}, {name: id, var: body_id}, {name: updated_at, var: updated_at}, {name: updated_by, var: updated_by}, {name: collaborators, var: collaborators}, {name: is_public, var: is_public}, {name: ooxml_documents, var: ooxml_documents}, {name: outline, var: outline}, {name: outline_history, var: outline_history}, {name: revision, var: revision}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_outline: $include_outline, created_at: $created_at, created_by: $created_by, body_id: $body_id, updated_at: $updated_at, updated_by: $updated_by, collaborators: $collaborators, is_public: $is_public, ooxml_documents: $ooxml_documents, outline: $outline, outline_history: $outline_history, revision: $revision, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: View Analytics
#
# GET /{id}/analytics
# Returns: string
# operationId: story_id_analytics
export def "story-id-analytics" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/{id}/analytics"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Collaborators: List
#
# GET /{id}/collaborators
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>
# operationId: story_id_collaborators_get
export def "story-id-collaborators-get" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{id}/collaborators"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Collaborators: Add New User
#
# POST /{id}/collaborators
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>
# operationId: story_id_collaborators_post
export def "story-id-collaborators-post" [
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
  --collaborator-type: string
  --user-email: string
  --user-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{id}/collaborators"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: collaborator_type, var: collaborator_type}, {name: user_email, var: user_email}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, collaborator_type: $collaborator_type, user_email: $user_email, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permissions: Story Authorization for a User
#
# GET /{id}/collaborators/authorize/{story_collaborator_userid}/{permissiontype}
# operationId: story_id_collaborators_userid_permissiontype_get
export def "story-id-collaborators-userid-permissiontype-get" [
  id: string
  story_collaborator_userid: string
  permissiontype: string
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
    path: "/{id}/collaborators/authorize/{story_collaborator_userid}/{permissiontype}"
    path_params: [{name: id, var: id}, {name: story_collaborator_userid, var: story_collaborator_userid}, {name: permissiontype, var: permissiontype}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, story_collaborator_userid: $story_collaborator_userid, permissiontype: $permissiontype
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Collaborators: Edit Inactive User Permission
#
# POST /{id}/collaborators/inactive
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>
# operationId: story_id_collaborators_inactive_post
export def "story-id-collaborators-inactive-post" [
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
  --action: string
  --lead-id: int # format: int32
  --user-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{id}/collaborators/inactive"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: lead_id, var: lead_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, action: $action, lead_id: $lead_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Collaborators: Remove User
#
# DELETE /{id}/collaborators/{story_collaborator_userid}
# operationId: story_id_collaborators_userid_delete
export def "story-id-collaborators-userid-delete" [
  id: string
  story_collaborator_userid: string
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
    method: delete
    path: "/{id}/collaborators/{story_collaborator_userid}"
    path_params: [{name: id, var: id}, {name: story_collaborator_userid, var: story_collaborator_userid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, story_collaborator_userid: $story_collaborator_userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Collaborators: Access Permissions
#
# GET /{id}/collaborators/{story_collaborator_userid}
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>
# operationId: story_id_collaborators_userid_get
export def "story-id-collaborators-userid-get" [
  id: string
  story_collaborator_userid: string
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
    path: "/{id}/collaborators/{story_collaborator_userid}"
    path_params: [{name: id, var: id}, {name: story_collaborator_userid, var: story_collaborator_userid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, story_collaborator_userid: $story_collaborator_userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story Collaborators: Edit Access Rights
#
# PUT /{id}/collaborators/{story_collaborator_userid}
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>
# operationId: story_id_collaborators_userid_put
export def "story-id-collaborators-userid-put" [
  id: string
  story_collaborator_userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # format: date-time
  --created-by: string # format: uuid
  --body-id: string # format: uuid (spec name: id)
  --updated-at: string # format: date-time
  --updated-by: string # format: uuid
  --active: oneof<nothing, bool> # nullable
  --email: string
  --lead-id: int # nullable, format: int32
  --name: string
  --permission-type: record # A permission type that can be applied to story collaborator — shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, can_add_collaborators?: bool, can_delete?: bool, can_edit?: bool, can_view?: bool, name?: string}
  --permission-type-id: string # format: uuid
  --story-id: string # format: uuid
  --user-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{id}/collaborators/{story_collaborator_userid}"
    path_params: [{name: id, var: id}, {name: story_collaborator_userid, var: story_collaborator_userid}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: created_by, var: created_by}, {name: id, var: body_id}, {name: updated_at, var: updated_at}, {name: updated_by, var: updated_by}, {name: active, var: active}, {name: email, var: email}, {name: lead_id, var: lead_id}, {name: name, var: name}, {name: permission_type, var: permission_type}, {name: permission_type_id, var: permission_type_id}, {name: story_id, var: story_id}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, story_collaborator_userid: $story_collaborator_userid, created_at: $created_at, created_by: $created_by, body_id: $body_id, updated_at: $updated_at, updated_by: $updated_by, active: $active, email: $email, lead_id: $lead_id, name: $name, permission_type: $permission_type, permission_type_id: $permission_type_id, story_id: $story_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Events: List Events
#
# GET /{id}/events
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, attributes: string, chat_prompt: string, conversation_id: string, dom_selectors: string, is_chat_hidden: bool, is_notify_enabled: bool, name: string>
# operationId: story_id_events_get
export def "story-id-events-get" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{id}/events"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Events: Manage Events
#
# POST /{id}/events
# Returns: record
# operationId: story_id_events_post
export def "story-id-events-post" [
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
  --action: string@action-completer
  --action-params: record
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{id}/events"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_params, var: action_params}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action: $action, action_params: $action_params, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Upload a File To Existing Story
#
# POST /{id}/file
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, is_public: bool, ooxml_documents: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, delete_target_on_story_delete: bool, ooxml_automation_id: string, story_id: string>, outline: string, outline_history: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator_user_id: string, outline: string, revision_number: int, story_id: string>, revision: int, title: string>
# operationId: story_id_file_post
export def "story-id-file-post" [
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
  --replace-existing: oneof<nothing, bool> # Indicates whether a put or post method would replace the existing contents
  --obsolete-id: string # A primary key pointing to an obsolete item in the story. Item type is context-dependent (format: uuid)
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline. Defaults to true. Useful for speeding up processing times.
  --file: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{id}/file"
    path_params: [{name: id, var: id}]
    query: [{name: replace_existing, var: replace_existing}, {name: obsolete_id, var: obsolete_id}, {name: include_outline, var: include_outline}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, replace_existing: $replace_existing, obsolete_id: $obsolete_id, include_outline: $include_outline, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Delete Subdocument
#
# DELETE /{id}/file/{ooxml_automation_id}
# operationId: story_id_file_ooxmlautomationid_delete
export def "story-id-file-ooxmlautomationid-delete" [
  id: string
  ooxml_automation_id: string
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
    method: delete
    path: "/{id}/file/{ooxml_automation_id}"
    path_params: [{name: id, var: id}, {name: ooxml_automation_id, var: ooxml_automation_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ooxml_automation_id: $ooxml_automation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Download Updated File
#
# GET /{id}/file/{ooxml_automation_id}
# Returns: binary
# operationId: story_id_file_ooxmlautomationid_get
export def "story-id-file-ooxmlautomationid-get" [
  id: string
  ooxml_automation_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/{id}/file/{ooxml_automation_id}"
    path_params: [{name: id, var: id}, {name: ooxml_automation_id, var: ooxml_automation_id}]
    accept: ["application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ooxml_automation_id: $ooxml_automation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Conversation: List Conversation Messages
#
# GET /{id}/messages
# Returns: table<body: string, id: string, remote: bool, timestamp: string, userId: string, userName: string>
# operationId: story_id_messages_get
export def "story-id-messages-get" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{id}/messages"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Conversation: Send a Message
#
# POST /{id}/messages
# operationId: story_id_messages_post
export def "story-id-messages-post" [
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
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{id}/messages"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Get Story Outline
#
# GET /{id}/outline
# Returns: string
# operationId: story_id_outline_get
export def "story-id-outline-get" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/{id}/outline"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Post Story Outline
#
# POST /{id}/outline
# operationId: story_id_outline_post
export def "story-id-outline-post" [
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
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{id}/outline"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Public Link to Story Reveal.js Document
#
# GET /{id}/public/
# Returns: string
# operationId: story_id_public
export def "story-id-public" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/{id}/public/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Get Story at Reveal.js Document
#
# GET /{id}/reveal
# Returns: string
# operationId: story_id_reveal
export def "story-id-reveal" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/{id}/reveal"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sessions: List Story Sessions
#
# GET /{id}/sessions
# Returns: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: list<record>>
# operationId: story_id_sessions_get
export def "story-id-sessions-get" [
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
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{id}/sessions"
    path_params: [{name: id, var: id}]
    query: [{name: include_relationships, var: include_relationships}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_relationships: $include_relationships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sessions: Create a Session
#
# POST /{id}/sessions
# Returns: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>>
# operationId: story_id_session_post
export def "story-id-session-post" [
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
  --collaborator-user-id: string # format: uuid
  --host: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{id}/sessions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: collaboratorUserId, var: collaborator_user_id}, {name: host, var: host}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, collaborator_user_id: $collaborator_user_id, host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Story: Get Story Status
#
# GET /{id}/status
# Returns: record<status: string>
# operationId: story_id_status_get
export def "story-id-status-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{id}/status"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
