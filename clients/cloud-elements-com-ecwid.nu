# Auto-generated client for ecwid vapi-v2
# Source: https://api.apis.guru/v2/specs/cloud-elements.com/ecwid/api-v2/swagger.json
# Auth: --token flag or $env.ECWID_TOKEN

const CLIENT = {
  base_url: "https://api.cloud-elements.com/elements/api-v2"
  token_env_var: "ECWID_TOKEN"
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

def base-url-completer [] { ["https://api.cloud-elements.com/elements/api-v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["application/json" "application/jsonl" "txt/csv"] }
def accept-completer [] { ["application/json" "application/jsonl" "text/csv"] }
def elements-version-completer [] { ["Helium" "Hydrogen"] }
def accept-completer-1 [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-bulk-download: "record<id: string, instance_id: float, status: string>"
    get-bulk-jobs: "record<completion_time: int, createdDate: int, error_count: int, fileFormat: string, id: int, instanceId: int, job_direction: string, job_query: string, job_reset_attempt: int, job_state: string, notification_url: string, object_name: string, record_count: int, status: string>"
    create-bulk-query: "record<id: string, instance_id: float, status: string>"
    replace-bulk-cancel: "record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string>"
    get-bulk-errors: "list<string>"
    get-bulk-status: "record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string>"
    get-bulk-by-object-name: "binary"
    create-bulk-by-object-name: "record<id: string, instanceId: int, status: string>"
    get-customers: "table<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: list<record>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>"
    create-customer: "record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>"
    get-customer-by-id: "record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>"
    update-customer-by-id: "record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>"
    get-customers-orders: "table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>"
    get-objects: "list<string>"
    get-objects-object-name-docs: "record<basePath: string, definitions: record<definition-name: record<properties: record>>, host: string, info: record<contact: record<email: string>, title: string, version: string>, paths: record<\"/contacts\": record<post: record>>, schemes: list<string>, swagger: string, tags: table<name: string>>"
    get-objects-object-name-metadata: "record<fields: table<mask: string, type: string, vendorDisplayName: string, vendorPath: string, vendorReadOnly: bool, vendorRequired: bool>>"
    get-orders: "table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>"
    create-order: "record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>"
    get-order-by-id: "record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>"
    update-order-by-id: "record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>"
    get-orders-payments: "table<paymentMethod: string, paymentStatus: string>"
    get-orders-refunds: "table<paymentMethod: string, paymentStatus: string>"
    get-ping: "record<dateTime: string, endpoint: string, valid: bool>"
    get-products: "table<attributes: list<record>, borderInfo: record<dominatingColor: record, homogeneity: bool>, categories: list<record>, categoryIds: list<int>, combinations: list<record>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: list<record>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: list<record>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list>, name: string, options: list<record>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list, relatedCategory: record>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list, enabledMethods: list, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list>, taxes: list<record>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<\"{quantity}\": float>>"
    create-product: "record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<\"{quantity}\": float>>"
    get-product-by-id: "record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<\"{quantity}\": float>>"
    update-product-by-id: "record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<\"{quantity}\": float>>"
    get-by-object-name: "table<objectField: string>"
    get-object-name-by-object-id: "record<objectField: string>"
    update-object-name-by-object-id: "record<objectField: string>"
    replace-object-name-by-object-id: "record<objectField: string>"
    get-object-name-by-child-object-name: "table<objectField: string>"
    get-object-name-by-child-object-id: "record<objectField: string>"
    update-object-name-by-child-object-id: "record<objectField: string>"
    replace-object-name-by-child-object-id: "record<objectField: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-bulk-download" "get-bulk-jobs" "create-bulk-query" "replace-bulk-cancel" "get-bulk-errors" "get-bulk-status" "get-bulk-by-object-name" "create-bulk-by-object-name" "get-customers" "create-customer" "delete-customer-by-id" "get-customer-by-id" "update-customer-by-id" "get-customers-orders" "get-objects" "get-objects-object-name-docs" "get-objects-object-name-metadata" "get-orders" "create-order" "delete-order-by-id" "get-order-by-id" "update-order-by-id" "get-orders-payments" "get-orders-refunds" "get-ping" "get-products" "create-product" "delete-product-by-id" "get-product-by-id" "update-product-by-id" "get-by-object-name" "create-by-object-name" "delete-object-name-by-object-id" "get-object-name-by-object-id" "update-object-name-by-object-id" "replace-object-name-by-object-id" "get-object-name-by-child-object-name" "create-object-name-by-child-object-name" "delete-object-name-by-child-object-id" "get-object-name-by-child-object-id" "update-object-name-by-child-object-id" "replace-object-name-by-child-object-id" "commands"] | sort) } | get name | first)
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

# Create a new bulk download job (asynchronous)
#
# POST /bulk/download
# Returns: record<id: string, instance_id: float, status: string>
# operationId: createBulkDownload
export def "create-bulk-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --api-limit: int # format: int32
  --continue-from-job-id: int # format: int32
  --docs-hub-details: record # shape: {instanceId?: string, path?: string}
  --filter-date-field: string
  --filter-nulls: oneof<nothing, bool>
  format: string@format-completer
  --from: string # format: date-time
  --limit: int # format: int32
  --notification-url: string
  object_name: string
  --page-size: int # format: int32
  --query: record # shape: {anyKey?: string}
  --select-fields: string
  --to: string # format: date-time
  --where: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bulk/download"
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiLimit, var: api_limit}, {name: continueFromJobId, var: continue_from_job_id}, {name: docsHubDetails, var: docs_hub_details}, {name: filterDateField, var: filter_date_field}, {name: filterNulls, var: filter_nulls}, {name: format, var: format}, {name: from, var: from}, {name: limit, var: limit}, {name: notificationUrl, var: notification_url}, {name: objectName, var: object_name}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: selectFields, var: select_fields}, {name: to, var: to}, {name: where, var: where}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_limit: $api_limit, continue_from_job_id: $continue_from_job_id, docs_hub_details: $docs_hub_details, filter_date_field: $filter_date_field, filter_nulls: $filter_nulls, format: $format, from: $from, limit: $limit, notification_url: $notification_url, object_name: $object_name, page_size: $page_size, query: $query, select_fields: $select_fields, to: $to, where: $where
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all the bulk jobs for an instance
#
# GET /bulk/jobs
# Returns: record<completion_time: int, createdDate: int, error_count: int, fileFormat: string, id: int, instanceId: int, job_direction: string, job_query: string, job_reset_attempt: int, job_state: string, notification_url: string, object_name: string, record_count: int, status: string>
# operationId: getBulkJobs
export def "get-bulk-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query. For example to get all upload jobs the expression would be where=job_direction='UPLOAD'. The following fields are valid search fields 'object_name', 'job_status', 'job_direction', 'record_count'
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --page-size: int # The page size for pagination, which defaults to 200 if not supplied (format: int64)
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulk/jobs"
    query: [{name: where, var: where}, {name: nextPage, var: next_page}, {name: pageSize, var: page_size}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, next_page: $next_page, page_size: $page_size, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an asynchronous bulk query job.
#
# POST /bulk/query
# Returns: record<id: string, instance_id: float, status: string>
# operationId: createBulkQuery
export def "create-bulk-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The CEQL query. When this parameter is omitted, all objects of the given type are returned via the bulk job. Endpoint limiters may still apply.
  --last-run-date: string # The last time this query was run. This is optional. You can also have this parameter in the query and leave this blank - optional eg. '2014-10-06T13:22:17-08:00'
  --from: string # The created/updated date of the object to filter on - optional eg. '2014-10-06T13:22:17-08:00'
  --to: string # The created/updated date of the object to filter on - optional eg. '2014-10-06T13:22:17-08:00'
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --elements-async-callback-url: string # The Url to send the notification to when the Job is completed
  --meta-data: string # Optional JSON MetaData that contains callback-payload and fileName, ex: {"callback-payload" : , "fileName" : "{Date format}_Name of the file"}. If the fileName is MyFile then pass metadata as {"fileName" : "{yyyy-MM-dd HH:mm:ss}_MyFile"}. The valid date formats are "yyyy-MM-dd'T'HH:mm:ssXXX", "yyyy-MM-dd'T'HH:mm:ss'Z'", "yyyy-MM-dd'T'HH:mm:ss.SXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd HH:mm:ss", "yyyy.MM.dd G 'at' HH:mm:ss z", "h:mm a", "yyyyy.MMMMM.dd GGG hh:mm aaa" and "yyMMddHHmmssZ". callback-payload - is passed back in bulk job notification
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bulk/query"
    query: [{name: q, var: q}, {name: lastRunDate, var: last_run_date}, {name: from, var: from}, {name: to, var: to}]
    header: [{name: Authorization, var: authorization, required: true}, {name: Elements-Async-Callback-Url, var: elements_async_callback_url}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: metaData, var: meta_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, last_run_date: $last_run_date, from: $from, to: $to, authorization: $authorization, elements_async_callback_url: $elements_async_callback_url, meta_data: $meta_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an asynchronous bulk query job.
#
# PUT /bulk/{id}/cancel
# Returns: record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string>
# operationId: replaceBulkCancel
export def "replace-bulk-cancel" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/bulk/{id}/cancel"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the errors of a bulk job.
#
# GET /bulk/{id}/errors
# Returns: list<string>
# operationId: getBulkErrors
export def "get-bulk-errors" [
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
  --page-size: int # The page size for pagination, which defaults to 200 if not supplied (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bulk/{id}/errors"
    path_params: [{name: id, var: id}]
    query: [{name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the status of a bulk job.
#
# GET /bulk/{id}/status
# Returns: record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string>
# operationId: getBulkStatus
export def "get-bulk-status" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulk/{id}/status"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the results of an asynchronous bulk query.
#
# GET /bulk/{id}/{objectName}
# Returns: binary
# operationId: getBulkByObjectName
export def "get-bulk-by-object-name" [
  id: string
  object_name: string
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/bulk/{id}/{objectName}"
    path_params: [{name: id, var: id}, {name: objectName, var: object_name}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["text/csv", "application/json", "application/jsonl"]
    ok: [200]
    auth: bearer
  } {
    id: $id, object_name: $object_name, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Upload a file of objects to be bulk uploaded to the provider.
#
# POST /bulk/{objectName}
# Returns: record<id: string, instanceId: int, status: string>
# operationId: createBulkByObjectName
export def "create-bulk-by-object-name" [
  object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --elements-async-callback-url: string # The Url to send the notification to when the Job is completed
  --meta-data: string # Optional JSON MetaData that contains callback-payload, path or format, ex: {"path" :<path for the sub resource>, "format": <json/csv>, "callback-payload":<json>}. path - is passed to the endpoint for bulk loading the data into a nested object. Optional JSON Metadata that contains identifierFieldName, action, listId or campaignId. The identifierField name is used for upserts and the optional fields like listId or campaignId. Example: {"listId":"1014","action":"upsert"}. If the Upload format is JSON pass metadata as {"format":"json"}. callback-payload - is passed back in bulk job notification
  --file: path # The file of objects to bulk load. If the JSON file upload, each JSON record should be in a single line
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bulk/{objectName}"
    path_params: [{name: objectName, var: object_name}]
    header: [{name: Authorization, var: authorization, required: true}, {name: Elements-Async-Callback-Url, var: elements_async_callback_url}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: metaData, var: meta_data}, {name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, authorization: $authorization, elements_async_callback_url: $elements_async_callback_url, meta_data: $meta_data, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find customers in the eCommerce system, using the provided CEQL search expression. If no search expression is provided, all records will be retrieved
#
# GET /customers
# Returns: table<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: list<record>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>
# operationId: getCustomers
export def "get-customers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). Supported search terms: customer_id and customer_email. All other search criteria are ignored. NOTE: When searching by customer_id, do not quote the value (ex: customer_id=15693430), as the ID is a number rather than a string. When searching by email, quote the value (ex: customer_email='a@b.c'), as the email parameter is a string
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers"
    query: [{name: where, var: where}, {name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new customer in eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Customer' model are those required to create a new customer
#
# POST /customers
# Returns: record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>
# operationId: createCustomer
export def "create-customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --billing-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --customer-group-id: int # format: int64
  email: string # customer email
  --password: string # customer password
  --shipping-addresses: list # item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --tax-exempt: oneof<nothing, bool>
  --tax-id: float # format: double
  --tax-id-valid: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers"
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingPerson, var: billing_person}, {name: customerGroupId, var: customer_group_id}, {name: email, var: email}, {name: password, var: password}, {name: shippingAddresses, var: shipping_addresses}, {name: taxExempt, var: tax_exempt}, {name: taxId, var: tax_id}, {name: taxIdValid, var: tax_id_valid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, billing_person: $billing_person, customer_group_id: $customer_group_id, email: $email, password: $password, shipping_addresses: $shipping_addresses, tax_exempt: $tax_exempt, tax_id: $tax_id, tax_id_valid: $tax_id_valid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a customer associated with a given ID from your eCommerce system. Specifying a customer associated with a given ID that does not exist will result in an error message
#
# DELETE /customers/{id}
# operationId: deleteCustomerById
export def "delete-customer-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a customer associated with a given ID from the eCommerce system. Specifying a customer with an ID that does not exist will result in an error response
#
# GET /customers/{id}
# Returns: record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>
# operationId: getCustomerById
export def "get-customer-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an customer associated with a given ID in the eCommerce system.The update API uses the PATCH HTTP verb, so only those fields provided in the customer object will be updated, and those fields not provided will be left alone. Updating a customer with a specified ID that does not exist will result in an error response
#
# PATCH /customers/{id}
# Returns: record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string>
# operationId: updateCustomerById
export def "update-customer-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --billing-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --customer-group-id: int # format: int64
  --email: string # customer email
  --password: string # customer password
  --shipping-addresses: list # item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --tax-exempt: oneof<nothing, bool>
  --tax-id: float # format: double
  --tax-id-valid: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/customers/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingPerson, var: billing_person}, {name: customerGroupId, var: customer_group_id}, {name: email, var: email}, {name: password, var: password}, {name: shippingAddresses, var: shipping_addresses}, {name: taxExempt, var: tax_exempt}, {name: taxId, var: tax_id}, {name: taxIdValid, var: tax_id_valid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization, billing_person: $billing_person, customer_group_id: $customer_group_id, email: $email, password: $password, shipping_addresses: $shipping_addresses, tax_exempt: $tax_exempt, tax_id: $tax_id, tax_id_valid: $tax_id_valid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find orders in the customer associated with a given ID. If the customer does not exist, an error response will be returned. If no orders are found in the given customer then an empty array will be returned
#
# GET /customers/{id}/orders
# Returns: table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>
# operationId: getCustomersOrders
export def "get-customers-orders" [
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
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/orders"
    path_params: [{name: id, var: id}]
    query: [{name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all the available objects.
#
# GET /objects
# Returns: list<string>
# operationId: getObjects
export def "get-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --elements-version: string@elements-version-completer # Elements Version to be used for getting metadata, possible options are Hydrogen, Helium. Default value is Hydrogen
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/objects"
    header: [{name: Authorization, var: authorization, required: true}, {name: Elements-Version, var: elements_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, elements_version: $elements_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get swagger docs for an object.
#
# GET /objects/{objectName}/docs
# Returns: record<basePath: string, definitions: record<definition-name: record<properties: record>>, host: string, info: record<contact: record<email: string>, title: string, version: string>, paths: record<"/contacts": record<post: record>>, schemes: list<string>, swagger: string, tags: table<name: string>>
# operationId: getObjectsObjectNameDocs
export def "get-objects-object-name-docs" [
  object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --discovery: oneof<nothing, bool> # Include discovery metadata in definitions
  --resolve-references: oneof<nothing, bool> # Optionally resolve swagger references for an inline object definition
  --basic: oneof<nothing, bool> # Include only OpenAPI / Swagger properties in definitions
  --version: string # The element swagger version to get the corresponding element swagger, Passing in "-1" gives latest element swagger (default: -1)
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/objects/{objectName}/docs"
    path_params: [{name: objectName, var: object_name}]
    query: [{name: discovery, var: discovery}, {name: resolveReferences, var: resolve_references}, {name: basic, var: basic}, {name: version, var: version}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, discovery: $discovery, resolve_references: $resolve_references, basic: $basic, version: $version, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all the field for an object.
#
# GET /objects/{objectName}/metadata
# Returns: record<fields: table<mask: string, type: string, vendorDisplayName: string, vendorPath: string, vendorReadOnly: bool, vendorRequired: bool>>
# operationId: getObjectsObjectNameMetadata
export def "get-objects-object-name-metadata" [
  object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --elements-version: string@elements-version-completer # Elements Version to be used for getting metadata, possible options are Hydrogen, Helium. Default value is Hydrogen
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/objects/{objectName}/metadata"
    path_params: [{name: objectName, var: object_name}]
    header: [{name: Authorization, var: authorization, required: true}, {name: Elements-Version, var: elements_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, authorization: $authorization, elements_version: $elements_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find orders in the eCommerce system, using the provided CEQL search expression. If no search expression is provided, all records will be retrieved
#
# GET /orders
# Returns: table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>
# operationId: getOrders
export def "get-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). Supported search terms: date, from_date, to_date, from_update_date, to_update_date, order, from_order, to_order, customer_id, customer_email and statuses. All other search criteria are ignored
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders"
    query: [{name: where, var: where}, {name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an order in the eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Order' model are those required to create a new order.The paymentStatus can only be AWAITING_PAYMENT or INCOMPLETE.The fulfillmentStatus can only be AWAITING_PROCESSING
#
# POST /orders
# Returns: record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>
# operationId: createOrder
export def "create-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --billing-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --coupon-discount: float # format: double
  --customer-id: float # format: double
  --customer-tax-exempt: oneof<nothing, bool>
  --customer-tax-id: int # format: int64
  --customer-tax-id-valid: oneof<nothing, bool>
  --discount: float # format: double
  --email: string
  fulfillment_status: string # AWAITING_PROCESSING, PROCESSING, SHIPPED, DELIVERED, WILL_NOT_DELIVER, RETURNED, READY_FOR_PICKUP
  --global-referer: string
  --hidden: oneof<nothing, bool>
  --items: list # item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
  --membership-based-discount: float # format: double
  --order-comments: string
  --payment-method: string
  --payment-module: string
  payment_status: string # AWAITING_PAYMENT, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED, INCOMPLETE
  --private-admin-notes: string
  --referer-url: string
  --reversed-tax-applied: oneof<nothing, bool>
  --sample: oneof<nothing, bool>
  --shipping-method: string
  --shipping-option: record # shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
  --shipping-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --subtotal: float # format: double
  --tax: float # format: double
  --total: float # format: double
  --total-and-membership-based-discount: float # format: double
  --volume-discount: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders"
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingPerson, var: billing_person}, {name: couponDiscount, var: coupon_discount}, {name: customerId, var: customer_id}, {name: customerTaxExempt, var: customer_tax_exempt}, {name: customerTaxId, var: customer_tax_id}, {name: customerTaxIdValid, var: customer_tax_id_valid}, {name: discount, var: discount}, {name: email, var: email}, {name: fulfillmentStatus, var: fulfillment_status}, {name: globalReferer, var: global_referer}, {name: hidden, var: hidden}, {name: items, var: items}, {name: membershipBasedDiscount, var: membership_based_discount}, {name: orderComments, var: order_comments}, {name: paymentMethod, var: payment_method}, {name: paymentModule, var: payment_module}, {name: paymentStatus, var: payment_status}, {name: privateAdminNotes, var: private_admin_notes}, {name: refererUrl, var: referer_url}, {name: reversedTaxApplied, var: reversed_tax_applied}, {name: sample, var: sample}, {name: shippingMethod, var: shipping_method}, {name: shippingOption, var: shipping_option}, {name: shippingPerson, var: shipping_person}, {name: subtotal, var: subtotal}, {name: tax, var: tax}, {name: total, var: total}, {name: totalAndMembershipBasedDiscount, var: total_and_membership_based_discount}, {name: volumeDiscount, var: volume_discount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, billing_person: $billing_person, coupon_discount: $coupon_discount, customer_id: $customer_id, customer_tax_exempt: $customer_tax_exempt, customer_tax_id: $customer_tax_id, customer_tax_id_valid: $customer_tax_id_valid, discount: $discount, email: $email, fulfillment_status: $fulfillment_status, global_referer: $global_referer, hidden: $hidden, items: $items, membership_based_discount: $membership_based_discount, order_comments: $order_comments, payment_method: $payment_method, payment_module: $payment_module, payment_status: $payment_status, private_admin_notes: $private_admin_notes, referer_url: $referer_url, reversed_tax_applied: $reversed_tax_applied, sample: $sample, shipping_method: $shipping_method, shipping_option: $shipping_option, shipping_person: $shipping_person, subtotal: $subtotal, tax: $tax, total: $total, total_and_membership_based_discount: $total_and_membership_based_discount, volume_discount: $volume_discount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an order associated with a given ID from your eCommerce system. Specifying an order associated with a given ID that does not exist will result in an error message
#
# DELETE /orders/{id}
# operationId: deleteOrderById
export def "delete-order-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/orders/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an order associated with a given ID from the eCommerce system. Specifying an order with an ID that does not exist will result in an error response
#
# GET /orders/{id}
# Returns: record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>
# operationId: getOrderById
export def "get-order-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an order associated with a given ID in the eCommerce system. The update API uses the PATCH HTTP verb, so only those fields provided in the order object will be updated, and those fields not provided will be left alone. Updating an order with a specified ID that does not exist will result in an error response
#
# PATCH /orders/{id}
# Returns: record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float>
# operationId: updateOrderById
export def "update-order-by-id" [
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
  --action: string # An action to perform on the order: cancel, reopen or close. If left blank then the order is updated but no action is taken
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --billing-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --coupon-discount: float # format: double
  --customer-id: float # format: double
  --customer-tax-exempt: oneof<nothing, bool>
  --customer-tax-id: int # format: int64
  --customer-tax-id-valid: oneof<nothing, bool>
  --discount: float # format: double
  --email: string
  --fulfillment-status: string # AWAITING_PROCESSING, PROCESSING, SHIPPED, DELIVERED, WILL_NOT_DELIVER, RETURNED, READY_FOR_PICKUP
  --global-referer: string
  --hidden: oneof<nothing, bool>
  --items: list # item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
  --membership-based-discount: float # format: double
  --order-comments: string
  --payment-module: string
  --payment-status: string # AWAITING_PAYMENT, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED, INCOMPLETE
  --private-admin-notes: string
  --referer-url: string
  --reversed-tax-applied: oneof<nothing, bool>
  --sample: oneof<nothing, bool>
  --shipping-method: string
  --shipping-option: record # shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
  --shipping-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --subtotal: float # format: double
  --tax: float # format: double
  --taxes-on-shipping: list # item shape: {name?: string, total?: float, value?: float}
  --total: float # format: double
  --total-and-membership-based-discount: float # format: double
  --volume-discount: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: action, var: action}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingPerson, var: billing_person}, {name: couponDiscount, var: coupon_discount}, {name: customerId, var: customer_id}, {name: customerTaxExempt, var: customer_tax_exempt}, {name: customerTaxId, var: customer_tax_id}, {name: customerTaxIdValid, var: customer_tax_id_valid}, {name: discount, var: discount}, {name: email, var: email}, {name: fulfillmentStatus, var: fulfillment_status}, {name: globalReferer, var: global_referer}, {name: hidden, var: hidden}, {name: items, var: items}, {name: membershipBasedDiscount, var: membership_based_discount}, {name: orderComments, var: order_comments}, {name: paymentModule, var: payment_module}, {name: paymentStatus, var: payment_status}, {name: privateAdminNotes, var: private_admin_notes}, {name: refererUrl, var: referer_url}, {name: reversedTaxApplied, var: reversed_tax_applied}, {name: sample, var: sample}, {name: shippingMethod, var: shipping_method}, {name: shippingOption, var: shipping_option}, {name: shippingPerson, var: shipping_person}, {name: subtotal, var: subtotal}, {name: tax, var: tax}, {name: taxesOnShipping, var: taxes_on_shipping}, {name: total, var: total}, {name: totalAndMembershipBasedDiscount, var: total_and_membership_based_discount}, {name: volumeDiscount, var: volume_discount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action: $action, authorization: $authorization, billing_person: $billing_person, coupon_discount: $coupon_discount, customer_id: $customer_id, customer_tax_exempt: $customer_tax_exempt, customer_tax_id: $customer_tax_id, customer_tax_id_valid: $customer_tax_id_valid, discount: $discount, email: $email, fulfillment_status: $fulfillment_status, global_referer: $global_referer, hidden: $hidden, items: $items, membership_based_discount: $membership_based_discount, order_comments: $order_comments, payment_module: $payment_module, payment_status: $payment_status, private_admin_notes: $private_admin_notes, referer_url: $referer_url, reversed_tax_applied: $reversed_tax_applied, sample: $sample, shipping_method: $shipping_method, shipping_option: $shipping_option, shipping_person: $shipping_person, subtotal: $subtotal, tax: $tax, taxes_on_shipping: $taxes_on_shipping, total: $total, total_and_membership_based_discount: $total_and_membership_based_discount, volume_discount: $volume_discount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the payments in the eCommerce system for the specified order
#
# GET /orders/{orderId}/payments
# Returns: table<paymentMethod: string, paymentStatus: string>
# operationId: getOrdersPayments
export def "get-orders-payments" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders/{orderId}/payments"
    path_params: [{name: orderId, var: order_id}]
    query: [{name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the refunds in the eCommerce system for the specified order
#
# GET /orders/{orderId}/refunds
# Returns: table<paymentMethod: string, paymentStatus: string>
# operationId: getOrdersRefunds
export def "get-orders-refunds" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders/{orderId}/refunds"
    path_params: [{name: orderId, var: order_id}]
    query: [{name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping the Element to confirm that the Hub Element has a heartbeat. If the Element does not have a heartbeat, an error message will be returned.
#
# GET /ping
# Returns: record<dateTime: string, endpoint: string, valid: bool>
# operationId: getPing
export def "get-ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ping"
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find products in the eCommerce system, using the provided CEQL search expression. The search expression in CEQL is the WHERE clause in a typical SQL query, but without the WHERE keyword. If no search expression is provided, all records will be retrieved
#
# GET /products
# Returns: table<attributes: list<record>, borderInfo: record<dominatingColor: record, homogeneity: bool>, categories: list<record>, categoryIds: list<int>, combinations: list<record>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: list<record>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: list<record>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list>, name: string, options: list<record>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list, relatedCategory: record>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list, enabledMethods: list, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list>, taxes: list<record>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<"{quantity}": float>>
# operationId: getProducts
export def "get-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). Supported search terms: category, hidden_products. All other search criteria are ignored
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products"
    query: [{name: where, var: where}, {name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product in eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Product' model are those required to create a new product
#
# POST /products
# Returns: record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<"{quantity}": float>>
# operationId: createProduct
export def "create-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --attributes: list # item shape: {id?: int, internalName?: string, name?: string, value?: string}
  --category-ids: list<int>
  --compare-at-price: float # Product’s sale price displayed strike-out in the customer (format: double)
  --compare-to-price: float # format: double
  --created: string # format: date-time
  --default-category-id: int # format: int64
  --description: string # Product description in HTML
  --dimensions: record # shape: {height?: float, length?: float, width?: float}
  --enabled: oneof<nothing, bool> # true/false
  --favorites: record # shape: {count?: int, displayedCount?: string}
  --fixed-shipping-rate: float # format: double
  --fixed-shipping-rate-only: oneof<nothing, bool> # true/false
  --gallery-images: list # item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
  --google-item-condition: string # Google Item Condition Status
  --is-shipping-required: oneof<nothing, bool>
  --name: string # Product title
  --options: list # item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
  --price: float # Base Product price (format: double)
  --product-class-id: int # Id of the product type that this product belongs to. (format: int64)
  --quantity: int # Amount of product items in stock. (format: int64)
  --related-products: record # shape: {productIds?: list<float>, relatedCategory?: record}
  --seo-description: string
  --seo-title: string
  --shipping: record # shape: {disabledMethods?: list<string>, enabledMethods?: list<string>, flatRate?: float, methodMarkup?: float, type?: string}
  --show-on-frontpage: float # format: double
  --sku: string # Product SKU
  --tax: record # shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list<int>}
  --taxes: list # item shape: {name?: string, total?: float, value?: float}
  --warning-limit: int # format: int64
  --weight: float # Product weight in the units defined in store settings (format: double)
  --wholesale-prices: record # shape: {{quantity}?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products"
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: categoryIds, var: category_ids}, {name: compareAtPrice, var: compare_at_price}, {name: compareToPrice, var: compare_to_price}, {name: created, var: created}, {name: defaultCategoryId, var: default_category_id}, {name: description, var: description}, {name: dimensions, var: dimensions}, {name: enabled, var: enabled}, {name: favorites, var: favorites}, {name: fixedShippingRate, var: fixed_shipping_rate}, {name: fixedShippingRateOnly, var: fixed_shipping_rate_only}, {name: galleryImages, var: gallery_images}, {name: googleItemCondition, var: google_item_condition}, {name: isShippingRequired, var: is_shipping_required}, {name: name, var: name}, {name: options, var: options}, {name: price, var: price}, {name: productClassId, var: product_class_id}, {name: quantity, var: quantity}, {name: relatedProducts, var: related_products}, {name: seoDescription, var: seo_description}, {name: seoTitle, var: seo_title}, {name: shipping, var: shipping}, {name: showOnFrontpage, var: show_on_frontpage}, {name: sku, var: sku}, {name: tax, var: tax}, {name: taxes, var: taxes}, {name: warningLimit, var: warning_limit}, {name: weight, var: weight}, {name: wholesalePrices, var: wholesale_prices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, attributes: $attributes, category_ids: $category_ids, compare_at_price: $compare_at_price, compare_to_price: $compare_to_price, created: $created, default_category_id: $default_category_id, description: $description, dimensions: $dimensions, enabled: $enabled, favorites: $favorites, fixed_shipping_rate: $fixed_shipping_rate, fixed_shipping_rate_only: $fixed_shipping_rate_only, gallery_images: $gallery_images, google_item_condition: $google_item_condition, is_shipping_required: $is_shipping_required, name: $name, options: $options, price: $price, product_class_id: $product_class_id, quantity: $quantity, related_products: $related_products, seo_description: $seo_description, seo_title: $seo_title, shipping: $shipping, show_on_frontpage: $show_on_frontpage, sku: $sku, tax: $tax, taxes: $taxes, warning_limit: $warning_limit, weight: $weight, wholesale_prices: $wholesale_prices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product associated with a given ID from your eCommerce system. Specifying a product associated with a given ID that does not exist will result in an error message
#
# DELETE /products/{id}
# operationId: deleteProductById
export def "delete-product-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a product associated with a given ID from the eCommerce system. Specifying a product with an ID that does not exist will result in an error response
#
# GET /products/{id}
# Returns: record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<"{quantity}": float>>
# operationId: getProductById
export def "get-product-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a product associated with a given ID in the eCommerce system. The update API uses the PATCH HTTP verb, so only those fields provided in the product object will be updated, and those fields not provided will be left alone. Updating a product with a specified ID that does not exist will result in an error response. Update supports the following fields: sku, quantity, trackQuantity, quantityDelta, warningLimit, name, price, weight, tangible, enabled, fixedShippingRateOnly, fixedShippingRate, description, wholesalePrices, compareAtPrice, productClassId
#
# PATCH /products/{id}
# Returns: record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<"{quantity}": float>>
# operationId: updateProductById
export def "update-product-by-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --attributes: list # item shape: {id?: int, internalName?: string, name?: string, value?: string}
  --category-ids: list<int>
  --compare-at-price: float # Product’s sale price displayed strike-out in the customer (format: double)
  --compare-to-price: float # format: double
  --default-category-id: int # format: int64
  --description: string # Product description in HTML
  --dimensions: record # shape: {height?: float, length?: float, width?: float}
  --enabled: oneof<nothing, bool> # true/false
  --fixed-shipping-rate: float # format: double
  --fixed-shipping-rate-only: oneof<nothing, bool> # true/false
  --gallery-images: list # item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
  --google-item-condition: string # Google Item Condition Status
  --is-shipping-required: oneof<nothing, bool>
  --name: string # Product title
  --options: list # item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
  --price: float # Base Product price (format: double)
  --product-class-id: int # Id of the product type that this product belongs to. (format: int64)
  --quantity: int # Amount of product items in stock. (format: int64)
  --related-products: record # shape: {productIds?: list<float>, relatedCategory?: record}
  --seo-description: string
  --seo-title: string
  --shipping: record # shape: {disabledMethods?: list<string>, enabledMethods?: list<string>, flatRate?: float, methodMarkup?: float, type?: string}
  --show-on-frontpage: float # format: double
  --sku: string # Product SKU
  --tax: record # shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list<int>}
  --taxes: list # item shape: {name?: string, total?: float, value?: float}
  --warning-limit: int # format: int64
  --weight: float # Product weight in the units defined in store settings (format: double)
  --wholesale-prices: record # shape: {{quantity}?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/products/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: categoryIds, var: category_ids}, {name: compareAtPrice, var: compare_at_price}, {name: compareToPrice, var: compare_to_price}, {name: defaultCategoryId, var: default_category_id}, {name: description, var: description}, {name: dimensions, var: dimensions}, {name: enabled, var: enabled}, {name: fixedShippingRate, var: fixed_shipping_rate}, {name: fixedShippingRateOnly, var: fixed_shipping_rate_only}, {name: galleryImages, var: gallery_images}, {name: googleItemCondition, var: google_item_condition}, {name: isShippingRequired, var: is_shipping_required}, {name: name, var: name}, {name: options, var: options}, {name: price, var: price}, {name: productClassId, var: product_class_id}, {name: quantity, var: quantity}, {name: relatedProducts, var: related_products}, {name: seoDescription, var: seo_description}, {name: seoTitle, var: seo_title}, {name: shipping, var: shipping}, {name: showOnFrontpage, var: show_on_frontpage}, {name: sku, var: sku}, {name: tax, var: tax}, {name: taxes, var: taxes}, {name: warningLimit, var: warning_limit}, {name: weight, var: weight}, {name: wholesalePrices, var: wholesale_prices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, authorization: $authorization, attributes: $attributes, category_ids: $category_ids, compare_at_price: $compare_at_price, compare_to_price: $compare_to_price, default_category_id: $default_category_id, description: $description, dimensions: $dimensions, enabled: $enabled, fixed_shipping_rate: $fixed_shipping_rate, fixed_shipping_rate_only: $fixed_shipping_rate_only, gallery_images: $gallery_images, google_item_condition: $google_item_condition, is_shipping_required: $is_shipping_required, name: $name, options: $options, price: $price, product_class_id: $product_class_id, quantity: $quantity, related_products: $related_products, seo_description: $seo_description, seo_title: $seo_title, shipping: $shipping, show_on_frontpage: $show_on_frontpage, sku: $sku, tax: $tax, taxes: $taxes, warning_limit: $warning_limit, weight: $weight, wholesale_prices: $wholesale_prices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for {objectName}
#
# GET /{objectName}
# Returns: table<objectField: string>
# operationId: getByObjectName
export def "get-by-object-name" [
  object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # The CEQL search expression.
  --page-size: int # The page size. Defaults to 200 if not provided. Maximum of 5000. (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{objectName}"
    path_params: [{name: objectName, var: object_name}]
    query: [{name: where, var: where}, {name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, where: $where, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an {objectName}
#
# POST /{objectName}
# operationId: createByObjectName
export def "create-by-object-name" [
  object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --object-field: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{objectName}"
    path_params: [{name: objectName, var: object_name}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: objectField, var: object_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, authorization: $authorization, object_field: $object_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an {objectName}
#
# DELETE /{objectName}/{objectId}
# operationId: deleteObjectNameByObjectId
export def "delete-object-name-by-object-id" [
  object_name: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{objectName}/{objectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an {objectName}
#
# GET /{objectName}/{objectId}
# Returns: record<objectField: string>
# operationId: getObjectNameByObjectId
export def "get-object-name-by-object-id" [
  object_name: string
  object_id: string
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{objectName}/{objectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json", "application/pdf"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an {objectName}
#
# PATCH /{objectName}/{objectId}
# Returns: record<objectField: string>
# operationId: updateObjectNameByObjectId
export def "update-object-name-by-object-id" [
  object_name: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --object-field: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{objectName}/{objectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: objectField, var: object_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, authorization: $authorization, object_field: $object_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an {objectName}
#
# PUT /{objectName}/{objectId}
# Returns: record<objectField: string>
# operationId: replaceObjectNameByObjectId
export def "replace-object-name-by-object-id" [
  object_name: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --object-field: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{objectName}/{objectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: objectField, var: object_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, authorization: $authorization, object_field: $object_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for {childObjectName}
#
# GET /{objectName}/{objectId}/{childObjectName}
# Returns: table<objectField: string>
# operationId: getObjectNameByChildObjectName
export def "get-object-name-by-child-object-name" [
  object_name: string
  object_id: string
  child_object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # The CEQL search expression.
  --page-size: int # The page size. Defaults to 200 if not provided. Maximum of 5000. (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{objectName}/{objectId}/{childObjectName}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}, {name: childObjectName, var: child_object_name}]
    query: [{name: where, var: where}, {name: pageSize, var: page_size}, {name: nextPage, var: next_page}, {name: fields, var: fields}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, child_object_name: $child_object_name, where: $where, page_size: $page_size, next_page: $next_page, fields: $fields, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an {objectName}
#
# POST /{objectName}/{objectId}/{childObjectName}
# operationId: createObjectNameByChildObjectName
export def "create-object-name-by-child-object-name" [
  object_name: string
  object_id: string
  child_object_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --object-field: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/{objectName}/{objectId}/{childObjectName}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}, {name: childObjectName, var: child_object_name}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: objectField, var: object_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, child_object_name: $child_object_name, authorization: $authorization, object_field: $object_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an {childObjectName}
#
# DELETE /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: deleteObjectNameByChildObjectId
export def "delete-object-name-by-child-object-id" [
  object_name: string
  object_id: string
  child_object_name: string
  child_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{objectName}/{objectId}/{childObjectName}/{childObjectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}, {name: childObjectName, var: child_object_name}, {name: childObjectId, var: child_object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, child_object_name: $child_object_name, child_object_id: $child_object_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an {childObjectName}
#
# GET /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# Returns: record<objectField: string>
# operationId: getObjectNameByChildObjectId
export def "get-object-name-by-child-object-id" [
  object_name: string
  object_id: string
  child_object_name: string
  child_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{objectName}/{objectId}/{childObjectName}/{childObjectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}, {name: childObjectName, var: child_object_name}, {name: childObjectId, var: child_object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, child_object_name: $child_object_name, child_object_id: $child_object_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an {childObjectName}
#
# PATCH /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# Returns: record<objectField: string>
# operationId: updateObjectNameByChildObjectId
export def "update-object-name-by-child-object-id" [
  object_name: string
  object_id: string
  child_object_name: string
  child_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --object-field: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{objectName}/{objectId}/{childObjectName}/{childObjectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}, {name: childObjectName, var: child_object_name}, {name: childObjectId, var: child_object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: objectField, var: object_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, child_object_name: $child_object_name, child_object_id: $child_object_id, authorization: $authorization, object_field: $object_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an {childObjectName}
#
# PUT /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# Returns: record<objectField: string>
# operationId: replaceObjectNameByChildObjectId
export def "replace-object-name-by-child-object-id" [
  object_name: string
  object_id: string
  child_object_name: string
  child_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>' (required)
  --object-field: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{objectName}/{objectId}/{childObjectName}/{childObjectId}"
    path_params: [{name: objectName, var: object_name}, {name: objectId, var: object_id}, {name: childObjectName, var: child_object_name}, {name: childObjectId, var: child_object_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: objectField, var: object_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_name: $object_name, object_id: $object_id, child_object_name: $child_object_name, child_object_id: $child_object_id, authorization: $authorization, object_field: $object_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
