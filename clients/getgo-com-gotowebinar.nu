# Auto-generated client for GoToWebinar v1.0.0
# Source: https://api.apis.guru/v2/specs/getgo.com/gotowebinar/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOWEBINAR_TOKEN

const CLIENT = {
  base_url: "https://api.getgo.com/G2W/rest"
  token_env_var: "GOTOWEBINAR_TOKEN"
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

def base-url-completer [] { ["https://api.getgo.com/G2W/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def locale-completer [] { ["de_DE" "en_US" "es_ES" "fr_FR" "it_IT" "zh_CN"] }
def type-completer [] { ["Hybrid" "PSTN" "Private" "VOIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-all-account-webinars: "record<_embedded: record<webinars: list<record>>, page: record<number: int, size: int, totalElements: int, totalPages: int>>"
    get-historical-webinars: "table<description: string, organizerKey: int, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int>"
    get-organizer-sessions: "table<endTime: string, registrantsAttended: int, sessionKey: int, startTime: string, webinarID: string, webinarKey: int>"
    get-upcoming-webinars: "table<description: string, inSession: bool, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int>"
    get-all-webinars: "table<description: string, inSession: bool, numberOfRegistrants: int, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int>"
    create-webinar: "record<webinarKey: string>"
    get-webinar: "record<description: string, inSession: bool, numberOfOpenedInvitations: int, numberOfRegistrants: int, numberOfRegistrationLinkClicks: int, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: table<endTime: string, startTime: string>, webinarID: string, webinarKey: int>"
    get-attendees-for-all-webinar-sessions: "table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int>"
    get-audio-information: "record<confCallNumbers: record, privateInfo: record<attendee: string, organizer: string, panelist: string>, type: string>"
    get-coorganizers: "table<email: string, external: bool, givenName: string, joinLink: string, memberKey: string, surname: string>"
    create-coorganizers: "table<email: string, external: bool, givenName: string, joinLink: string, memberKey: string, surname: string>"
    get-webinar-meeting-times: "table<endTime: string, startTime: string>"
    get-panelists: "table<email: string, firstName: string, joinLink: string, lastName: string, name: string, panelistId: int>"
    create-panelists: "table<email: string, joinLink: string, name: string, panelistKey: string>"
    get-performance-for-all-webinar-sessions: "record"
    get-all-registrants-for-webinar: "table<email: string, firstName: string, joinUrl: string, lastName: string, registrantKey: int, registrationDate: string, status: string, timeZone: string>"
    create-registrant: "record<joinUrl: string, registrantKey: int>"
    get-registration-fields: "record<fields: table<answers: list, field: string, maxSize: int, required: bool>, questions: table<answers: list, maxSize: int, question: string, questionKey: int, required: bool, type: string>>"
    get-registrant: "record<address: string, city: string, country: string, email: string, employeeCount: string, firstName: string, implementationTimeFrame: string, industry: string, jobTitle: string, joinUrl: string, lastName: string, numberOfEmployees: string, organization: string, phone: string, purchasingRole: string, purchasingTimeFrame: string, questionsAndComments: string, registrantKey: int, registrationDate: string, responses: table<answer: string, question: string>, source: string, state: string, status: string, timeZone: string, type: string, unsubscribed: bool, zipCode: string>"
    get-all-sessions: "table<endTime: string, registrantsAttended: int, sessionKey: int, startTime: string, webinarID: string, webinarKey: int>"
    get-webinar-session: "table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int>"
    get-attendees: "table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int>"
    get-attendee: "record<email: string, firstName: string, joinUrl: string, lastName: string, registrantKey: int, registrationDate: string, status: string, timeZone: string>"
    get-attendee-poll-answers: "table<answer: string, question: string>"
    get-attendee-questions: "table<answers: list<record>, askedBy: string, question: string>"
    get-attendee-survey-answers: "table<answer: string, question: string>"
    get-performance: "record<attendance: record<averageAttendanceTimeSeconds: float, averageAttentiveness: float, averageInterestRating: float, percentageAttendance: float, registrantCount: int>, pollsAndSurveys: record<percentagePollsCompleted: float, percentageSurveysCompleted: float, pollCount: int, questionsAsked: int, surveyCount: float>>"
    get-polls: "table<numberOfResponses: int, question: string, responses: list<record>>"
    get-questions: "table<answers: list<record>, askedBy: string, question: string>"
    get-surveys: "table<numberOfResponses: int, question: string, responses: list<record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-all-account-webinars" "get-historical-webinars" "get-organizer-sessions" "get-upcoming-webinars" "get-all-webinars" "create-webinar" "cancel-webinar" "get-webinar" "update-webinar" "get-attendees-for-all-webinar-sessions" "get-audio-information" "update-audio-information" "get-coorganizers" "create-coorganizers" "delete-coorganizer" "resend-coorganizer-invitation" "get-webinar-meeting-times" "get-panelists" "create-panelists" "delete-webinar-panelist" "resend-panelist-invitation" "get-performance-for-all-webinar-sessions" "get-all-registrants-for-webinar" "create-registrant" "get-registration-fields" "delete-registrant" "get-registrant" "get-all-sessions" "get-webinar-session" "get-attendees" "get-attendee" "get-attendee-poll-answers" "get-attendee-questions" "get-attendee-survey-answers" "get-performance" "get-polls" "get-questions" "get-surveys" "commands"] | sort) } | get name | first)
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

# Get all webinars for an account
#
# GET /accounts/{accountKey}/webinars
# Returns: record<_embedded: record<webinars: list<record>>, page: record<number: int, size: int, totalElements: int, totalPages: int>>
# operationId: getAllAccountWebinars
export def "get-all-account-webinars" [
  account_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # A required start of datetime range in ISO8601 UTC format, e.g. 2015-07-13T10:00:00Z (required, format: date-time)
  --to-time: string # A required end of datetime range in ISO8601 UTC format, e.g. 2015-07-13T22:00:00Z (required, format: date-time)
  --page: int # The page number to be displayed. The first page is 0. (format: int64)
  --size: int # The size of the page. (format: int64)
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountKey}/webinars"
    path_params: [{name: accountKey, var: account_key}]
    query: [{name: fromTime, var: from_time, required: true}, {name: toTime, var: to_time, required: true}, {name: page, var: page}, {name: size, var: size}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_key: $account_key, from_time: $from_time, to_time: $to_time, page: $page, size: $size, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get historical webinars
#
# GET /organizers/{organizerKey}/historicalWebinars
# Returns: table<description: string, organizerKey: int, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int>
# operationId: getHistoricalWebinars
export def "get-historical-webinars" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # A required start of datetime range in ISO8601 UTC format, e.g. 2015-07-13T10:00:00Z (required, format: date-time)
  --to-time: string # A required end of datetime range in ISO8601 UTC format, e.g. 2015-07-13T22:00:00Z (required, format: date-time)
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/historicalWebinars"
    path_params: [{name: organizerKey, var: organizer_key}]
    query: [{name: fromTime, var: from_time, required: true}, {name: toTime, var: to_time, required: true}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, from_time: $from_time, to_time: $to_time, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organizer sessions
#
# GET /organizers/{organizerKey}/sessions
# Returns: table<endTime: string, registrantsAttended: int, sessionKey: int, startTime: string, webinarID: string, webinarKey: int>
# operationId: getOrganizerSessions
export def "get-organizer-sessions" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # A required start of datetime range in ISO8601 UTC format, e.g. 2015-07-13T10:00:00Z (required, format: date-time)
  --to-time: string # A required end of datetime range in ISO8601 UTC format, e.g. 2015-07-13T22:00:00Z (required, format: date-time)
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/sessions"
    path_params: [{name: organizerKey, var: organizer_key}]
    query: [{name: fromTime, var: from_time, required: true}, {name: toTime, var: to_time, required: true}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, from_time: $from_time, to_time: $to_time, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upcoming webinars
#
# GET /organizers/{organizerKey}/upcomingWebinars
# Returns: table<description: string, inSession: bool, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int>
# operationId: getUpcomingWebinars
export def "get-upcoming-webinars" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/upcomingWebinars"
    path_params: [{name: organizerKey, var: organizer_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all webinars
#
# GET /organizers/{organizerKey}/webinars
# Returns: table<description: string, inSession: bool, numberOfRegistrants: int, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int>
# operationId: getAllWebinars
export def "get-all-webinars" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars"
    path_params: [{name: organizerKey, var: organizer_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create webinar
#
# POST /organizers/{organizerKey}/webinars
# Returns: record<webinarKey: string>
# operationId: createWebinar
export def "create-webinar" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
  --description: string # A short description of the webinar (2048 characters maximum)
  --is-password-protected: oneof<nothing, bool> # A boolean flag indicating if the webinar is password protected or not. (default: false)
  subject: string # The name/subject of the webinar (128 characters maximum)
  --time-zone: string # The time zone where the webinar is taking place (must be a valid time zone ID, see https://goto-developer.logmein.com/time-zones). If this parameter is not passed, the timezone of the organizer's profile will be used
  times: list # Array with startTime and endTime for webinar. Since this call creates single session webinars, the array can only contain a single pair of startTime and endTime — item shape: {endTime: string, startTime: string}
  --type: string # Specifies the webinar type. The default type value is "single_session", which is used to create a single webinar session. The possible values are "single_session", "series", "sequence". If type is set to "single_session", a single webinar session is created. If type is set to "series", a webinar series is created. In this case 2 or more timeframes must be specified for each webinar. Example: "times": [{"startTime": "...", "endTime": "..."},{"startTime": "...", "endTime": "..."},{"startTime": "...", "endTime": "..."}. If type is set to "sequence" a sequence of webinars is created. The times object in the body must be replaced by the "recurrenceStart" object. Example: "recurrenceStart": {"startTime":"2012-06-12T16:00:00Z", "endTime": "2012-06-12T17:00:00Z" }. The "recurrenceEnd" and "recurrencePattern" body parameter must be specified. Example: , "recurrenceEnd": "2012-07-10", "recurrencePattern": "daily". (default: single_session)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars"
    path_params: [{name: organizerKey, var: organizer_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: isPasswordProtected, var: is_password_protected}, {name: subject, var: subject}, {name: timeZone, var: time_zone}, {name: times, var: times}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organizer_key: $organizer_key, authorization: $authorization, description: $description, is_password_protected: $is_password_protected, subject: $subject, time_zone: $time_zone, times: $times, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel webinar
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}
# operationId: cancelWebinar
export def "cancel-webinar" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --send-cancellation-emails: oneof<nothing, bool> # Indicates whether cancellation notice emails should be sent. The default value is false
  --authorization: string # Access token (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizers/{organizerKey}/webinars/{webinarKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    query: [{name: sendCancellationEmails, var: send_cancellation_emails}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, send_cancellation_emails: $send_cancellation_emails, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webinar
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}
# Returns: record<description: string, inSession: bool, numberOfOpenedInvitations: int, numberOfRegistrants: int, numberOfRegistrationLinkClicks: int, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: table<endTime: string, startTime: string>, webinarID: string, webinarKey: int>
# operationId: getWebinar
export def "get-webinar" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update webinar
#
# PUT /organizers/{organizerKey}/webinars/{webinarKey}
# operationId: updateWebinar
export def "update-webinar" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-participants: oneof<nothing, bool> # Defines whether to send notifications to participants
  --authorization: string # Access token (required)
  --description: string # A description of the webinar (2048 characters maximum)
  --locale: string@locale-completer # The webinar language
  --subject: string # The name/subject of the webinar (128 characters maximum)
  --time-zone: string # The time zone where the webinar is taking place (must be a valid time zone ID, see https://goto-developer.logmein.com/time-zones). If this parameter is not passed, the timezone of the organizer's profile will be used
  --times: list # Array with start and end time(s) for webinar — item shape: {endTime: string, startTime: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizers/{organizerKey}/webinars/{webinarKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    query: [{name: notifyParticipants, var: notify_participants}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: locale, var: locale}, {name: subject, var: subject}, {name: timeZone, var: time_zone}, {name: times, var: times}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, notify_participants: $notify_participants, authorization: $authorization, description: $description, locale: $locale, subject: $subject, time_zone: $time_zone, times: $times
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attendees for all webinar sessions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/attendees
# Returns: table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int>
# operationId: getAttendeesForAllWebinarSessions
export def "get-attendees-for-all-webinar-sessions" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/attendees"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get audio information
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/audio
# Returns: record<confCallNumbers: record, privateInfo: record<attendee: string, organizer: string, panelist: string>, type: string>
# operationId: getAudioInformation
export def "get-audio-information" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/audio"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update audio information
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/audio
# operationId: updateAudioInformation
export def "update-audio-information" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-participants: oneof<nothing, bool> # Defines whether to send notifications to participants
  --authorization: string # Access token (required)
  --private-info: any # Defines the audio data for an own conferencing system — shape: {attendee: string, organizer?: string, panelist?: string}
  --pstn-info: any # Defines the audio/conferencing settings for the specified webinar. It required to pass 'tollFreeCountries' or 'tollCountries' or both. — shape: {tollCountries?: list<string>, tollFreeCountries?: list<string>}
  type: string@type-completer # How to connect to the webinar's audio conference
]: any -> any {
  $in | http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/audio"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    query: [{name: notifyParticipants, var: notify_participants}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: privateInfo, var: private_info}, {name: pstnInfo, var: pstn_info}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, notify_participants: $notify_participants, authorization: $authorization, private_info: $private_info, pstn_info: $pstn_info, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get co-organizers
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers
# Returns: table<email: string, external: bool, givenName: string, joinLink: string, memberKey: string, surname: string>
# operationId: getCoorganizers
export def "get-coorganizers" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/coorganizers"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create co-organizers
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers
# Returns: table<email: string, external: bool, givenName: string, joinLink: string, memberKey: string, surname: string>
# operationId: createCoorganizers
export def "create-coorganizers" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/coorganizers"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete co-organizer
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers/{coorganizerKey}
# operationId: deleteCoorganizer
export def "delete-coorganizer" [
  organizer_key: int
  webinar_key: int
  coorganizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external: oneof<nothing, bool> # By default only internal co-organizers (with a GoToWebinar account) can be deleted. If you want to use this call for external co-organizers you have to set this parameter to 'true'.
  --authorization: string # Access token (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/coorganizers/{coorganizerKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: coorganizerKey, var: coorganizer_key}]
    query: [{name: external, var: external}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, coorganizer_key: $coorganizer_key, external: $external, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend invitation
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers/{coorganizerKey}/resendInvitation
# operationId: resendCoorganizerInvitation
export def "resend-coorganizer-invitation" [
  organizer_key: int
  webinar_key: int
  coorganizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external: oneof<nothing, bool> # By default only internal co-organizers (with a GoToWebinar account) will retrieve the resent invitation email. If you want to use this call for external co-organizers you have to set this parameter to 'true'.
  --authorization: string # Access token (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/coorganizers/{coorganizerKey}/resendInvitation"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: coorganizerKey, var: coorganizer_key}]
    query: [{name: external, var: external}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, coorganizer_key: $coorganizer_key, external: $external, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webinar meeting times
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/meetingtimes
# Returns: table<endTime: string, startTime: string>
# operationId: getWebinarMeetingTimes
export def "get-webinar-meeting-times" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/meetingtimes"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webinar panelists
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/panelists
# Returns: table<email: string, firstName: string, joinLink: string, lastName: string, name: string, panelistId: int>
# operationId: getPanelists
export def "get-panelists" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/panelists"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Panelists
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/panelists
# Returns: table<email: string, joinLink: string, name: string, panelistKey: string>
# operationId: createPanelists
export def "create-panelists" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/panelists"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete webinar panelist
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}/panelists/{panelistKey}
# operationId: deleteWebinarPanelist
export def "delete-webinar-panelist" [
  organizer_key: int
  webinar_key: int
  panelist_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/panelists/{panelistKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: panelistKey, var: panelist_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, panelist_key: $panelist_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend panelist invitation
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/panelists/{panelistKey}/resendInvitation
# operationId: resendPanelistInvitation
export def "resend-panelist-invitation" [
  organizer_key: int
  webinar_key: int
  panelist_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/panelists/{panelistKey}/resendInvitation"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: panelistKey, var: panelist_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, panelist_key: $panelist_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get performance for all webinar sessions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/performance
# Returns: record
# operationId: getPerformanceForAllWebinarSessions
export def "get-performance-for-all-webinar-sessions" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/performance"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get registrants
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/registrants
# Returns: table<email: string, firstName: string, joinUrl: string, lastName: string, registrantKey: int, registrationDate: string, status: string, timeZone: string>
# operationId: getAllRegistrantsForWebinar
export def "get-all-registrants-for-webinar" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/registrants"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create registrant
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/registrants
# Returns: record<joinUrl: string, registrantKey: int>
# operationId: createRegistrant
export def "create-registrant" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resend-confirmation: oneof<nothing, bool> # Indicates whether the confirmation email should be resent when a registrant is re-registered. The default value is false.
  --authorization: string # Access token (required)
  --hdr-accept: string # Set to 'application/vnd.citrix.g2wapi-v1.1+json' to make a registration using fields (custom or default) additional to the basic ones. (spec name: Accept)
  --address: string # The registrant's address
  --city: string # The registrant's city
  --country: string # The registrant's country
  email: string # The registrant's email address
  first_name: string # The registrant's first name
  --industry: string # The type of industry the registrant's organization belongs to
  --job-title: string # The registrant's job title
  last_name: string # The registrant's last name
  --number-of-employees: string # The size in employees of the registrant's organization
  --organization: string # The registrant's organization
  --phone: string # The registrant's phone
  --purchasing-role: string # The registrant's role in purchasing the product
  --purchasing-time-frame: string # The time frame within which the product will be purchased
  --questions-and-comments: string # Any questions or comments the registrant made at the time of registration
  --responses: list # Set the answers of all questions — item shape: {answerKey?: int, questionKey: int, responseText?: string}
  --source: string # The source that led to the registration. This can be any string like 'Newsletter 123' or 'Marketing campaign ABC'
  --state: string # The registrant's state (US only)
  --zip-code: string # The registrant's zip (post) code
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/registrants"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    query: [{name: resendConfirmation, var: resend_confirmation}]
    header: [{name: Authorization, var: authorization, required: true}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: country, var: country}, {name: email, var: email}, {name: firstName, var: first_name}, {name: industry, var: industry}, {name: jobTitle, var: job_title}, {name: lastName, var: last_name}, {name: numberOfEmployees, var: number_of_employees}, {name: organization, var: organization}, {name: phone, var: phone}, {name: purchasingRole, var: purchasing_role}, {name: purchasingTimeFrame, var: purchasing_time_frame}, {name: questionsAndComments, var: questions_and_comments}, {name: responses, var: responses}, {name: source, var: source}, {name: state, var: state}, {name: zipCode, var: zip_code}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, resend_confirmation: $resend_confirmation, authorization: $authorization, hdr_accept: $hdr_accept, address: $address, city: $city, country: $country, email: $email, first_name: $first_name, industry: $industry, job_title: $job_title, last_name: $last_name, number_of_employees: $number_of_employees, organization: $organization, phone: $phone, purchasing_role: $purchasing_role, purchasing_time_frame: $purchasing_time_frame, questions_and_comments: $questions_and_comments, responses: $responses, source: $source, state: $state, zip_code: $zip_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get registration fields
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/registrants/fields
# Returns: record<fields: table<answers: list, field: string, maxSize: int, required: bool>, questions: table<answers: list, maxSize: int, question: string, questionKey: int, required: bool, type: string>>
# operationId: getRegistrationFields
export def "get-registration-fields" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/registrants/fields"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete registrant
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}/registrants/{registrantKey}
# operationId: deleteRegistrant
export def "delete-registrant" [
  organizer_key: int
  webinar_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/registrants/{registrantKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: registrantKey, var: registrant_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, registrant_key: $registrant_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get registrant
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/registrants/{registrantKey}
# Returns: record<address: string, city: string, country: string, email: string, employeeCount: string, firstName: string, implementationTimeFrame: string, industry: string, jobTitle: string, joinUrl: string, lastName: string, numberOfEmployees: string, organization: string, phone: string, purchasingRole: string, purchasingTimeFrame: string, questionsAndComments: string, registrantKey: int, registrationDate: string, responses: table<answer: string, question: string>, source: string, state: string, status: string, timeZone: string, type: string, unsubscribed: bool, zipCode: string>
# operationId: getRegistrant
export def "get-registrant" [
  organizer_key: int
  webinar_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/registrants/{registrantKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: registrantKey, var: registrant_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, registrant_key: $registrant_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webinar sessions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions
# Returns: table<endTime: string, registrantsAttended: int, sessionKey: int, startTime: string, webinarID: string, webinarKey: int>
# operationId: getAllSessions
export def "get-all-sessions" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webinar session
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}
# Returns: table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int>
# operationId: getWebinarSession
export def "get-webinar-session" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session attendees
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees
# Returns: table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int>
# operationId: getAttendees
export def "get-attendees" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attendee
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}
# Returns: record<email: string, firstName: string, joinUrl: string, lastName: string, registrantKey: int, registrationDate: string, status: string, timeZone: string>
# operationId: getAttendee
export def "get-attendee" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}, {name: registrantKey, var: registrant_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, registrant_key: $registrant_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attendee poll answers
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/polls
# Returns: table<answer: string, question: string>
# operationId: getAttendeePollAnswers
export def "get-attendee-poll-answers" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/polls"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}, {name: registrantKey, var: registrant_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, registrant_key: $registrant_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attendee questions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/questions
# Returns: table<answers: list<record>, askedBy: string, question: string>
# operationId: getAttendeeQuestions
export def "get-attendee-questions" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/questions"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}, {name: registrantKey, var: registrant_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, registrant_key: $registrant_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attendee survey answers
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/surveys
# Returns: table<answer: string, question: string>
# operationId: getAttendeeSurveyAnswers
export def "get-attendee-survey-answers" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/surveys"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}, {name: registrantKey, var: registrant_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, registrant_key: $registrant_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session performance
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/performance
# Returns: record<attendance: record<averageAttendanceTimeSeconds: float, averageAttentiveness: float, averageInterestRating: float, percentageAttendance: float, registrantCount: int>, pollsAndSurveys: record<percentagePollsCompleted: float, percentageSurveysCompleted: float, pollCount: int, questionsAsked: int, surveyCount: float>>
# operationId: getPerformance
export def "get-performance" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/performance"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session polls
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/polls
# Returns: table<numberOfResponses: int, question: string, responses: list<record>>
# operationId: getPolls
export def "get-polls" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/polls"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session questions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/questions
# Returns: table<answers: list<record>, askedBy: string, question: string>
# operationId: getQuestions
export def "get-questions" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/questions"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session surveys
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/surveys
# Returns: table<numberOfResponses: int, question: string, responses: list<record>>
# operationId: getSurveys
export def "get-surveys" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/surveys"
    path_params: [{name: organizerKey, var: organizer_key}, {name: webinarKey, var: webinar_key}, {name: sessionKey, var: session_key}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organizer_key: $organizer_key, webinar_key: $webinar_key, session_key: $session_key, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
