# Auto-generated client for Advicent.FactFinderService v1
# Source: https://api.apis.guru/v2/specs/naviplancentral.com/factfinder/v1/swagger.json
# Auth: --token flag or $env.ADVICENT_FACTFINDERSERVICE_TOKEN

const CLIENT = {
  base_url: "https://demo.uat.naviplancentral.com/factfinder"
  token_env_var: "ADVICENT_FACTFINDERSERVICE_TOKEN"
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

def base-url-completer [] { ["https://demo.uat.naviplancentral.com/factfinder" "http://demo.uat.naviplancentral.com/factfinder"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def country-completer [] { ["Canada" "UnitedStates"] }
def accept-completer [] { ["application/json" "text/json"] }
def owner-completer [] { ["Client" "CoClient" "Dependent" "Joint" "Other"] }
def employer-savings-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def mandatory-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def post-tax-savings-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def pre-tax-savings-amount-type-completer [] { ["Dollar" "Max" "Percent"] }
def plan-action-completer [] { ["Duplicate" "New" "Project" "Update"] }
def insured-completer [] { ["Client" "CoClient"] }
def member-completer [] { ["Client" "CoClient"] }
def dependent-of-completer [] { ["Client" "CoClient" "Joint" "Other"] }
def relationship-completer [] { ["Aunt" "Brother" "Daughter" "DaughterInLaw" "Father" "FemaleCousin" "FemaleOther" "FosterDaughter" "FosterSon" "Granddaughter" "Grandfather" "Grandmother" "Grandson" "MaleCousin" "MaleOther" "Mother" "Nephew" "Niece" "Sister" "Son" "SonInLaw" "Uncle"] }
def benefit-type-completer [] { ["Dollar" "Percent"] }
def member-completer-1 [] { ["Client" "CoClient" "Dependent"] }
def member-completer-2 [] { ["Client" "CoClient" "Joint"] }
def plan-level-completer [] { ["Level1" "Level2"] }
def module-name-completer [] { ["Assets" "Demographics" "Education" "Expenses" "Incomes" "Insurance" "Liabilities" "MajorPurchase" "Retirement"] }
def status-completer [] { ["AdvisorAccepted" "Canceled" "ClientSubmitted" "Deleted" "Draft" "InProgress" "New"] }
def entity-completer [] { ["CriticalIllnessInsurancePolicies" "DisabilityInsurancePoliciesBenefit" "DisabilityInsurancePoliciesPremium" "Expenses" "Liabilities" "LifeInsurancePolicies" "LongTermCareInsurancePoliciesBenefit" "LongTermCareInsurancePoliciesPremium" "RealEstateAssets" "RetirementExpenses" "SavingsStrategies"] }
def owner-completer-1 [] { ["Client" "CoClient"] }
def owner-completer-2 [] { ["Client" "CoClient" "Joint"] }
def payment-type-completer [] { ["InterestOnly" "LastPeriod" "PrincipalAndInterest" "SetPrincipal"] }
def beneficiary-completer [] { ["Client" "CoClient" "Dependent" "Other"] }
def insured-completer-1 [] { ["Client" "CoClient" "FirstToDie" "Other" "SecondToDie"] }
def payer-completer [] { ["Client" "CoClient" "Joint" "Other"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    account-types-get-by-country: "record<accountTypes: table<allowedSavingsTypes: list, id: int, links: list, name: string>>"
    account-types-get-by-id: "record<allowedSavingsTypes: table<typeName: string, validAmountTypes: list>, id: int, links: table<href: string, rel: string>, name: string>"
    accounts-get-accounts-by-fact-finder-id-by-factfinderid-externalsourceid: "record<accounts: table<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: list, marketValue: float, owner: string, ownerDependentId: int>>"
    accounts-post-by-model: "record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int>"
    accounts-get-account-holdings-by-accountid: "record<holdings: table<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: list, marketValue: float, symbol: string, valuationDate: string>>"
    accounts-post-account-holding-by-accountid-model: "record<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: table<href: string, rel: string>, marketValue: float, symbol: string, valuationDate: string>"
    accounts-put-holdings-by-accountid-holdings: "record<holdings: table<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: list, marketValue: float, symbol: string, valuationDate: string>>"
    accounts-get-account-holding-by-accountid-id: "record<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: table<href: string, rel: string>, marketValue: float, symbol: string, valuationDate: string>"
    accounts-put-by-accountid-id-holding: "record<costBasis: float, cusip: string, description: string, externalDestinationId: string, marketValue: float, symbol: string, valuationDate: string>"
    accounts-get-savings-strategies-by-account-id-by-accountid: "record<savingsStrategies: table<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>>"
    accounts-post-savings-strategy-by-accountid-savingsstrategy: "record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>"
    accounts-get-savings-strategies-by-account-id-and-savings-strategy-id-by-accountid-id: "record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>"
    accounts-put-savings-strategy-by-accountid-id-savingsstrategy: "record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>"
    accounts-get-by-id: "record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int>"
    accounts-put-by-id-model: "record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int>"
    clients-post-by-model: "record<clientId: int, message: string, ownerUser: string, planId: int, success: bool>"
    critical-illness-insurance-policies-get-critical-illness-insurance-policies-by-fact-finder-id-by-factfinderid: "record<criticalIllnessInsurancePolicies: table<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: list, policyType: int, premium: float>>"
    critical-illness-insurance-policies-post-by-model: "record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float>"
    critical-illness-insurance-policies-get-by-id: "record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float>"
    critical-illness-insurance-policies-put-by-id-model: "record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float>"
    critical-illness-insurance-policy-types-get-by-country: "record<insurancePolicyTypes: table<id: int, links: list, name: string>>"
    critical-illness-insurance-policy-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    defined-benefit-pensions-get-defined-benefit-pensions-by-fact-finder-id-by-factfinderid: "record<definedBenefitPensions: table<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: list, member: string, startDate: string>>"
    defined-benefit-pensions-post-by-model: "record"
    defined-benefit-pensions-delete-defined-benefit-pension-by-id: "record"
    defined-benefit-pensions-get-by-id: "record<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, member: string, startDate: string>"
    defined-benefit-pensions-put-defined-benefit-pension-by-id-model: "record<description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, member: string, startDate: string>"
    demographics-get-demographics-by-fact-finder-id-by-factfinderid: "record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>"
    demographics-post-by-model: "record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>"
    demographics-get-dependents-by-demographicid: "record<dependents: table<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: list, relationship: string>>"
    demographics-post-by-demographicid-model: "record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string>"
    demographics-get-dependent-by-demographicid-id: "record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string>"
    demographics-put-by-demographicid-id-model: "record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string>"
    demographics-get-by-id: "record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>"
    demographics-put-by-id-model: "record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>"
    disability-insurance-policies-get-disability-insurance-policies-by-fact-finder-id-by-factfinderid: "record<disabilityInsurancePolicies: table<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: list, policyType: int, premium: float, premiumFrequency: int>>"
    disability-insurance-policies-post-by-model: "record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int>"
    disability-insurance-policies-get-by-id: "record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int>"
    disability-insurance-policies-put-by-id-model: "record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int>"
    disability-insurance-policy-types-get-by-country: "record<insurancePolicyTypes: table<id: int, links: list, name: string>>"
    disability-insurance-policy-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    education-goals-get-education-goals-by-fact-finder-id-by-factfinderid: "record<educationGoals: table<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: list, projectedCost: float>>"
    education-goals-post-by-model: "record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float>"
    education-goals-get-education-expenses-by-education-goal-id-by-educationgoalid: "record<educationExpenses: table<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: list, member: string, memberDependentId: int, startYear: string, years: int>>"
    education-goals-post-by-educationgoalid-model: "record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int>"
    education-goals-get-education-expense-by-educationgoalid-id: "record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int>"
    education-goals-put-by-educationgoalid-id-model: "record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int>"
    education-goals-get-by-id: "record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float>"
    education-goals-put-by-id-model: "record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float>"
    expense-types-get-by-country: "record<expenseTypes: table<id: int, links: list, name: string>>"
    expense-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    expenses-get-expenses-by-fact-finder-id-by-factfinderid: "record<expenses: table<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: list, member: string, startDate: string>>"
    expenses-post-by-model: "record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string>"
    expenses-get-by-id: "record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string>"
    expenses-put-by-id-model: "record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string>"
    fact-finders-get-by-household-id-by-householdid: "table<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: list<record>, modules: record<factFinderModules: list>, planId: int, planLevel: string, status: string>"
    fact-finders-post-by-model: "record"
    fact-finders-post-populate-by-model: "record"
    fact-finder-modules-get-by-factfinderid: "record<factFinderModules: table<available: bool, factFinderId: int, links: list, moduleId: int, moduleName: string, visited: bool>>"
    fact-finder-modules-get-by-factfinderid-id: "record<available: bool, factFinderId: int, links: table<href: string, rel: string>, moduleId: int, moduleName: string, visited: bool>"
    fact-finder-modules-put-by-model-factfinderid-id: "record<available: bool, factFinderId: int, links: table<href: string, rel: string>, moduleId: int, moduleName: string, visited: bool>"
    fact-finders-get-snapshots-by-factfinderid: "record<snapshots: table<created: string, factFinderData: record, factFinderId: int, factFinderStatus: string, snapshotId: int>>"
    fact-finders-post-snapshots-by-factfinderid: "record"
    fact-finders-delete-by-id: "record"
    fact-finders-get-by-id: "record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string>"
    fact-finders-put-by-id-model: "record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string>"
    fact-finders-put-populate-fact-finder-by-id-model: "record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string>"
    filing-status-types-get-by-country: "record<filingStatusTypes: table<filingStatusTypeId: int, filingStatusTypeName: string, hasJointDependent: bool, links: list, partnerStatuses: list, validForSingleAnalysis: bool>>"
    filing-status-types-get-by-id: "record<filingStatusTypeId: int, filingStatusTypeName: string, hasJointDependent: bool, links: table<href: string, rel: string>, partnerStatuses: list<int>, validForSingleAnalysis: bool>"
    frequency-types-get-by-entity-country: "record<frequencyTypes: table<id: int, links: list, name: string>>"
    frequency-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    income-types-get-by-country: "record<incomeTypes: table<id: int, links: list, name: string>>"
    income-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    incomes-get-incomes-by-fact-finder-id-by-factfinderid: "record<incomes: table<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: list, owner: string, startDate: string>>"
    incomes-post-by-model: "record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string>"
    incomes-get-by-id: "record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string>"
    incomes-put-by-id-model: "record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string>"
    liabilities-get-liabilities-by-fact-finder-id-by-factfinderid-externalsourceid: "record<liabilities: table<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: list, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>>"
    liabilities-post-by-model: "record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>"
    liabilities-get-by-id: "record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>"
    liabilities-put-by-id-model: "record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>"
    liability-types-get-by-country: "record<liabilityTypes: table<id: int, links: list, name: string>>"
    liability-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    life-insurance-policies-get-life-insurance-policies-by-fact-finder-id-by-factfinderid: "record<lifeInsurancePolicies: table<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: list, payer: string, policyType: int, premium: float>>"
    life-insurance-policies-post-by-model: "record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float>"
    life-insurance-policies-get-by-id: "record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float>"
    life-insurance-policies-put-by-id-model: "record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float>"
    life-insurance-policies-get-subaccounts-by-lifeinsurancepolicyid: "record<lifeInsurancePolicySubaccounts: table<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>>"
    life-insurance-policies-post-subaccount-by-lifeinsurancepolicyid-model: "record<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>"
    life-insurance-policies-get-subaccount-by-lifeinsurancepolicyid-id: "record<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>"
    life-insurance-policies-put-subaccount-by-lifeinsurancepolicyid-id-model: "record<description: string, externalDestinationId: string, marketValue: float, symbol: string>"
    life-insurance-policy-types-get-by-country: "record<insurancePolicyTypes: table<id: int, links: list, name: string>>"
    life-insurance-policy-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    lifestyle-asset-types-get-by-country: "record<lifestyleAssetTypes: table<id: int, links: list, name: string>>"
    lifestyle-asset-types-get-by-id: "record<id: int, links: table<href: string, rel: string>, name: string>"
    lifestyle-assets-get-lifestyle-assets-by-fact-finder-id-by-factfinderid: "record<lifestyleAssets: table<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: list, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>>"
    lifestyle-assets-post-by-model: "record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>"
    lifestyle-assets-get-by-id: "record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>"
    lifestyle-assets-put-by-id-model: "record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>"
    long-term-care-insurance-policies-get-long-term-care-insurance-policies-by-fact-finder-id-by-factfinderid: "record<longTermCareInsurancePolicies: table<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: list, premium: float, premiumFrequency: int>>"
    long-term-care-insurance-policies-post-by-model: "record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int>"
    long-term-care-insurance-policies-get-by-id: "record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int>"
    long-term-care-insurance-policies-put-by-id-model: "record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int>"
    major-purchase-goal-types-get-by-country: "record<majorPurchaseGoalTypes: table<description: string, links: list, majorPurchaseGoalTypeId: int>>"
    major-purchase-goal-types-get-by-id: "record<description: string, links: table<href: string, rel: string>, majorPurchaseGoalTypeId: int>"
    major-purchase-goals-get-major-purchase-goals-by-fact-finder-id-by-factfinderid: "record<majorPurchaseGoals: table<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: list, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>>"
    major-purchase-goals-post-by-model: "record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>"
    major-purchase-goals-get-by-id: "record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>"
    major-purchase-goals-put-by-id-model: "record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>"
    presentation-get-accounts-by-factfinderid-externalsourceid: "record<accounts: table<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, holdings: list, lastUpdated: string, links: list, marketValue: float, owner: string, ownerDependentId: int, savingsStrategies: list>>"
    presentation-get-demographic-owners-by-factfinderid: "record<owners: table<displayName: string, owner: string, ownerDependentId: int>>"
    presentation-get-demographic-relationships: "record<relationshipTypes: table<id: int, isChildType: bool, relationshipType: string>>"
    presentation-get-incomes-by-factfinderid: "record<incomes: table<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: list, owner: string, startDate: string>>"
    presentation-get-liabilities-by-factfinderid: "record<liabilities: table<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: list, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>>"
    presentation-get-life-insurance-policies-by-factfinderid: "record<lifeInsurancePolicies: table<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: list, payer: string, policyType: int, premium: float, subaccounts: list>>"
    presentation-get-pensions-by-factfinderid: "record<definedBenefitPensions: table<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: list, member: string, startDate: string>>"
    real-estate-assets-get-real-estate-assets-by-fact-finder-id-by-factfinderid: "record<realEstateAssets: table<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: list, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>>"
    real-estate-assets-post-by-model: "record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>"
    real-estate-assets-get-by-id: "record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>"
    real-estate-assets-put-by-id-model: "record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>"
    retirement-goals-get-retirement-goals-by-fact-finder-id-by-factfinderid: "record<retirementGoals: table<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: list, retirementGoalId: int>>"
    retirement-goals-post-by-model: "record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int>"
    retirement-goals-get-by-id: "record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int>"
    retirement-goals-put-by-id-model: "record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int>"
    retirement-goals-get-retirement-expenses-by-retirement-goal-id-by-retirementgoalid: "record<retirementExpenses: table<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: list, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>>"
    retirement-goals-post-by-retirementgoalid-model: "record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>"
    retirement-goals-get-retirement-expense-by-retirementgoalid-id: "record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>"
    retirement-goals-put-by-retirementgoalid-id-model: "record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>"
    fact-finder-service-information-get: "record<name: string, schemaVersion: int, serviceVersion: string, status: string>"
    states-provinces-get-by-country: "record<statesProvinces: table<links: list, stateProvinceId: int, stateProvinceName: string>>"
    states-provinces-get-by-id: "record<links: table<href: string, rel: string>, stateProvinceId: int, stateProvinceName: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["account-types-get-by-country" "account-types-get-by-id" "accounts-get-accounts-by-fact-finder-id-by-factfinderid-externalsourceid" "accounts-post-by-model" "accounts-get-account-holdings-by-accountid" "accounts-post-account-holding-by-accountid-model" "accounts-put-holdings-by-accountid-holdings" "accounts-delete-account-holding-by-accountid-id" "accounts-get-account-holding-by-accountid-id" "accounts-put-by-accountid-id-holding" "accounts-delete-savings-strategies-by-accountid" "accounts-get-savings-strategies-by-account-id-by-accountid" "accounts-post-savings-strategy-by-accountid-savingsstrategy" "accounts-delete-savings-strategy-by-accountid-id" "accounts-get-savings-strategies-by-account-id-and-savings-strategy-id-by-accountid-id" "accounts-put-savings-strategy-by-accountid-id-savingsstrategy" "accounts-delete-account-by-id" "accounts-get-by-id" "accounts-put-by-id-model" "clients-post-by-model" "critical-illness-insurance-policies-get-critical-illness-insurance-policies-by-fact-finder-id-by-factfinderid" "critical-illness-insurance-policies-post-by-model" "critical-illness-insurance-policies-delete-by-id" "critical-illness-insurance-policies-get-by-id" "critical-illness-insurance-policies-put-by-id-model" "critical-illness-insurance-policy-types-get-by-country" "critical-illness-insurance-policy-types-get-by-id" "defined-benefit-pensions-get-defined-benefit-pensions-by-fact-finder-id-by-factfinderid" "defined-benefit-pensions-post-by-model" "defined-benefit-pensions-delete-defined-benefit-pension-by-id" "defined-benefit-pensions-get-by-id" "defined-benefit-pensions-put-defined-benefit-pension-by-id-model" "demographics-get-demographics-by-fact-finder-id-by-factfinderid" "demographics-post-by-model" "demographics-get-dependents-by-demographicid" "demographics-post-by-demographicid-model" "demographics-delete-dependent-by-demographicid-id" "demographics-get-dependent-by-demographicid-id" "demographics-put-by-demographicid-id-model" "demographics-get-by-id" "demographics-put-by-id-model" "disability-insurance-policies-get-disability-insurance-policies-by-fact-finder-id-by-factfinderid" "disability-insurance-policies-post-by-model" "disability-insurance-policies-delete-by-id" "disability-insurance-policies-get-by-id" "disability-insurance-policies-put-by-id-model" "disability-insurance-policy-types-get-by-country" "disability-insurance-policy-types-get-by-id" "education-goals-get-education-goals-by-fact-finder-id-by-factfinderid" "education-goals-post-by-model" "education-goals-get-education-expenses-by-education-goal-id-by-educationgoalid" "education-goals-post-by-educationgoalid-model" "education-goals-delete-by-educationgoalid-id" "education-goals-get-education-expense-by-educationgoalid-id" "education-goals-put-by-educationgoalid-id-model" "education-goals-delete-by-id" "education-goals-get-by-id" "education-goals-put-by-id-model" "expense-types-get-by-country" "expense-types-get-by-id" "expenses-get-expenses-by-fact-finder-id-by-factfinderid" "expenses-post-by-model" "expenses-delete-by-id" "expenses-get-by-id" "expenses-put-by-id-model" "fact-finders-get-by-household-id-by-householdid" "fact-finders-post-by-model" "fact-finders-post-populate-by-model" "fact-finder-modules-get-by-factfinderid" "fact-finder-modules-get-by-factfinderid-id" "fact-finder-modules-put-by-model-factfinderid-id" "fact-finders-get-snapshots-by-factfinderid" "fact-finders-post-snapshots-by-factfinderid" "fact-finders-delete-by-id" "fact-finders-get-by-id" "fact-finders-put-by-id-model" "fact-finders-put-populate-fact-finder-by-id-model" "filing-status-types-get-by-country" "filing-status-types-get-by-id" "frequency-types-get-by-entity-country" "frequency-types-get-by-id" "income-types-get-by-country" "income-types-get-by-id" "incomes-get-incomes-by-fact-finder-id-by-factfinderid" "incomes-post-by-model" "incomes-delete-by-id" "incomes-get-by-id" "incomes-put-by-id-model" "liabilities-get-liabilities-by-fact-finder-id-by-factfinderid-externalsourceid" "liabilities-post-by-model" "liabilities-delete-by-id" "liabilities-get-by-id" "liabilities-put-by-id-model" "liability-types-get-by-country" "liability-types-get-by-id" "life-insurance-policies-get-life-insurance-policies-by-fact-finder-id-by-factfinderid" "life-insurance-policies-post-by-model" "life-insurance-policies-delete-by-id" "life-insurance-policies-get-by-id" "life-insurance-policies-put-by-id-model" "life-insurance-policies-get-subaccounts-by-lifeinsurancepolicyid" "life-insurance-policies-post-subaccount-by-lifeinsurancepolicyid-model" "life-insurance-policies-delete-subaccount-by-lifeinsurancepolicyid-id" "life-insurance-policies-get-subaccount-by-lifeinsurancepolicyid-id" "life-insurance-policies-put-subaccount-by-lifeinsurancepolicyid-id-model" "life-insurance-policy-types-get-by-country" "life-insurance-policy-types-get-by-id" "lifestyle-asset-types-get-by-country" "lifestyle-asset-types-get-by-id" "lifestyle-assets-get-lifestyle-assets-by-fact-finder-id-by-factfinderid" "lifestyle-assets-post-by-model" "lifestyle-assets-delete-by-id" "lifestyle-assets-get-by-id" "lifestyle-assets-put-by-id-model" "long-term-care-insurance-policies-get-long-term-care-insurance-policies-by-fact-finder-id-by-factfinderid" "long-term-care-insurance-policies-post-by-model" "long-term-care-insurance-policies-delete-by-id" "long-term-care-insurance-policies-get-by-id" "long-term-care-insurance-policies-put-by-id-model" "major-purchase-goal-types-get-by-country" "major-purchase-goal-types-get-by-id" "major-purchase-goals-get-major-purchase-goals-by-fact-finder-id-by-factfinderid" "major-purchase-goals-post-by-model" "major-purchase-goals-delete-by-id" "major-purchase-goals-get-by-id" "major-purchase-goals-put-by-id-model" "presentation-get-accounts-by-factfinderid-externalsourceid" "presentation-get-demographic-owners-by-factfinderid" "presentation-get-demographic-relationships" "presentation-get-incomes-by-factfinderid" "presentation-get-liabilities-by-factfinderid" "presentation-get-life-insurance-policies-by-factfinderid" "presentation-get-pensions-by-factfinderid" "real-estate-assets-get-real-estate-assets-by-fact-finder-id-by-factfinderid" "real-estate-assets-post-by-model" "real-estate-assets-delete-by-id" "real-estate-assets-get-by-id" "real-estate-assets-put-by-id-model" "retirement-goals-get-retirement-goals-by-fact-finder-id-by-factfinderid" "retirement-goals-post-by-model" "retirement-goals-delete-by-id" "retirement-goals-get-by-id" "retirement-goals-put-by-id-model" "retirement-goals-get-retirement-expenses-by-retirement-goal-id-by-retirementgoalid" "retirement-goals-post-by-retirementgoalid-model" "retirement-goals-delete-by-retirementgoalid-id" "retirement-goals-get-retirement-expense-by-retirementgoalid-id" "retirement-goals-put-by-retirementgoalid-id-model" "fact-finder-service-information-get" "states-provinces-get-by-country" "states-provinces-get-by-id" "commands"] | sort) } | get name | first)
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

# Description: This operation retrieves all Account Types for the specified country. Purpose: Provides access to the Account Types including id and type description.
#
# GET /api/AccountTypes
# Returns: record<accountTypes: table<allowedSavingsTypes: list, id: int, links: list, name: string>>
# operationId: AccountTypes_GetByCountry
export def "account-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Account Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/AccountTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Account Types for the specified id. Purpose: Provides access to the Account Types including id and type description.
#
# GET /api/AccountTypes/{id}
# Returns: record<allowedSavingsTypes: table<typeName: string, validAmountTypes: list>, id: int, links: table<href: string, rel: string>, name: string>
# operationId: AccountTypes_GetById
export def "account-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/AccountTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Accounts for the specified Fact Finder ID and/or external source ID. Purpose: Provides access to the Account information including description and market value.
#
# GET /api/Accounts
# Returns: record<accounts: table<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: list, marketValue: float, owner: string, ownerDependentId: int>>
# operationId: Accounts_GetAccountsByFactFinderIdByFactfinderidExternalsourceid
export def "accounts-get-accounts-by-fact-finder-id-by-factfinderid-externalsourceid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Accounts (required, format: int32)
  --external-source-id: string # The external ID used to filter Accounts
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Accounts"
    query: [{name: factFinderId, var: fact_finder_id, required: true}, {name: externalSourceId, var: external_source_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id, external_source_id: $external_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates an Account. Purpose: Allows for creation of Accounts on a Fact Finder.
#
# POST /api/Accounts
# Returns: record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int>
# operationId: Accounts_PostByModel
export def "accounts-post-by-model" [
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
  --account-type: int # format: int32
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --last-updated: string # format: date-time
  --market-value: float # format: double
  --owner: string@owner-completer
  --owner-dependent-id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: accountType, var: account_type}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: externalSourceId, var: external_source_id}, {name: externalSourceName, var: external_source_name}, {name: factFinderId, var: fact_finder_id}, {name: lastUpdated, var: last_updated}, {name: marketValue, var: market_value}, {name: owner, var: owner}, {name: ownerDependentId, var: owner_dependent_id}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    account_type: $account_type, description: $description, external_destination_id: $external_destination_id, external_source_id: $external_source_id, external_source_name: $external_source_name, fact_finder_id: $fact_finder_id, last_updated: $last_updated, market_value: $market_value, owner: $owner, owner_dependent_id: $owner_dependent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves all holdings in the specified Account.
#
# GET /api/Accounts/{accountId}/Holdings
# Returns: record<holdings: table<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: list, marketValue: float, symbol: string, valuationDate: string>>
# operationId: Accounts_GetAccountHoldingsByAccountid
export def "accounts-get-account-holdings-by-accountid" [
  account_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Accounts/{accountId}/Holdings"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a holding and adds it to an existing Account.
#
# POST /api/Accounts/{accountId}/Holdings
# Returns: record<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: table<href: string, rel: string>, marketValue: float, symbol: string, valuationDate: string>
# operationId: Accounts_PostAccountHoldingByAccountidModel
export def "accounts-post-account-holding-by-accountid-model" [
  account_id: int
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
  --cost-basis: float # format: double
  --cusip: string
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
  --valuation-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Accounts/{accountId}/Holdings"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: costBasis, var: cost_basis}, {name: cusip, var: cusip}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: marketValue, var: market_value}, {name: symbol, var: symbol}, {name: valuationDate, var: valuation_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, cost_basis: $cost_basis, cusip: $cusip, description: $description, external_destination_id: $external_destination_id, market_value: $market_value, symbol: $symbol, valuation_date: $valuation_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates all holdings associated with an account
#
# PUT /api/Accounts/{accountId}/Holdings
# Returns: record<holdings: table<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: list, marketValue: float, symbol: string, valuationDate: string>>
# operationId: Accounts_PutHoldingsByAccountidHoldings
export def "accounts-put-holdings-by-accountid-holdings" [
  account_id: int
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
  --holdings: list # item shape: {costBasis?: float, cusip?: string, description: string, externalDestinationId?: string, marketValue?: float, symbol?: string, valuationDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Accounts/{accountId}/Holdings"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: holdings, var: holdings}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, holdings: $holdings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation deletes a single Account Holding for the specified Account Holding ID and Account ID. Purpose: Provides the ability to remove individual holdings from a specified Account.
#
# DELETE /api/Accounts/{accountId}/Holdings/{id}
# operationId: Accounts_DeleteAccountHoldingByAccountidId
export def "accounts-delete-account-holding-by-accountid-id" [
  account_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Accounts/{accountId}/Holdings/{id}"
    path_params: [{name: accountId, var: account_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Account Holding for the specified Account Holding ID and Account ID. Purpose: Provides access to the Account Holding information including description and market value.
#
# GET /api/Accounts/{accountId}/Holdings/{id}
# Returns: record<accountHoldingId: int, accountId: int, costBasis: float, cusip: string, description: string, externalDestinationId: string, links: table<href: string, rel: string>, marketValue: float, symbol: string, valuationDate: string>
# operationId: Accounts_GetAccountHoldingByAccountidId
export def "accounts-get-account-holding-by-accountid-id" [
  account_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Accounts/{accountId}/Holdings/{id}"
    path_params: [{name: accountId, var: account_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a holding associated with an account
#
# PUT /api/Accounts/{accountId}/Holdings/{id}
# Returns: record<costBasis: float, cusip: string, description: string, externalDestinationId: string, marketValue: float, symbol: string, valuationDate: string>
# operationId: Accounts_PutByAccountidIdHolding
export def "accounts-put-by-accountid-id-holding" [
  account_id: int
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
  --accept: string@accept-completer # Response content type
  --cost-basis: float # format: double
  --cusip: string
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
  --valuation-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Accounts/{accountId}/Holdings/{id}"
    path_params: [{name: accountId, var: account_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: costBasis, var: cost_basis}, {name: cusip, var: cusip}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: marketValue, var: market_value}, {name: symbol, var: symbol}, {name: valuationDate, var: valuation_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, id: $id, cost_basis: $cost_basis, cusip: $cusip, description: $description, external_destination_id: $external_destination_id, market_value: $market_value, symbol: $symbol, valuation_date: $valuation_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes all savings strategies tied to an account
#
# DELETE /api/Accounts/{accountId}/SavingsStrategies
# operationId: Accounts_DeleteSavingsStrategiesByAccountid
export def "accounts-delete-savings-strategies-by-accountid" [
  account_id: int
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
    method: delete
    path: "/api/Accounts/{accountId}/SavingsStrategies"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all of the savings strategies for a specific account
#
# GET /api/Accounts/{accountId}/SavingsStrategies
# Returns: record<savingsStrategies: table<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>>
# operationId: Accounts_GetSavingsStrategiesByAccountIdByAccountid
export def "accounts-get-savings-strategies-by-account-id-by-accountid" [
  account_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Accounts/{accountId}/SavingsStrategies"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a savings strategy on a specific account
#
# POST /api/Accounts/{accountId}/SavingsStrategies
# Returns: record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>
# operationId: Accounts_PostSavingsStrategyByAccountidSavingsstrategy
export def "accounts-post-savings-strategy-by-accountid-savingsstrategy" [
  account_id: int
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
  --employer-savings-amount: float # format: double
  --employer-savings-amount-type: string@employer-savings-amount-type-completer
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency-id: int # format: int32
  --mandatory-amount: float # format: double
  --mandatory-amount-type: string@mandatory-amount-type-completer
  --post-tax-savings-amount: float # format: double
  --post-tax-savings-amount-type: string@post-tax-savings-amount-type-completer
  --pre-tax-savings-amount: float # format: double
  --pre-tax-savings-amount-type: string@pre-tax-savings-amount-type-completer
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Accounts/{accountId}/SavingsStrategies"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: employerSavingsAmount, var: employer_savings_amount}, {name: employerSavingsAmountType, var: employer_savings_amount_type}, {name: endDate, var: end_date}, {name: externalDestinationId, var: external_destination_id}, {name: frequencyId, var: frequency_id}, {name: mandatoryAmount, var: mandatory_amount}, {name: mandatoryAmountType, var: mandatory_amount_type}, {name: postTaxSavingsAmount, var: post_tax_savings_amount}, {name: postTaxSavingsAmountType, var: post_tax_savings_amount_type}, {name: preTaxSavingsAmount, var: pre_tax_savings_amount}, {name: preTaxSavingsAmountType, var: pre_tax_savings_amount_type}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, employer_savings_amount: $employer_savings_amount, employer_savings_amount_type: $employer_savings_amount_type, end_date: $end_date, external_destination_id: $external_destination_id, frequency_id: $frequency_id, mandatory_amount: $mandatory_amount, mandatory_amount_type: $mandatory_amount_type, post_tax_savings_amount: $post_tax_savings_amount, post_tax_savings_amount_type: $post_tax_savings_amount_type, pre_tax_savings_amount: $pre_tax_savings_amount, pre_tax_savings_amount_type: $pre_tax_savings_amount_type, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a specific savings strategy
#
# DELETE /api/Accounts/{accountId}/SavingsStrategies/{id}
# operationId: Accounts_DeleteSavingsStrategyByAccountidId
export def "accounts-delete-savings-strategy-by-accountid-id" [
  account_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Accounts/{accountId}/SavingsStrategies/{id}"
    path_params: [{name: accountId, var: account_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific savings strategy for an account
#
# GET /api/Accounts/{accountId}/SavingsStrategies/{id}
# Returns: record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>
# operationId: Accounts_GetSavingsStrategiesByAccountIdAndSavingsStrategyIdByAccountidId
export def "accounts-get-savings-strategies-by-account-id-and-savings-strategy-id-by-accountid-id" [
  account_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Accounts/{accountId}/SavingsStrategies/{id}"
    path_params: [{name: accountId, var: account_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a specific savings strategy
#
# PUT /api/Accounts/{accountId}/SavingsStrategies/{id}
# Returns: record<accountId: int, employerSavingsAmount: float, employerSavingsAmountType: string, endDate: string, externalDestinationId: string, frequencyId: int, mandatoryAmount: float, mandatoryAmountType: string, postTaxSavingsAmount: float, postTaxSavingsAmountType: string, preTaxSavingsAmount: float, preTaxSavingsAmountType: string, savingsStrategyId: int, startDate: string>
# operationId: Accounts_PutSavingsStrategyByAccountidIdSavingsstrategy
export def "accounts-put-savings-strategy-by-accountid-id-savingsstrategy" [
  account_id: int
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
  --accept: string@accept-completer # Response content type
  --employer-savings-amount: float # format: double
  --employer-savings-amount-type: string@employer-savings-amount-type-completer
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency-id: int # format: int32
  --mandatory-amount: float # format: double
  --mandatory-amount-type: string@mandatory-amount-type-completer
  --post-tax-savings-amount: float # format: double
  --post-tax-savings-amount-type: string@post-tax-savings-amount-type-completer
  --pre-tax-savings-amount: float # format: double
  --pre-tax-savings-amount-type: string@pre-tax-savings-amount-type-completer
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Accounts/{accountId}/SavingsStrategies/{id}"
    path_params: [{name: accountId, var: account_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: employerSavingsAmount, var: employer_savings_amount}, {name: employerSavingsAmountType, var: employer_savings_amount_type}, {name: endDate, var: end_date}, {name: externalDestinationId, var: external_destination_id}, {name: frequencyId, var: frequency_id}, {name: mandatoryAmount, var: mandatory_amount}, {name: mandatoryAmountType, var: mandatory_amount_type}, {name: postTaxSavingsAmount, var: post_tax_savings_amount}, {name: postTaxSavingsAmountType, var: post_tax_savings_amount_type}, {name: preTaxSavingsAmount, var: pre_tax_savings_amount}, {name: preTaxSavingsAmountType, var: pre_tax_savings_amount_type}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, id: $id, employer_savings_amount: $employer_savings_amount, employer_savings_amount_type: $employer_savings_amount_type, end_date: $end_date, external_destination_id: $external_destination_id, frequency_id: $frequency_id, mandatory_amount: $mandatory_amount, mandatory_amount_type: $mandatory_amount_type, post_tax_savings_amount: $post_tax_savings_amount, post_tax_savings_amount_type: $post_tax_savings_amount_type, pre_tax_savings_amount: $pre_tax_savings_amount, pre_tax_savings_amount_type: $pre_tax_savings_amount_type, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes an Account tied to a Fact Finder. Purpose: Allows for removal of an Account from a Fact Finder.
#
# DELETE /api/Accounts/{id}
# operationId: Accounts_DeleteAccountById
export def "accounts-delete-account-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Account for the specified Account ID. Purpose: Provides access to the Account information including description and market value.
#
# GET /api/Accounts/{id}
# Returns: record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int>
# operationId: Accounts_GetById
export def "accounts-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates an Account, deletes associated saving strategies if the account type changes. Purpose: Allows for complete replacement of an Account on a Fact Finder.
#
# PUT /api/Accounts/{id}
# Returns: record<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, lastUpdated: string, links: table<href: string, rel: string>, marketValue: float, owner: string, ownerDependentId: int>
# operationId: Accounts_PutByIdModel
export def "accounts-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --account-type: int # format: int32
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --last-updated: string # format: date-time
  --market-value: float # format: double
  --owner: string@owner-completer
  --owner-dependent-id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Accounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountType, var: account_type}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: externalSourceId, var: external_source_id}, {name: externalSourceName, var: external_source_name}, {name: factFinderId, var: fact_finder_id}, {name: lastUpdated, var: last_updated}, {name: marketValue, var: market_value}, {name: owner, var: owner}, {name: ownerDependentId, var: owner_dependent_id}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_type: $account_type, description: $description, external_destination_id: $external_destination_id, external_source_id: $external_source_id, external_source_name: $external_source_name, fact_finder_id: $fact_finder_id, last_updated: $last_updated, market_value: $market_value, owner: $owner, owner_dependent_id: $owner_dependent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation submits the Fact Finder data to an external system. Purpose: Allows Fact Finder data to be persisted in another system for that system's consumption and use.
#
# POST /api/Clients
# Returns: record<clientId: int, message: string, ownerUser: string, planId: int, success: bool>
# operationId: Clients_PostByModel
export def "clients-post-by-model" [
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
  --external-destination-name: string
  fact_finder_id: int # format: int32
  plan_action: string@plan-action-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Clients"
    body: {content_type: "application/json", kind: json, fields: [{name: externalDestinationName, var: external_destination_name}, {name: factFinderId, var: fact_finder_id}, {name: planAction, var: plan_action}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    external_destination_name: $external_destination_name, fact_finder_id: $fact_finder_id, plan_action: $plan_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Critical Illness Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Critical Illness Insurance Policies including description and policy type.
#
# GET /api/CriticalIllnessInsurancePolicies
# Returns: record<criticalIllnessInsurancePolicies: table<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: list, policyType: int, premium: float>>
# operationId: CriticalIllnessInsurancePolicies_GetCriticalIllnessInsurancePoliciesByFactFinderIdByFactfinderid
export def "critical-illness-insurance-policies-get-critical-illness-insurance-policies-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Critical Illness Insurance Policies (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/CriticalIllnessInsurancePolicies"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Critical Illness Insurance Policy. Purpose: Allows for creation of Critical Illness Insurance Policies on a Fact Finder.
#
# POST /api/CriticalIllnessInsurancePolicies
# Returns: record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float>
# operationId: CriticalIllnessInsurancePolicies_PostByModel
export def "critical-illness-insurance-policies-post-by-model" [
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
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/CriticalIllnessInsurancePolicies"
    body: {content_type: "application/json", kind: json, fields: [{name: benefit, var: benefit}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: insured, var: insured}, {name: policyType, var: policy_type}, {name: premium, var: premium}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    benefit: $benefit, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, insured: $insured, policy_type: $policy_type, premium: $premium
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Critical Illness Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Critical Illness Insurance Policy from a Fact Finder.
#
# DELETE /api/CriticalIllnessInsurancePolicies/{id}
# operationId: CriticalIllnessInsurancePolicies_DeleteById
export def "critical-illness-insurance-policies-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/CriticalIllnessInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Critical Illness Insurance Policy for the specified Critical Illness Insurance Policy ID. Purpose: Provides access to the Critical Illness Insurance Policy including description and policy type.
#
# GET /api/CriticalIllnessInsurancePolicies/{id}
# Returns: record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float>
# operationId: CriticalIllnessInsurancePolicies_GetById
export def "critical-illness-insurance-policies-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/CriticalIllnessInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Critical Illness Insurance Policy. Purpose: Allows for complete replacement of a Critical Illness Insurance Policy on a Fact Finder.
#
# PUT /api/CriticalIllnessInsurancePolicies/{id}
# Returns: record<benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float>
# operationId: CriticalIllnessInsurancePolicies_PutByIdModel
export def "critical-illness-insurance-policies-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/CriticalIllnessInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefit, var: benefit}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: insured, var: insured}, {name: policyType, var: policy_type}, {name: premium, var: premium}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, benefit: $benefit, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, insured: $insured, policy_type: $policy_type, premium: $premium
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Critical Illness Insurance Policy Types for the specified country. Purpose: Provides access to the Critical Illness Insurance Policy Types including id and type description.
#
# GET /api/CriticalIllnessInsurancePolicyTypes
# Returns: record<insurancePolicyTypes: table<id: int, links: list, name: string>>
# operationId: CriticalIllnessInsurancePolicyTypes_GetByCountry
export def "critical-illness-insurance-policy-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Critical Illness Insurance Policy Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/CriticalIllnessInsurancePolicyTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Critical Illness Insurance Policy Type for the specified id. Purpose: Provides access to the Critical Illness Insurance Policy Types including id and type description.
#
# GET /api/CriticalIllnessInsurancePolicyTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: CriticalIllnessInsurancePolicyTypes_GetById
export def "critical-illness-insurance-policy-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/CriticalIllnessInsurancePolicyTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Defined Benefit Pensions for the specified Fact Finder ID. Purpose: Provides access to the Defined Benefit Pensions including description and start date.
#
# GET /api/DefinedBenefitPensions
# Returns: record<definedBenefitPensions: table<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: list, member: string, startDate: string>>
# operationId: DefinedBenefitPensions_GetDefinedBenefitPensionsByFactFinderIdByFactfinderid
export def "defined-benefit-pensions-get-defined-benefit-pensions-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Defined Benefit Pensions (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DefinedBenefitPensions"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Defined Benefit Pension. Purpose: Allows for creation of Defined Benefit Pensions on a Fact Finder.
#
# POST /api/DefinedBenefitPensions
# Returns: record
# operationId: DefinedBenefitPensions_PostByModel
export def "defined-benefit-pensions-post-by-model" [
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
  description: string
  --estimated-amount: float # format: double
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --member: string@member-completer
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/DefinedBenefitPensions"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: estimatedAmount, var: estimated_amount}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: member, var: member}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    description: $description, estimated_amount: $estimated_amount, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, member: $member, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Defined Benefit Pension tied to a Fact Finder. Purpose: Allows for removal of a Defined Benefit Pension from a Fact Finder.
#
# DELETE /api/DefinedBenefitPensions/{id}
# Returns: record
# operationId: DefinedBenefitPensions_DeleteDefinedBenefitPensionById
export def "defined-benefit-pensions-delete-defined-benefit-pension-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/DefinedBenefitPensions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Defined Benefit Pension for the specified Defined Benefit Pension ID. Purpose: Provides access to the Defined Benefit Pension including description and start date.
#
# GET /api/DefinedBenefitPensions/{id}
# Returns: record<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, member: string, startDate: string>
# operationId: DefinedBenefitPensions_GetById
export def "defined-benefit-pensions-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DefinedBenefitPensions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Defined Benefit Pension. Purpose: Allows for complete replacement of a Defined Benefit Pension on a Fact Finder.
#
# PUT /api/DefinedBenefitPensions/{id}
# Returns: record<description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, member: string, startDate: string>
# operationId: DefinedBenefitPensions_PutDefinedBenefitPensionByIdModel
export def "defined-benefit-pensions-put-defined-benefit-pension-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  description: string
  --estimated-amount: float # format: double
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --member: string@member-completer
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/DefinedBenefitPensions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: estimatedAmount, var: estimated_amount}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: member, var: member}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, estimated_amount: $estimated_amount, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, member: $member, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Demographic information for the specified Fact Finder ID. Purpose: Provides access to the Demographic information including city and state.
#
# GET /api/Demographics
# Returns: record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>
# operationId: Demographics_GetDemographicsByFactFinderIdByFactfinderid
export def "demographics-get-demographics-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Demographic information (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Demographics"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates Demographic information. Purpose: Allows for creation of Demographic information on a Fact Finder.
#
# POST /api/Demographics
# Returns: record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>
# operationId: Demographics_PostByModel
export def "demographics-post-by-model" [
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
  city: string
  --external-destination-id: string
  --external-source-id: string
  fact_finder_id: int # format: int32
  head1: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --head2: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --joint-analysis: oneof<nothing, bool>
  state: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Demographics"
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: externalDestinationId, var: external_destination_id}, {name: externalSourceId, var: external_source_id}, {name: factFinderId, var: fact_finder_id}, {name: head1, var: head1}, {name: head2, var: head2}, {name: jointAnalysis, var: joint_analysis, required: true}, {name: state, var: state}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    city: $city, external_destination_id: $external_destination_id, external_source_id: $external_source_id, fact_finder_id: $fact_finder_id, head1: $head1, head2: $head2, joint_analysis: $joint_analysis, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Dependents for the specified Demographic information ID. Purpose: Provides access to the Dependents including first and last name.
#
# GET /api/Demographics/{demographicId}/Dependents
# Returns: record<dependents: table<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: list, relationship: string>>
# operationId: Demographics_GetDependentsByDemographicid
export def "demographics-get-dependents-by-demographicid" [
  demographic_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Demographics/{demographicId}/Dependents"
    path_params: [{name: demographicId, var: demographic_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    demographic_id: $demographic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Dependent. Purpose: Allows for creation of Dependents on a Fact Finder.
#
# POST /api/Demographics/{demographicId}/Dependents
# Returns: record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string>
# operationId: Demographics_PostByDemographicidModel
export def "demographics-post-by-demographicid-model" [
  demographic_id: int
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
  birth_date: string # format: date-time
  dependent_of: string@dependent-of-completer
  --external-destination-id: string
  first_name: string
  last_name: string
  relationship: string@relationship-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Demographics/{demographicId}/Dependents"
    path_params: [{name: demographicId, var: demographic_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: birthDate, var: birth_date}, {name: dependentOf, var: dependent_of}, {name: externalDestinationId, var: external_destination_id}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: relationship, var: relationship}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    demographic_id: $demographic_id, birth_date: $birth_date, dependent_of: $dependent_of, external_destination_id: $external_destination_id, first_name: $first_name, last_name: $last_name, relationship: $relationship
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Dependent tied to a Fact Finder. Purpose: Allows for removal of a Dependent from a Fact Finder.
#
# DELETE /api/Demographics/{demographicId}/Dependents/{id}
# operationId: Demographics_DeleteDependentByDemographicidId
export def "demographics-delete-dependent-by-demographicid-id" [
  demographic_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Demographics/{demographicId}/Dependents/{id}"
    path_params: [{name: demographicId, var: demographic_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    demographic_id: $demographic_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Dependent for the specified Dependent ID. Purpose: Provides access to the Dependent including first and last name.
#
# GET /api/Demographics/{demographicId}/Dependents/{id}
# Returns: record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string>
# operationId: Demographics_GetDependentByDemographicidId
export def "demographics-get-dependent-by-demographicid-id" [
  demographic_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Demographics/{demographicId}/Dependents/{id}"
    path_params: [{name: demographicId, var: demographic_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    demographic_id: $demographic_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Dependent. Purpose: Allows for complete replacement of a Dependent on a Fact Finder.
#
# PUT /api/Demographics/{demographicId}/Dependents/{id}
# Returns: record<birthDate: string, demographicsId: int, dependentId: int, dependentOf: string, externalDestinationId: string, firstName: string, lastName: string, links: table<href: string, rel: string>, relationship: string>
# operationId: Demographics_PutByDemographicidIdModel
export def "demographics-put-by-demographicid-id-model" [
  demographic_id: int
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
  --accept: string@accept-completer # Response content type
  birth_date: string # format: date-time
  dependent_of: string@dependent-of-completer
  --external-destination-id: string
  first_name: string
  last_name: string
  relationship: string@relationship-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Demographics/{demographicId}/Dependents/{id}"
    path_params: [{name: demographicId, var: demographic_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: birthDate, var: birth_date}, {name: dependentOf, var: dependent_of}, {name: externalDestinationId, var: external_destination_id}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: relationship, var: relationship}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    demographic_id: $demographic_id, id: $id, birth_date: $birth_date, dependent_of: $dependent_of, external_destination_id: $external_destination_id, first_name: $first_name, last_name: $last_name, relationship: $relationship
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves Demographic information for the specified Demographic information ID. Purpose: Provides access to the Demographic information including city and state.
#
# GET /api/Demographics/{id}
# Returns: record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>
# operationId: Demographics_GetById
export def "demographics-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Demographics/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates Demographic information. Purpose: Allows for complete replacement of Demographic information on a Fact Finder.
#
# PUT /api/Demographics/{id}
# Returns: record<city: string, created: string, demographicsId: int, externalDestinationId: string, externalSourceId: string, factFinderId: int, head1: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, head2: record<alreadyRetired: bool, birthDate: string, externalDestinationId: string, firstName: string, gender: string, lastName: string, taxFilingStatus: int>, jointAnalysis: bool, links: table<href: string, rel: string>, lockRetirement: bool, state: int>
# operationId: Demographics_PutByIdModel
export def "demographics-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  city: string
  --external-destination-id: string
  --external-source-id: string
  fact_finder_id: int # format: int32
  head1: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --head2: record # shape: {alreadyRetired: bool, birthDate: string, externalDestinationId?: string, firstName: string, gender: "Male"|"Female"|"None", lastName: string, taxFilingStatus: int}
  --joint-analysis: oneof<nothing, bool>
  state: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Demographics/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: externalDestinationId, var: external_destination_id}, {name: externalSourceId, var: external_source_id}, {name: factFinderId, var: fact_finder_id}, {name: head1, var: head1}, {name: head2, var: head2}, {name: jointAnalysis, var: joint_analysis, required: true}, {name: state, var: state}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, city: $city, external_destination_id: $external_destination_id, external_source_id: $external_source_id, fact_finder_id: $fact_finder_id, head1: $head1, head2: $head2, joint_analysis: $joint_analysis, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Disability Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Disability Insurance Policies including description and policy type.
#
# GET /api/DisabilityInsurancePolicies
# Returns: record<disabilityInsurancePolicies: table<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: list, policyType: int, premium: float, premiumFrequency: int>>
# operationId: DisabilityInsurancePolicies_GetDisabilityInsurancePoliciesByFactFinderIdByFactfinderid
export def "disability-insurance-policies-get-disability-insurance-policies-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Disability Insurance Policies (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DisabilityInsurancePolicies"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Disability Insurance Policy. Purpose: Allows for creation of Disability Insurance Policies on a Fact Finder.
#
# POST /api/DisabilityInsurancePolicies
# Returns: record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int>
# operationId: DisabilityInsurancePolicies_PostByModel
export def "disability-insurance-policies-post-by-model" [
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
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  --benefit-type: string@benefit-type-completer
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/DisabilityInsurancePolicies"
    body: {content_type: "application/json", kind: json, fields: [{name: benefit, var: benefit}, {name: benefitFrequency, var: benefit_frequency}, {name: benefitType, var: benefit_type}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: insured, var: insured}, {name: policyType, var: policy_type}, {name: premium, var: premium}, {name: premiumFrequency, var: premium_frequency}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    benefit: $benefit, benefit_frequency: $benefit_frequency, benefit_type: $benefit_type, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, insured: $insured, policy_type: $policy_type, premium: $premium, premium_frequency: $premium_frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Disability Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Disability Insurance Policy from a Fact Finder.
#
# DELETE /api/DisabilityInsurancePolicies/{id}
# operationId: DisabilityInsurancePolicies_DeleteById
export def "disability-insurance-policies-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/DisabilityInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Disability Insurance Policy for the specified Disability Insurance Policy ID. Purpose: Provides access to the Disability Insurance Policy including description and policy type.
#
# GET /api/DisabilityInsurancePolicies/{id}
# Returns: record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int>
# operationId: DisabilityInsurancePolicies_GetById
export def "disability-insurance-policies-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DisabilityInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Disability Insurance Policy. Purpose: Allows for complete replacement of a Disability Insurance Policy on a Fact Finder.
#
# PUT /api/DisabilityInsurancePolicies/{id}
# Returns: record<benefit: float, benefitFrequency: int, benefitType: string, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, policyType: int, premium: float, premiumFrequency: int>
# operationId: DisabilityInsurancePolicies_PutByIdModel
export def "disability-insurance-policies-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  --benefit-type: string@benefit-type-completer
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --policy-type: int # format: int32
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/DisabilityInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefit, var: benefit}, {name: benefitFrequency, var: benefit_frequency}, {name: benefitType, var: benefit_type}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: insured, var: insured}, {name: policyType, var: policy_type}, {name: premium, var: premium}, {name: premiumFrequency, var: premium_frequency}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, benefit: $benefit, benefit_frequency: $benefit_frequency, benefit_type: $benefit_type, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, insured: $insured, policy_type: $policy_type, premium: $premium, premium_frequency: $premium_frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Disability Insurance Policy Types for the specified country. Purpose: Provides access to the Disability Insurance Policy Types including id and type description.
#
# GET /api/DisabilityInsurancePolicyTypes
# Returns: record<insurancePolicyTypes: table<id: int, links: list, name: string>>
# operationId: DisabilityInsurancePolicyTypes_GetByCountry
export def "disability-insurance-policy-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Disability Insurance Policy Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DisabilityInsurancePolicyTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Disability Insurance Policy Types for the specified id. Purpose: Provides access to the Disability Insurance Policy Types including id and type description.
#
# GET /api/DisabilityInsurancePolicyTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: DisabilityInsurancePolicyTypes_GetById
export def "disability-insurance-policy-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DisabilityInsurancePolicyTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Education Goals for the specified Fact Finder ID. Purpose: Provides access to the Education Goals including description and projected cost.
#
# GET /api/EducationGoals
# Returns: record<educationGoals: table<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: list, projectedCost: float>>
# operationId: EducationGoals_GetEducationGoalsByFactFinderIdByFactfinderid
export def "education-goals-get-education-goals-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Education Goals (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/EducationGoals"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates an Education Goal. Purpose: Allows for creation of Education Goals on a Fact Finder.
#
# POST /api/EducationGoals
# Returns: record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float>
# operationId: EducationGoals_PostByModel
export def "education-goals-post-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --projected-cost: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/EducationGoals"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: projectedCost, var: projected_cost}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, projected_cost: $projected_cost
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Education Goal Expenses for the specified Education Goal ID. Purpose: Provides access to the Education Goal Expenses including description and annual cost.
#
# GET /api/EducationGoals/{educationGoalId}/Expenses
# Returns: record<educationExpenses: table<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: list, member: string, memberDependentId: int, startYear: string, years: int>>
# operationId: EducationGoals_GetEducationExpensesByEducationGoalIdByEducationgoalid
export def "education-goals-get-education-expenses-by-education-goal-id-by-educationgoalid" [
  education_goal_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/EducationGoals/{educationGoalId}/Expenses"
    path_params: [{name: educationGoalId, var: education_goal_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    education_goal_id: $education_goal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates an Education Goal Expense. Purpose: Allows for creation of Education Goal Expenses on a Fact Finder.
#
# POST /api/EducationGoals/{educationGoalId}/Expenses
# Returns: record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int>
# operationId: EducationGoals_PostByEducationgoalidModel
export def "education-goals-post-by-educationgoalid-model" [
  education_goal_id: int
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
  --annual-cost: float # format: double
  --external-destination-id: string
  --member: string@member-completer-1
  --member-dependent-id: int # format: int32
  --start-year: string # format: date-time
  --years: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/EducationGoals/{educationGoalId}/Expenses"
    path_params: [{name: educationGoalId, var: education_goal_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annualCost, var: annual_cost}, {name: externalDestinationId, var: external_destination_id}, {name: member, var: member}, {name: memberDependentId, var: member_dependent_id}, {name: startYear, var: start_year}, {name: years, var: years}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    education_goal_id: $education_goal_id, annual_cost: $annual_cost, external_destination_id: $external_destination_id, member: $member, member_dependent_id: $member_dependent_id, start_year: $start_year, years: $years
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes an Education Goal Expense tied to a Fact Finder. Purpose: Allows for removal of an Education Goal Expense from a Fact Finder.
#
# DELETE /api/EducationGoals/{educationGoalId}/Expenses/{id}
# operationId: EducationGoals_DeleteByEducationgoalidId
export def "education-goals-delete-by-educationgoalid-id" [
  education_goal_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/EducationGoals/{educationGoalId}/Expenses/{id}"
    path_params: [{name: educationGoalId, var: education_goal_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    education_goal_id: $education_goal_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Education Goal Expense for the specified Education Goal Expense ID. Purpose: Provides access to the Education Goal Expense including description and annual cost.
#
# GET /api/EducationGoals/{educationGoalId}/Expenses/{id}
# Returns: record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int>
# operationId: EducationGoals_GetEducationExpenseByEducationgoalidId
export def "education-goals-get-education-expense-by-educationgoalid-id" [
  education_goal_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/EducationGoals/{educationGoalId}/Expenses/{id}"
    path_params: [{name: educationGoalId, var: education_goal_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    education_goal_id: $education_goal_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates an Education Goal Expense. Purpose: Allows for complete replacement of an Education Goal Expense on a Fact Finder.
#
# PUT /api/EducationGoals/{educationGoalId}/Expenses/{id}
# Returns: record<annualCost: float, educationExpenseId: int, educationGoalId: int, externalDestinationId: string, links: table<href: string, rel: string>, member: string, memberDependentId: int, startYear: string, years: int>
# operationId: EducationGoals_PutByEducationgoalidIdModel
export def "education-goals-put-by-educationgoalid-id-model" [
  education_goal_id: int
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
  --accept: string@accept-completer # Response content type
  --annual-cost: float # format: double
  --external-destination-id: string
  --member: string@member-completer-1
  --member-dependent-id: int # format: int32
  --start-year: string # format: date-time
  --years: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/EducationGoals/{educationGoalId}/Expenses/{id}"
    path_params: [{name: educationGoalId, var: education_goal_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annualCost, var: annual_cost}, {name: externalDestinationId, var: external_destination_id}, {name: member, var: member}, {name: memberDependentId, var: member_dependent_id}, {name: startYear, var: start_year}, {name: years, var: years}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    education_goal_id: $education_goal_id, id: $id, annual_cost: $annual_cost, external_destination_id: $external_destination_id, member: $member, member_dependent_id: $member_dependent_id, start_year: $start_year, years: $years
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes an Education Goal tied to a Fact Finder. Purpose: Allows for removal of an Education Goal from a Fact Finder.
#
# DELETE /api/EducationGoals/{id}
# operationId: EducationGoals_DeleteById
export def "education-goals-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/EducationGoals/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Education Goal for the specified Education Goal ID. Purpose: Provides access to the Education Goal including description and projected cost.
#
# GET /api/EducationGoals/{id}
# Returns: record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float>
# operationId: EducationGoals_GetById
export def "education-goals-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/EducationGoals/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates an Education Goal Expense. Purpose: Allows for creation of Education Goal Expenses on a Fact Finder.
#
# PUT /api/EducationGoals/{id}
# Returns: record<description: string, educationGoalId: int, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, projectedCost: float>
# operationId: EducationGoals_PutByIdModel
export def "education-goals-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --projected-cost: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/EducationGoals/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: projectedCost, var: projected_cost}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, projected_cost: $projected_cost
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Expense Types for the specified country. Purpose: Provides access to the Expense Types including id and type description.
#
# GET /api/ExpenseTypes
# Returns: record<expenseTypes: table<id: int, links: list, name: string>>
# operationId: ExpenseTypes_GetByCountry
export def "expense-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Expense Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpenseTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Expense Types for the specified country. Purpose: Provides access to the Expense Types including id and type description.
#
# GET /api/ExpenseTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: ExpenseTypes_GetById
export def "expense-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpenseTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Expenses for the specified Fact Finder ID. Purpose: Provides access to the Expenses including description and Expense type.
#
# GET /api/Expenses
# Returns: record<expenses: table<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: list, member: string, startDate: string>>
# operationId: Expenses_GetExpensesByFactFinderIdByFactfinderid
export def "expenses-get-expenses-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Expenses (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Expenses"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates an Expense. Purpose: Allows for creation of Expenses on a Fact Finder.
#
# POST /api/Expenses
# Returns: record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string>
# operationId: Expenses_PostByModel
export def "expenses-post-by-model" [
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
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --expense-amount: float # format: double
  --expense-type-id: int # format: int32
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Expenses"
    body: {content_type: "application/json", kind: json, fields: [{name: annualPeriod, var: annual_period}, {name: description, var: description}, {name: endDate, var: end_date}, {name: expenseAmount, var: expense_amount}, {name: expenseTypeId, var: expense_type_id}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: member, var: member}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    annual_period: $annual_period, description: $description, end_date: $end_date, expense_amount: $expense_amount, expense_type_id: $expense_type_id, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, member: $member, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes an Expense tied to a Fact Finder. Purpose: Allows for removal of an Expense from a Fact Finder.
#
# DELETE /api/Expenses/{id}
# operationId: Expenses_DeleteById
export def "expenses-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Expenses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Expense for the specified Expense ID. Purpose: Provides access to the Expense including description and Expense type.
#
# GET /api/Expenses/{id}
# Returns: record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string>
# operationId: Expenses_GetById
export def "expenses-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Expenses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates an Expense. Purpose: Allows for complete replacement of an Expense on a Fact Finder. Note: Expense type cannot be changed for expenses prepopulated from NaviPlan.
#
# PUT /api/Expenses/{id}
# Returns: record<annualPeriod: int, description: string, endDate: string, expenseAmount: float, expenseId: int, expenseTypeId: int, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, member: string, startDate: string>
# operationId: Expenses_PutByIdModel
export def "expenses-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --expense-amount: float # format: double
  --expense-type-id: int # format: int32
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Expenses/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annualPeriod, var: annual_period}, {name: description, var: description}, {name: endDate, var: end_date}, {name: expenseAmount, var: expense_amount}, {name: expenseTypeId, var: expense_type_id}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: member, var: member}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, annual_period: $annual_period, description: $description, end_date: $end_date, expense_amount: $expense_amount, expense_type_id: $expense_type_id, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, member: $member, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Fact Finders for the specified householdId, or if null, all households associated with the user. Purpose: Provides access to the Fact Finder including status.
#
# GET /api/FactFinders
# Returns: table<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: list<record>, modules: record<factFinderModules: list>, planId: int, planLevel: string, status: string>
# operationId: FactFinders_GetByHouseholdIdByHouseholdid
export def "fact-finders-get-by-household-id-by-householdid" [
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
  --household-id: int # The ID of the household used to retrieve the fact finders. If not set, uses all households associated with the user (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/FactFinders"
    query: [{name: householdId, var: household_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    household_id: $household_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a completely empty draft Fact Finder. Requirements: A householdId and list of modules must be provided. Purpose: Stages a Fact Finder for population.
#
# POST /api/FactFinders
# Returns: record
# operationId: FactFinders_PostByModel
export def "fact-finders-post-by-model" [
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
  household_id: int # format: int32
  --modules: list<string>
  --plan-level: string@plan-level-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/FactFinders"
    body: {content_type: "application/json", kind: json, fields: [{name: householdId, var: household_id}, {name: modules, var: modules}, {name: planLevel, var: plan_level}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    household_id: $household_id, modules: $modules, plan_level: $plan_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a new Populated Fact Finder. Requirements: A householdId and list of modules must be provided. Purpose: Creation of a Fact Finder.
#
# POST /api/FactFinders/Populate
# Returns: record
# operationId: FactFinders_PostPopulateByModel
export def "fact-finders-post-populate-by-model" [
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
  household_id: int # format: int32
  --modules: list<string>
  --plan-id: int # format: int32
  --plan-level: string@plan-level-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/FactFinders/Populate"
    body: {content_type: "application/json", kind: json, fields: [{name: householdId, var: household_id}, {name: modules, var: modules}, {name: planId, var: plan_id}, {name: planLevel, var: plan_level}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    household_id: $household_id, modules: $modules, plan_id: $plan_id, plan_level: $plan_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Fact Finder Modules for the specified Fact Finder ID. Purpose: Provides access to the Fact Finder Modules including description and policy type.
#
# GET /api/FactFinders/{factFinderId}/Modules
# Returns: record<factFinderModules: table<available: bool, factFinderId: int, links: list, moduleId: int, moduleName: string, visited: bool>>
# operationId: FactFinderModules_GetByFactfinderid
export def "fact-finder-modules-get-by-factfinderid" [
  fact_finder_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FactFinders/{factFinderId}/Modules"
    path_params: [{name: factFinderId, var: fact_finder_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Fact Finder Module for the specified Fact Finder Module ID. Purpose: Provides access to the Fact Finder Module including description and policy type.
#
# GET /api/FactFinders/{factFinderId}/Modules/{id}
# Returns: record<available: bool, factFinderId: int, links: table<href: string, rel: string>, moduleId: int, moduleName: string, visited: bool>
# operationId: FactFinderModules_GetByFactfinderidId
export def "fact-finder-modules-get-by-factfinderid-id" [
  fact_finder_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FactFinders/{factFinderId}/Modules/{id}"
    path_params: [{name: factFinderId, var: fact_finder_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Fact Finder Module. Purpose: Allows for complete replacement of a Fact Finder Module on a Fact Finder.
#
# PUT /api/FactFinders/{factFinderId}/Modules/{id}
# Returns: record<available: bool, factFinderId: int, links: table<href: string, rel: string>, moduleId: int, moduleName: string, visited: bool>
# operationId: FactFinderModules_PutByModelFactfinderidId
export def "fact-finder-modules-put-by-model-factfinderid-id" [
  fact_finder_id: int
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
  --accept: string@accept-completer # Response content type
  --available: oneof<nothing, bool>
  module_name: string@module-name-completer
  --visited: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/FactFinders/{factFinderId}/Modules/{id}"
    path_params: [{name: factFinderId, var: fact_finder_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: available, var: available}, {name: moduleName, var: module_name}, {name: visited, var: visited}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id, id: $id, available: $available, module_name: $module_name, visited: $visited
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation retrieves Snapshots of a Fact Finder. Purpose: Allows for advisors to view all Snapshots taken of a Fact Finder.
#
# GET /api/FactFinders/{factFinderId}/Snapshots
# Returns: record<snapshots: table<created: string, factFinderData: record, factFinderId: int, factFinderStatus: string, snapshotId: int>>
# operationId: FactFinders_GetSnapshotsByFactfinderid
export def "fact-finders-get-snapshots-by-factfinderid" [
  fact_finder_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FactFinders/{factFinderId}/Snapshots"
    path_params: [{name: factFinderId, var: fact_finder_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Snapshot of a Fact Finder. Purpose: Allows for advisors to compare the current fact finder to a snapshot prior to acceptance.
#
# POST /api/FactFinders/{factFinderId}/Snapshots
# Returns: record
# operationId: FactFinders_PostSnapshotsByFactfinderid
export def "fact-finders-post-snapshots-by-factfinderid" [
  fact_finder_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/FactFinders/{factFinderId}/Snapshots"
    path_params: [{name: factFinderId, var: fact_finder_id}]
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation deletes a single Fact Finder for the specified Fact Finder ID. Purpose: Deletes the fact finder.
#
# DELETE /api/FactFinders/{id}
# Returns: record
# operationId: FactFinders_DeleteById
export def "fact-finders-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/FactFinders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Fact Finder for the specified Fact Finder ID. Purpose: Provides access to the Fact Finder including status.
#
# GET /api/FactFinders/{id}
# Returns: record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string>
# operationId: FactFinders_GetById
export def "fact-finders-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FactFinders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Fact Finder. Purpose: Allows for the updating of a Fact Finder.
#
# PUT /api/FactFinders/{id}
# Returns: record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string>
# operationId: FactFinders_PutByIdModel
export def "fact-finders-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/FactFinders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation populates a fact finder. Purpose: Allows for the population of a Fact Finder based on a NaviPlan plan or client. This operation cannot be performed on a Fact Finder more than once.
#
# PUT /api/FactFinders/{id}/Populate
# Returns: record<countryCode: string, created: string, factFinderId: int, householdId: int, lastStatusUpdate: string, links: table<href: string, rel: string>, modules: record<factFinderModules: list<record>>, planId: int, planLevel: string, status: string>
# operationId: FactFinders_PutPopulateFactFinderByIdModel
export def "fact-finders-put-populate-fact-finder-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --plan-id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/FactFinders/{id}/Populate"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: planId, var: plan_id}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Filing Status Types for the specified country. Purpose: Provides access to the Filing Status Types including id and type description.
#
# GET /api/FilingStatusTypes
# Returns: record<filingStatusTypes: table<filingStatusTypeId: int, filingStatusTypeName: string, hasJointDependent: bool, links: list, partnerStatuses: list, validForSingleAnalysis: bool>>
# operationId: FilingStatusTypes_GetByCountry
export def "filing-status-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Filing Status Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FilingStatusTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Filing Status Type for the specified id. Purpose: Provides access to the Filing Status Types including id and type description.
#
# GET /api/FilingStatusTypes/{id}
# Returns: record<filingStatusTypeId: int, filingStatusTypeName: string, hasJointDependent: bool, links: table<href: string, rel: string>, partnerStatuses: list<int>, validForSingleAnalysis: bool>
# operationId: FilingStatusTypes_GetById
export def "filing-status-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FilingStatusTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Frequency Types for the specified country and entity. Purpose: Provides access to the Frequency Types including id and type description.
#
# GET /api/FrequencyTypes
# Returns: record<frequencyTypes: table<id: int, links: list, name: string>>
# operationId: FrequencyTypes_GetByEntityCountry
export def "frequency-types-get-by-entity-country" [
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
  --entity: string@entity-completer # The entity used to filter Frequency Types (required)
  --country: string@country-completer # The country used to filter Frequency Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FrequencyTypes"
    query: [{name: entity, var: entity, required: true}, {name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    entity: $entity, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Frequency Type for the specified id. Purpose: Provides access to the Frequency Types including id and type description.
#
# GET /api/FrequencyTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: FrequencyTypes_GetById
export def "frequency-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FrequencyTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Income Types for the specified country. Purpose: Provides access to the Income Types including id and type description.
#
# GET /api/IncomeTypes
# Returns: record<incomeTypes: table<id: int, links: list, name: string>>
# operationId: IncomeTypes_GetByCountry
export def "income-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Income Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/IncomeTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Income Type for the specified id. Purpose: Provides access to the Income Types including id and type description.
#
# GET /api/IncomeTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: IncomeTypes_GetById
export def "income-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/IncomeTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Incomes for the specified Fact Finder ID. Purpose: Provides access to the Incomes including annual amount and start date.
#
# GET /api/Incomes
# Returns: record<incomes: table<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: list, owner: string, startDate: string>>
# operationId: Incomes_GetIncomesByFactFinderIdByFactfinderid
export def "incomes-get-incomes-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Incomes (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Incomes"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates an Income. Purpose: Allows for creation of Incomes on a Fact Finder.
#
# POST /api/Incomes
# Returns: record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string>
# operationId: Incomes_PostByModel
export def "incomes-post-by-model" [
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
  --annual-amount: float # format: double
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --income-type-id: int # format: int32
  --owner: string@owner-completer-1
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Incomes"
    body: {content_type: "application/json", kind: json, fields: [{name: annualAmount, var: annual_amount}, {name: description, var: description}, {name: endDate, var: end_date}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: incomeTypeId, var: income_type_id}, {name: owner, var: owner}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    annual_amount: $annual_amount, description: $description, end_date: $end_date, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, income_type_id: $income_type_id, owner: $owner, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes an Income tied to a Fact Finder. Purpose: Allows for removal of an Income from a Fact Finder.
#
# DELETE /api/Incomes/{id}
# operationId: Incomes_DeleteById
export def "incomes-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Incomes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Income for the specified Income ID. Purpose: Provides access to the Income including annual amount and start date.
#
# GET /api/Incomes/{id}
# Returns: record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string>
# operationId: Incomes_GetById
export def "incomes-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Incomes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates an Income. Purpose: Allows for complete replacement of an Income on a Fact Finder.
#
# PUT /api/Incomes/{id}
# Returns: record<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: table<href: string, rel: string>, owner: string, startDate: string>
# operationId: Incomes_PutByIdModel
export def "incomes-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --annual-amount: float # format: double
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --income-type-id: int # format: int32
  --owner: string@owner-completer-1
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Incomes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annualAmount, var: annual_amount}, {name: description, var: description}, {name: endDate, var: end_date}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: incomeTypeId, var: income_type_id}, {name: owner, var: owner}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, annual_amount: $annual_amount, description: $description, end_date: $end_date, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, income_type_id: $income_type_id, owner: $owner, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Liabilities for the specified Fact Finder ID. Purpose: Provides access to the Liabilities including owner and type.
#
# GET /api/Liabilities
# Returns: record<liabilities: table<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: list, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>>
# operationId: Liabilities_GetLiabilitiesByFactFinderIdByFactfinderidExternalsourceid
export def "liabilities-get-liabilities-by-fact-finder-id-by-factfinderid-externalsourceid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Liabilities (required, format: int32)
  --external-source-id: string # The external source ID used to filter Liabilities
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Liabilities"
    query: [{name: factFinderId, var: fact_finder_id, required: true}, {name: externalSourceId, var: external_source_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id, external_source_id: $external_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Liability. Purpose: Allows for creation of Liabilities on a Fact Finder.
#
# POST /api/Liabilities
# Returns: record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>
# operationId: Liabilities_PostByModel
export def "liabilities-post-by-model" [
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
  --balance: float # format: double
  --balance-as-of-date: string # format: date-time
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --interest-rate: float # format: double
  --last-updated: string # format: date-time
  --liability-type: int # format: int32
  --loan-date: string # format: date-time
  --original-principal: float # format: double
  --owner: string@owner-completer-2
  --payment: float # format: double
  --payment-type: string@payment-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Liabilities"
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: balanceAsOfDate, var: balance_as_of_date}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: externalSourceId, var: external_source_id}, {name: externalSourceName, var: external_source_name}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: interestRate, var: interest_rate}, {name: lastUpdated, var: last_updated}, {name: liabilityType, var: liability_type}, {name: loanDate, var: loan_date}, {name: originalPrincipal, var: original_principal}, {name: owner, var: owner}, {name: payment, var: payment}, {name: paymentType, var: payment_type}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    balance: $balance, balance_as_of_date: $balance_as_of_date, description: $description, external_destination_id: $external_destination_id, external_source_id: $external_source_id, external_source_name: $external_source_name, fact_finder_id: $fact_finder_id, frequency: $frequency, interest_rate: $interest_rate, last_updated: $last_updated, liability_type: $liability_type, loan_date: $loan_date, original_principal: $original_principal, owner: $owner, payment: $payment, payment_type: $payment_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Liability tied to a Fact Finder. Purpose: Allows for removal of a Liability from a Fact Finder.
#
# DELETE /api/Liabilities/{id}
# operationId: Liabilities_DeleteById
export def "liabilities-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/Liabilities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Liability for the specified Liability ID. Purpose: Provides access to the Liability including owner and type.
#
# GET /api/Liabilities/{id}
# Returns: record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>
# operationId: Liabilities_GetById
export def "liabilities-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Liabilities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Liability. Purpose: Allows for complete replacement of a Liability on a Fact Finder.
#
# PUT /api/Liabilities/{id}
# Returns: record<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: table<href: string, rel: string>, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>
# operationId: Liabilities_PutByIdModel
export def "liabilities-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --balance: float # format: double
  --balance-as-of-date: string # format: date-time
  description: string
  --external-destination-id: string
  --external-source-id: string
  --external-source-name: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --interest-rate: float # format: double
  --last-updated: string # format: date-time
  --liability-type: int # format: int32
  --loan-date: string # format: date-time
  --original-principal: float # format: double
  --owner: string@owner-completer-2
  --payment: float # format: double
  --payment-type: string@payment-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Liabilities/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: balanceAsOfDate, var: balance_as_of_date}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: externalSourceId, var: external_source_id}, {name: externalSourceName, var: external_source_name}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: interestRate, var: interest_rate}, {name: lastUpdated, var: last_updated}, {name: liabilityType, var: liability_type}, {name: loanDate, var: loan_date}, {name: originalPrincipal, var: original_principal}, {name: owner, var: owner}, {name: payment, var: payment}, {name: paymentType, var: payment_type}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, balance: $balance, balance_as_of_date: $balance_as_of_date, description: $description, external_destination_id: $external_destination_id, external_source_id: $external_source_id, external_source_name: $external_source_name, fact_finder_id: $fact_finder_id, frequency: $frequency, interest_rate: $interest_rate, last_updated: $last_updated, liability_type: $liability_type, loan_date: $loan_date, original_principal: $original_principal, owner: $owner, payment: $payment, payment_type: $payment_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Liability Types for the specified country. Purpose: Provides access to the Liability Types including id and type description.
#
# GET /api/LiabilityTypes
# Returns: record<liabilityTypes: table<id: int, links: list, name: string>>
# operationId: LiabilityTypes_GetByCountry
export def "liability-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Liability Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LiabilityTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Liability Type for the specified id. Purpose: Provides access to the Liability Types including id and type description.
#
# GET /api/LiabilityTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: LiabilityTypes_GetById
export def "liability-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LiabilityTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Life Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Life Insurance Policies including description and policy type.
#
# GET /api/LifeInsurancePolicies
# Returns: record<lifeInsurancePolicies: table<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: list, payer: string, policyType: int, premium: float>>
# operationId: LifeInsurancePolicies_GetLifeInsurancePoliciesByFactFinderIdByFactfinderid
export def "life-insurance-policies-get-life-insurance-policies-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Life Insurance Policies (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifeInsurancePolicies"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Life Insurance Policy. Purpose: Allows for creation of Life Insurance Policies on a Fact Finder.
#
# POST /api/LifeInsurancePolicies
# Returns: record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float>
# operationId: LifeInsurancePolicies_PostByModel
export def "life-insurance-policies-post-by-model" [
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
  --beneficiary: string@beneficiary-completer
  --beneficiary-dependent-id: int # format: int32
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --general-account-market-value: float # format: double
  --insured: string@insured-completer-1
  --payer: string@payer-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/LifeInsurancePolicies"
    body: {content_type: "application/json", kind: json, fields: [{name: beneficiary, var: beneficiary}, {name: beneficiaryDependentId, var: beneficiary_dependent_id}, {name: benefit, var: benefit}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: generalAccountMarketValue, var: general_account_market_value}, {name: insured, var: insured}, {name: payer, var: payer}, {name: policyType, var: policy_type}, {name: premium, var: premium}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    beneficiary: $beneficiary, beneficiary_dependent_id: $beneficiary_dependent_id, benefit: $benefit, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, general_account_market_value: $general_account_market_value, insured: $insured, payer: $payer, policy_type: $policy_type, premium: $premium
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Life Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Life Insurance Policy and associated subaccounts from a Fact Finder.
#
# DELETE /api/LifeInsurancePolicies/{id}
# operationId: LifeInsurancePolicies_DeleteById
export def "life-insurance-policies-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/LifeInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Life Insurance Policy for the specified Life Insurance Policy ID. Purpose: Provides access to the Life Insurance Policy including description and policy type.
#
# GET /api/LifeInsurancePolicies/{id}
# Returns: record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float>
# operationId: LifeInsurancePolicies_GetById
export def "life-insurance-policies-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifeInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Life Insurance Policy, deletes associated sub-accounts if the policy type changes. Purpose: Allows for complete replacement of a Life Insurance Policy on a Fact Finder.
#
# PUT /api/LifeInsurancePolicies/{id}
# Returns: record<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, payer: string, policyType: int, premium: float>
# operationId: LifeInsurancePolicies_PutByIdModel
export def "life-insurance-policies-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --beneficiary: string@beneficiary-completer
  --beneficiary-dependent-id: int # format: int32
  --benefit: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --general-account-market-value: float # format: double
  --insured: string@insured-completer-1
  --payer: string@payer-completer
  --policy-type: int # format: int32
  --premium: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/LifeInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: beneficiary, var: beneficiary}, {name: beneficiaryDependentId, var: beneficiary_dependent_id}, {name: benefit, var: benefit}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: generalAccountMarketValue, var: general_account_market_value}, {name: insured, var: insured}, {name: payer, var: payer}, {name: policyType, var: policy_type}, {name: premium, var: premium}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, beneficiary: $beneficiary, beneficiary_dependent_id: $beneficiary_dependent_id, benefit: $benefit, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, general_account_market_value: $general_account_market_value, insured: $insured, payer: $payer, policy_type: $policy_type, premium: $premium
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: Get all the subaccounts for an existing Life Insurance Policy. Purpose: Provides access to all the Life Insurance Policy subaccounts.
#
# GET /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts
# Returns: record<lifeInsurancePolicySubaccounts: table<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>>
# operationId: LifeInsurancePolicies_GetSubaccountsByLifeinsurancepolicyid
export def "life-insurance-policies-get-subaccounts-by-lifeinsurancepolicyid" [
  life_insurance_policy_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts"
    path_params: [{name: lifeInsurancePolicyId, var: life_insurance_policy_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    life_insurance_policy_id: $life_insurance_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: Creates a subaccount and adds it to an existing Life Insurance Policy. Purpose: Allows for creation of subaccount on a Life Insurance Policy.
#
# POST /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts
# Returns: record<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>
# operationId: LifeInsurancePolicies_PostSubaccountByLifeinsurancepolicyidModel
export def "life-insurance-policies-post-subaccount-by-lifeinsurancepolicyid-model" [
  life_insurance_policy_id: int
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
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts"
    path_params: [{name: lifeInsurancePolicyId, var: life_insurance_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: marketValue, var: market_value}, {name: symbol, var: symbol}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    life_insurance_policy_id: $life_insurance_policy_id, description: $description, external_destination_id: $external_destination_id, market_value: $market_value, symbol: $symbol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: Deletes an existing Life Insurance Policy Subaccount for an existing Life Insurance Policy. Purpose: Allows for removal of a subaccount from a Life Insurance Policy.
#
# DELETE /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}
# operationId: LifeInsurancePolicies_DeleteSubaccountByLifeinsurancepolicyidId
export def "life-insurance-policies-delete-subaccount-by-lifeinsurancepolicyid-id" [
  life_insurance_policy_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}"
    path_params: [{name: lifeInsurancePolicyId, var: life_insurance_policy_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    life_insurance_policy_id: $life_insurance_policy_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: Get a specific subaccount for an existing Life Insurance Policy. Purpose: Provides access to the Life Insurance Policy subaccount.
#
# GET /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}
# Returns: record<description: string, externalDestinationId: string, lifeInsurancePolicyId: int, lifeInsurancePolicySubaccountId: int, marketValue: float, symbol: string>
# operationId: LifeInsurancePolicies_GetSubaccountByLifeinsurancepolicyidId
export def "life-insurance-policies-get-subaccount-by-lifeinsurancepolicyid-id" [
  life_insurance_policy_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}"
    path_params: [{name: lifeInsurancePolicyId, var: life_insurance_policy_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    life_insurance_policy_id: $life_insurance_policy_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: Updates an existing Life Insurance Policy Subaccount for an existing Life Insurance Policy. Purpose: Allows for complete replacement of a subaccount on a Life Insurance Policy.
#
# PUT /api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}
# Returns: record<description: string, externalDestinationId: string, marketValue: float, symbol: string>
# operationId: LifeInsurancePolicies_PutSubaccountByLifeinsurancepolicyidIdModel
export def "life-insurance-policies-put-subaccount-by-lifeinsurancepolicyid-id-model" [
  life_insurance_policy_id: int
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
  --accept: string@accept-completer # Response content type
  description: string
  --external-destination-id: string
  --market-value: float # format: double
  --symbol: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/LifeInsurancePolicies/{lifeInsurancePolicyId}/Subaccounts/{id}"
    path_params: [{name: lifeInsurancePolicyId, var: life_insurance_policy_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: marketValue, var: market_value}, {name: symbol, var: symbol}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    life_insurance_policy_id: $life_insurance_policy_id, id: $id, description: $description, external_destination_id: $external_destination_id, market_value: $market_value, symbol: $symbol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Life Insurance Policy Types for the specified country. Purpose: Provides access to the Life Insurance Policy Types including id and type description.
#
# GET /api/LifeInsurancePolicyTypes
# Returns: record<insurancePolicyTypes: table<id: int, links: list, name: string>>
# operationId: LifeInsurancePolicyTypes_GetByCountry
export def "life-insurance-policy-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Life Insurance Policy Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifeInsurancePolicyTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Life Insurance Policy Type for the specified id. Purpose: Provides access to the Life Insurance Policy Types including id and type description.
#
# GET /api/LifeInsurancePolicyTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: LifeInsurancePolicyTypes_GetById
export def "life-insurance-policy-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifeInsurancePolicyTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Lifestyle Asset Types for the specified country. Purpose: Provides access to the Lifestyle Asset Types including id and type description.
#
# GET /api/LifestyleAssetTypes
# Returns: record<lifestyleAssetTypes: table<id: int, links: list, name: string>>
# operationId: LifestyleAssetTypes_GetByCountry
export def "lifestyle-asset-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Lifestyle Asset Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifestyleAssetTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Lifestyle Asset Type for the specified id. Purpose: Provides access to the Lifestyle Asset Types including id and type description.
#
# GET /api/LifestyleAssetTypes/{id}
# Returns: record<id: int, links: table<href: string, rel: string>, name: string>
# operationId: LifestyleAssetTypes_GetById
export def "lifestyle-asset-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifestyleAssetTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Lifestyle Assets for the specified Fact Finder ID. Purpose: Provides access to the Lifestyle Assets including description and market value.
#
# GET /api/LifestyleAssets
# Returns: record<lifestyleAssets: table<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: list, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>>
# operationId: LifestyleAssets_GetLifestyleAssetsByFactFinderIdByFactfinderid
export def "lifestyle-assets-get-lifestyle-assets-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Lifestyle Assets (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifestyleAssets"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Lifestyle Asset. Purpose: Allows for creation of Lifestyle Assets on a Fact Finder.
#
# POST /api/LifestyleAssets
# Returns: record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>
# operationId: LifestyleAssets_PostByModel
export def "lifestyle-assets-post-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --type: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/LifestyleAssets"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: marketValue, var: market_value}, {name: owner, var: owner}, {name: purchaseAmount, var: purchase_amount}, {name: purchaseDate, var: purchase_date}, {name: type, var: type}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, market_value: $market_value, owner: $owner, purchase_amount: $purchase_amount, purchase_date: $purchase_date, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Lifestyle Asset tied to a Fact Finder. Purpose: Allows for removal of a Lifestyle Asset from a Fact Finder.
#
# DELETE /api/LifestyleAssets/{id}
# operationId: LifestyleAssets_DeleteById
export def "lifestyle-assets-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/LifestyleAssets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Lifestyle Asset for the specified Lifestyle Asset ID. Purpose: Provides access to the Lifestyle Asset including description and market value.
#
# GET /api/LifestyleAssets/{id}
# Returns: record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>
# operationId: LifestyleAssets_GetById
export def "lifestyle-assets-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LifestyleAssets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Lifestyle Asset. Purpose: Allows for complete replacement of a Lifestyle Asset on a Fact Finder.
#
# PUT /api/LifestyleAssets/{id}
# Returns: record<description: string, externalDestinationId: string, factFinderId: int, lifestyleAssetId: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, type: int>
# operationId: LifestyleAssets_PutByIdModel
export def "lifestyle-assets-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --type: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/LifestyleAssets/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: marketValue, var: market_value}, {name: owner, var: owner}, {name: purchaseAmount, var: purchase_amount}, {name: purchaseDate, var: purchase_date}, {name: type, var: type}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, market_value: $market_value, owner: $owner, purchase_amount: $purchase_amount, purchase_date: $purchase_date, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Long Term Care Insurance Policies for the specified Fact Finder ID. Purpose: Provides access to the Long Term Care Insurance Policies including description and premium.
#
# GET /api/LongTermCareInsurancePolicies
# Returns: record<longTermCareInsurancePolicies: table<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: list, premium: float, premiumFrequency: int>>
# operationId: LongTermCareInsurancePolicies_GetLongTermCareInsurancePoliciesByFactFinderIdByFactfinderid
export def "long-term-care-insurance-policies-get-long-term-care-insurance-policies-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Long Term Care Insurance Policies (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LongTermCareInsurancePolicies"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Long Term Care Insurance Policy. Purpose: Allows for creation of Long Term Care Insurance Policies on a Fact Finder.
#
# POST /api/LongTermCareInsurancePolicies
# Returns: record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int>
# operationId: LongTermCareInsurancePolicies_PostByModel
export def "long-term-care-insurance-policies-post-by-model" [
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
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/LongTermCareInsurancePolicies"
    body: {content_type: "application/json", kind: json, fields: [{name: benefit, var: benefit}, {name: benefitFrequency, var: benefit_frequency}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: insured, var: insured}, {name: premium, var: premium}, {name: premiumFrequency, var: premium_frequency}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    benefit: $benefit, benefit_frequency: $benefit_frequency, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, insured: $insured, premium: $premium, premium_frequency: $premium_frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Long Term Care Insurance Policy tied to a Fact Finder. Purpose: Allows for removal of a Long Term Care Insurance Policy from a Fact Finder.
#
# DELETE /api/LongTermCareInsurancePolicies/{id}
# operationId: LongTermCareInsurancePolicies_DeleteById
export def "long-term-care-insurance-policies-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/LongTermCareInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Long Term Care Insurance Policy for the specified Long Term Care Insurance Policy ID. Purpose: Provides access to the Long Term Care Insurance Policy including description and premium.
#
# GET /api/LongTermCareInsurancePolicies/{id}
# Returns: record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int>
# operationId: LongTermCareInsurancePolicies_GetById
export def "long-term-care-insurance-policies-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/LongTermCareInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Long Term Care Insurance Policy. Purpose: Allows for complete replacement of a Long Term Care Insurance Policy on a Fact Finder.
#
# PUT /api/LongTermCareInsurancePolicies/{id}
# Returns: record<benefit: float, benefitFrequency: int, description: string, externalDestinationId: string, factFinderId: int, insurancePolicyId: int, insured: string, links: table<href: string, rel: string>, premium: float, premiumFrequency: int>
# operationId: LongTermCareInsurancePolicies_PutByIdModel
export def "long-term-care-insurance-policies-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --benefit: float # format: double
  --benefit-frequency: int # format: int32
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --insured: string@insured-completer
  --premium: float # format: double
  --premium-frequency: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/LongTermCareInsurancePolicies/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefit, var: benefit}, {name: benefitFrequency, var: benefit_frequency}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: insured, var: insured}, {name: premium, var: premium}, {name: premiumFrequency, var: premium_frequency}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, benefit: $benefit, benefit_frequency: $benefit_frequency, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, insured: $insured, premium: $premium, premium_frequency: $premium_frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Major Purchase Goal Types for the specified country. Purpose: Provides access to the Major Purchase Goal Types including id and type description.
#
# GET /api/MajorPurchaseGoalTypes
# Returns: record<majorPurchaseGoalTypes: table<description: string, links: list, majorPurchaseGoalTypeId: int>>
# operationId: MajorPurchaseGoalTypes_GetByCountry
export def "major-purchase-goal-types-get-by-country" [
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
  --country: string@country-completer # The country used to filter Major Purchase Goal Types (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/MajorPurchaseGoalTypes"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the Major Purchase Goal Type for the specified id. Purpose: Provides access to the Major Purchase Goal Types including id and type description.
#
# GET /api/MajorPurchaseGoalTypes/{id}
# Returns: record<description: string, links: table<href: string, rel: string>, majorPurchaseGoalTypeId: int>
# operationId: MajorPurchaseGoalTypes_GetById
export def "major-purchase-goal-types-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/MajorPurchaseGoalTypes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Major Purchases for the specified Fact Finder ID. Purpose: Provides access to the Major Purchases including description and amount.
#
# GET /api/MajorPurchaseGoals
# Returns: record<majorPurchaseGoals: table<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: list, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>>
# operationId: MajorPurchaseGoals_GetMajorPurchaseGoalsByFactFinderIdByFactfinderid
export def "major-purchase-goals-get-major-purchase-goals-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Major Purchases (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/MajorPurchaseGoals"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Major Purchase. Purpose: Allows for creation of Major Purchases on a Fact Finder.
#
# POST /api/MajorPurchaseGoals
# Returns: record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>
# operationId: MajorPurchaseGoals_PostByModel
export def "major-purchase-goals-post-by-model" [
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
  --amount: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --major-purchase-goal-type-id: int # format: int32
  --member: string@member-completer-2
  --target-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/MajorPurchaseGoals"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: majorPurchaseGoalTypeId, var: major_purchase_goal_type_id}, {name: member, var: member}, {name: targetDate, var: target_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    amount: $amount, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, major_purchase_goal_type_id: $major_purchase_goal_type_id, member: $member, target_date: $target_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Major Purchase tied to a Fact Finder. Purpose: Allows for removal of a Major Purchase from a Fact Finder.
#
# DELETE /api/MajorPurchaseGoals/{id}
# operationId: MajorPurchaseGoals_DeleteById
export def "major-purchase-goals-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/MajorPurchaseGoals/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Major Purchase for the specified Major Purchase ID. Purpose: Provides access to the Major Purchase including description and amount.
#
# GET /api/MajorPurchaseGoals/{id}
# Returns: record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>
# operationId: MajorPurchaseGoals_GetById
export def "major-purchase-goals-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/MajorPurchaseGoals/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Major Purchase. Purpose: Allows for complete replacement of a Major Purchase on a Fact Finder.
#
# PUT /api/MajorPurchaseGoals/{id}
# Returns: record<amount: float, description: string, externalDestinationId: string, factFinderId: int, links: table<href: string, rel: string>, majorPurchaseGoalId: int, majorPurchaseGoalTypeId: int, member: string, targetDate: string>
# operationId: MajorPurchaseGoals_PutByIdModel
export def "major-purchase-goals-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --amount: float # format: double
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --major-purchase-goal-type-id: int # format: int32
  --member: string@member-completer-2
  --target-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/MajorPurchaseGoals/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: majorPurchaseGoalTypeId, var: major_purchase_goal_type_id}, {name: member, var: member}, {name: targetDate, var: target_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, amount: $amount, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, major_purchase_goal_type_id: $major_purchase_goal_type_id, member: $member, target_date: $target_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all current Accounts for the specified Fact Finder ID, as well as all of the holdings and savings strategies belonging to those accounts. Purpose: Provides access to the Accounts in a Fact Finder as well as any sub-entities belonging to them.
#
# GET /api/Presentation/Accounts
# Returns: record<accounts: table<accountId: int, accountType: int, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, holdings: list, lastUpdated: string, links: list, marketValue: float, owner: string, ownerDependentId: int, savingsStrategies: list>>
# operationId: Presentation_GetAccountsByFactfinderidExternalsourceid
export def "presentation-get-accounts-by-factfinderid-externalsourceid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Accounts (required, format: int32)
  --external-source-id: string # The external ID used to filter Accounts
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/Accounts"
    query: [{name: factFinderId, var: fact_finder_id, required: true}, {name: externalSourceId, var: external_source_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id, external_source_id: $external_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves owner values for the fact finder based on demographics data Purpose: Provides the list of valid options for owner, student, beneficiary, etc.
#
# GET /api/Presentation/Demographics/Owners
# Returns: record<owners: table<displayName: string, owner: string, ownerDependentId: int>>
# operationId: Presentation_GetDemographicOwnersByFactfinderid
export def "presentation-get-demographic-owners-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve owners. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/Demographics/Owners"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all relationship types relevant to demographics. Purpose: Provides a list of relationship types organized by whether or not they can be defined as children.
#
# GET /api/Presentation/Demographics/Relationships
# Returns: record<relationshipTypes: table<id: int, isChildType: bool, relationshipType: string>>
# operationId: Presentation_GetDemographicRelationships
export def "presentation-get-demographic-relationships" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/Demographics/Relationships"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all current Incomes for the specified Fact Finder ID. Purpose: Provides access to the Incomes in a Fact Finder, filtered by Incomes that are current.
#
# GET /api/Presentation/Incomes
# Returns: record<incomes: table<annualAmount: float, description: string, endDate: string, externalDestinationId: string, factFinderId: int, incomeId: int, incomeTypeId: int, links: list, owner: string, startDate: string>>
# operationId: Presentation_GetIncomesByFactfinderid
export def "presentation-get-incomes-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Incomes (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/Incomes"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all current Liabilities for the specified Fact Finder ID. Purpose: Provides access to the Liabilities in a Fact Finder, filtered by Liabilities that are current.
#
# GET /api/Presentation/Liabilities
# Returns: record<liabilities: table<balance: float, balanceAsOfDate: string, description: string, externalDestinationId: string, externalSourceId: string, externalSourceName: string, factFinderId: int, frequency: int, interestRate: float, lastUpdated: string, liabilityId: int, liabilityType: int, links: list, loanDate: string, originalPrincipal: float, owner: string, payment: float, paymentType: string>>
# operationId: Presentation_GetLiabilitiesByFactfinderid
export def "presentation-get-liabilities-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Liabilities (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/Liabilities"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all life insurance policies, including subaccounts if available, for the specified Fact Finder ID. Purpose: Provides access to the Life Insurance Policies in a Fact Finder.
#
# GET /api/Presentation/LifeInsurancePolicies
# Returns: record<lifeInsurancePolicies: table<beneficiary: string, beneficiaryDependentId: int, benefit: float, description: string, externalDestinationId: string, factFinderId: int, frequency: int, generalAccountMarketValue: float, insurancePolicyId: int, insured: string, links: list, payer: string, policyType: int, premium: float, subaccounts: list>>
# operationId: Presentation_GetLifeInsurancePoliciesByFactfinderid
export def "presentation-get-life-insurance-policies-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Life Insurance Policies. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/LifeInsurancePolicies"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all future Defined Benefit Pensions for the specified Fact Finder ID. Purpose: Provides access to the Pensions in a Fact Finder, filtered by Pensions that are in the future.
#
# GET /api/Presentation/Pensions
# Returns: record<definedBenefitPensions: table<definedBenefitPensionId: int, description: string, estimatedAmount: float, externalDestinationId: string, factFinderId: int, links: list, member: string, startDate: string>>
# operationId: Presentation_GetPensionsByFactfinderid
export def "presentation-get-pensions-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Pensions. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Presentation/Pensions"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Real Estate Assets for the specified Fact Finder ID. Purpose: Provides access to the Real Estate Assets including description and market value.
#
# GET /api/RealEstateAssets
# Returns: record<realEstateAssets: table<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: list, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>>
# operationId: RealEstateAssets_GetRealEstateAssetsByFactFinderIdByFactfinderid
export def "real-estate-assets-get-real-estate-assets-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Real Estate Assets (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RealEstateAssets"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Real Estate Asset. Purpose: Allows for creation of Real Estate Assets on a Fact Finder.
#
# POST /api/RealEstateAssets
# Returns: record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>
# operationId: RealEstateAssets_PostByModel
export def "real-estate-assets-post-by-model" [
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
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --rental-income: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/RealEstateAssets"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: marketValue, var: market_value}, {name: owner, var: owner}, {name: purchaseAmount, var: purchase_amount}, {name: purchaseDate, var: purchase_date}, {name: rentalIncome, var: rental_income}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, market_value: $market_value, owner: $owner, purchase_amount: $purchase_amount, purchase_date: $purchase_date, rental_income: $rental_income
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Real Estate Asset tied to a Fact Finder. Purpose: Allows for removal of a Real Estate Asset from a Fact Finder.
#
# DELETE /api/RealEstateAssets/{id}
# operationId: RealEstateAssets_DeleteById
export def "real-estate-assets-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/RealEstateAssets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Real Estate Asset for the specified Real Estate Asset ID. Purpose: Provides access to the Real Estate Asset including description and market value.
#
# GET /api/RealEstateAssets/{id}
# Returns: record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>
# operationId: RealEstateAssets_GetById
export def "real-estate-assets-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RealEstateAssets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Real Estate Asset. Purpose: Allows for complete replacement of a Real Estate Asset on a Fact Finder.
#
# PUT /api/RealEstateAssets/{id}
# Returns: record<description: string, externalDestinationId: string, factFinderId: int, frequency: int, links: table<href: string, rel: string>, marketValue: float, owner: string, purchaseAmount: float, purchaseDate: string, realEstateAssetId: int, rentalIncome: float>
# operationId: RealEstateAssets_PutByIdModel
export def "real-estate-assets-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  description: string
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --frequency: int # format: int32
  --market-value: float # format: double
  --owner: string@owner-completer-2
  --purchase-amount: float # format: double
  --purchase-date: string # format: date-time
  --rental-income: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/RealEstateAssets/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: frequency, var: frequency}, {name: marketValue, var: market_value}, {name: owner, var: owner}, {name: purchaseAmount, var: purchase_amount}, {name: purchaseDate, var: purchase_date}, {name: rentalIncome, var: rental_income}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, frequency: $frequency, market_value: $market_value, owner: $owner, purchase_amount: $purchase_amount, purchase_date: $purchase_date, rental_income: $rental_income
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Retirement Goals for the specified Fact Finder ID. Purpose: Provides access to the Retirement Goals including retirement date.
#
# GET /api/RetirementGoals
# Returns: record<retirementGoals: table<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: list, retirementGoalId: int>>
# operationId: RetirementGoals_GetRetirementGoalsByFactFinderIdByFactfinderid
export def "retirement-goals-get-retirement-goals-by-fact-finder-id-by-factfinderid" [
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
  --fact-finder-id: int # The ID of the Fact Finder used to retrieve Retirement Goals (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RetirementGoals"
    query: [{name: factFinderId, var: fact_finder_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    fact_finder_id: $fact_finder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Retirement Goal. Purpose: Allows for creation of Retirement Goals on a Fact Finder.
#
# POST /api/RetirementGoals
# Returns: record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int>
# operationId: RetirementGoals_PostByModel
export def "retirement-goals-post-by-model" [
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
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --head1-retirement-date: string # format: date-time
  --head2-retirement-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/RetirementGoals"
    body: {content_type: "application/json", kind: json, fields: [{name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: head1RetirementDate, var: head1_retirement_date}, {name: head2RetirementDate, var: head2_retirement_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, head1_retirement_date: $head1_retirement_date, head2_retirement_date: $head2_retirement_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Retirement Goal tied to a Fact Finder. Purpose: Allows for removal of a Retirement Goal from a Fact Finder.
#
# DELETE /api/RetirementGoals/{id}
# operationId: RetirementGoals_DeleteById
export def "retirement-goals-delete-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/RetirementGoals/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Retirement Goal for the specified Retirement Goal ID. Purpose: Provides access to the Retirement Goal including retirement date.
#
# GET /api/RetirementGoals/{id}
# Returns: record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int>
# operationId: RetirementGoals_GetById
export def "retirement-goals-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RetirementGoals/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Retirement Goal. Purpose: Allows for complete replacement of a Retirement Goal on a Fact Finder.
#
# PUT /api/RetirementGoals/{id}
# Returns: record<externalDestinationId: string, factFinderId: int, head1RetirementDate: string, head2RetirementDate: string, links: table<href: string, rel: string>, retirementGoalId: int>
# operationId: RetirementGoals_PutByIdModel
export def "retirement-goals-put-by-id-model" [
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
  --accept: string@accept-completer # Response content type
  --external-destination-id: string
  fact_finder_id: int # format: int32
  --head1-retirement-date: string # format: date-time
  --head2-retirement-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/RetirementGoals/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalDestinationId, var: external_destination_id}, {name: factFinderId, var: fact_finder_id}, {name: head1RetirementDate, var: head1_retirement_date}, {name: head2RetirementDate, var: head2_retirement_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, external_destination_id: $external_destination_id, fact_finder_id: $fact_finder_id, head1_retirement_date: $head1_retirement_date, head2_retirement_date: $head2_retirement_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all Retirement Goal Expenses for the specified Retirement Goal ID. Purpose: Provides access to the Retirement Goal Expenses including description and amount.
#
# GET /api/RetirementGoals/{retirementGoalId}/Expenses
# Returns: record<retirementExpenses: table<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: list, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>>
# operationId: RetirementGoals_GetRetirementExpensesByRetirementGoalIdByRetirementgoalid
export def "retirement-goals-get-retirement-expenses-by-retirement-goal-id-by-retirementgoalid" [
  retirement_goal_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RetirementGoals/{retirementGoalId}/Expenses"
    path_params: [{name: retirementGoalId, var: retirement_goal_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    retirement_goal_id: $retirement_goal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation creates a Retirement Goal Expense. Purpose: Allows for creation of Retirement Goal Expenses on a Fact Finder.
#
# POST /api/RetirementGoals/{retirementGoalId}/Expenses
# Returns: record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>
# operationId: RetirementGoals_PostByRetirementgoalidModel
export def "retirement-goals-post-by-retirementgoalid-model" [
  retirement_goal_id: int
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
  --amount: float # format: double
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/RetirementGoals/{retirementGoalId}/Expenses"
    path_params: [{name: retirementGoalId, var: retirement_goal_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: annualPeriod, var: annual_period}, {name: description, var: description}, {name: endDate, var: end_date}, {name: externalDestinationId, var: external_destination_id}, {name: frequency, var: frequency}, {name: member, var: member}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    retirement_goal_id: $retirement_goal_id, amount: $amount, annual_period: $annual_period, description: $description, end_date: $end_date, external_destination_id: $external_destination_id, frequency: $frequency, member: $member, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation removes a Retirement Goal Expense tied to a Fact Finder. Purpose: Allows for removal of a Retirement Goal Expense from a Fact Finder.
#
# DELETE /api/RetirementGoals/{retirementGoalId}/Expenses/{id}
# operationId: RetirementGoals_DeleteByRetirementgoalidId
export def "retirement-goals-delete-by-retirementgoalid-id" [
  retirement_goal_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/RetirementGoals/{retirementGoalId}/Expenses/{id}"
    path_params: [{name: retirementGoalId, var: retirement_goal_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    retirement_goal_id: $retirement_goal_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves a single Retirement Goal Expense for the specified Retirement Goal Expense ID. Purpose: Provides access to the Retirement Goal Expense including description and amount.
#
# GET /api/RetirementGoals/{retirementGoalId}/Expenses/{id}
# Returns: record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>
# operationId: RetirementGoals_GetRetirementExpenseByRetirementgoalidId
export def "retirement-goals-get-retirement-expense-by-retirementgoalid-id" [
  retirement_goal_id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/RetirementGoals/{retirementGoalId}/Expenses/{id}"
    path_params: [{name: retirementGoalId, var: retirement_goal_id}, {name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    retirement_goal_id: $retirement_goal_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: The operation updates a Retirement Goal Expense. Purpose: Allows for complete replacement of a Retirement Goal Expense on a Fact Finder.
#
# PUT /api/RetirementGoals/{retirementGoalId}/Expenses/{id}
# Returns: record<amount: float, annualPeriod: int, description: string, endDate: string, externalDestinationId: string, frequency: int, links: table<href: string, rel: string>, member: string, retirementExpenseId: int, retirementGoalId: int, startDate: string>
# operationId: RetirementGoals_PutByRetirementgoalidIdModel
export def "retirement-goals-put-by-retirementgoalid-id-model" [
  retirement_goal_id: int
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
  --accept: string@accept-completer # Response content type
  --amount: float # format: double
  --annual-period: int # format: int32
  description: string
  --end-date: string # format: date-time
  --external-destination-id: string
  --frequency: int # format: int32
  --member: string@member-completer-2
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/RetirementGoals/{retirementGoalId}/Expenses/{id}"
    path_params: [{name: retirementGoalId, var: retirement_goal_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: annualPeriod, var: annual_period}, {name: description, var: description}, {name: endDate, var: end_date}, {name: externalDestinationId, var: external_destination_id}, {name: frequency, var: frequency}, {name: member, var: member}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    retirement_goal_id: $retirement_goal_id, id: $id, amount: $amount, annual_period: $annual_period, description: $description, end_date: $end_date, external_destination_id: $external_destination_id, frequency: $frequency, member: $member, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves information statistics for the current service. Purpose: Provides access to Service Information.
#
# GET /api/ServiceInformation
# Returns: record<name: string, schemaVersion: int, serviceVersion: string, status: string>
# operationId: FactFinderServiceInformation_Get
export def "fact-finder-service-information-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ServiceInformation"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves all States and Provinces for the specified country. Purpose: Provides access to the States and Provinces.
#
# GET /api/StatesProvinces
# Returns: record<statesProvinces: table<links: list, stateProvinceId: int, stateProvinceName: string>>
# operationId: StatesProvinces_GetByCountry
export def "states-provinces-get-by-country" [
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
  --country: string@country-completer # The country used to filter States and Provinces (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/StatesProvinces"
    query: [{name: country, var: country, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Description: This operation retrieves the States and Provinces for the specified id. Purpose: Provides access to the States and Provinces.
#
# GET /api/StatesProvinces/{id}
# Returns: record<links: table<href: string, rel: string>, stateProvinceId: int, stateProvinceName: string>
# operationId: StatesProvinces_GetById
export def "states-provinces-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/StatesProvinces/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
