# Auto-generated client for LetMC Api V2, Free (Tier 1) v2-free-tier
# Source: https://api.apis.guru/v2/specs/letmc.com/free-tier/v2-free-tier/swagger.json
# Auth: --token flag or $env.LETMC_API_V2_FREE_TIER_1_TOKEN

const CLIENT = {
  base_url: "https://live-api.letmc.com"
  token_env_var: "LETMC_API_V2_FREE_TIER_1_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: apikey, in: header, header_name: ApiKey, prefix: ""}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-v2-tier1-short-name-area-areas: "record<Count: int, Data: table<Branch: string, ETag: string, Name: string, OID: string, ShowOnSites: bool>>"
    get-v2-tier1-short-name-area-areas-area-id: "record<Branch: string, ETag: string, Name: string, OID: string, ShowOnSites: bool>"
    get-v2-tier1-short-name-branch-branches: "record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>"
    get-v2-tier1-short-name-branch-branches-branch-id: "record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>"
    company-controller-get-company: "record<CompanyName: string, CompanyRegistration: string, ETag: string, MarketingCompanyName: string, OID: string, ShortName: string>"
    get-v2-tier1-short-name-county-counties: "record<Count: int, Data: table<ETag: string, Name: string, OID: string>>"
    get-v2-tier1-short-name-county-counties-county-id: "record<ETag: string, Name: string, OID: string>"
    county-controller-get-counties-branches: "record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>"
    get-v2-tier1-short-name-diary-allocations: "record<Count: int, Data: table<AppointmentType: string, ETag: string, End: string, OID: string, Staff: string, Start: string>>"
    get-v2-tier1-short-name-diary-allocations-diary-allocation-id: "record<AppointmentType: string, ETag: string, End: string, OID: string, Staff: string, Start: string>"
    get-v2-tier1-short-name-diary-appointments: "record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, OID: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>>"
    get-v2-tier1-short-name-diary-appointments-diary-appointment-id: "record<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, OID: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>"
    get-v2-tier1-short-name-diary-appointmenttypes: "record<Count: int, Data: table<ETag: string, Name: string, OID: string, SystemType: string>>"
    get-v2-tier1-short-name-diary-appointmenttypes-diary-appointment-type-id: "record<ETag: string, Name: string, OID: string, SystemType: string>"
    lettings-controller-get-advertised: "record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>"
    lettings-controller-get-advertised-between-dates: "record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>"
    get-v2-tier1-short-name-lettings-tenancies: "record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>"
    get-v2-tier1-short-name-lettings-tenancies-tenancy-id: "record<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list<string>, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>"
    lettings-controller-get-tenancy-brochure: "record"
    get-v2-tier1-short-name-photo-photos: "record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>"
    get-v2-tier1-short-name-photo-photos-photo-id: "record<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>"
    photo-controller-get-photo-download: "record"
    get-v2-tier1-short-name-property-properties: "record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, PropertyType: string, RoomName: string, VideoURL: string>>"
    get-v2-tier1-short-name-property-properties-property-id: "record<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, PropertyType: string, RoomName: string, VideoURL: string>"
    property-controller-get-properties-facilities: "record<Count: int, Data: table<ETag: string, Name: string, OID: string>>"
    property-controller-get-properties-photos: "record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>"
    property-controller-get-properties-rooms: "record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, HeightCentimeters: int, HeightMeters: int, LengthCentimeters: int, LengthMeters: int, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, RoomFloor: string, RoomName: string, WidthCentiMeters: int, WidthMeters: int>>"
    property-controller-get-properties-tenancies: "record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>"
    property-controller-get-property-eer-download: "record"
    property-controller-get-property-eir-download: "record"
    sales-controller-get-advertised-sales: "record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>>"
    sales-controller-get-eer: "record"
    sales-controller-get-eir: "record"
    get-v2-tier1-short-name-sales-salesfeaturetypes: "record<Count: int, Data: table<ETag: string, Name: string, OID: string>>"
    get-v2-tier1-short-name-sales-salesfeaturetypes-sales-feature-type-id: "record<ETag: string, Name: string, OID: string>"
    get-v2-tier1-short-name-sales-salesinstructions: "record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>>"
    get-v2-tier1-short-name-sales-salesinstructions-sales-instruction-id: "record<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>"
    sales-controller-get-sales-instructions-features: "record<Count: int, Data: table<Comment: string, ETag: string, OID: string, Type: string>>"
    sales-controller-get-sales-instructions-floor-plans: "record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>"
    sales-controller-get-sales-instructions-photos: "record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>"
    sales-controller-get-sales-instructions-rooms: "record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, HeightCentimeters: int, HeightMeters: int, LengthCentimeters: int, LengthMeters: int, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, RoomFloor: string, RoomName: string, WidthCentiMeters: int, WidthMeters: int>>"
    get-v2-tier1-short-name-staff-staff: "record<Count: int, Data: table<ETag: string, Forename: string, GlobalReference: string, IsEnabled: bool, ManagedBy: string, Middlename: string, OID: string, Surname: string, Title: string>>"
    get-v2-tier1-short-name-staff-staff-application-staff-id: "record<ETag: string, Forename: string, GlobalReference: string, IsEnabled: bool, ManagedBy: string, Middlename: string, OID: string, Surname: string, Title: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-v2-tier1-short-name-area-areas" "get-v2-tier1-short-name-area-areas-area-id" "get-v2-tier1-short-name-branch-branches" "get-v2-tier1-short-name-branch-branches-branch-id" "company-controller-get-company" "get-v2-tier1-short-name-county-counties" "get-v2-tier1-short-name-county-counties-county-id" "county-controller-get-counties-branches" "get-v2-tier1-short-name-diary-allocations" "get-v2-tier1-short-name-diary-allocations-diary-allocation-id" "get-v2-tier1-short-name-diary-appointments" "get-v2-tier1-short-name-diary-appointments-diary-appointment-id" "get-v2-tier1-short-name-diary-appointmenttypes" "get-v2-tier1-short-name-diary-appointmenttypes-diary-appointment-type-id" "lettings-controller-get-advertised" "lettings-controller-get-advertised-between-dates" "get-v2-tier1-short-name-lettings-tenancies" "get-v2-tier1-short-name-lettings-tenancies-tenancy-id" "lettings-controller-get-tenancy-brochure" "get-v2-tier1-short-name-photo-photos" "get-v2-tier1-short-name-photo-photos-photo-id" "photo-controller-get-photo-download" "get-v2-tier1-short-name-property-properties" "get-v2-tier1-short-name-property-properties-property-id" "property-controller-get-properties-facilities" "property-controller-get-properties-photos" "property-controller-get-properties-rooms" "property-controller-get-properties-tenancies" "property-controller-get-property-eer-download" "property-controller-get-property-eir-download" "sales-controller-get-advertised-sales" "sales-controller-get-eer" "sales-controller-get-eir" "get-v2-tier1-short-name-sales-salesfeaturetypes" "get-v2-tier1-short-name-sales-salesfeaturetypes-sales-feature-type-id" "get-v2-tier1-short-name-sales-salesinstructions" "get-v2-tier1-short-name-sales-salesinstructions-sales-instruction-id" "sales-controller-get-sales-instructions-features" "sales-controller-get-sales-instructions-floor-plans" "sales-controller-get-sales-instructions-photos" "sales-controller-get-sales-instructions-rooms" "get-v2-tier1-short-name-staff-staff" "get-v2-tier1-short-name-staff-staff-application-staff-id" "commands"] | sort) } | get name | first)
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

# A collection of all the areas for a company
#
# GET /v2/tier1/{shortName}/area/areas
# Returns: record<Count: int, Data: table<Branch: string, ETag: string, Name: string, OID: string, ShowOnSites: bool>>
export def "get-v2-tier1-short-name-area-areas" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/area/areas"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific area given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/area/areas/{areaID}
# Returns: record<Branch: string, ETag: string, Name: string, OID: string, ShowOnSites: bool>
export def "get-v2-tier1-short-name-area-areas-area-id" [
  short_name: string
  area_id: string
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
    path: "/v2/tier1/{shortName}/area/areas/{areaID}"
    path_params: [{name: shortName, var: short_name}, {name: areaID, var: area_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, area_id: $area_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# All branches defined for a company
#
# GET /v2/tier1/{shortName}/branch/branches
# Returns: record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>
export def "get-v2-tier1-short-name-branch-branches" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/branch/branches"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/branch/branches/{branchID}
# Returns: record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>
export def "get-v2-tier1-short-name-branch-branches-branch-id" [
  short_name: string
  branch_id: string
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
    path: "/v2/tier1/{shortName}/branch/branches/{branchID}"
    path_params: [{name: shortName, var: short_name}, {name: branchID, var: branch_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, branch_id: $branch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Information about a specific company
#
# GET /v2/tier1/{shortName}/company
# Returns: record<CompanyName: string, CompanyRegistration: string, ETag: string, MarketingCompanyName: string, OID: string, ShortName: string>
# operationId: CompanyController_GetCompany
export def "company-controller-get-company" [
  short_name: string
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
    path: "/v2/tier1/{shortName}/company"
    path_params: [{name: shortName, var: short_name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all counties available for a company
#
# GET /v2/tier1/{shortName}/county/counties
# Returns: record<Count: int, Data: table<ETag: string, Name: string, OID: string>>
export def "get-v2-tier1-short-name-county-counties" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/county/counties"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific county given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/county/counties/{countyID}
# Returns: record<ETag: string, Name: string, OID: string>
export def "get-v2-tier1-short-name-county-counties-county-id" [
  short_name: string
  county_id: string
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
    path: "/v2/tier1/{shortName}/county/counties/{countyID}"
    path_params: [{name: shortName, var: short_name}, {name: countyID, var: county_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, county_id: $county_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of branches that manage a specific county
#
# GET /v2/tier1/{shortName}/county/counties/{countyID}/branches
# Returns: record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>
# operationId: CountyController_GetCountiesBranches
export def "county-controller-get-counties-branches" [
  short_name: string
  county_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/county/counties/{countyID}/branches"
    path_params: [{name: shortName, var: short_name}, {name: countyID, var: county_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, county_id: $county_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all diary allocations
#
# GET /v2/tier1/{shortName}/diary/allocations
# Returns: record<Count: int, Data: table<AppointmentType: string, ETag: string, End: string, OID: string, Staff: string, Start: string>>
export def "get-v2-tier1-short-name-diary-allocations" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/diary/allocations"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific diary allocation given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/diary/allocations/{diaryAllocationID}
# Returns: record<AppointmentType: string, ETag: string, End: string, OID: string, Staff: string, Start: string>
export def "get-v2-tier1-short-name-diary-allocations-diary-allocation-id" [
  short_name: string
  diary_allocation_id: string
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
    path: "/v2/tier1/{shortName}/diary/allocations/{diaryAllocationID}"
    path_params: [{name: shortName, var: short_name}, {name: diaryAllocationID, var: diary_allocation_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, diary_allocation_id: $diary_allocation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all diary appointments
#
# GET /v2/tier1/{shortName}/diary/appointments
# Returns: record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, OID: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>>
export def "get-v2-tier1-short-name-diary-appointments" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/diary/appointments"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific diary appointment given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/diary/appointments/{diaryAppointmentID}
# Returns: record<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, OID: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>
export def "get-v2-tier1-short-name-diary-appointments-diary-appointment-id" [
  short_name: string
  diary_appointment_id: string
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
    path: "/v2/tier1/{shortName}/diary/appointments/{diaryAppointmentID}"
    path_params: [{name: shortName, var: short_name}, {name: diaryAppointmentID, var: diary_appointment_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, diary_appointment_id: $diary_appointment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all diary appointment types
#
# GET /v2/tier1/{shortName}/diary/appointmenttypes
# Returns: record<Count: int, Data: table<ETag: string, Name: string, OID: string, SystemType: string>>
export def "get-v2-tier1-short-name-diary-appointmenttypes" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/diary/appointmenttypes"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific diary appointment type given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/diary/appointmenttypes/{diaryAppointmentTypeID}
# Returns: record<ETag: string, Name: string, OID: string, SystemType: string>
export def "get-v2-tier1-short-name-diary-appointmenttypes-diary-appointment-type-id" [
  short_name: string
  diary_appointment_type_id: string
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
    path: "/v2/tier1/{shortName}/diary/appointmenttypes/{diaryAppointmentTypeID}"
    path_params: [{name: shortName, var: short_name}, {name: diaryAppointmentTypeID, var: diary_appointment_type_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, diary_appointment_type_id: $diary_appointment_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search all properties available for rent given a range of search criteria.
#
# GET /v2/tier1/{shortName}/lettings/advertised
# Returns: record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>
# operationId: LettingsController_GetAdvertised
export def "lettings-controller-get-advertised" [
  short_name: string
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
  --branch-id: string # The unique ID of the Branch (required)
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
  --area-id: string # The unique ID of the Area
  --rent-minimum: float # The minimum advertised rent to search for (format: double)
  --rent-maximum: float # The maximum advertised rent to search for (format: double)
  --maximum-tenants: int # The maximum number of tenants a property can accommodate (format: int32)
  --want-shared-properties: oneof<nothing, bool> # Search for shared properties?
  --want-student-properties: oneof<nothing, bool> # Search for student properties?
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/lettings/advertised"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: branchID, var: branch_id, required: true}, {name: offset, var: offset, required: true}, {name: count, var: count, required: true}, {name: areaID, var: area_id}, {name: rentMinimum, var: rent_minimum}, {name: rentMaximum, var: rent_maximum}, {name: maximumTenants, var: maximum_tenants}, {name: wantSharedProperties, var: want_shared_properties}, {name: wantStudentProperties, var: want_student_properties}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, branch_id: $branch_id, offset: $offset, count: $count, area_id: $area_id, rent_minimum: $rent_minimum, rent_maximum: $rent_maximum, maximum_tenants: $maximum_tenants, want_shared_properties: $want_shared_properties, want_student_properties: $want_student_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search all properties available for rent given a range of search criteria and dates.
#
# GET /v2/tier1/{shortName}/lettings/advertisedbetweendates
# Returns: record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>
# operationId: LettingsController_GetAdvertisedBetweenDates
export def "lettings-controller-get-advertised-between-dates" [
  short_name: string
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
  --branch-id: string # The unique ID of the Branch (required)
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
  --range-start-date: string # The date to search from (required, format: date-time)
  --range-end-date: string # The date to search to (required, format: date-time)
  --area-id: string # The unique ID of the Area
  --rent-minimum: float # The minimum advertised rent to search for (format: double)
  --rent-maximum: float # The maximum advertised rent to search for (format: double)
  --maximum-tenants: int # The maximum number of tenants a property can accommodate (format: int32)
  --want-shared-properties: oneof<nothing, bool> # Search for shared properties?
  --want-student-properties: oneof<nothing, bool> # Search for student properties?
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/lettings/advertisedbetweendates"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: branchID, var: branch_id, required: true}, {name: offset, var: offset, required: true}, {name: count, var: count, required: true}, {name: rangeStartDate, var: range_start_date, required: true}, {name: rangeEndDate, var: range_end_date, required: true}, {name: areaID, var: area_id}, {name: rentMinimum, var: rent_minimum}, {name: rentMaximum, var: rent_maximum}, {name: maximumTenants, var: maximum_tenants}, {name: wantSharedProperties, var: want_shared_properties}, {name: wantStudentProperties, var: want_student_properties}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, branch_id: $branch_id, offset: $offset, count: $count, range_start_date: $range_start_date, range_end_date: $range_end_date, area_id: $area_id, rent_minimum: $rent_minimum, rent_maximum: $rent_maximum, maximum_tenants: $maximum_tenants, want_shared_properties: $want_shared_properties, want_student_properties: $want_student_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all the company's tenancies
#
# GET /v2/tier1/{shortName}/lettings/tenancies
# Returns: record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>
export def "get-v2-tier1-short-name-lettings-tenancies" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/lettings/tenancies"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific tenancy given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/lettings/tenancies/{tenancyID}
# Returns: record<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list<string>, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>
export def "get-v2-tier1-short-name-lettings-tenancies-tenancy-id" [
  short_name: string
  tenancy_id: string
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
    path: "/v2/tier1/{shortName}/lettings/tenancies/{tenancyID}"
    path_params: [{name: shortName, var: short_name}, {name: tenancyID, var: tenancy_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, tenancy_id: $tenancy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the brochure relating to the latest advertised rental of a property
#
# GET /v2/tier1/{shortName}/lettings/tenancies/{tenancyID}/brochure
# Returns: record
# operationId: LettingsController_GetTenancyBrochure
export def "lettings-controller-get-tenancy-brochure" [
  short_name: string
  tenancy_id: string
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
    path: "/v2/tier1/{shortName}/lettings/tenancies/{tenancyID}/brochure"
    path_params: [{name: shortName, var: short_name}, {name: tenancyID, var: tenancy_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, tenancy_id: $tenancy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all photos in the company
#
# GET /v2/tier1/{shortName}/photo/photos
# Returns: record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>
export def "get-v2-tier1-short-name-photo-photos" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/photo/photos"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific photo given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/photo/photos/{photoID}
# Returns: record<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>
export def "get-v2-tier1-short-name-photo-photos-photo-id" [
  short_name: string
  photo_id: string
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
    path: "/v2/tier1/{shortName}/photo/photos/{photoID}"
    path_params: [{name: shortName, var: short_name}, {name: photoID, var: photo_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, photo_id: $photo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the photo of a property given the property and photo ID.
#
# GET /v2/tier1/{shortName}/photos/photo/{photoID}/download
# Returns: record
# operationId: PhotoController_GetPhotoDownload
export def "photo-controller-get-photo-download" [
  short_name: string
  photo_id: string
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
  --width: int # An optional parameter specifying the image width (format: int32)
  --height: int # An optional parameter specifying the image height (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/photos/photo/{photoID}/download"
    path_params: [{name: shortName, var: short_name}, {name: photoID, var: photo_id}]
    query: [{name: width, var: width}, {name: height, var: height}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, photo_id: $photo_id, width: $width, height: $height
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all properties within a company
#
# GET /v2/tier1/{shortName}/property/properties
# Returns: record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, PropertyType: string, RoomName: string, VideoURL: string>>
export def "get-v2-tier1-short-name-property-properties" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/property/properties"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific property given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}
# Returns: record<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, PropertyType: string, RoomName: string, VideoURL: string>
export def "get-v2-tier1-short-name-property-properties-property-id" [
  short_name: string
  property_id: string
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
    path: "/v2/tier1/{shortName}/property/properties/{propertyID}"
    path_params: [{name: shortName, var: short_name}, {name: propertyID, var: property_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_id: $property_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of facilities linked to a block, property or room
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/facilities
# Returns: record<Count: int, Data: table<ETag: string, Name: string, OID: string>>
# operationId: PropertyController_GetPropertiesFacilities
export def "property-controller-get-properties-facilities" [
  short_name: string
  property_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/property/properties/{propertyID}/facilities"
    path_params: [{name: shortName, var: short_name}, {name: propertyID, var: property_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_id: $property_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection showing all the photos linked to a specific block, property or room
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/photos
# Returns: record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>
# operationId: PropertyController_GetPropertiesPhotos
export def "property-controller-get-properties-photos" [
  short_name: string
  property_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/property/properties/{propertyID}/photos"
    path_params: [{name: shortName, var: short_name}, {name: propertyID, var: property_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_id: $property_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of the rooms that belong to this property or block
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/rooms
# Returns: record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, HeightCentimeters: int, HeightMeters: int, LengthCentimeters: int, LengthMeters: int, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, RoomFloor: string, RoomName: string, WidthCentiMeters: int, WidthMeters: int>>
# operationId: PropertyController_GetPropertiesRooms
export def "property-controller-get-properties-rooms" [
  short_name: string
  property_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/property/properties/{propertyID}/rooms"
    path_params: [{name: shortName, var: short_name}, {name: propertyID, var: property_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_id: $property_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all tenancies associated with this block, property or room
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/tenancies
# Returns: record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>>
# operationId: PropertyController_GetPropertiesTenancies
export def "property-controller-get-properties-tenancies" [
  short_name: string
  property_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/property/properties/{propertyID}/tenancies"
    path_params: [{name: shortName, var: short_name}, {name: propertyID, var: property_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_id: $property_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the energy efficiency report (EER) graph for a property
#
# GET /v2/tier1/{shortName}/property/structures/{propertyStructureID}/reports/eer
# Returns: record
# operationId: PropertyController_GetPropertyEERDownload
export def "property-controller-get-property-eer-download" [
  short_name: string
  property_structure_id: string
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
    path: "/v2/tier1/{shortName}/property/structures/{propertyStructureID}/reports/eer"
    path_params: [{name: shortName, var: short_name}, {name: propertyStructureID, var: property_structure_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_structure_id: $property_structure_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the environmental impact report (EIR) graph for a property
#
# GET /v2/tier1/{shortName}/property/structures/{propertyStructureID}/reports/eir
# Returns: record
# operationId: PropertyController_GetPropertyEIRDownload
export def "property-controller-get-property-eir-download" [
  short_name: string
  property_structure_id: string
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
    path: "/v2/tier1/{shortName}/property/structures/{propertyStructureID}/reports/eir"
    path_params: [{name: shortName, var: short_name}, {name: propertyStructureID, var: property_structure_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_structure_id: $property_structure_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search all sales properties available given a range of search criteria
#
# GET /v2/tier1/{shortName}/sales/advertisedsales
# Returns: record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>>
# operationId: SalesController_GetAdvertisedSales
export def "sales-controller-get-advertised-sales" [
  short_name: string
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
  --branch-id: string # The unique ID of the Branch (required)
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
  --only-developement: oneof<nothing, bool> # Show only development properties? (required)
  --only-investements: oneof<nothing, bool> # Show only investment properties? (required)
  --minimum-price: float # The minimum price to search for (format: double)
  --maximum-price: float # The maximum price to search for (format: double)
  --minimum-beds: int # The minimum beds to search for (format: int32)
  --minimum-bathrooms: int # The minimum bathrooms to search for (format: int32)
  --minimum-ensuites: int # The minimum ensuite bathrooms to search for (format: int32)
  --minimum-toilets: int # The minimum toilets to search for (format: int32)
  --minimum-reception: int # The minimum reception rooms to search for (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/advertisedsales"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: branchID, var: branch_id, required: true}, {name: offset, var: offset, required: true}, {name: count, var: count, required: true}, {name: onlyDevelopement, var: only_developement, required: true}, {name: onlyInvestements, var: only_investements, required: true}, {name: minimumPrice, var: minimum_price}, {name: maximumPrice, var: maximum_price}, {name: minimumBeds, var: minimum_beds}, {name: minimumBathrooms, var: minimum_bathrooms}, {name: minimumEnsuites, var: minimum_ensuites}, {name: minimumToilets, var: minimum_toilets}, {name: minimumReception, var: minimum_reception}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, branch_id: $branch_id, offset: $offset, count: $count, only_developement: $only_developement, only_investements: $only_investements, minimum_price: $minimum_price, maximum_price: $maximum_price, minimum_beds: $minimum_beds, minimum_bathrooms: $minimum_bathrooms, minimum_ensuites: $minimum_ensuites, minimum_toilets: $minimum_toilets, minimum_reception: $minimum_reception
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the energy efficiency report (EER) graph for a sales instruction
#
# GET /v2/tier1/{shortName}/sales/reports/eer/{salesInstructionID}
# Returns: record
# operationId: SalesController_GetEER
export def "sales-controller-get-eer" [
  short_name: string
  sales_instruction_id: string
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
    path: "/v2/tier1/{shortName}/sales/reports/eer/{salesInstructionID}"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the energy efficiency report (EIR) graph for a sales instruction
#
# GET /v2/tier1/{shortName}/sales/reports/eir/{salesInstructionID}
# Returns: record
# operationId: SalesController_GetEIR
export def "sales-controller-get-eir" [
  short_name: string
  sales_instruction_id: string
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
    path: "/v2/tier1/{shortName}/sales/reports/eir/{salesInstructionID}"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all sales feature types linked to a company
#
# GET /v2/tier1/{shortName}/sales/salesfeaturetypes
# Returns: record<Count: int, Data: table<ETag: string, Name: string, OID: string>>
export def "get-v2-tier1-short-name-sales-salesfeaturetypes" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/salesfeaturetypes"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific sales feature type given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/sales/salesfeaturetypes/{salesFeatureTypeID}
# Returns: record<ETag: string, Name: string, OID: string>
export def "get-v2-tier1-short-name-sales-salesfeaturetypes-sales-feature-type-id" [
  short_name: string
  sales_feature_type_id: string
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
    path: "/v2/tier1/{shortName}/sales/salesfeaturetypes/{salesFeatureTypeID}"
    path_params: [{name: shortName, var: short_name}, {name: salesFeatureTypeID, var: sales_feature_type_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_feature_type_id: $sales_feature_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all sales instructions linked to a company
#
# GET /v2/tier1/{shortName}/sales/salesinstructions
# Returns: record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>>
export def "get-v2-tier1-short-name-sales-salesinstructions" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/salesinstructions"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific sales instruction given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}
# Returns: record<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>
export def "get-v2-tier1-short-name-sales-salesinstructions-sales-instruction-id" [
  short_name: string
  sales_instruction_id: string
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
    path: "/v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all features linked to a sales instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/features
# Returns: record<Count: int, Data: table<Comment: string, ETag: string, OID: string, Type: string>>
# operationId: SalesController_GetSalesInstructionsFeatures
export def "sales-controller-get-sales-instructions-features" [
  short_name: string
  sales_instruction_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/features"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of floor plans linked to an instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/floorplans
# Returns: record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>
# operationId: SalesController_GetSalesInstructionsFloorPlans
export def "sales-controller-get-sales-instructions-floor-plans" [
  short_name: string
  sales_instruction_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/floorplans"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of photos linked to an instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/photos
# Returns: record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>>
# operationId: SalesController_GetSalesInstructionsPhotos
export def "sales-controller-get-sales-instructions-photos" [
  short_name: string
  sales_instruction_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/photos"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of rooms linked to an instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/rooms
# Returns: record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, HeightCentimeters: int, HeightMeters: int, LengthCentimeters: int, LengthMeters: int, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, RoomFloor: string, RoomName: string, WidthCentiMeters: int, WidthMeters: int>>
# operationId: SalesController_GetSalesInstructionsRooms
export def "sales-controller-get-sales-instructions-rooms" [
  short_name: string
  sales_instruction_id: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/rooms"
    path_params: [{name: shortName, var: short_name}, {name: salesInstructionID, var: sales_instruction_id}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, sales_instruction_id: $sales_instruction_id, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection of all the staff members linked to a specific company
#
# GET /v2/tier1/{shortName}/staff/staff
# Returns: record<Count: int, Data: table<ETag: string, Forename: string, GlobalReference: string, IsEnabled: bool, ManagedBy: string, Middlename: string, OID: string, Surname: string, Title: string>>
export def "get-v2-tier1-short-name-staff-staff" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tier1/{shortName}/staff/staff"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific application staff given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/staff/staff/{applicationStaffID}
# Returns: record<ETag: string, Forename: string, GlobalReference: string, IsEnabled: bool, ManagedBy: string, Middlename: string, OID: string, Surname: string, Title: string>
export def "get-v2-tier1-short-name-staff-staff-application-staff-id" [
  short_name: string
  application_staff_id: string
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
    path: "/v2/tier1/{shortName}/staff/staff/{applicationStaffID}"
    path_params: [{name: shortName, var: short_name}, {name: applicationStaffID, var: application_staff_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, application_staff_id: $application_staff_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
