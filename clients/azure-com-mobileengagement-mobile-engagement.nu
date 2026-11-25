# Auto-generated client for Engagement.ManagementClient v2014-12-01
# Source: https://api.apis.guru/v2/specs/azure.com/mobileengagement-mobile-engagement/2014-12-01/swagger.json
# Auth: --token flag or $env.ENGAGEMENT_MANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "ENGAGEMENT_MANAGEMENTCLIENT_TOKEN"
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
def kind-completer [] { ["announcements" "dataPushes" "nativePushes" "polls"] }
def delivery-time-completer [] { ["any" "background" "session"] }
def notification-type-completer [] { ["popup" "system"] }
def push-mode-completer [] { ["manual" "one-shot" "real-time"] }
def type-completer [] { ["only_notif" "text/base64" "text/html" "text/plain"] }
def export-format-completer [] { ["CsvBlob" "JsonBlob"] }
def campaign-type-completer [] { ["Announcement" "DataPush" "NativePush" "Poll"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    app-collections-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    app-collections-check-name-availability: "record<available: bool, name: string, unavailabilityReason: string>"
    supported-platforms-list: "record<platforms: list<string>>"
    apps-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    campaigns-list: "record<nextLink: string, value: table<activatedDate: string, endTime: string, finishedDate: string, name: string, startTime: string, timezone: string, id: int, state: string>>"
    campaigns-create: "record<id: int, state: string>"
    campaigns-test-new: "record<state: string>"
    campaigns-get: "record<activatedDate: string, finishedDate: string, id: int, state: string, audience: record<criteria: record, expression: string, filters: list<record>>, category: string, deliveryActivities: list<string>, deliveryTime: string, endTime: string, localization: record, name: string, notificationBadge: bool, notificationCloseable: bool, notificationIcon: bool, notificationSound: bool, notificationType: string, notificationVibrate: bool, pushMode: string, questions: table<choices: list, id: int, localization: record, title: string>, startTime: string, timezone: string, type: string, actionButtonText: string, actionUrl: string, body: string, exitButtonText: string, notificationImage: string, notificationMessage: string, notificationOptions: record<actionText: string, bigPicture: string, bigText: string, sound: string>, notificationTitle: string, payload: record, title: string>"
    campaigns-update: "record<id: int, state: string>"
    campaigns-activate: "record<id: int, state: string>"
    campaigns-finish: "record<id: int, state: string>"
    campaigns-push: "record<invalidDeviceIds: list<string>>"
    campaigns-get-statistics: "record<answers: record, content-actioned: int, content-displayed: int, content-exited: int, delivered: int, dropped: int, in-app-notification-actioned: int, in-app-notification-displayed: int, in-app-notification-exited: int, pushed: int, pushed-native: int, pushed-native-adm: int, pushed-native-google: int, queued: int, system-notification-actioned: int, system-notification-displayed: int, system-notification-exited: int>"
    campaigns-suspend: "record<id: int, state: string>"
    campaigns-test-saved: "record<id: int, state: string>"
    campaigns-get-by-name: "record<activatedDate: string, finishedDate: string, id: int, state: string, audience: record<criteria: record, expression: string, filters: list<record>>, category: string, deliveryActivities: list<string>, deliveryTime: string, endTime: string, localization: record, name: string, notificationBadge: bool, notificationCloseable: bool, notificationIcon: bool, notificationSound: bool, notificationType: string, notificationVibrate: bool, pushMode: string, questions: table<choices: list, id: int, localization: record, title: string>, startTime: string, timezone: string, type: string, actionButtonText: string, actionUrl: string, body: string, exitButtonText: string, notificationImage: string, notificationMessage: string, notificationOptions: record<actionText: string, bigPicture: string, bigText: string, sound: string>, notificationTitle: string, payload: record, title: string>"
    devices-list: "record<nextLink: string, value: table<appInfo: record, deviceId: string, meta: record>>"
    export-tasks-list: "record<nextLink: string, value: table<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>>"
    export-tasks-create-activities-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-crashes-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-errors-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-events-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-feedback-task-by-campaign: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-feedback-task-by-date-range: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-jobs-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-sessions-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-tags-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-create-tokens-task: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    export-tasks-get: "record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>"
    import-tasks-list: "record<nextLink: string, value: table<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>>"
    import-tasks-create: "record<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>"
    import-tasks-get: "record<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>"
    devices-tag-by-device-id: "record<invalidIds: list<string>>"
    devices-get-by-device-id: "record<appInfo: record, deviceId: string, info: record<androidAPILevel: int, applicationVersionCode: int, applicationVersionName: string, carrierCountry: string, carrierName: string, firmwareName: string, firmwareVersion: string, locale: string, networkSubtype: string, networkType: string, phoneManufacturer: string, phoneModel: string, serviceVersion: string, timeZoneOffset: int>, location: record<countrycode: string, locality: string, region: string>, meta: record<firstSeen: int, lastInfo: int, lastLocation: int, lastSeen: int, nativePushEnabled: bool>>"
    devices-tag-by-user-id: "record<invalidIds: list<string>>"
    devices-get-by-user-id: "record<appInfo: record, deviceId: string, info: record<androidAPILevel: int, applicationVersionCode: int, applicationVersionName: string, carrierCountry: string, carrierName: string, firmwareName: string, firmwareVersion: string, locale: string, networkSubtype: string, networkType: string, phoneManufacturer: string, phoneModel: string, serviceVersion: string, timeZoneOffset: int>, location: record<countrycode: string, locality: string, region: string>, meta: record<firstSeen: int, lastInfo: int, lastLocation: int, lastSeen: int, nativePushEnabled: bool>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["app-collections-list" "app-collections-check-name-availability" "supported-platforms-list" "apps-list" "campaigns-list" "campaigns-create" "campaigns-test-new" "campaigns-delete" "campaigns-get" "campaigns-update" "campaigns-activate" "campaigns-finish" "campaigns-push" "campaigns-get-statistics" "campaigns-suspend" "campaigns-test-saved" "campaigns-get-by-name" "devices-list" "export-tasks-list" "export-tasks-create-activities-task" "export-tasks-create-crashes-task" "export-tasks-create-errors-task" "export-tasks-create-events-task" "export-tasks-create-feedback-task-by-campaign" "export-tasks-create-feedback-task-by-date-range" "export-tasks-create-jobs-task" "export-tasks-create-sessions-task" "export-tasks-create-tags-task" "export-tasks-create-tokens-task" "export-tasks-get" "import-tasks-list" "import-tasks-create" "import-tasks-get" "devices-tag-by-device-id" "devices-get-by-device-id" "devices-tag-by-user-id" "devices-get-by-user-id" "commands"] | sort) } | get name | first)
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

# Lists app collections in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/appCollections
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: AppCollections_List
export def "app-collections-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/appCollections"
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

# Checks availability of an app collection name in the Engagement domain.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/checkAppCollectionNameAvailability
# Returns: record<available: bool, name: string, unavailabilityReason: string>
# operationId: AppCollections_CheckNameAvailability
export def "app-collections-check-name-availability" [
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
  --api-version: string # Client Api Version. (required)
  --available: oneof<nothing, bool> # Available.
  --name: string # Name.
  --unavailability-reason: string # UnavailabilityReason.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/checkAppCollectionNameAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: available, var: available}, {name: name, var: name}, {name: unavailabilityReason, var: unavailability_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, available: $available, name: $name, unavailability_reason: $unavailability_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists supported platforms for Engagement applications.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/supportedPlatforms
# Returns: record<platforms: list<string>>
# operationId: SupportedPlatforms_List
export def "supported-platforms-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/supportedPlatforms"
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

# Lists apps in an appCollection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Apps_List
export def "apps-list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of campaigns.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}
# Returns: record<nextLink: string, value: table<activatedDate: string, endTime: string, finishedDate: string, name: string, startTime: string, timezone: string, id: int, state: string>>
# operationId: Campaigns_List
export def "campaigns-list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --skip: int # Control paging of campaigns, start results at the given offset, defaults to 0 (1st page of data).
  --top: int # Control paging of campaigns, number of campaigns to return with each call. It returns all campaigns by default. When specifying $top parameter, the response contains a `nextLink` property describing the path to get the next page if there are more results.
  --filter: string # Filter can be used to restrict the results to campaigns matching a specific state. The syntax is `$filter=state eq 'draft'`. Valid state values are: draft, scheduled, in-progress, and finished. Only the eq operator and the state property are supported.
  --orderby: string # Sort results by an expression which looks like `$orderby=id asc` (this example is actually the default behavior). The syntax is orderby={property} {direction} or just orderby={property}. The available sorting properties are id, name, state, activatedDate, and finishedDate. The available directions are asc (for ascending order) and desc (for descending order). When not specified the asc direction is used. Only one property at a time can be used for sorting.
  --search: string # Restrict results to campaigns matching the optional `search` expression. This currently performs the search based on the name on the campaign only, case insensitive. If the campaign contains the value of the `search` parameter anywhere in the name, it matches.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$skip", var: skip}, {name: "$top", var: top}, {name: "$filter", var: filter}, {name: "$orderby", var: orderby}, {name: "$search", var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, api_version: $api_version, skip: $skip, top: $top, filter: $filter, orderby: $orderby, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a push campaign (announcement, poll, data push or native push).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}
# Returns: record<id: int, state: string>
# operationId: Campaigns_Create
export def "campaigns-create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --audience: record # Specify which users will be targeted by this campaign. By default, all users will be targeted. If you set `pushMode` property to `manual`, the only thing you can specify in the audience is the push quota filter. An audience is a boolean expression made of criteria (variables) operators (`not`, `and` or `or`) and parenthesis. Additionally, a set of filters can be added to an audience. 65535 bytes max as per JSON encoding. — shape: {criteria?: record, expression?: string, filters?: list}
  --category: string # Category of the campaign. Categories can be used on the application side to customize campaigns.
  --delivery-activities: list<string> # Announcements/polls only. Array containing the list of activities in which the campaign can be delivered. deliveryTime must be set to session. If the platform is iOS, this option can also be set if deliveryTime is set to any. In that case, if the campaign is received when the application is launched, it will be delivered only in the specified list of activities.
  --delivery-time: string@delivery-time-completer # Announcements/polls only. Defines when the campaign should be delivered. Valid values are: * `any`: Campaign will be delivered as soon as possible. * `background`: iOS only. Campaign will be only delivered when the application is in background (out of app). * `session`: Campaign will be delivered when the application is running.
  --end-time: string # The date at which the campaign should be finished. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. Example: `2011-11-21 15:23Z`
  --localization: record # Push campaigns can be localized using an optional JSON object. The JSON key is a two-character language code as specified by the ISO 639-1 standard. The corresponding value is an object containing the localizable properties.
  --name: string # Unique name of the campaign.
  --notification-badge: oneof<nothing, bool> # A flag indicating whether or not you want the native Apple Push notification to update the badge icon to the number of unread messages. The `deliveryTime` property must be set to `any` or `background`. (default: false)
  --notification-closeable: oneof<nothing, bool> # A flag indicating whether or not you want the notification to be closeable. (default: true)
  --notification-icon: oneof<nothing, bool> # A flag indicating whether or not you want to display the resource icon in notification content. (default: true)
  --notification-sound: oneof<nothing, bool> # * `Android`: A flag indicating whether or not you want the system notification to make a sound. The `notificationType` property must be set to `system`. * `iOS`: A flag indicating whether or not you want the native Apple Push notification to make a sound. The `deliveryTime` property must be set to `any` or `background`. This will play the 'default' sound. If you want to play a custom sound, see the `notificationOptions` property. * `Windows`: A flag indicating whether or not you want the native Windows Notification Service to make a sound. The `deliveryTime` property must be set to `any`. (default: false)
  --notification-type: string@notification-type-completer # Android only. Defines how the notification should be displayed. Valid values are: * `system`: Display the notification using a standard system notification. * `popup`: Display the notification using a in-app banner notification. (default: popup)
  --notification-vibrate: oneof<nothing, bool> # Android only. A flag indicating whether or not you want the system notification to make a vibration. The notificationType property must be set to system. (default: false)
  --push-mode: string@push-mode-completer # Announcements/polls only. Defines how the campaign is pushed. Valid values are: * `real-time`: Never ending campaign, the campaign will be delivered to your existing users and also to your new users. * `one-shot`: In this mode, the campaign will be delivered only to your existing users (campaign will stop after that). * `manual`: In this mode, the campaign will not be pushed automatically to devices. You will have to use the Push campaign command to push the campaign to your end-users. Campaigns can be pushed multiple times to the same device. (default: real-time)
  --questions: list # Poll questions. — item shape: {choices?: list, id?: int, localization?: record, title?: string}
  --start-time: string # The date at which the campaign should be started. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. * If you set pushMode property to manual, this attribute will be ignored. * If you set pushMode property to one-shot, then the timezone attribute must be specified. Example: `2011-11-21 15:23Z`
  --timezone: string # The id of the time zone to use for the startTime and endTime dates. If not provided, the two date attributes will be expressed using the device timezone. Example: America/Los_Angeles
  --type: string@type-completer # Applicable only to announcements and data pushes. Type of announcement. Valid values are: * `text/plain`: Text-only announcement: `body` property should only contain plain text. * `text/html`: HTML announcement: `body` attribute can contain HTML code. * `only_notif`: Notification-only announcement. With this kind of announcements, the `body`, `title`, `actionButtonText` and `exitButtonText` are ignored. Type of data push. Valid values are: * `text/plain`: Text only data push: `body` property must be plain text. * `text/base64`: Base 64 data push: `body` property must be encoded in base 64.
  --action-button-text: string # Text of the action button for text/web announcements and polls (answer button).
  --action-url: string # URL to launch when the announcement is actioned.
  --body: string # Body of the text/web announcement, poll or data push. This field supports appInfo markers.
  --exit-button-text: string # Text of the exit button for text/web announcements and polls.
  --notification-image: string # Optional image encoded in base 64. Usually included in the right part of in app notifications (or as a banner if there is neither text nor content icon). For Android system notifications, the image is used as the large icon (displayed only on Android 3+). (format: byte)
  --notification-message: string # Message of the notification. This field supports appInfo markers.
  --notification-options: any # shape: {actionText?: string, bigPicture?: string, bigText?: string, sound?: string}
  --notification-title: string # Title of the notification. This field supports appInfo markers.
  --payload: record # Native push payload.
  --title: string # Title of the announcement or poll. This field supports appInfo markers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: audience, var: audience}, {name: category, var: category}, {name: deliveryActivities, var: delivery_activities}, {name: deliveryTime, var: delivery_time}, {name: endTime, var: end_time}, {name: localization, var: localization}, {name: name, var: name}, {name: notificationBadge, var: notification_badge}, {name: notificationCloseable, var: notification_closeable}, {name: notificationIcon, var: notification_icon}, {name: notificationSound, var: notification_sound}, {name: notificationType, var: notification_type}, {name: notificationVibrate, var: notification_vibrate}, {name: pushMode, var: push_mode}, {name: questions, var: questions}, {name: startTime, var: start_time}, {name: timezone, var: timezone}, {name: type, var: type}, {name: actionButtonText, var: action_button_text}, {name: actionUrl, var: action_url}, {name: body, var: body}, {name: exitButtonText, var: exit_button_text}, {name: notificationImage, var: notification_image}, {name: notificationMessage, var: notification_message}, {name: notificationOptions, var: notification_options}, {name: notificationTitle, var: notification_title}, {name: payload, var: payload}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, api_version: $api_version, audience: $audience, category: $category, delivery_activities: $delivery_activities, delivery_time: $delivery_time, end_time: $end_time, localization: $localization, name: $name, notification_badge: $notification_badge, notification_closeable: $notification_closeable, notification_icon: $notification_icon, notification_sound: $notification_sound, notification_type: $notification_type, notification_vibrate: $notification_vibrate, push_mode: $push_mode, questions: $questions, start_time: $start_time, timezone: $timezone, type: $type, action_button_text: $action_button_text, action_url: $action_url, body: $body, exit_button_text: $exit_button_text, notification_image: $notification_image, notification_message: $notification_message, notification_options: $notification_options, notification_title: $notification_title, payload: $payload, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test a new campaign on a set of devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/test
# Returns: record<state: string>
# operationId: Campaigns_TestNew
export def "campaigns-test-new" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  data: any # shape: {audience?: record, category?: string, deliveryActivities?: list<string>, deliveryTime?: "any"|"background"|"session", endTime?: string, localization?: record, name?: string, notificationBadge?: bool, notificationCloseable?: bool, notificationIcon?: bool, notificationSound?: bool, notificationType?: "system"|"popup", notificationVibrate?: bool, pushMode?: "real-time"|"one-shot"|"manual", questions?: list, startTime?: string, timezone?: string, ... (11 more fields)}
  device_id: string # Device identifier (as returned by the SDK).
  --lang: string # The language to test expressed using ISO 639-1 code. The default language of the campaign will be used if the parameter is not provided.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/test"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: deviceId, var: device_id}, {name: lang, var: lang}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, api_version: $api_version, data: $data, device_id: $device_id, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a campaign previously created by a call to Create campaign.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}
# operationId: Campaigns_Delete
export def "campaigns-delete" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Get campaign operation retrieves information about a previously created campaign.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}
# Returns: record<activatedDate: string, finishedDate: string, id: int, state: string, audience: record<criteria: record, expression: string, filters: list<record>>, category: string, deliveryActivities: list<string>, deliveryTime: string, endTime: string, localization: record, name: string, notificationBadge: bool, notificationCloseable: bool, notificationIcon: bool, notificationSound: bool, notificationType: string, notificationVibrate: bool, pushMode: string, questions: table<choices: list, id: int, localization: record, title: string>, startTime: string, timezone: string, type: string, actionButtonText: string, actionUrl: string, body: string, exitButtonText: string, notificationImage: string, notificationMessage: string, notificationOptions: record<actionText: string, bigPicture: string, bigText: string, sound: string>, notificationTitle: string, payload: record, title: string>
# operationId: Campaigns_Get
export def "campaigns-get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing push campaign (announcement, poll, data push or native push).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}
# Returns: record<id: int, state: string>
# operationId: Campaigns_Update
export def "campaigns-update" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --audience: record # Specify which users will be targeted by this campaign. By default, all users will be targeted. If you set `pushMode` property to `manual`, the only thing you can specify in the audience is the push quota filter. An audience is a boolean expression made of criteria (variables) operators (`not`, `and` or `or`) and parenthesis. Additionally, a set of filters can be added to an audience. 65535 bytes max as per JSON encoding. — shape: {criteria?: record, expression?: string, filters?: list}
  --category: string # Category of the campaign. Categories can be used on the application side to customize campaigns.
  --delivery-activities: list<string> # Announcements/polls only. Array containing the list of activities in which the campaign can be delivered. deliveryTime must be set to session. If the platform is iOS, this option can also be set if deliveryTime is set to any. In that case, if the campaign is received when the application is launched, it will be delivered only in the specified list of activities.
  --delivery-time: string@delivery-time-completer # Announcements/polls only. Defines when the campaign should be delivered. Valid values are: * `any`: Campaign will be delivered as soon as possible. * `background`: iOS only. Campaign will be only delivered when the application is in background (out of app). * `session`: Campaign will be delivered when the application is running.
  --end-time: string # The date at which the campaign should be finished. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. Example: `2011-11-21 15:23Z`
  --localization: record # Push campaigns can be localized using an optional JSON object. The JSON key is a two-character language code as specified by the ISO 639-1 standard. The corresponding value is an object containing the localizable properties.
  --name: string # Unique name of the campaign.
  --notification-badge: oneof<nothing, bool> # A flag indicating whether or not you want the native Apple Push notification to update the badge icon to the number of unread messages. The `deliveryTime` property must be set to `any` or `background`. (default: false)
  --notification-closeable: oneof<nothing, bool> # A flag indicating whether or not you want the notification to be closeable. (default: true)
  --notification-icon: oneof<nothing, bool> # A flag indicating whether or not you want to display the resource icon in notification content. (default: true)
  --notification-sound: oneof<nothing, bool> # * `Android`: A flag indicating whether or not you want the system notification to make a sound. The `notificationType` property must be set to `system`. * `iOS`: A flag indicating whether or not you want the native Apple Push notification to make a sound. The `deliveryTime` property must be set to `any` or `background`. This will play the 'default' sound. If you want to play a custom sound, see the `notificationOptions` property. * `Windows`: A flag indicating whether or not you want the native Windows Notification Service to make a sound. The `deliveryTime` property must be set to `any`. (default: false)
  --notification-type: string@notification-type-completer # Android only. Defines how the notification should be displayed. Valid values are: * `system`: Display the notification using a standard system notification. * `popup`: Display the notification using a in-app banner notification. (default: popup)
  --notification-vibrate: oneof<nothing, bool> # Android only. A flag indicating whether or not you want the system notification to make a vibration. The notificationType property must be set to system. (default: false)
  --push-mode: string@push-mode-completer # Announcements/polls only. Defines how the campaign is pushed. Valid values are: * `real-time`: Never ending campaign, the campaign will be delivered to your existing users and also to your new users. * `one-shot`: In this mode, the campaign will be delivered only to your existing users (campaign will stop after that). * `manual`: In this mode, the campaign will not be pushed automatically to devices. You will have to use the Push campaign command to push the campaign to your end-users. Campaigns can be pushed multiple times to the same device. (default: real-time)
  --questions: list # Poll questions. — item shape: {choices?: list, id?: int, localization?: record, title?: string}
  --start-time: string # The date at which the campaign should be started. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. * If you set pushMode property to manual, this attribute will be ignored. * If you set pushMode property to one-shot, then the timezone attribute must be specified. Example: `2011-11-21 15:23Z`
  --timezone: string # The id of the time zone to use for the startTime and endTime dates. If not provided, the two date attributes will be expressed using the device timezone. Example: America/Los_Angeles
  --type: string@type-completer # Applicable only to announcements and data pushes. Type of announcement. Valid values are: * `text/plain`: Text-only announcement: `body` property should only contain plain text. * `text/html`: HTML announcement: `body` attribute can contain HTML code. * `only_notif`: Notification-only announcement. With this kind of announcements, the `body`, `title`, `actionButtonText` and `exitButtonText` are ignored. Type of data push. Valid values are: * `text/plain`: Text only data push: `body` property must be plain text. * `text/base64`: Base 64 data push: `body` property must be encoded in base 64.
  --action-button-text: string # Text of the action button for text/web announcements and polls (answer button).
  --action-url: string # URL to launch when the announcement is actioned.
  --body: string # Body of the text/web announcement, poll or data push. This field supports appInfo markers.
  --exit-button-text: string # Text of the exit button for text/web announcements and polls.
  --notification-image: string # Optional image encoded in base 64. Usually included in the right part of in app notifications (or as a banner if there is neither text nor content icon). For Android system notifications, the image is used as the large icon (displayed only on Android 3+). (format: byte)
  --notification-message: string # Message of the notification. This field supports appInfo markers.
  --notification-options: any # shape: {actionText?: string, bigPicture?: string, bigText?: string, sound?: string}
  --notification-title: string # Title of the notification. This field supports appInfo markers.
  --payload: record # Native push payload.
  --title: string # Title of the announcement or poll. This field supports appInfo markers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: audience, var: audience}, {name: category, var: category}, {name: deliveryActivities, var: delivery_activities}, {name: deliveryTime, var: delivery_time}, {name: endTime, var: end_time}, {name: localization, var: localization}, {name: name, var: name}, {name: notificationBadge, var: notification_badge}, {name: notificationCloseable, var: notification_closeable}, {name: notificationIcon, var: notification_icon}, {name: notificationSound, var: notification_sound}, {name: notificationType, var: notification_type}, {name: notificationVibrate, var: notification_vibrate}, {name: pushMode, var: push_mode}, {name: questions, var: questions}, {name: startTime, var: start_time}, {name: timezone, var: timezone}, {name: type, var: type}, {name: actionButtonText, var: action_button_text}, {name: actionUrl, var: action_url}, {name: body, var: body}, {name: exitButtonText, var: exit_button_text}, {name: notificationImage, var: notification_image}, {name: notificationMessage, var: notification_message}, {name: notificationOptions, var: notification_options}, {name: notificationTitle, var: notification_title}, {name: payload, var: payload}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version, audience: $audience, category: $category, delivery_activities: $delivery_activities, delivery_time: $delivery_time, end_time: $end_time, localization: $localization, name: $name, notification_badge: $notification_badge, notification_closeable: $notification_closeable, notification_icon: $notification_icon, notification_sound: $notification_sound, notification_type: $notification_type, notification_vibrate: $notification_vibrate, push_mode: $push_mode, questions: $questions, start_time: $start_time, timezone: $timezone, type: $type, action_button_text: $action_button_text, action_url: $action_url, body: $body, exit_button_text: $exit_button_text, notification_image: $notification_image, notification_message: $notification_message, notification_options: $notification_options, notification_title: $notification_title, payload: $payload, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate a campaign previously created by a call to Create campaign.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/activate
# Returns: record<id: int, state: string>
# operationId: Campaigns_Activate
export def "campaigns-activate" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/activate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finish a push campaign previously activated by a call to Activate campaign.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/finish
# Returns: record<id: int, state: string>
# operationId: Campaigns_Finish
export def "campaigns-finish" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/finish"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push a previously saved campaign (created with Create campaign) to a set of devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/push
# Returns: record<invalidDeviceIds: list<string>>
# operationId: Campaigns_Push
export def "campaigns-push" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --data: any # shape: {audience?: record, category?: string, deliveryActivities?: list<string>, deliveryTime?: "any"|"background"|"session", endTime?: string, localization?: record, name?: string, notificationBadge?: bool, notificationCloseable?: bool, notificationIcon?: bool, notificationSound?: bool, notificationType?: "system"|"popup", notificationVibrate?: bool, pushMode?: "real-time"|"one-shot"|"manual", questions?: list, startTime?: string, timezone?: string, ... (11 more fields)}
  device_ids: list<string> # Device identifiers to push as a JSON array of strings. Note that if you want to push the same campaign several times to the same device, you need to make several API calls.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/push"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: deviceIds, var: device_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version, data: $data, device_ids: $device_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the campaign statistics.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/statistics
# Returns: record<answers: record, content-actioned: int, content-displayed: int, content-exited: int, delivered: int, dropped: int, in-app-notification-actioned: int, in-app-notification-displayed: int, in-app-notification-exited: int, pushed: int, pushed-native: int, pushed-native-adm: int, pushed-native-google: int, queued: int, system-notification-actioned: int, system-notification-displayed: int, system-notification-exited: int>
# operationId: Campaigns_GetStatistics
export def "campaigns-get-statistics" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/statistics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspend a push campaign previously activated by a call to Activate campaign.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/suspend
# Returns: record<id: int, state: string>
# operationId: Campaigns_Suspend
export def "campaigns-suspend" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/suspend"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test an existing campaign (created with Create campaign) on a set of devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/test
# Returns: record<id: int, state: string>
# operationId: Campaigns_TestSaved
export def "campaigns-test-saved" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  device_id: string # Device identifier (as returned by the SDK).
  --lang: string # The language to test expressed using ISO 639-1 code. The default language of the campaign will be used if the parameter is not provided.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/test"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceId, var: device_id}, {name: lang, var: lang}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, id: $id, api_version: $api_version, device_id: $device_id, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Get campaign operation retrieves information about a previously created campaign.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaignsByName/{kind}/{name}
# Returns: record<activatedDate: string, finishedDate: string, id: int, state: string, audience: record<criteria: record, expression: string, filters: list<record>>, category: string, deliveryActivities: list<string>, deliveryTime: string, endTime: string, localization: record, name: string, notificationBadge: bool, notificationCloseable: bool, notificationIcon: bool, notificationSound: bool, notificationType: string, notificationVibrate: bool, pushMode: string, questions: table<choices: list, id: int, localization: record, title: string>, startTime: string, timezone: string, type: string, actionButtonText: string, actionUrl: string, body: string, exitButtonText: string, notificationImage: string, notificationMessage: string, notificationOptions: record<actionText: string, bigPicture: string, bigText: string, sound: string>, notificationTitle: string, payload: record, title: string>
# operationId: Campaigns_GetByName
export def "campaigns-get-by-name" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string@kind-completer
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaignsByName/{kind}/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: kind, var: kind}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, kind: $kind, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query the information associated to the devices running an application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices
# Returns: record<nextLink: string, value: table<appInfo: record, deviceId: string, meta: record>>
# operationId: Devices_List
export def "devices-list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --top: int # Number of devices to return with each call. Defaults to 100 and cannot return more. Passing a greater value is ignored. The response contains a `nextLink` property describing the URI path to get the next page of results if not all results could be returned at once.
  --select: string # By default all `meta` and `appInfo` properties are returned, this property is used to restrict the output to the desired properties. It also excludes all devices from the output that have none of the selected properties. In other terms, only devices having at least one of the selected property being set is part of the results. Examples: - `$select=appInfo` : select all devices having at least 1 appInfo, return them all and don’t return any meta property. - `$select=meta` : return only meta properties in the output. - `$select=appInfo,meta/firstSeen,meta/lastSeen` : return all `appInfo`, plus meta object containing only firstSeen and lastSeen properties. The format is thus a comma separated list of properties to select. Use `appInfo` to select all appInfo properties, `meta` to select all meta properties. Use `appInfo/{key}` and `meta/{key}` to select specific appInfo and meta properties.
  --filter: string # Filter can be used to reduce the number of results. Filter is a boolean expression that can look like the following examples: * `$filter=deviceId gt 'abcdef0123456789abcdef0123456789'` * `$filter=lastModified le 1447284263690L` * `$filter=(deviceId ge 'abcdef0123456789abcdef0123456789') and (deviceId lt 'bacdef0123456789abcdef0123456789') and (lastModified gt 1447284263690L)` The first example is used automatically for paging when returning the `nextLink` property. The filter expression is a combination of checks on some properties that can be compared to their value. The available operators are: * `gt` : greater than * `ge` : greater than or equals * `lt` : less than * `le` : less than or equals * `and` : to add multiple checks (all checks must pass), optional parentheses can be used. The properties that can be used in the expression are the following: * `deviceId {operator} '{deviceIdValue}'` : a lexicographical comparison is made on the deviceId value, use single quotes for the value. * `lastModified {operator} {number}L` : returns only meta properties or appInfo properties whose last value modification timestamp compared to the specified value is matching (value is milliseconds since January 1st, 1970 UTC). Please note the `L` character after the number of milliseconds, its required when the number of milliseconds exceeds `2^31 - 1` (which is always the case for recent timestamps). Using `lastModified` excludes all devices from the output that have no property matching the timestamp criteria, like `$select`. Please note that the internal value of `lastModified` timestamp for a given property is never part of the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$select", var: select}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, top: $top, select: $select, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of export tasks.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks
# Returns: record<nextLink: string, value: table<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>>
# operationId: ExportTasks_List
export def "export-tasks-list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --skip: int # Control paging of export tasks, start results at the given offset, defaults to 0 (1st page of data). (default: 0)
  --top: int # Control paging of export tasks, number of export tasks to return with each call. By default, it returns all export tasks with a default paging of 20. The response contains a `nextLink` property describing the path to get the next page if there are more results. The maximum paging limit for $top is 40. (default: 20)
  --orderby: string # Sort results by an expression which looks like `$orderby=taskId asc` (default when not specified). The syntax is orderby={property} {direction} or just orderby={property}. Properties that can be specified for sorting: taskId, errorDetails, dateCreated, taskStatus, and dateCreated. The available directions are asc (for ascending order) and desc (for descending order). When not specified the asc direction is used. Only one orderby property can be specified.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$skip", var: skip}, {name: "$top", var: top}, {name: "$orderby", var: orderby}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, skip: $skip, top: $top, orderby: $orderby
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export activities.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/activities
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateActivitiesTask
export def "export-tasks-create-activities-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/activities"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: endDate, var: end_date}, {name: exportFormat, var: export_format}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, end_date: $end_date, export_format: $export_format, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export crashes.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/crashes
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateCrashesTask
export def "export-tasks-create-crashes-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/crashes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: endDate, var: end_date}, {name: exportFormat, var: export_format}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, end_date: $end_date, export_format: $export_format, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export errors.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/errors
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateErrorsTask
export def "export-tasks-create-errors-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/errors"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: endDate, var: end_date}, {name: exportFormat, var: export_format}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, end_date: $end_date, export_format: $export_format, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/events
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateEventsTask
export def "export-tasks-create-events-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/events"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: endDate, var: end_date}, {name: exportFormat, var: export_format}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, end_date: $end_date, export_format: $export_format, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export push campaign data for a set of campaigns.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/feedbackByCampaign
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateFeedbackTaskByCampaign
export def "export-tasks-create-feedback-task-by-campaign" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  campaign_ids: list<int> # A list of campaign identifiers.
  campaign_type: string@campaign-type-completer # Campaign type.
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/feedbackByCampaign"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: campaignIds, var: campaign_ids}, {name: campaignType, var: campaign_type}, {name: containerUrl, var: container_url}, {name: description, var: description}, {name: exportFormat, var: export_format}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, campaign_ids: $campaign_ids, campaign_type: $campaign_type, container_url: $container_url, description: $description, export_format: $export_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export push campaign data for a date range.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/feedbackByDate
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateFeedbackTaskByDateRange
export def "export-tasks-create-feedback-task-by-date-range" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  campaign_type: string@campaign-type-completer # Campaign type.
  campaign_window_end: string # A date time as defined by date-time in RFC3339. (format: date-time)
  campaign_window_start: string # A date time as defined by date-time in RFC3339. (format: date-time)
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/feedbackByDate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: campaignType, var: campaign_type}, {name: campaignWindowEnd, var: campaign_window_end}, {name: campaignWindowStart, var: campaign_window_start}, {name: containerUrl, var: container_url}, {name: description, var: description}, {name: exportFormat, var: export_format}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, campaign_type: $campaign_type, campaign_window_end: $campaign_window_end, campaign_window_start: $campaign_window_start, container_url: $container_url, description: $description, export_format: $export_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export jobs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/jobs
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateJobsTask
export def "export-tasks-create-jobs-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/jobs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: endDate, var: end_date}, {name: exportFormat, var: export_format}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, end_date: $end_date, export_format: $export_format, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export sessions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/sessions
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateSessionsTask
export def "export-tasks-create-sessions-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/sessions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: endDate, var: end_date}, {name: exportFormat, var: export_format}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, end_date: $end_date, export_format: $export_format, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export tags.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/tags
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateTagsTask
export def "export-tasks-create-tags-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/tags"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: exportFormat, var: export_format}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, export_format: $export_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task to export tags.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/tokens
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_CreateTokensTask
export def "export-tasks-create-tokens-task" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/tokens"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containerUrl, var: container_url}, {name: description, var: description}, {name: exportFormat, var: export_format}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, container_url: $container_url, description: $description, export_format: $export_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a previously created export task.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/{id}
# Returns: record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>
# operationId: ExportTasks_Get
export def "export-tasks-get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of import jobs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks
# Returns: record<nextLink: string, value: table<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>>
# operationId: ImportTasks_List
export def "import-tasks-list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --skip: int # Control paging of import jobs, start results at the given offset, defaults to 0 (1st page of data). (default: 0)
  --top: int # Control paging of import jobs, number of import jobs to return with each call. By default, it returns all import jobs with a default paging of 20. The response contains a `nextLink` property describing the path to get the next page if there are more results. The maximum paging limit for $top is 40. (default: 20)
  --orderby: string # Sort results by an expression which looks like `$orderby=jobId asc` (default when not specified). The syntax is orderby={property} {direction} or just orderby={property}. Properties that can be specified for sorting: jobId, errorDetails, dateCreated, jobStatus, and dateCreated. The available directions are asc (for ascending order) and desc (for descending order). When not specified the asc direction is used. Only one orderby property can be specified.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$skip", var: skip}, {name: "$top", var: top}, {name: "$orderby", var: orderby}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, skip: $skip, top: $top, orderby: $orderby
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job to import the specified data to a storageUrl.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks
# Returns: record<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>
# operationId: ImportTasks_Create
export def "import-tasks-create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --storage-url: string # A shared Access Signature (SAS) Storage URI where the job results will be retrieved from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: storageUrl, var: storage_url}]}
    accept: ["application/json"]
    ok: [201, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, storage_url: $storage_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Get import job operation retrieves information about a previously created import job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks/{id}
# Returns: record<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>
# operationId: ImportTasks_Get
export def "import-tasks-get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the tags registered for a set of devices running an application. Updates are performed asynchronously, meaning that a few seconds are needed before the modifications appear in the results of the Get device command.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/tag
# Returns: record<invalidIds: list<string>>
# operationId: Devices_TagByDeviceId
export def "devices-tag-by-device-id" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --delete-on-null: oneof<nothing, bool> # If this parameter is `true`, tags with a null value will be deleted. (default: false)
  tags: any # A JSON object describing the set of tags to record for a set of users. Each key is a device/user identifier, each value is itself a key/value set: the tags to set for the specified device/user identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/tag"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deleteOnNull, var: delete_on_null}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, delete_on_null: $delete_on_null, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information associated to a device running an application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/{deviceId}
# Returns: record<appInfo: record, deviceId: string, info: record<androidAPILevel: int, applicationVersionCode: int, applicationVersionName: string, carrierCountry: string, carrierName: string, firmwareName: string, firmwareVersion: string, locale: string, networkSubtype: string, networkType: string, phoneManufacturer: string, phoneModel: string, serviceVersion: string, timeZoneOffset: int>, location: record<countrycode: string, locality: string, region: string>, meta: record<firstSeen: int, lastInfo: int, lastLocation: int, lastSeen: int, nativePushEnabled: bool>>
# operationId: Devices_GetByDeviceId
export def "devices-get-by-device-id" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/{deviceId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: deviceId, var: device_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, device_id: $device_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the tags registered for a set of users running an application. Updates are performed asynchronously, meaning that a few seconds are needed before the modifications appear in the results of the Get device command.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/users/tag
# Returns: record<invalidIds: list<string>>
# operationId: Devices_TagByUserId
export def "devices-tag-by-user-id" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --delete-on-null: oneof<nothing, bool> # If this parameter is `true`, tags with a null value will be deleted. (default: false)
  tags: any # A JSON object describing the set of tags to record for a set of users. Each key is a device/user identifier, each value is itself a key/value set: the tags to set for the specified device/user identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/users/tag"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deleteOnNull, var: delete_on_null}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, api_version: $api_version, delete_on_null: $delete_on_null, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information associated to a device running an application using the user identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/users/{userId}
# Returns: record<appInfo: record, deviceId: string, info: record<androidAPILevel: int, applicationVersionCode: int, applicationVersionName: string, carrierCountry: string, carrierName: string, firmwareName: string, firmwareVersion: string, locale: string, networkSubtype: string, networkType: string, phoneManufacturer: string, phoneModel: string, serviceVersion: string, timeZoneOffset: int>, location: record<countrycode: string, locality: string, region: string>, meta: record<firstSeen: int, lastInfo: int, lastLocation: int, lastSeen: int, nativePushEnabled: bool>>
# operationId: Devices_GetByUserId
export def "devices-get-by-user-id" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/users/{userId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: appCollection, var: app_collection}, {name: appName, var: app_name}, {name: userId, var: user_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, app_collection: $app_collection, app_name: $app_name, user_id: $user_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
