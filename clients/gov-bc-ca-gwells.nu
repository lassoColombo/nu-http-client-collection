# Auto-generated client for Groundwater Wells, Aquifers and Registry API v1
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/gwells/v1/openapi.json
# Auth: --token flag or $env.GROUNDWATER_WELLS_AQUIFERS_AND_REGISTRY_API_TOKEN

const CLIENT = {
  base_url: "https://apps.nrs.gov.bc.ca/gwells/api/v1"
  token_env_var: "GROUNDWATER_WELLS_AQUIFERS_AND_REGISTRY_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: jwt, in: header, header_name: JWT, prefix: ""}
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

def base-url-completer [] { ["https://apps.nrs.gov.bc.ca/gwells/api/v1"] }
def auth-scheme-completer [] { ["jwt"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    aquifer-codes-demand-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifer-codes-materials-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifer-codes-productivity-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifer-codes-quality-concerns-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifer-codes-subtypes-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifer-codes-vulnerability-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifer-codes-water-use-list: "record<count: int, next: string, previous: string, results: table<code: string, description: string>>"
    aquifers-list: "record<count: int, next: string, previous: string, results: table<aquifer_id: int, aquifer_name: string, area: string, demand: string, demand_description: string, known_water_use: string, known_water_use_description: string, litho_stratographic_unit: string, location_description: string, mapping_year: int, material: string, material_description: string, notes: string, productivity: string, productivity_description: string, quality_concern: string, quality_concern_description: string, subtype: string, subtype_description: string, vulnerability: string, vulnerability_description: string>>"
    aquifers-names-list: "table<aquifer_id: int, description: string>"
    aquifers-read: "record<aquifer_id: int, aquifer_name: string, area: string, demand: string, demand_description: string, known_water_use: string, known_water_use_description: string, litho_stratographic_unit: string, location_description: string, mapping_year: int, material: string, material_description: string, notes: string, productivity: string, productivity_description: string, quality_concern: string, quality_concern_description: string, subtype: string, subtype_description: string, vulnerability: string, vulnerability_description: string>"
    aquifers-files-list: "record<private: table<name: string, url: string>, public: table<name: string, url: string>>"
    cities-drillers-list: "table<organization: record<city: string, email: string, fax_tel: string, main_tel: string, name: string, org_guid: string, org_verbose_name: string, postal_code: string, province_state: string, street_address: string, website_url: string>>"
    cities-installers-list: "table<organization: record<city: string, email: string, fax_tel: string, main_tel: string, name: string, org_guid: string, org_verbose_name: string, postal_code: string, province_state: string, street_address: string, website_url: string>>"
    drillers-list: "table<contact_cell: string, contact_email: string, contact_tel: string, first_name: string, person_guid: string, registrations: list<record>, surname: string>"
    drillers-names-list: "table<name: string, person_guid: string, registrations: list<record>>"
    drillers-files-list: "record<private: table<name: string, url: string>, public: table<name: string, url: string>>"
    surveys-list: "table<survey_guid: string, survey_introduction_text: string, survey_link: string, survey_page: string>"
    wells-list: "record<count: int, next: string, previous: string, results: table<alteration_end_date: string, alternative_specs_submitted: bool, analytic_solution_type: string, aquifer: int, aquifer_vulnerability_index: string, artesian_flow: string, artesian_pressure: string, backfill_depth: string, backfill_material: string, backfill_type: string, bcgs_id: int, bedrock_depth: string, boundary_effect: string, city: string, comments: string, construction_end_date: string, construction_start_date: string, coordinate_acquisition_code: string, decommission_details: string, decommission_end_date: string, decommission_method: string, decommission_reason: string, decommission_start_date: string, development_hours: string, development_method: string, development_notes: string, diameter: string, drawdown: string, drilling_company: string, drilling_method: string, ems: string, filter_pack_from: string, filter_pack_material: string, filter_pack_material_size: string, filter_pack_thickness: string, filter_pack_to: string, final_casing_stick_up: string, finished_well_depth: string, ground_elevation: string, ground_elevation_method: string, hydraulic_conductivity: string, hydro_fracturing_performed: bool, hydro_fracturing_yield_increase: string, id_plate_attached_by: string, identification_plate_number: int, intended_water_use: string, land_district: string, latitude: string, legal_block: string, legal_district_lot: string, legal_lot: string, legal_pid: int, legal_plan: string, legal_range: string, legal_section: string, legal_township: string, licenced_status: string, liner_diameter: string, liner_from: string, liner_material: string, liner_thickness: string, liner_to: string, longitude: string, observation_well_number: string, observation_well_status: string, other_drilling_method: string, other_screen_bottom: string, other_screen_material: string, owner_full_name: string, recommended_pump_depth: string, recommended_pump_rate: string, screen_bottom: string, screen_information: string, screen_intake_method: string, screen_material: string, screen_opening: string, screen_type: string, sealant_material: string, specific_storage: string, specific_yield: string, static_level_before_test: string, static_water_level: string, storativity: string, street_address: string, surface_seal_depth: string, surface_seal_length: string, surface_seal_material: string, surface_seal_method: string, surface_seal_thickness: string, testing_duration: int, testing_method: string, total_depth_drilled: string, transmissivity: string, utm_easting: int, utm_northing: int, utm_zone_code: string, water_quality_characteristics: list, water_quality_colour: string, water_quality_odour: string, water_supply_system_name: string, water_supply_system_well_name: string, well_cap_type: string, well_class: string, well_disinfected: bool, well_guid: string, well_identification_plate_attached: string, well_location_description: string, well_orientation: bool, well_status: string, well_subclass: string, well_tag_number: int, well_yield: string, well_yield_unit: string, yield_estimation_duration: string, yield_estimation_method: string, yield_estimation_rate: string>>"
    wells-tags-list: "table<owner_full_name: string, well_tag_number: int>"
    wells-files-list: "record<private: table<name: string, url: string>, public: table<name: string, url: string>>"
    wells-read: "record<alteration_end_date: string, alternative_specs_submitted: bool, analytic_solution_type: string, aquifer: int, aquifer_vulnerability_index: string, artesian_flow: string, artesian_pressure: string, backfill_depth: string, backfill_material: string, backfill_type: string, bcgs_id: int, bedrock_depth: string, boundary_effect: string, casing_set: table<casing_code: string, casing_material: string, diameter: string, drive_shoe: bool, end: string, start: string, wall_thickness: string>, city: string, comments: string, company_of_person_responsible: record<name: string, org_guid: string, org_verbose_name: string>, construction_end_date: string, construction_start_date: string, coordinate_acquisition_code: string, decommission_description_set: table<end: string, material: string, observations: string, start: string>, decommission_details: string, decommission_end_date: string, decommission_method: string, decommission_reason: string, decommission_start_date: string, development_hours: string, development_method: string, development_notes: string, diameter: string, drawdown: string, drilling_company: string, drilling_method: string, ems: string, filter_pack_from: string, filter_pack_material: string, filter_pack_material_size: string, filter_pack_thickness: string, filter_pack_to: string, final_casing_stick_up: string, finished_well_depth: string, ground_elevation: string, ground_elevation_method: string, hydraulic_conductivity: string, hydro_fracturing_performed: bool, hydro_fracturing_yield_increase: string, id_plate_attached_by: string, identification_plate_number: int, intended_water_use: string, land_district: string, latitude: string, legal_block: string, legal_district_lot: string, legal_lot: string, legal_pid: int, legal_plan: string, legal_range: string, legal_section: string, legal_township: string, licenced_status: string, liner_diameter: string, liner_from: string, liner_material: string, liner_thickness: string, liner_to: string, linerperforation_set: table<end: string, start: string>, lithologydescription_set: table<lithology_colour: string, lithology_from: string, lithology_hardness: string, lithology_moisture: string, lithology_raw_data: string, lithology_to: string, water_bearing_estimated_flow: string>, longitude: string, observation_well_number: string, observation_well_status: string, other_drilling_method: string, other_screen_bottom: string, other_screen_material: string, owner_full_name: string, person_responsible: record<name: string, person_guid: string>, recommended_pump_depth: string, recommended_pump_rate: string, screen_bottom: string, screen_information: string, screen_intake_method: string, screen_material: string, screen_opening: string, screen_set: table<assembly_type: string, end: string, internal_diameter: string, slot_size: string, start: string>, screen_type: string, sealant_material: string, specific_storage: string, specific_yield: string, static_level_before_test: string, static_water_level: string, storativity: string, street_address: string, surface_seal_depth: string, surface_seal_length: string, surface_seal_material: string, surface_seal_method: string, surface_seal_thickness: string, testing_duration: int, testing_method: string, total_depth_drilled: string, transmissivity: string, utm_easting: int, utm_northing: int, utm_zone_code: string, water_quality_characteristics: list<string>, water_quality_colour: string, water_quality_odour: string, water_supply_system_name: string, water_supply_system_well_name: string, well: int, well_cap_type: string, well_class: string, well_disinfected: bool, well_guid: string, well_identification_plate_attached: string, well_location_description: string, well_orientation: bool, well_status: string, well_subclass: string, well_tag_number: int, well_yield: string, well_yield_unit: string, yield_estimation_duration: string, yield_estimation_method: string, yield_estimation_rate: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["aquifer-codes-demand-list" "aquifer-codes-materials-list" "aquifer-codes-productivity-list" "aquifer-codes-quality-concerns-list" "aquifer-codes-subtypes-list" "aquifer-codes-vulnerability-list" "aquifer-codes-water-use-list" "aquifers-list" "aquifers-names-list" "aquifers-read" "aquifers-files-list" "cities-drillers-list" "cities-installers-list" "config-list" "drillers-list" "drillers-names-list" "drillers-files-list" "keycloak-list" "submissions-options-list" "surveys-list" "wells-list" "wells-tags-list" "wells-files-list" "wells-read" "commands"] | sort) } | get name | first)
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

# return a list of aquifer demand codes
#
# GET /aquifer-codes/demand/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_demand_list
export def "aquifer-codes-demand-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/demand/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of aquifer material codes
#
# GET /aquifer-codes/materials/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_materials_list
export def "aquifer-codes-materials-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/materials/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of aquifer productivity codes
#
# GET /aquifer-codes/productivity/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_productivity_list
export def "aquifer-codes-productivity-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/productivity/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of quality concern codes
#
# GET /aquifer-codes/quality-concerns/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_quality-concerns_list
export def "aquifer-codes-quality-concerns-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/quality-concerns/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of aquifer subtype codes
#
# GET /aquifer-codes/subtypes/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_subtypes_list
export def "aquifer-codes-subtypes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/subtypes/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of aquifer vulnerability codes
#
# GET /aquifer-codes/vulnerability/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_vulnerability_list
export def "aquifer-codes-vulnerability-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/vulnerability/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of water use codes
#
# GET /aquifer-codes/water-use/
# Returns: record<count: int, next: string, previous: string, results: table<code: string, description: string>>
# operationId: aquifer-codes_water-use_list
export def "aquifer-codes-water-use-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifer-codes/water-use/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return a list of aquifers
#
# GET /aquifers/
# Returns: record<count: int, next: string, previous: string, results: table<aquifer_id: int, aquifer_name: string, area: string, demand: string, demand_description: string, known_water_use: string, known_water_use_description: string, litho_stratographic_unit: string, location_description: string, mapping_year: int, material: string, material_description: string, notes: string, productivity: string, productivity_description: string, quality_concern: string, quality_concern_description: string, subtype: string, subtype_description: string, vulnerability: string, vulnerability_description: string>>
# operationId: aquifers_list
export def "aquifers-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aquifer-id: float
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aquifers/"
    query: [{name: aquifer_id, var: aquifer_id}, {name: ordering, var: ordering}, {name: search, var: search}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    aquifer_id: $aquifer_id, ordering: $ordering, search: $search, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all aquifers in a simplified format
#
# GET /aquifers/names/
# Returns: table<aquifer_id: int, description: string>
# operationId: aquifers_names_list
export def "aquifers-names-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/aquifers/names/"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return details of aquifers
#
# GET /aquifers/{aquifer_id}/
# Returns: record<aquifer_id: int, aquifer_name: string, area: string, demand: string, demand_description: string, known_water_use: string, known_water_use_description: string, litho_stratographic_unit: string, location_description: string, mapping_year: int, material: string, material_description: string, notes: string, productivity: string, productivity_description: string, quality_concern: string, quality_concern_description: string, subtype: string, subtype_description: string, vulnerability: string, vulnerability_description: string>
# operationId: aquifers_read
export def "aquifers-read" [
  aquifer_id: int
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
    path: "/aquifers/{aquifer_id}/"
    path_params: [{name: aquifer_id, var: aquifer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    aquifer_id: $aquifer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list files found for the aquifer identified in the uri
#
# GET /aquifers/{aquifer_id}/files
# Returns: record<private: table<name: string, url: string>, public: table<name: string, url: string>>
# operationId: aquifers_files_list
export def "aquifers-files-list" [
  aquifer_id: string
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
    path: "/aquifers/{aquifer_id}/files"
    path_params: [{name: aquifer_id, var: aquifer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    aquifer_id: $aquifer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns a list of cities with a qualified, registered operator (driller or installer)
#
# GET /cities/drillers/
# Returns: table<organization: record<city: string, email: string, fax_tel: string, main_tel: string, name: string, org_guid: string, org_verbose_name: string, postal_code: string, province_state: string, street_address: string, website_url: string>>
# operationId: cities_drillers_list
export def "cities-drillers-list" [
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
    path: "/cities/drillers/"
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns a list of cities with a qualified, registered operator (driller or installer)
#
# GET /cities/installers/
# Returns: table<organization: record<city: string, email: string, fax_tel: string, main_tel: string, name: string, org_guid: string, org_verbose_name: string, postal_code: string, province_state: string, street_address: string, website_url: string>>
# operationId: cities_installers_list
export def "cities-installers-list" [
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
    path: "/cities/installers/"
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# serves general configuration
#
# GET /config
# operationId: config_list
export def "config-list" [
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
    path: "/config"
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all person records
#
# GET /drillers/
# Returns: table<contact_cell: string, contact_email: string, contact_tel: string, first_name: string, person_guid: string, registrations: list<record>, surname: string>
# operationId: drillers_list
export def "drillers-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
  --ordering: string # Which field to use when ordering the results.
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/drillers/"
    query: [{name: search, var: search}, {name: ordering, var: ordering}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    search: $search, ordering: $ordering, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for a person in the Register
#
# GET /drillers/names/
# Returns: table<name: string, person_guid: string, registrations: list<record>>
# operationId: drillers_names_list
export def "drillers-names-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/drillers/names/"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list files found for the aquifer identified in the uri
#
# GET /drillers/{person_guid}/files/
# Returns: record<private: table<name: string, url: string>, public: table<name: string, url: string>>
# operationId: drillers_files_list
export def "drillers-files-list" [
  person_guid: string
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
    path: "/drillers/{person_guid}/files/"
    path_params: [{name: person_guid, var: person_guid}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    person_guid: $person_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# serves keycloak config
#
# GET /keycloak
# operationId: keycloak_list
export def "keycloak-list" [
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
    path: "/keycloak"
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Options required for submitting activity report forms
#
# GET /submissions/options/
# operationId: submissions_options_list
export def "submissions-options-list" [
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
    path: "/submissions/options/"
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns a list of active surveys
#
# GET /surveys/
# Returns: table<survey_guid: string, survey_introduction_text: string, survey_link: string, survey_page: string>
# operationId: surveys_list
export def "surveys-list" [
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
    path: "/surveys/"
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns a list of wells
#
# GET /wells/
# Returns: record<count: int, next: string, previous: string, results: table<alteration_end_date: string, alternative_specs_submitted: bool, analytic_solution_type: string, aquifer: int, aquifer_vulnerability_index: string, artesian_flow: string, artesian_pressure: string, backfill_depth: string, backfill_material: string, backfill_type: string, bcgs_id: int, bedrock_depth: string, boundary_effect: string, city: string, comments: string, construction_end_date: string, construction_start_date: string, coordinate_acquisition_code: string, decommission_details: string, decommission_end_date: string, decommission_method: string, decommission_reason: string, decommission_start_date: string, development_hours: string, development_method: string, development_notes: string, diameter: string, drawdown: string, drilling_company: string, drilling_method: string, ems: string, filter_pack_from: string, filter_pack_material: string, filter_pack_material_size: string, filter_pack_thickness: string, filter_pack_to: string, final_casing_stick_up: string, finished_well_depth: string, ground_elevation: string, ground_elevation_method: string, hydraulic_conductivity: string, hydro_fracturing_performed: bool, hydro_fracturing_yield_increase: string, id_plate_attached_by: string, identification_plate_number: int, intended_water_use: string, land_district: string, latitude: string, legal_block: string, legal_district_lot: string, legal_lot: string, legal_pid: int, legal_plan: string, legal_range: string, legal_section: string, legal_township: string, licenced_status: string, liner_diameter: string, liner_from: string, liner_material: string, liner_thickness: string, liner_to: string, longitude: string, observation_well_number: string, observation_well_status: string, other_drilling_method: string, other_screen_bottom: string, other_screen_material: string, owner_full_name: string, recommended_pump_depth: string, recommended_pump_rate: string, screen_bottom: string, screen_information: string, screen_intake_method: string, screen_material: string, screen_opening: string, screen_type: string, sealant_material: string, specific_storage: string, specific_yield: string, static_level_before_test: string, static_water_level: string, storativity: string, street_address: string, surface_seal_depth: string, surface_seal_length: string, surface_seal_material: string, surface_seal_method: string, surface_seal_thickness: string, testing_duration: int, testing_method: string, total_depth_drilled: string, transmissivity: string, utm_easting: int, utm_northing: int, utm_zone_code: string, water_quality_characteristics: list, water_quality_colour: string, water_quality_odour: string, water_supply_system_name: string, water_supply_system_well_name: string, well_cap_type: string, well_class: string, well_disinfected: bool, well_guid: string, well_identification_plate_attached: string, well_location_description: string, well_orientation: bool, well_status: string, well_subclass: string, well_tag_number: int, well_yield: string, well_yield_unit: string, yield_estimation_duration: string, yield_estimation_method: string, yield_estimation_rate: string>>
# operationId: wells_list
export def "wells-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wells/"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# seach for wells by tag or owner
#
# GET /wells/tags/
# Returns: table<owner_full_name: string, well_tag_number: int>
# operationId: wells_tags_list
export def "wells-tags-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A search term.
  --ordering: string # Which field to use when ordering the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/wells/tags/"
    query: [{name: search, var: search}, {name: ordering, var: ordering}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    search: $search, ordering: $ordering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list files found for the well identified in the uri
#
# GET /wells/{tag}/files
# Returns: record<private: table<name: string, url: string>, public: table<name: string, url: string>>
# operationId: wells_files_list
export def "wells-files-list" [
  tag: string
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
    path: "/wells/{tag}/files"
    path_params: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return well detail. This view is open to all, and has no permissions.
#
# GET /wells/{well_tag_number}
# Returns: record<alteration_end_date: string, alternative_specs_submitted: bool, analytic_solution_type: string, aquifer: int, aquifer_vulnerability_index: string, artesian_flow: string, artesian_pressure: string, backfill_depth: string, backfill_material: string, backfill_type: string, bcgs_id: int, bedrock_depth: string, boundary_effect: string, casing_set: table<casing_code: string, casing_material: string, diameter: string, drive_shoe: bool, end: string, start: string, wall_thickness: string>, city: string, comments: string, company_of_person_responsible: record<name: string, org_guid: string, org_verbose_name: string>, construction_end_date: string, construction_start_date: string, coordinate_acquisition_code: string, decommission_description_set: table<end: string, material: string, observations: string, start: string>, decommission_details: string, decommission_end_date: string, decommission_method: string, decommission_reason: string, decommission_start_date: string, development_hours: string, development_method: string, development_notes: string, diameter: string, drawdown: string, drilling_company: string, drilling_method: string, ems: string, filter_pack_from: string, filter_pack_material: string, filter_pack_material_size: string, filter_pack_thickness: string, filter_pack_to: string, final_casing_stick_up: string, finished_well_depth: string, ground_elevation: string, ground_elevation_method: string, hydraulic_conductivity: string, hydro_fracturing_performed: bool, hydro_fracturing_yield_increase: string, id_plate_attached_by: string, identification_plate_number: int, intended_water_use: string, land_district: string, latitude: string, legal_block: string, legal_district_lot: string, legal_lot: string, legal_pid: int, legal_plan: string, legal_range: string, legal_section: string, legal_township: string, licenced_status: string, liner_diameter: string, liner_from: string, liner_material: string, liner_thickness: string, liner_to: string, linerperforation_set: table<end: string, start: string>, lithologydescription_set: table<lithology_colour: string, lithology_from: string, lithology_hardness: string, lithology_moisture: string, lithology_raw_data: string, lithology_to: string, water_bearing_estimated_flow: string>, longitude: string, observation_well_number: string, observation_well_status: string, other_drilling_method: string, other_screen_bottom: string, other_screen_material: string, owner_full_name: string, person_responsible: record<name: string, person_guid: string>, recommended_pump_depth: string, recommended_pump_rate: string, screen_bottom: string, screen_information: string, screen_intake_method: string, screen_material: string, screen_opening: string, screen_set: table<assembly_type: string, end: string, internal_diameter: string, slot_size: string, start: string>, screen_type: string, sealant_material: string, specific_storage: string, specific_yield: string, static_level_before_test: string, static_water_level: string, storativity: string, street_address: string, surface_seal_depth: string, surface_seal_length: string, surface_seal_material: string, surface_seal_method: string, surface_seal_thickness: string, testing_duration: int, testing_method: string, total_depth_drilled: string, transmissivity: string, utm_easting: int, utm_northing: int, utm_zone_code: string, water_quality_characteristics: list<string>, water_quality_colour: string, water_quality_odour: string, water_supply_system_name: string, water_supply_system_well_name: string, well: int, well_cap_type: string, well_class: string, well_disinfected: bool, well_guid: string, well_identification_plate_attached: string, well_location_description: string, well_orientation: bool, well_status: string, well_subclass: string, well_tag_number: int, well_yield: string, well_yield_unit: string, yield_estimation_duration: string, yield_estimation_method: string, yield_estimation_rate: string>
# operationId: wells_read
export def "wells-read" [
  well_tag_number: int
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
    path: "/wells/{well_tag_number}"
    path_params: [{name: well_tag_number, var: well_tag_number}]
    accept: ["application/json"]
    ok: [200]
    auth: jwt
  } {
    well_tag_number: $well_tag_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
