# Auto-generated client for StorSimple8000SeriesManagementClient v2017-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/storsimple8000series-storsimple/2017-06-01/swagger.json
# Auth: --token flag or $env.STORSIMPLE8000SERIESMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "STORSIMPLE8000SERIESMANAGEMENTCLIENT_TOKEN"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def kind-completer [] { ["Series8000"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    operations-list: "record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>>"
    managers-list: "record<value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    managers-list-by-resource-group: "record<value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    managers-get: "record<etag: string, properties: record<cisIntrinsicSettings: record<type: string>, provisioningState: string, sku: record<name: string>>, id: string, location: string, name: string, tags: record, type: string>"
    managers-update: "record<etag: string, properties: record<cisIntrinsicSettings: record<type: string>, provisioningState: string, sku: record<name: string>>, id: string, location: string, name: string, tags: record, type: string>"
    managers-create-or-update: "record<etag: string, properties: record<cisIntrinsicSettings: record<type: string>, provisioningState: string, sku: record<name: string>>, id: string, location: string, name: string, tags: record, type: string>"
    access-control-records-list-by-manager: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    access-control-records-get: "record<properties: record<initiatorName: string, volumeCount: int>, id: string, kind: string, name: string, type: string>"
    access-control-records-create-or-update: "record<properties: record<initiatorName: string, volumeCount: int>, id: string, kind: string, name: string, type: string>"
    alerts-list-by-manager: "record<nextLink: string, value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    bandwidth-settings-list-by-manager: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    bandwidth-settings-get: "record<properties: record<schedules: list<record>, volumeCount: int>, id: string, kind: string, name: string, type: string>"
    bandwidth-settings-create-or-update: "record<properties: record<schedules: list<record>, volumeCount: int>, id: string, kind: string, name: string, type: string>"
    cloud-appliances-list-supported-configurations: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    devices-list-by-manager: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    devices-get: "record<properties: record<activationTime: string, activeController: string, agentGroupVersion: int, availableLocalStorageInBytes: int, availableTieredStorageInBytes: int, culture: string, details: record<endpointCount: int, volumeContainerCount: int>, deviceConfigurationStatus: string, deviceDescription: string, deviceLocation: string, deviceSoftwareVersion: string, deviceType: string, friendlyName: string, friendlySoftwareName: string, friendlySoftwareVersion: string, modelDescription: string, networkInterfaceCardCount: int, provisionedLocalStorageInBytes: int, provisionedTieredStorageInBytes: int, provisionedVolumeSizeInBytes: int, rolloverDetails: record<authorizationEligibility: string, authorizationStatus: string, inEligibilityReason: string>, serialNumber: string, status: string, targetIqn: string, totalTieredStorageInBytes: int, usingStorageInBytes: int, virtualMachineApiType: string>, id: string, kind: string, name: string, type: string>"
    devices-update: "record<properties: record<activationTime: string, activeController: string, agentGroupVersion: int, availableLocalStorageInBytes: int, availableTieredStorageInBytes: int, culture: string, details: record<endpointCount: int, volumeContainerCount: int>, deviceConfigurationStatus: string, deviceDescription: string, deviceLocation: string, deviceSoftwareVersion: string, deviceType: string, friendlyName: string, friendlySoftwareName: string, friendlySoftwareVersion: string, modelDescription: string, networkInterfaceCardCount: int, provisionedLocalStorageInBytes: int, provisionedTieredStorageInBytes: int, provisionedVolumeSizeInBytes: int, rolloverDetails: record<authorizationEligibility: string, authorizationStatus: string, inEligibilityReason: string>, serialNumber: string, status: string, targetIqn: string, totalTieredStorageInBytes: int, usingStorageInBytes: int, virtualMachineApiType: string>, id: string, kind: string, name: string, type: string>"
    device-settings-get-alert-settings: "record<properties: record<additionalRecipientEmailList: list<string>, alertNotificationCulture: string, emailNotification: string, notificationToServiceOwners: string>, id: string, kind: string, name: string, type: string>"
    device-settings-create-or-update-alert-settings: "record<properties: record<additionalRecipientEmailList: list<string>, alertNotificationCulture: string, emailNotification: string, notificationToServiceOwners: string>, id: string, kind: string, name: string, type: string>"
    backup-policies-list-by-device: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    backup-policies-get: "record<properties: record<backupPolicyCreationType: string, lastBackupTime: string, nextBackupTime: string, scheduledBackupStatus: string, schedulesCount: int, ssmHostName: string, volumeIds: list<string>>, id: string, kind: string, name: string, type: string>"
    backup-policies-create-or-update: "record<properties: record<backupPolicyCreationType: string, lastBackupTime: string, nextBackupTime: string, scheduledBackupStatus: string, schedulesCount: int, ssmHostName: string, volumeIds: list<string>>, id: string, kind: string, name: string, type: string>"
    backup-schedules-list-by-backup-policy: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    backup-schedules-get: "record<properties: record<backupType: string, lastSuccessfulRun: string, retentionCount: int, scheduleRecurrence: record<recurrenceType: string, recurrenceValue: int, weeklyDaysList: list>, scheduleStatus: string, startTime: string>, id: string, kind: string, name: string, type: string>"
    backup-schedules-create-or-update: "record<properties: record<backupType: string, lastSuccessfulRun: string, retentionCount: int, scheduleRecurrence: record<recurrenceType: string, recurrenceValue: int, weeklyDaysList: list>, scheduleStatus: string, startTime: string>, id: string, kind: string, name: string, type: string>"
    backups-list-by-device: "record<nextLink: string, value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    hardware-component-groups-list-by-device: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    jobs-list-by-device: "record<nextLink: string, value: table<endTime: string, error: record, percentComplete: int, properties: record, startTime: string, status: string, id: string, kind: string, name: string, type: string>>"
    jobs-get: "record<endTime: string, error: record<code: string, errorDetails: list<record>, message: string>, percentComplete: int, properties: record<backupPointInTime: string, backupType: string, dataStats: record<cloudData: int, processedData: int, throughput: int, totalData: int>, deviceId: string, entityLabel: string, entityType: string, isCancellable: bool, jobStages: list<record>, jobType: string, sourceDeviceId: string>, startTime: string, status: string, id: string, kind: string, name: string, type: string>"
    devices-list-failover-sets: "record<value: table<eligibilityResult: record, volumeContainers: list>>"
    devices-list-metrics: "record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>"
    devices-list-metric-definition: "record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>"
    device-settings-get-network-settings: "record<properties: record<dnsSettings: record<primaryDnsServer: string, primaryIpv6DnsServer: string, secondaryDnsServers: list, secondaryIpv6DnsServers: list>, networkAdapters: record<value: list>, webproxySettings: record<authentication: string, connectionUri: string, username: string>>, id: string, kind: string, name: string, type: string>"
    device-settings-update-network-settings: "record<properties: record<dnsSettings: record<primaryDnsServer: string, primaryIpv6DnsServer: string, secondaryDnsServers: list, secondaryIpv6DnsServers: list>, networkAdapters: record<value: list>, webproxySettings: record<authentication: string, connectionUri: string, username: string>>, id: string, kind: string, name: string, type: string>"
    managers-get-device-public-encryption-key: "record<key: string>"
    device-settings-get-security-settings: "record<properties: record<chapSettings: record<initiatorSecret: record, initiatorUser: string, targetSecret: record, targetUser: string>, remoteManagementSettings: record<remoteManagementCertificate: string, remoteManagementMode: string>>, id: string, kind: string, name: string, type: string>"
    device-settings-update-security-settings: "record<properties: record<chapSettings: record<initiatorSecret: record, initiatorUser: string, targetSecret: record, targetUser: string>, remoteManagementSettings: record<remoteManagementCertificate: string, remoteManagementMode: string>>, id: string, kind: string, name: string, type: string>"
    device-settings-get-time-settings: "record<properties: record<primaryTimeServer: string, secondaryTimeServer: list<string>, timeZone: string>, id: string, kind: string, name: string, type: string>"
    device-settings-create-or-update-time-settings: "record<properties: record<primaryTimeServer: string, secondaryTimeServer: list<string>, timeZone: string>, id: string, kind: string, name: string, type: string>"
    devices-get-update-summary: "record<properties: record<isUpdateInProgress: bool, lastUpdatedTime: string, maintenanceModeUpdatesAvailable: bool, regularUpdatesAvailable: bool>, id: string, kind: string, name: string, type: string>"
    volume-containers-list-by-device: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    volume-containers-get: "record<properties: record<bandWidthRateInMbps: int, bandwidthSettingId: string, encryptionKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, encryptionStatus: string, ownerShipStatus: string, storageAccountCredentialId: string, totalCloudStorageUsageInBytes: int, volumeCount: int>, id: string, kind: string, name: string, type: string>"
    volume-containers-create-or-update: "record<properties: record<bandWidthRateInMbps: int, bandwidthSettingId: string, encryptionKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, encryptionStatus: string, ownerShipStatus: string, storageAccountCredentialId: string, totalCloudStorageUsageInBytes: int, volumeCount: int>, id: string, kind: string, name: string, type: string>"
    volume-containers-list-metrics: "record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>"
    volume-containers-list-metric-definition: "record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>"
    volumes-list-by-volume-container: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    volumes-get: "record<properties: record<accessControlRecordIds: list<string>, backupPolicyIds: list<string>, backupStatus: string, monitoringStatus: string, operationStatus: string, sizeInBytes: int, volumeContainerId: string, volumeStatus: string, volumeType: string>, id: string, kind: string, name: string, type: string>"
    volumes-create-or-update: "record<properties: record<accessControlRecordIds: list<string>, backupPolicyIds: list<string>, backupStatus: string, monitoringStatus: string, operationStatus: string, sizeInBytes: int, volumeContainerId: string, volumeStatus: string, volumeType: string>, id: string, kind: string, name: string, type: string>"
    volumes-list-metrics: "record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>"
    volumes-list-metric-definition: "record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>"
    volumes-list-by-device: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    devices-list-failover-targets: "record<value: table<availableLocalStorageInBytes: int, availableTieredStorageInBytes: int, dataContainersCount: int, deviceId: string, deviceLocation: string, deviceSoftwareVersion: string, deviceStatus: string, eligibilityResult: record, friendlyDeviceSoftwareVersion: string, modelDescription: string, volumesCount: int>>"
    managers-get-encryption-settings: "record<properties: record<encryptionStatus: string, keyRolloverStatus: string>, id: string, kind: string, name: string, type: string>"
    managers-get-extended-info: "record<etag: string, properties: record<algorithm: string, encryptionKey: string, encryptionKeyThumbprint: string, integrityKey: string, portalCertificateThumbprint: string, version: string>, id: string, kind: string, name: string, type: string>"
    managers-update-extended-info: "record<etag: string, properties: record<algorithm: string, encryptionKey: string, encryptionKeyThumbprint: string, integrityKey: string, portalCertificateThumbprint: string, version: string>, id: string, kind: string, name: string, type: string>"
    managers-create-extended-info: "record<etag: string, properties: record<algorithm: string, encryptionKey: string, encryptionKeyThumbprint: string, integrityKey: string, portalCertificateThumbprint: string, version: string>, id: string, kind: string, name: string, type: string>"
    managers-list-feature-support-status: "record<value: table<name: string, status: string>>"
    jobs-list-by-manager: "record<nextLink: string, value: table<endTime: string, error: record, percentComplete: int, properties: record, startTime: string, status: string, id: string, kind: string, name: string, type: string>>"
    managers-get-activation-key: "record<activationKey: string>"
    managers-get-public-encryption-key: "record<encryptionAlgorithm: string, value: string, valueCertificateThumbprint: string>"
    managers-list-metrics: "record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>"
    managers-list-metric-definition: "record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>"
    managers-regenerate-activation-key: "record<activationKey: string>"
    storage-account-credentials-list-by-manager: "record<value: table<properties: record, id: string, kind: string, name: string, type: string>>"
    storage-account-credentials-get: "record<properties: record<accessKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, endPoint: string, sslStatus: string, volumesCount: int>, id: string, kind: string, name: string, type: string>"
    storage-account-credentials-create-or-update: "record<properties: record<accessKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, endPoint: string, sslStatus: string, volumesCount: int>, id: string, kind: string, name: string, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "managers-list" "managers-list-by-resource-group" "managers-delete" "managers-get" "managers-update" "managers-create-or-update" "access-control-records-list-by-manager" "access-control-records-delete" "access-control-records-get" "access-control-records-create-or-update" "alerts-list-by-manager" "bandwidth-settings-list-by-manager" "bandwidth-settings-delete" "bandwidth-settings-get" "bandwidth-settings-create-or-update" "alerts-clear" "cloud-appliances-list-supported-configurations" "devices-configure" "devices-list-by-manager" "devices-delete" "devices-get" "devices-update" "device-settings-get-alert-settings" "device-settings-create-or-update-alert-settings" "devices-authorize-for-service-encryption-key-rollover" "backup-policies-list-by-device" "backup-policies-delete" "backup-policies-get" "backup-policies-create-or-update" "backup-policies-backup-now" "backup-schedules-list-by-backup-policy" "backup-schedules-delete" "backup-schedules-get" "backup-schedules-create-or-update" "backups-list-by-device" "backups-delete" "backups-clone" "backups-restore" "devices-deactivate" "hardware-component-groups-list-by-device" "hardware-component-groups-change-controller-power-state" "devices-install-updates" "jobs-list-by-device" "jobs-get" "jobs-cancel" "devices-list-failover-sets" "devices-list-metrics" "devices-list-metric-definition" "device-settings-get-network-settings" "device-settings-update-network-settings" "managers-get-device-public-encryption-key" "devices-scan-for-updates" "device-settings-get-security-settings" "device-settings-update-security-settings" "device-settings-sync-remotemanagement-certificate" "alerts-send-test-email" "device-settings-get-time-settings" "device-settings-create-or-update-time-settings" "devices-get-update-summary" "volume-containers-list-by-device" "volume-containers-delete" "volume-containers-get" "volume-containers-create-or-update" "volume-containers-list-metrics" "volume-containers-list-metric-definition" "volumes-list-by-volume-container" "volumes-delete" "volumes-get" "volumes-create-or-update" "volumes-list-metrics" "volumes-list-metric-definition" "volumes-list-by-device" "devices-failover" "devices-list-failover-targets" "managers-get-encryption-settings" "managers-delete-extended-info" "managers-get-extended-info" "managers-update-extended-info" "managers-create-extended-info" "managers-list-feature-support-status" "jobs-list-by-manager" "managers-get-activation-key" "managers-get-public-encryption-key" "managers-list-metrics" "managers-list-metric-definition" "cloud-appliances-provision" "managers-regenerate-activation-key" "storage-account-credentials-list-by-manager" "storage-account-credentials-delete" "storage-account-credentials-get" "storage-account-credentials-create-or-update" "commands"] | sort) } | get name | first)
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

# Lists all of the available REST API operations of the Microsoft.StorSimple provider
#
# GET /providers/Microsoft.StorSimple/operations
# Returns: record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>>
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.StorSimple/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the managers in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.StorSimple/managers
# Returns: record<value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Managers_List
export def "managers-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.StorSimple/managers"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the managers in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers
# Returns: record<value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Managers_ListByResourceGroup
export def "managers-list-by-resource-group" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the manager.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}
# operationId: Managers_Delete
export def "managers-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the properties of the specified manager name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}
# Returns: record<etag: string, properties: record<cisIntrinsicSettings: record<type: string>, provisioningState: string, sku: record<name: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Managers_Get
export def "managers-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the StorSimple Manager.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}
# Returns: record<etag: string, properties: record<cisIntrinsicSettings: record<type: string>, provisioningState: string, sku: record<name: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Managers_Update
export def "managers-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --tags: record # The tags attached to the Manager.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the manager.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}
# Returns: record<etag: string, properties: record<cisIntrinsicSettings: record<type: string>, provisioningState: string, sku: record<name: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Managers_CreateOrUpdate
export def "managers-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --etag: string # The etag of the manager.
  --properties: record # The properties of the StorSimple Manager. — shape: {cisIntrinsicSettings?: record, provisioningState?: string, sku?: record}
  location: string # The geo location of the resource.
  --tags: record # The tags attached to the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, etag: $etag, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the access control records in a manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: AccessControlRecords_ListByManager
export def "access-control-records-list-by-manager" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the access control record.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords/{accessControlRecordName}
# operationId: AccessControlRecords_Delete
export def "access-control-records-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  access_control_record_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords/{accessControlRecordName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: accessControlRecordName, var: access_control_record_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, access_control_record_name: $access_control_record_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the properties of the specified access control record name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords/{accessControlRecordName}
# Returns: record<properties: record<initiatorName: string, volumeCount: int>, id: string, kind: string, name: string, type: string>
# operationId: AccessControlRecords_Get
export def "access-control-records-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  access_control_record_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords/{accessControlRecordName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: accessControlRecordName, var: access_control_record_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, access_control_record_name: $access_control_record_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or Updates an access control record.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords/{accessControlRecordName}
# Returns: record<properties: record<initiatorName: string, volumeCount: int>, id: string, kind: string, name: string, type: string>
# operationId: AccessControlRecords_CreateOrUpdate
export def "access-control-records-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  access_control_record_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of access control record. — shape: {initiatorName: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/accessControlRecords/{accessControlRecordName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: accessControlRecordName, var: access_control_record_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, access_control_record_name: $access_control_record_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the alerts in a manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/alerts
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: Alerts_ListByManager
export def "alerts-list-by-manager" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/alerts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the bandwidth setting in a manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: BandwidthSettings_ListByManager
export def "bandwidth-settings-list-by-manager" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the bandwidth setting
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings/{bandwidthSettingName}
# operationId: BandwidthSettings_Delete
export def "bandwidth-settings-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  bandwidth_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings/{bandwidthSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: bandwidthSettingName, var: bandwidth_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, bandwidth_setting_name: $bandwidth_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the properties of the specified bandwidth setting name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings/{bandwidthSettingName}
# Returns: record<properties: record<schedules: list<record>, volumeCount: int>, id: string, kind: string, name: string, type: string>
# operationId: BandwidthSettings_Get
export def "bandwidth-settings-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  bandwidth_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings/{bandwidthSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: bandwidthSettingName, var: bandwidth_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, bandwidth_setting_name: $bandwidth_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the bandwidth setting
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings/{bandwidthSettingName}
# Returns: record<properties: record<schedules: list<record>, volumeCount: int>, id: string, kind: string, name: string, type: string>
# operationId: BandwidthSettings_CreateOrUpdate
export def "bandwidth-settings-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  bandwidth_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the bandwidth setting. — shape: {schedules: list}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/bandwidthSettings/{bandwidthSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: bandwidthSettingName, var: bandwidth_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, bandwidth_setting_name: $bandwidth_setting_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear the alerts.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/clearAlerts
# operationId: Alerts_Clear
export def "alerts-clear" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  alerts: list<string> # The list of alert IDs to be cleared
  --resolution-message: string # The resolution message while clearing the alert
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/clearAlerts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alerts, var: alerts}, {name: resolutionMessage, var: resolution_message}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, alerts: $alerts, resolution_message: $resolution_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists supported cloud appliance models and supported configurations.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/cloudApplianceConfigurations
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: CloudAppliances_ListSupportedConfigurations
export def "cloud-appliances-list-supported-configurations" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/cloudApplianceConfigurations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete minimal setup before using the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/configureDevice
# operationId: Devices_Configure
export def "devices-configure" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the configure device request. — shape: {currentDeviceName: string, dnsSettings?: record, friendlyName: string, networkInterfaceData0Settings?: record, timeZone: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/configureDevice"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of devices for the specified manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: Devices_ListByManager
export def "devices-list-by-manager" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --expand: string # Specify $expand=details to populate additional fields related to the device or $expand=rolloverdetails to populate additional fields related to the service data encryption key rollover on device
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the device.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}
# operationId: Devices_Delete
export def "devices-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the properties of the specified device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}
# Returns: record<properties: record<activationTime: string, activeController: string, agentGroupVersion: int, availableLocalStorageInBytes: int, availableTieredStorageInBytes: int, culture: string, details: record<endpointCount: int, volumeContainerCount: int>, deviceConfigurationStatus: string, deviceDescription: string, deviceLocation: string, deviceSoftwareVersion: string, deviceType: string, friendlyName: string, friendlySoftwareName: string, friendlySoftwareVersion: string, modelDescription: string, networkInterfaceCardCount: int, provisionedLocalStorageInBytes: int, provisionedTieredStorageInBytes: int, provisionedVolumeSizeInBytes: int, rolloverDetails: record<authorizationEligibility: string, authorizationStatus: string, inEligibilityReason: string>, serialNumber: string, status: string, targetIqn: string, totalTieredStorageInBytes: int, usingStorageInBytes: int, virtualMachineApiType: string>, id: string, kind: string, name: string, type: string>
# operationId: Devices_Get
export def "devices-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --expand: string # Specify $expand=details to populate additional fields related to the device or $expand=rolloverdetails to populate additional fields related to the service data encryption key rollover on device
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the device.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}
# Returns: record<properties: record<activationTime: string, activeController: string, agentGroupVersion: int, availableLocalStorageInBytes: int, availableTieredStorageInBytes: int, culture: string, details: record<endpointCount: int, volumeContainerCount: int>, deviceConfigurationStatus: string, deviceDescription: string, deviceLocation: string, deviceSoftwareVersion: string, deviceType: string, friendlyName: string, friendlySoftwareName: string, friendlySoftwareVersion: string, modelDescription: string, networkInterfaceCardCount: int, provisionedLocalStorageInBytes: int, provisionedTieredStorageInBytes: int, provisionedVolumeSizeInBytes: int, rolloverDetails: record<authorizationEligibility: string, authorizationStatus: string, inEligibilityReason: string>, serialNumber: string, status: string, targetIqn: string, totalTieredStorageInBytes: int, usingStorageInBytes: int, virtualMachineApiType: string>, id: string, kind: string, name: string, type: string>
# operationId: Devices_Update
export def "devices-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the device patch. — shape: {deviceDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the alert settings of the specified device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/alertSettings/default
# Returns: record<properties: record<additionalRecipientEmailList: list<string>, alertNotificationCulture: string, emailNotification: string, notificationToServiceOwners: string>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_GetAlertSettings
export def "device-settings-get-alert-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/alertSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the alert settings of the specified device.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/alertSettings/default
# Returns: record<properties: record<additionalRecipientEmailList: list<string>, alertNotificationCulture: string, emailNotification: string, notificationToServiceOwners: string>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_CreateOrUpdateAlertSettings
export def "device-settings-create-or-update-alert-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the alert notification settings. — shape: {additionalRecipientEmailList?: list<string>, alertNotificationCulture?: string, emailNotification: "Enabled"|"Disabled", notificationToServiceOwners?: "Enabled"|"Disabled"}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/alertSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorizes the specified device for service data encryption key rollover.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/authorizeForServiceEncryptionKeyRollover
# operationId: Devices_AuthorizeForServiceEncryptionKeyRollover
export def "devices-authorize-for-service-encryption-key-rollover" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/authorizeForServiceEncryptionKeyRollover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the backup policies in a device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: BackupPolicies_ListByDevice
export def "backup-policies-list-by-device" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the backup policy.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}
# operationId: BackupPolicies_Delete
export def "backup-policies-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties of the specified backup policy name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}
# Returns: record<properties: record<backupPolicyCreationType: string, lastBackupTime: string, nextBackupTime: string, scheduledBackupStatus: string, schedulesCount: int, ssmHostName: string, volumeIds: list<string>>, id: string, kind: string, name: string, type: string>
# operationId: BackupPolicies_Get
export def "backup-policies-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the backup policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}
# Returns: record<properties: record<backupPolicyCreationType: string, lastBackupTime: string, nextBackupTime: string, scheduledBackupStatus: string, schedulesCount: int, ssmHostName: string, volumeIds: list<string>>, id: string, kind: string, name: string, type: string>
# operationId: BackupPolicies_CreateOrUpdate
export def "backup-policies-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the backup policy. — shape: {volumeIds: list<string>}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backup the backup policy now.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/backup
# operationId: BackupPolicies_BackupNow
export def "backup-policies-backup-now" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backup-type: string # The backup Type. This can be cloudSnapshot or localSnapshot. (required)
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/backup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}]
    query: [{name: backupType, var: backup_type, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, backup_type: $backup_type, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the backup schedules in a backup policy.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: BackupSchedules_ListByBackupPolicy
export def "backup-schedules-list-by-backup-policy" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the backup schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules/{backupScheduleName}
# operationId: BackupSchedules_Delete
export def "backup-schedules-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  backup_schedule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules/{backupScheduleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}, {name: backupScheduleName, var: backup_schedule_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, backup_schedule_name: $backup_schedule_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties of the specified backup schedule name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules/{backupScheduleName}
# Returns: record<properties: record<backupType: string, lastSuccessfulRun: string, retentionCount: int, scheduleRecurrence: record<recurrenceType: string, recurrenceValue: int, weeklyDaysList: list>, scheduleStatus: string, startTime: string>, id: string, kind: string, name: string, type: string>
# operationId: BackupSchedules_Get
export def "backup-schedules-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  backup_schedule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules/{backupScheduleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}, {name: backupScheduleName, var: backup_schedule_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, backup_schedule_name: $backup_schedule_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the backup schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules/{backupScheduleName}
# Returns: record<properties: record<backupType: string, lastSuccessfulRun: string, retentionCount: int, scheduleRecurrence: record<recurrenceType: string, recurrenceValue: int, weeklyDaysList: list>, scheduleStatus: string, startTime: string>, id: string, kind: string, name: string, type: string>
# operationId: BackupSchedules_CreateOrUpdate
export def "backup-schedules-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_policy_name: string
  backup_schedule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the backup schedule. — shape: {backupType: "LocalSnapshot"|"CloudSnapshot", retentionCount: int, scheduleRecurrence: record, scheduleStatus: "Enabled"|"Disabled", startTime: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backupPolicies/{backupPolicyName}/schedules/{backupScheduleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupPolicyName, var: backup_policy_name}, {name: backupScheduleName, var: backup_schedule_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_policy_name: $backup_policy_name, backup_schedule_name: $backup_schedule_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the backups in a device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: Backups_ListByDevice
export def "backups-list-by-device" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the backup.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups/{backupName}
# operationId: Backups_Delete
export def "backups-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups/{backupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupName, var: backup_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_name: $backup_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clones the backup element as a new volume.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups/{backupName}/elements/{backupElementName}/clone
# operationId: Backups_Clone
export def "backups-clone" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_name: string
  backup_element_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  backup_element: record # The backup element. — shape: {elementId: string, elementName: string, elementType: string, sizeInBytes: int, volumeContainerId: string, volumeName: string, volumeType?: "Tiered"|"Archival"|"LocallyPinned"}
  target_access_control_record_ids: list<string> # The list of path IDs of the access control records to be associated to the new cloned volume.
  target_device_id: string # The path ID of the device which will act as the clone target.
  target_volume_name: string # The name of the new volume which will be created and the backup will be cloned into.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups/{backupName}/elements/{backupElementName}/clone"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupName, var: backup_name}, {name: backupElementName, var: backup_element_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: backupElement, var: backup_element}, {name: targetAccessControlRecordIds, var: target_access_control_record_ids}, {name: targetDeviceId, var: target_device_id}, {name: targetVolumeName, var: target_volume_name}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_name: $backup_name, backup_element_name: $backup_element_name, api_version: $api_version, backup_element: $backup_element, target_access_control_record_ids: $target_access_control_record_ids, target_device_id: $target_device_id, target_volume_name: $target_volume_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores the backup on the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups/{backupName}/restore
# operationId: Backups_Restore
export def "backups-restore" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  backup_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/backups/{backupName}/restore"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: backupName, var: backup_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, backup_name: $backup_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/deactivate
# operationId: Devices_Deactivate
export def "devices-deactivate" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/deactivate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the hardware component groups at device-level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/hardwareComponentGroups
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: HardwareComponentGroups_ListByDevice
export def "hardware-component-groups-list-by-device" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/hardwareComponentGroups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the power state of the controller.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/hardwareComponentGroups/{hardwareComponentGroupName}/changeControllerPowerState
# operationId: HardwareComponentGroups_ChangeControllerPowerState
export def "hardware-component-groups-change-controller-power-state" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  hardware_component_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the controller power state change request. — shape: {action: "Start"|"Restart"|"Shutdown", activeController: "Unknown"|"None"|"Controller0"|"Controller1", controller0State: "NotPresent"|"PoweredOff"|"Ok"|"Recovering"|"Warning"|"Failure", controller1State: "NotPresent"|"PoweredOff"|"Ok"|"Recovering"|"Warning"|"Failure"}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/hardwareComponentGroups/{hardwareComponentGroupName}/changeControllerPowerState"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: hardwareComponentGroupName, var: hardware_component_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, hardware_component_group_name: $hardware_component_group_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads and installs the updates on the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/installUpdates
# operationId: Devices_InstallUpdates
export def "devices-install-updates" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/installUpdates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the jobs for specified device. With optional OData query parameters, a filtered set of jobs is returned.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/jobs
# Returns: record<nextLink: string, value: table<endTime: string, error: record, percentComplete: int, properties: record, startTime: string, status: string, id: string, kind: string, name: string, type: string>>
# operationId: Jobs_ListByDevice
export def "jobs-list-by-device" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/jobs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the specified job name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/jobs/{jobName}
# Returns: record<endTime: string, error: record<code: string, errorDetails: list<record>, message: string>, percentComplete: int, properties: record<backupPointInTime: string, backupType: string, dataStats: record<cloudData: int, processedData: int, throughput: int, totalData: int>, deviceId: string, entityLabel: string, entityType: string, isCancellable: bool, jobStages: list<record>, jobType: string, sourceDeviceId: string>, startTime: string, status: string, id: string, kind: string, name: string, type: string>
# operationId: Jobs_Get
export def "jobs-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/jobs/{jobName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, job_name: $job_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a job on the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/jobs/{jobName}/cancel
# operationId: Jobs_Cancel
export def "jobs-cancel" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/jobs/{jobName}/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, job_name: $job_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all failover sets for a given device and their eligibility for participating in a failover. A failover set refers to a set of volume containers that need to be failed-over as a single unit to maintain data integrity.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/listFailoverSets
# Returns: record<value: table<eligibilityResult: record, volumeContainers: list>>
# operationId: Devices_ListFailoverSets
export def "devices-list-failover-sets" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/listFailoverSets"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metrics for the specified device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/metrics
# Returns: record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>
# operationId: Devices_ListMetrics
export def "devices-list-metrics" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metric definitions for the specified device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/metricsDefinitions
# Returns: record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>
# operationId: Devices_ListMetricDefinition
export def "devices-list-metric-definition" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/metricsDefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the network settings of the specified device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/networkSettings/default
# Returns: record<properties: record<dnsSettings: record<primaryDnsServer: string, primaryIpv6DnsServer: string, secondaryDnsServers: list, secondaryIpv6DnsServers: list>, networkAdapters: record<value: list>, webproxySettings: record<authentication: string, connectionUri: string, username: string>>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_GetNetworkSettings
export def "device-settings-get-network-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/networkSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the network settings on the specified device.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/networkSettings/default
# Returns: record<properties: record<dnsSettings: record<primaryDnsServer: string, primaryIpv6DnsServer: string, secondaryDnsServers: list, secondaryIpv6DnsServers: list>, networkAdapters: record<value: list>, webproxySettings: record<authentication: string, connectionUri: string, username: string>>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_UpdateNetworkSettings
export def "device-settings-update-network-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the network settings patch. — shape: {dnsSettings?: record, networkAdapters?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/networkSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the public encryption key of the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/publicEncryptionKey
# Returns: record<key: string>
# operationId: Managers_GetDevicePublicEncryptionKey
export def "managers-get-device-public-encryption-key" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/publicEncryptionKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scans for updates on the device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/scanForUpdates
# operationId: Devices_ScanForUpdates
export def "devices-scan-for-updates" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/scanForUpdates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Security properties of the specified device name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/securitySettings/default
# Returns: record<properties: record<chapSettings: record<initiatorSecret: record, initiatorUser: string, targetSecret: record, targetUser: string>, remoteManagementSettings: record<remoteManagementCertificate: string, remoteManagementMode: string>>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_GetSecuritySettings
export def "device-settings-get-security-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/securitySettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch Security properties of the specified device name.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/securitySettings/default
# Returns: record<properties: record<chapSettings: record<initiatorSecret: record, initiatorUser: string, targetSecret: record, targetUser: string>, remoteManagementSettings: record<remoteManagementCertificate: string, remoteManagementMode: string>>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_UpdateSecuritySettings
export def "device-settings-update-security-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of the security settings patch. — shape: {chapSettings?: record, cloudApplianceSettings?: record, deviceAdminPassword?: record, remoteManagementSettings?: record, snapshotPassword?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/securitySettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sync Remote management Certificate between appliance and Service
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/securitySettings/default/syncRemoteManagementCertificate
# operationId: DeviceSettings_SyncRemotemanagementCertificate
export def "device-settings-sync-remotemanagement-certificate" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/securitySettings/default/syncRemoteManagementCertificate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a test alert email.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/sendTestAlertEmail
# operationId: Alerts_SendTestEmail
export def "alerts-send-test-email" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  email_list: list<string> # The list of email IDs to send the test alert email
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/sendTestAlertEmail"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: emailList, var: email_list}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, email_list: $email_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the time settings of the specified device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/timeSettings/default
# Returns: record<properties: record<primaryTimeServer: string, secondaryTimeServer: list<string>, timeZone: string>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_GetTimeSettings
export def "device-settings-get-time-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/timeSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the time settings of the specified device.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/timeSettings/default
# Returns: record<properties: record<primaryTimeServer: string, secondaryTimeServer: list<string>, timeZone: string>, id: string, kind: string, name: string, type: string>
# operationId: DeviceSettings_CreateOrUpdateTimeSettings
export def "device-settings-create-or-update-time-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of time settings of a device. — shape: {primaryTimeServer?: string, secondaryTimeServer?: list<string>, timeZone: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/timeSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the update summary of the specified device name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/updateSummary/default
# Returns: record<properties: record<isUpdateInProgress: bool, lastUpdatedTime: string, maintenanceModeUpdatesAvailable: bool, regularUpdatesAvailable: bool>, id: string, kind: string, name: string, type: string>
# operationId: Devices_GetUpdateSummary
export def "devices-get-update-summary" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/updateSummary/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the volume containers in a device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: VolumeContainers_ListByDevice
export def "volume-containers-list-by-device" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the volume container.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}
# operationId: VolumeContainers_Delete
export def "volume-containers-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties of the specified volume container name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}
# Returns: record<properties: record<bandWidthRateInMbps: int, bandwidthSettingId: string, encryptionKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, encryptionStatus: string, ownerShipStatus: string, storageAccountCredentialId: string, totalCloudStorageUsageInBytes: int, volumeCount: int>, id: string, kind: string, name: string, type: string>
# operationId: VolumeContainers_Get
export def "volume-containers-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the volume container.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}
# Returns: record<properties: record<bandWidthRateInMbps: int, bandwidthSettingId: string, encryptionKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, encryptionStatus: string, ownerShipStatus: string, storageAccountCredentialId: string, totalCloudStorageUsageInBytes: int, volumeCount: int>, id: string, kind: string, name: string, type: string>
# operationId: VolumeContainers_CreateOrUpdate
export def "volume-containers-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of volume container. — shape: {bandWidthRateInMbps?: int, bandwidthSettingId?: string, encryptionKey?: record, storageAccountCredentialId: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metrics for the specified volume container.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/metrics
# Returns: record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>
# operationId: VolumeContainers_ListMetrics
export def "volume-containers-list-metrics" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metric definitions for the specified volume container.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/metricsDefinitions
# Returns: record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>
# operationId: VolumeContainers_ListMetricDefinition
export def "volume-containers-list-metric-definition" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/metricsDefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the volumes in a volume container.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: Volumes_ListByVolumeContainer
export def "volumes-list-by-volume-container" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the volume.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}
# operationId: Volumes_Delete
export def "volumes-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  volume_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}, {name: volumeName, var: volume_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, volume_name: $volume_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the properties of the specified volume name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}
# Returns: record<properties: record<accessControlRecordIds: list<string>, backupPolicyIds: list<string>, backupStatus: string, monitoringStatus: string, operationStatus: string, sizeInBytes: int, volumeContainerId: string, volumeStatus: string, volumeType: string>, id: string, kind: string, name: string, type: string>
# operationId: Volumes_Get
export def "volumes-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  volume_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}, {name: volumeName, var: volume_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, volume_name: $volume_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the volume.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}
# Returns: record<properties: record<accessControlRecordIds: list<string>, backupPolicyIds: list<string>, backupStatus: string, monitoringStatus: string, operationStatus: string, sizeInBytes: int, volumeContainerId: string, volumeStatus: string, volumeType: string>, id: string, kind: string, name: string, type: string>
# operationId: Volumes_CreateOrUpdate
export def "volumes-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  volume_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The properties of volume. — shape: {accessControlRecordIds: list<string>, monitoringStatus: "Enabled"|"Disabled", sizeInBytes: int, volumeStatus: "Online"|"Offline", volumeType: "Tiered"|"Archival"|"LocallyPinned"}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}, {name: volumeName, var: volume_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, volume_name: $volume_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metrics for the specified volume.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}/metrics
# Returns: record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>
# operationId: Volumes_ListMetrics
export def "volumes-list-metrics" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  volume_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}, {name: volumeName, var: volume_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, volume_name: $volume_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metric definitions for the specified volume.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}/metricsDefinitions
# Returns: record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>
# operationId: Volumes_ListMetricDefinition
export def "volumes-list-metric-definition" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  volume_container_name: string
  volume_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumeContainers/{volumeContainerName}/volumes/{volumeName}/metricsDefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}, {name: volumeContainerName, var: volume_container_name}, {name: volumeName, var: volume_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, volume_container_name: $volume_container_name, volume_name: $volume_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the volumes in a device.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumes
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: Volumes_ListByDevice
export def "volumes-list-by-device" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{deviceName}/volumes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: deviceName, var: device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, device_name: $device_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Failovers a set of volume containers from a specified source device to a target device.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{sourceDeviceName}/failover
# operationId: Devices_Failover
export def "devices-failover" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  source_device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --target-device-id: string # The ARM path ID of the device which will act as the failover target.
  --volume-containers: list<string> # The list of path IDs of the volume containers which needs to be failed-over to the target device.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{sourceDeviceName}/failover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: sourceDeviceName, var: source_device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetDeviceId, var: target_device_id}, {name: volumeContainers, var: volume_containers}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, source_device_name: $source_device_name, api_version: $api_version, target_device_id: $target_device_id, volume_containers: $volume_containers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a list of volume containers to be failed over from a source device, this method returns the eligibility result, as a failover target, for all devices under that resource.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{sourceDeviceName}/listFailoverTargets
# Returns: record<value: table<availableLocalStorageInBytes: int, availableTieredStorageInBytes: int, dataContainersCount: int, deviceId: string, deviceLocation: string, deviceSoftwareVersion: string, deviceStatus: string, eligibilityResult: record, friendlyDeviceSoftwareVersion: string, modelDescription: string, volumesCount: int>>
# operationId: Devices_ListFailoverTargets
export def "devices-list-failover-targets" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  source_device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --volume-containers: list<string> # The list of path IDs of the volume containers that needs to be failed-over, for which we want to fetch the eligible targets.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/devices/{sourceDeviceName}/listFailoverTargets"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: sourceDeviceName, var: source_device_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: volumeContainers, var: volume_containers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, source_device_name: $source_device_name, api_version: $api_version, volume_containers: $volume_containers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the encryption settings of the manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/encryptionSettings/default
# Returns: record<properties: record<encryptionStatus: string, keyRolloverStatus: string>, id: string, kind: string, name: string, type: string>
# operationId: Managers_GetEncryptionSettings
export def "managers-get-encryption-settings" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/encryptionSettings/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the extended info of the manager.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo
# operationId: Managers_DeleteExtendedInfo
export def "managers-delete-extended-info" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the extended information of the specified manager name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo
# Returns: record<etag: string, properties: record<algorithm: string, encryptionKey: string, encryptionKeyThumbprint: string, integrityKey: string, portalCertificateThumbprint: string, version: string>, id: string, kind: string, name: string, type: string>
# operationId: Managers_GetExtendedInfo
export def "managers-get-extended-info" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the extended info of the manager.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo
# Returns: record<etag: string, properties: record<algorithm: string, encryptionKey: string, encryptionKeyThumbprint: string, integrityKey: string, portalCertificateThumbprint: string, version: string>, id: string, kind: string, name: string, type: string>
# operationId: Managers_UpdateExtendedInfo
export def "managers-update-extended-info" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --if-match: string # Pass the ETag of ExtendedInfo fetched from GET call (required)
  --etag: string # The etag of the resource.
  --properties: record # The properties of the manager extended info. — shape: {algorithm: string, encryptionKey?: string, encryptionKeyThumbprint?: string, integrityKey: string, portalCertificateThumbprint?: string, version?: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, if_match: $if_match, etag: $etag, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates the extended info of the manager.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo
# Returns: record<etag: string, properties: record<algorithm: string, encryptionKey: string, encryptionKeyThumbprint: string, integrityKey: string, portalCertificateThumbprint: string, version: string>, id: string, kind: string, name: string, type: string>
# operationId: Managers_CreateExtendedInfo
export def "managers-create-extended-info" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --etag: string # The etag of the resource.
  --properties: record # The properties of the manager extended info. — shape: {algorithm: string, encryptionKey?: string, encryptionKeyThumbprint?: string, integrityKey: string, portalCertificateThumbprint?: string, version?: string}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/extendedInformation/vaultExtendedInfo"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, etag: $etag, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the features and their support status
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/features
# Returns: record<value: table<name: string, status: string>>
# operationId: Managers_ListFeatureSupportStatus
export def "managers-list-feature-support-status" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/features"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the jobs for the specified manager. With optional OData query parameters, a filtered set of jobs is returned.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/jobs
# Returns: record<nextLink: string, value: table<endTime: string, error: record, percentComplete: int, properties: record, startTime: string, status: string, id: string, kind: string, name: string, type: string>>
# operationId: Jobs_ListByManager
export def "jobs-list-by-manager" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/jobs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the activation key of the manager.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/listActivationKey
# Returns: record<activationKey: string>
# operationId: Managers_GetActivationKey
export def "managers-get-activation-key" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/listActivationKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the symmetric encrypted public encryption key of the manager.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/listPublicEncryptionKey
# Returns: record<encryptionAlgorithm: string, value: string, valueCertificateThumbprint: string>
# operationId: Managers_GetPublicEncryptionKey
export def "managers-get-public-encryption-key" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/listPublicEncryptionKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metrics for the specified manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/metrics
# Returns: record<value: table<dimensions: list, endTime: string, name: record, primaryAggregation: string, resourceId: string, startTime: string, timeGrain: string, type: string, unit: string, values: list>>
# operationId: Managers_ListMetrics
export def "managers-list-metrics" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --filter: string # OData Filter options (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metric definitions for the specified manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/metricsDefinitions
# Returns: record<value: table<category: string, dimensions: list, metricAvailabilities: list, name: record, primaryAggregationType: string, resourceId: string, type: string, unit: string>>
# operationId: Managers_ListMetricDefinition
export def "managers-list-metric-definition" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/metricsDefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions cloud appliance.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/provisionCloudAppliance
# operationId: CloudAppliances_Provision
export def "cloud-appliances-provision" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  --is-vnet-dns-configured: oneof<nothing, bool> # Indicates whether virtual network used is configured with DNS or not.
  --is-vnet-express-configured: oneof<nothing, bool> # Indicates whether virtual network used is configured with express route or not.
  --model-number: string # The model number.
  name: string # The name.
  --storage-account-name: string # The name of the storage account.
  --storage-account-type: string # The type of the storage account.
  --subnet-name: string # The name of the subnet.
  --vm-image-name: string # The name of the virtual machine image.
  --vm-type: string # The type of the virtual machine.
  --vnet-name: string # The name of the virtual network.
  vnet_region: string # The virtual network region.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/provisionCloudAppliance"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: isVnetDnsConfigured, var: is_vnet_dns_configured}, {name: isVnetExpressConfigured, var: is_vnet_express_configured}, {name: modelNumber, var: model_number}, {name: name, var: name}, {name: storageAccountName, var: storage_account_name}, {name: storageAccountType, var: storage_account_type}, {name: subnetName, var: subnet_name}, {name: vmImageName, var: vm_image_name}, {name: vmType, var: vm_type}, {name: vnetName, var: vnet_name}, {name: vnetRegion, var: vnet_region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version, is_vnet_dns_configured: $is_vnet_dns_configured, is_vnet_express_configured: $is_vnet_express_configured, model_number: $model_number, name: $name, storage_account_name: $storage_account_name, storage_account_type: $storage_account_type, subnet_name: $subnet_name, vm_image_name: $vm_image_name, vm_type: $vm_type, vnet_name: $vnet_name, vnet_region: $vnet_region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Re-generates and returns the activation key of the manager.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/regenerateActivationKey
# Returns: record<activationKey: string>
# operationId: Managers_RegenerateActivationKey
export def "managers-regenerate-activation-key" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/regenerateActivationKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the storage account credentials in a manager.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials
# Returns: record<value: table<properties: record, id: string, kind: string, name: string, type: string>>
# operationId: StorageAccountCredentials_ListByManager
export def "storage-account-credentials-list-by-manager" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the storage account credential.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials/{storageAccountCredentialName}
# operationId: StorageAccountCredentials_Delete
export def "storage-account-credentials-delete" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  storage_account_credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials/{storageAccountCredentialName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: storageAccountCredentialName, var: storage_account_credential_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, storage_account_credential_name: $storage_account_credential_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties of the specified storage account credential name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials/{storageAccountCredentialName}
# Returns: record<properties: record<accessKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, endPoint: string, sslStatus: string, volumesCount: int>, id: string, kind: string, name: string, type: string>
# operationId: StorageAccountCredentials_Get
export def "storage-account-credentials-get" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  storage_account_credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials/{storageAccountCredentialName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: storageAccountCredentialName, var: storage_account_credential_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, storage_account_credential_name: $storage_account_credential_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the storage account credential.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials/{storageAccountCredentialName}
# Returns: record<properties: record<accessKey: record<encryptionAlgorithm: string, encryptionCertThumbprint: string, value: string>, endPoint: string, sslStatus: string, volumesCount: int>, id: string, kind: string, name: string, type: string>
# operationId: StorageAccountCredentials_CreateOrUpdate
export def "storage-account-credentials-create-or-update" [
  subscription_id: string
  resource_group_name: string
  manager_name: string
  storage_account_credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version (required)
  properties: record # The storage account credential properties. — shape: {accessKey?: record, endPoint: string, sslStatus: "Enabled"|"Disabled"}
  --kind: string@kind-completer # The Kind of the object. Currently only Series8000 is supported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorSimple/managers/{managerName}/storageAccountCredentials/{storageAccountCredentialName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: managerName, var: manager_name}, {name: storageAccountCredentialName, var: storage_account_credential_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, manager_name: $manager_name, storage_account_credential_name: $storage_account_credential_name, api_version: $api_version, properties: $properties, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
