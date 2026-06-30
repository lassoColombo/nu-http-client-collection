# Auto-generated client for Brain Web API v2.23.2+0.gfbc3926.dirty
# Source: https://api.apis.guru/v2/specs/intellifi.nl/2.23.2+0.gfbc3926.dirty/openapi.json
# Auth: --token flag or $env.BRAIN_WEB_API_TOKEN

const BASE_URL = "https://brain.intellifi.cloud/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BRAIN_WEB_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "cookie-brain.sid" => { {scheme: $scheme, headers: {Cookie: $"(encode-path-segment "brain.sid")=(encode-path-segment $token_val)"}, query: "", location: "cookie"} }
    "x-api-key" => { {scheme: $scheme, headers: {X-Api-Key: $token_val}, query: "", location: "header"} }
    "query-key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "key")=(encode-path-segment $token_val)", location: "query"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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

def base-url-completer [] { ["https://brain.intellifi.cloud/api" "http://brain.intellifi.cloud/api" "https://brain.intellifi.nl/api"] }
def auth-scheme-completer [] { ["cookie-brain.sid" "x-api-key" "query-key"] }

# Completers for enum parameters
def topic-resource-type-completer [] { ["blobs" "items" "keys" "kvpairs" "locations" "presences" "services" "spots" "subscriptions" "users"] }
def topic-action-completer [] { ["connection-rssi-changed" "created" "deleted" "disappeared" "updated"] }
def protocol-completer [] { ["altbeacon" "eddystone" "epcgen2" "generic" "ibeacon" "nanoble" "nfc" "uniwear"] }
def technology-completer [] { ["bluetooth" "optical" "rfid"] }
def type-completer [] { ["barcode" "bluetitan" "gbtag" "relay" "smarttag" "tag"] }
def type-completer-1 [] { ["allow" "debounce" "disallow" "disappeared"] }
def proximity-completer [] { ["far" "immediate" "near"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authinfo get" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Authentication information
#
# GET /authinfo
# operationId: getAuthinfo
export def "authinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_key_id: string, auth_method: string, authenticated: bool, permissions: record<mutate: bool>, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authinfo" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all binary large objects (blob)
#
# GET /blobs
# operationId: getBlobs
export def "blobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --hash: string # Filter based on the hash of the blob.
  --blob-key: string # Filter based on the unique blob_key
  --content-type: string # Filter based on the content type of the blob.
  --filename: string # Filter based on the filename of the blob.
  --time-last-accessed: string # Filter based on the last time the blob was accessed
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<blob_key: string, content_type: string, download_url: string, filename: string, hash: string, id: string, time_created: string, time_last_accessed: string, time_updated: string, upload_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "hash" $hash "scalar") (serialize-qp "blob_key" $blob_key "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "time_last_accessed" $time_last_accessed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blobs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "hash": $hash, "blob_key": $blob_key, "content_type": $content_type, "filename": $filename, "time_last_accessed": $time_last_accessed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create binary large object (blob) metadata
#
# POST /blobs
# operationId: addBlob
export def "blobs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blob-key: string # Unique key to the blob (e.g. foobar)
  --content-type: string # Media type of the resource. Automatically detected when not given in a POST. (e.g. image/png)
  --filename: string # Filename of the blob (e.g. Foo bar)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blobs" $auth.query)
  let req_body = {"blob_key": $blob_key, "content_type": $content_type, "filename": $filename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete binary large object (blob)
#
# DELETE /blobs/{id}
# operationId: deleteBlob
export def "blobs delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/blobs/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get binary large object (blob)
#
# GET /blobs/{id}
# operationId: getBlobMetadataById
export def "blobs get-metadata" [
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
]: nothing -> record<blob_key: string, content_type: string, download_url: string, filename: string, hash: string, id: string, time_created: string, time_last_accessed: string, time_updated: string, upload_url: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/blobs/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Download a binary large object (blob)
#
# GET /blobs/{id}/download/{filename}
# operationId: getBlobById
export def "blobs-download get" [
  id: string
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), filename: (encode-path-segment $filename)} | format pattern "/blobs/{id}/download/{filename}") $auth.query)
  let accept_val = "image/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create binary large object (blob)
#
# POST /blobs/{id}/upload
# operationId: uploadBlobById
export def "blobs-upload upload" [
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
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/blobs/{id}/upload") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Get all events
#
# GET /events
# operationId: getEvents
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --topic-resource-type: string@topic-resource-type-completer # Filter on the topic resource type (e.g. items)
  --topic-action: string@topic-action-completer # Filter on the topic action (e.g. created)
  --topic-resource: string # Filter on the topic resource id (e.g. 5b7d6cbd7503c445552a1664)
  --time-event: string # Filter on the time the event was generated on the device. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-expire: string # Filter on the time the event will expire. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "topic.resource_type" $topic_resource_type "scalar") (serialize-qp "topic.action" $topic_action "scalar") (serialize-qp "topic.resource" $topic_resource "scalar") (serialize-qp "time_event" $time_event "scalar") (serialize-qp "time_expire" $time_expire "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "topic.resource_type": $topic_resource_type, "topic.action": $topic_action, "topic.resource": $topic_resource, "time_event": $time_event, "time_expire": $time_expire} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get event
#
# GET /events/{id}
# operationId: getEventById
export def "events get" [
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
]: nothing -> record<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record<action: string, arguments: any, resource_id: string, resource_type: string, resource_url: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all items
#
# GET /items
# operationId: getItems
export def "items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --after-code: string # Limits directly on `code_hex`. Marks the start of a range, optionally use `before_code` to set the end. Result output excludes the given `code_hex` value. (e.g. e20000000000000000000000)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before-code: string # Limits directly on `code_hex`. Marks the end of a range, optionally use `after_code` to set the start. Result output excludes the given `code_hex` value. (e.g. e20000000000000000001fff)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --from-code: string # Limits on `code_hex`. Marks the start of a range, optionally use `until_code` to set the end. Result output includes the given `code_hex` value. (e.g. e20000000000000000000000)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --until-code: string # Limits on `code_hex`. Marks the end of a range, optionally use `from_code` to set the start. Result output includes the given `code_hex` value. (e.g. e20000000000000000001ffff)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --code-hex: string # Filter based on the hexadecimal string representation of the item. Supports wildcards: `*`. (e.g. deadbeef)
  --is-present: oneof<nothing, bool> # Only show items which are present of not. (e.g. true)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --location: string # Filter based on the location (e.g. 5b7d6cbd7503c445552a1664)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --move-count: int # Filter based on move count (e.g. 4523)
  --protocol: string@protocol-completer # Filter based on the detected protocol of an item. (e.g. epcgen2)
  --sets: string # Filter based on the set the resource is in. (e.g. 5b7d6cbd7503c445552a1664)
  --technology: string@technology-completer # Filter based on the detected technology of an item. (e.g. rfid)
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
  --time-last-present: string # Filter based on the time last present (e.g. 2018-09-03T10:23:46.596Z)
  --time-moved: string # Filter based on time last moved (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --type: string@type-completer # Filter based on the type of an item. (e.g. tag)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record, id: string, is_present: bool, move_count: int, protocol: string, sets: list, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "after_code" $after_code "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "before_code" $before_code "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "from_code" $from_code "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "until_code" $until_code "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "code_hex" $code_hex "scalar") (serialize-qp "is_present" $is_present "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "move_count" $move_count "scalar") (serialize-qp "protocol" $protocol "scalar") (serialize-qp "sets" $sets "scalar") (serialize-qp "technology" $technology "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "time_last_present" $time_last_present "scalar") (serialize-qp "time_moved" $time_moved "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/items" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "after_code": $after_code, "before": $before, "before_id": $before_id, "before_code": $before_code, "from": $qp_from, "from_id": $from_id, "from_code": $from_code, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "until_code": $until_code, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "code_hex": $code_hex, "is_present": $is_present, "label": $label, "location": $location, "metadata": $metadata, "move_count": $move_count, "protocol": $protocol, "sets": $sets, "technology": $technology, "text": $text, "time_last_present": $time_last_present, "time_moved": $time_moved, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create item
#
# POST /items
# operationId: addItem
export def "items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --location-request: string # Instruction for the location engine to forcibly localize the item at the specified location id as soon as possible. Cleared automatically. (e.g. 5b7d6cbd7503c445552a1664)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
  --code-hex: string # String representation of the unique code that this item transmits. By default this is a hexadecimal representation. This number could be so long (> 40 bytes!) that a decimal representation would be useless to generate. (e.g. deadbeef)
  --protocol: string@protocol-completer # Type of protocol that was used to decode this item. (e.g. epcgen2)
  --technology: string@technology-completer # Type of technology that was used to detect this item. (e.g. rfid)
  --type: string@type-completer # Type of item. (e.g. tag)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/items" $auth.query)
  let req_body = {"config_request": $config_request, "custom": $custom, "label": $label, "location_request": $location_request, "metadata": $metadata, "code_hex": $code_hex, "protocol": $protocol, "technology": $technology, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete item
#
# DELETE /items/{id}
# operationId: deleteItem
export def "items delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get item
#
# GET /items/{id}
# operationId: getItemById
export def "items get" [
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
]: nothing -> record<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_present: bool, move_count: int, protocol: string, sets: list<string>, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing item
#
# PUT /items/{id}
# operationId: updateItem
export def "items update" [
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
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --location-request: string # Instruction for the location engine to forcibly localize the item at the specified location id as soon as possible. Cleared automatically. (e.g. 5b7d6cbd7503c445552a1664)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}") $auth.query)
  let req_body = {"config_request": $config_request, "custom": $custom, "label": $label, "location_request": $location_request, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all keys
#
# GET /keys
# operationId: getKeys
export def "keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --secret: string # Filter on the secret token.
  --label: string # Filter on the label.
  --is-read-only: oneof<nothing, bool> # Filter on read only status.
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, is_read_only: bool, label: string, secret: string, time_created: string, time_updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "secret" $secret "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "is_read_only" $is_read_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keys" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "secret": $secret, "label": $label, "is_read_only": $is_read_only} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create key
#
# POST /keys
# operationId: addKey
export def "keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-read-only: oneof<nothing, bool> # Whether or not this key can only read and not write.
  --label: string # Custom label for this API key.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys" $auth.query)
  let req_body = {"is_read_only": $is_read_only, "label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete key
#
# DELETE /keys/{id}
# operationId: deleteKey
export def "keys delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/keys/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get key
#
# GET /keys/{id}
# operationId: getKeyById
export def "keys get" [
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
]: nothing -> record<id: string, is_read_only: bool, label: string, secret: string, time_created: string, time_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/keys/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing key
#
# PUT /keys/{id}
# operationId: updateKey
export def "keys update" [
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
  --is-read-only: oneof<nothing, bool> # Whether or not this key can only read and not write.
  --label: string # Custom label for this API key.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/keys/{id}") $auth.query)
  let req_body = {"is_read_only": $is_read_only, "label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all key-value pairs
#
# GET /kvpairs
# operationId: getKvPairs
export def "kvpairs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --kv-key: string # Filter on the key-value pair key value.
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<kv_value: any, id: string, kv_key: string, time_created: string, time_updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "kv_key" $kv_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kvpairs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "kv_key": $kv_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create key-value pair
#
# POST /kvpairs
# operationId: addKvPairs
export def "kvpairs create-kv-pairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kv-value: any # The value of the key value pair. (nullable, e.g. all the bars)
  --kv-key: string # Unique identifier for the value. (e.g. foo)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kvpairs" $auth.query)
  let req_body = {"kv_value": $kv_value, "kv_key": $kv_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete key-value pair
#
# DELETE /kvpairs/{id}
# operationId: deleteKvPair
export def "kvpairs delete-kv-pair" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kvpairs/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get key-value pair
#
# GET /kvpairs/{id}
# operationId: getKvPairsById
export def "kvpairs get-kv-pairs" [
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
]: nothing -> record<kv_value: any, id: string, kv_key: string, time_created: string, time_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kvpairs/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing Key-value pair
#
# PUT /kvpairs/{id}
# operationId: updateKvPair
export def "kvpairs update-kv-pair" [
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
  --kv-value: any # The value of the key value pair. (nullable, e.g. all the bars)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/kvpairs/{id}") $auth.query)
  let req_body = {"kv_value": $kv_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all location rules
#
# GET /locationrules
# operationId: getLocationRules
export def "locationrules get-location-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --type: string@type-completer-1 # Filter based on the type of location rule.
  --enabled: oneof<nothing, bool> # Filter based on the `enabled` property. (e.g. true)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<conditions: any, enabled: bool, id: string, label: string, parameters: record, time_created: string, time_updated: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locationrules" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "label": $label, "type": $type, "enabled": $enabled} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create location rule
#
# POST /locationrules
# operationId: addLocationRule
# --conditions shape: {from_location?: string, to_location?: string}
export def "locationrules create-location-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: record # Scope of this rule, e.g. moves at or away from a specific location or towards a specific location. The `from_location` is mandatory. The `to_location` is either mandatory, optional or not allowed depending on rule type. — shape: {from_location?: string, to_location?: string}
  --enabled: oneof<nothing, bool> # Whether this rule should be in effect (`true`) or on hold (`false`). (e.g. true)
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --parameters: record # Parameters for this rule; depends on the rule type. Refer to the rule type specification for details.
  --type: string@type-completer-1 # The type of location rule to be applied. Allow: items at `conditions.from_location` can only move to `conditions.to_location` and locations allowed in other `allow` rules (destination whitelist). Disallow: items at `conditions.from_location` cannot be moved to `conditions.to_location` and locations disallowed in other `disallow` rules (destination blacklist). Disappeared: items disappearing at `conditions.from_location` will be moved to `parameters.location` after `parameters.time_s` seconds. Debounce: items moves from `conditions.from_location` (and optionally to `conditions.to_location`) will be debounced with a period of `parameters.time_s` seconds, for a maximum of `parameters.max_periods` periods.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locationrules" $auth.query)
  let req_body = {"conditions": $conditions, "enabled": $enabled, "label": $label, "parameters": $parameters, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete location rule
#
# DELETE /locationrules/{id}
# operationId: deleteLocationRule
export def "locationrules delete-location-rule" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locationrules/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get location rule
#
# GET /locationrules/{id}
# operationId: getLocationRuleById
export def "locationrules get-location-rule" [
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
]: nothing -> record<conditions: any, enabled: bool, id: string, label: string, parameters: record, time_created: string, time_updated: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locationrules/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing location rule
#
# PUT /locationrules/{id}
# operationId: updateLocationRule
# --conditions shape: {from_location?: string, to_location?: string}
export def "locationrules update-location-rule" [
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
  --conditions: record # Scope of this rule, e.g. moves at or away from a specific location or towards a specific location. The `from_location` is mandatory. The `to_location` is either mandatory, optional or not allowed depending on rule type. — shape: {from_location?: string, to_location?: string}
  --enabled: oneof<nothing, bool> # Whether this rule should be in effect (`true`) or on hold (`false`). (e.g. true)
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --parameters: record # Parameters for this rule; depends on the rule type. Refer to the rule type specification for details.
  --type: string@type-completer-1 # The type of location rule to be applied. Allow: items at `conditions.from_location` can only move to `conditions.to_location` and locations allowed in other `allow` rules (destination whitelist). Disallow: items at `conditions.from_location` cannot be moved to `conditions.to_location` and locations disallowed in other `disallow` rules (destination blacklist). Disappeared: items disappearing at `conditions.from_location` will be moved to `parameters.location` after `parameters.time_s` seconds. Debounce: items moves from `conditions.from_location` (and optionally to `conditions.to_location`) will be debounced with a period of `parameters.time_s` seconds, for a maximum of `parameters.max_periods` periods.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locationrules/{id}") $auth.query)
  let req_body = {"conditions": $conditions, "enabled": $enabled, "label": $label, "parameters": $parameters, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all locations
#
# GET /locations
# operationId: getLocations
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "label": $label, "metadata": $metadata, "text": $text} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create location
#
# POST /locations
# operationId: addLocation
export def "locations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locations" $auth.query)
  let req_body = {"custom": $custom, "label": $label, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete location
#
# DELETE /locations/{id}
# operationId: deleteLocation
export def "locations delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get location
#
# GET /locations/{id}
# operationId: getLocationById
export def "locations get" [
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
]: nothing -> record<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing location
#
# PUT /locations/{id}
# operationId: updateLocation
export def "locations update" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/locations/{id}") $auth.query)
  let req_body = {"custom": $custom, "label": $label, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all presences
#
# GET /presences
# operationId: getPresences
export def "presences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --item: string # Filter based on the item (e.g. 5b7d6cbd7503c445552a1664)
  --location: string # Filter based on the location (e.g. 5b7d6cbd7503c445552a1664)
  --proximity: string@proximity-completer # Filter based on the proximity. (e.g. immediate)
  --technology: string@technology-completer # Filter based on the detected technology of an item. (e.g. rfid)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, item: record, item_id: string, item_url: string, location: record, location_id: string, location_url: string, proximity: string, technology: string, time_created: string, time_updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "item" $item "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "proximity" $proximity "scalar") (serialize-qp "technology" $technology "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/presences" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "item": $item, "location": $location, "proximity": $proximity, "technology": $technology} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get presence
#
# GET /presences/{id}
# operationId: getPresenceById
export def "presences get" [
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
]: nothing -> record<id: string, item: record<config_request: record, custom: any, label: string, location_request: string, metadata: record, code_hex: string, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_present: bool, move_count: int, protocol: string, sets: list<string>, technology: string, time_created: string, time_last_present: string, time_moved: string, time_updated: string, type: string, url: string>, item_id: string, item_url: string, location: record<custom: any, id: string, label: string, metadata: record, time_created: string, time_updated: string, url: string>, location_id: string, location_url: string, proximity: string, technology: string, time_created: string, time_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/presences/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all services
#
# GET /services
# operationId: getServices
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --name: string # Filter based on the name of the resource. Supports wildcards: `*` (e.g. Foo Bar)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<boot_count: int, config: record, config_request: record, id: string, name: string, restart_request: bool, time_created: string, time_updated: string, url: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get service
#
# GET /services/{id}
# operationId: getServiceById
export def "services get" [
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
]: nothing -> record<boot_count: int, config: record, config_request: record, id: string, name: string, restart_request: bool, time_created: string, time_updated: string, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/services/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing service
#
# PUT /services/{id}
# operationId: updateService
export def "services update" [
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
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --restart-request: oneof<nothing, bool> # Set this to `true` to send a reset request for the specific resource. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/services/{id}") $auth.query)
  let req_body = {"config_request": $config_request, "restart_request": $restart_request} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all item lists
#
# GET /sets/itemlists
# operationId: getItemLists
export def "sets-itemlists get-item-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
  --total: int # Filter based on the total amount of items in the list (e.g. 2)
  --sha1: string # The sha1 checksum of the list. This will change when the list is mutated. (e.g. 92cfceb39d57d914ed8b14d0e37643de0797ae56)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, list: string, metadata: record, sha1: string, time_created: string, time_updated: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "sha1" $sha1 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sets/itemlists" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "label": $label, "metadata": $metadata, "text": $text, "total": $total, "sha1": $sha1} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create item list
#
# POST /sets/itemlists
# operationId: addItemList
export def "sets-itemlists create-item-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sets/itemlists" $auth.query)
  let req_body = {"custom": $custom, "label": $label, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete item list
#
# DELETE /sets/itemlists/{id}
# operationId: deleteItemSet
export def "sets-itemlists delete-item" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/itemlists/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get item list
#
# GET /sets/itemlists/{id}
# operationId: getItemListById
export def "sets-itemlists get-item-list" [
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
]: nothing -> record<custom: any, id: string, label: string, list: string, metadata: record, sha1: string, time_created: string, time_updated: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/itemlists/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing item list
#
# PUT /sets/itemlists/{id}
# operationId: updateItemList
export def "sets-itemlists update-item-list" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/itemlists/{id}") $auth.query)
  let req_body = {"custom": $custom, "label": $label, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get item ids for this list
#
# GET /sets/itemlists/{id}/ids
# operationId: getItemListIdsById
export def "sets-itemlists-ids get-item-list" [
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
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/itemlists/{id}/ids") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add items to an existing list
#
# POST /sets/itemlists/{id}/ids
# operationId: addItemIdsList
export def "sets-itemlists-ids create-item-list" [
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
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/itemlists/{id}/ids") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete item from list
#
# DELETE /sets/itemlists/{id}/ids/{itemId}
# operationId: deleteItemIdFromItemList
export def "sets-itemlists-ids delete-item-from-item-list" [
  id: string
  item_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), item_id: (encode-path-segment $item_id)} | format pattern "/sets/itemlists/{id}/ids/{item_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get all spot lists
#
# GET /sets/spotlists
# operationId: getSpotLists
export def "sets-spotlists get-spot-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --label: string # Filter based on the label value. Supports wildcards: `*` (e.g. Foo Bar)
  --metadata: string # Filter based on metadata. Does a partial match on any value in the metadata object. It is also possible to do an exact/wildcard match on specific properties, e.g. `metadata.foo=bar`
  --text: string # Filter based on a full text search. Searched properties depend on the resource type. Matches on any of the given words. Supports quote (exact words) and minus (exclude) operators. (e.g. penguin)
  --total: int # Filter based on the total amount of spots in the list (e.g. 2)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, id: string, label: string, list: string, metadata: record, time_created: string, time_updated: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sets/spotlists" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "label": $label, "metadata": $metadata, "text": $text, "total": $total} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create spot list
#
# POST /sets/spotlists
# operationId: addSpotList
export def "sets-spotlists create-spot-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sets/spotlists" $auth.query)
  let req_body = {"custom": $custom, "label": $label, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete spot list
#
# DELETE /sets/spotlists/{id}
# operationId: deleteSpotList
export def "sets-spotlists delete-spot-list" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/spotlists/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Info for a specific spot list
#
# GET /sets/spotlists/{id}
# operationId: getSpotListById
export def "sets-spotlists get-spot-list" [
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
]: nothing -> record<custom: any, id: string, label: string, list: string, metadata: record, time_created: string, time_updated: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/spotlists/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing spot list
#
# PUT /sets/spotlists/{id}
# operationId: updateSpotList
export def "sets-spotlists update-spot-list" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --label: string # A name or a label for this resource. This is used in the user interface, may be empty. (e.g. Foo Bar)
  --metadata: record # Object of searchable metadata for this resource. Can be freely used to store metadata properties. (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/spotlists/{id}") $auth.query)
  let req_body = {"custom": $custom, "label": $label, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get spot ids for this list
#
# GET /sets/spotlists/{id}/ids
# operationId: getSpotListIdsById
export def "sets-spotlists-ids get-spot-list" [
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
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/spotlists/{id}/ids") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add spots to an existing list
#
# POST /sets/spotlists/{id}/ids
# operationId: addItemIdsSpotList
export def "sets-spotlists-ids create-item-spot-list" [
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
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sets/spotlists/{id}/ids") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete spot from list
#
# DELETE /sets/spotlists/{id}/ids/{itemId}
# operationId: deleteItemIdFromSpotList
export def "sets-spotlists-ids delete-item-from-spot-list" [
  id: string
  item_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), item_id: (encode-path-segment $item_id)} | format pattern "/sets/spotlists/{id}/ids/{item_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get all spots
#
# GET /spots
# operationId: getSpots
export def "spots list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --is-online: oneof<nothing, bool> # Filter based on the online status. (e.g. true)
  --request-counter: int # Filter based on the amount of request made (e.g. 73807)
  --serial-number: int # Filter based on the serial number. (e.g. 1337)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<antenna_report_locations: list, config: record, config_request: record, geo_coords: record, id: string, is_online: bool, request_counter: int, senses: record, senses_request: record, serial_number: int, status: any, time_created: string, time_updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "is_online" $is_online "scalar") (serialize-qp "request_counter" $request_counter "scalar") (serialize-qp "serial_number" $serial_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spots" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "is_online": $is_online, "request_counter": $request_counter, "serial_number": $serial_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get spot
#
# GET /spots/{id}
# operationId: getSpotById
export def "spots get" [
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
]: nothing -> record<antenna_report_locations: table<antenna_number: int, report_location: record, report_location_id: string, report_location_url: string>, config: record, config_request: record, geo_coords: record<lat: float, lng: float, time_updated: string>, id: string, is_online: bool, request_counter: int, senses: record, senses_request: record, serial_number: int, status: any, time_created: string, time_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing spot
#
# PUT /spots/{id}
# operationId: updateSpot
# --antenna_report_locations item shape: {antenna_number?: int}
# --geo_coords shape: {lat?: float, lng?: float}
export def "spots update" [
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
  --antenna-report-locations: list # You may configure this field to an object which couples individual antenna ports to locations. — item shape: {antenna_number?: int}
  --config-request: record # Object containing the new configuration. This will be applied automatically when the values are valid. (e.g. {foo: bar})
  --geo-coords: record # Last known geolocation estimate of this object. Not guaranteed to be included in response. — shape: {lat?: float, lng?: float}
  --senses-request: record # Object containing the new senses configuration. See [Sense & Control](https://intellifi.zendesk.com/hc/en-us/sections/360001568254) documentation for more information. (e.g. {foo: bar})
  --report-location: string # Unique identifier for resource. (e.g. 5b7d6cbd7503c445552a1664)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}") $auth.query)
  let req_body = {"antenna_report_locations": $antenna_report_locations, "config_request": $config_request, "geo_coords": $geo_coords, "senses_request": $senses_request, "report_location": $report_location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get spotsets
#
# GET /spots/{id}/sets
# operationId: getSpotSetsById
export def "spots-sets list" [
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
]: nothing -> record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/sets") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create spotset
#
# POST /spots/{id}/sets
# operationId: addSpotSet
export def "spots-sets create" [
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
  --setid: int # Spot set unique identifier. Must be unique within a single device
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/sets") $auth.query)
  let req_body = {"setid": $setid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get spotset
#
# GET /spots/{id}/sets/{setId}
# operationId: getSpotSetById
export def "spots-sets get" [
  id: string
  set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($set_id | is-empty) { error make --unspanned { msg: "path parameter 'setId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), set_id: (encode-path-segment $set_id)} | format pattern "/spots/{id}/sets/{set_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing spotset
#
# PUT /spots/{id}/sets/{setId}
# operationId: updateSpotSet
export def "spots-sets update" [
  id: string
  set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # Request to delete a set. Remove request needs to be synchronized to the device, so it may take some time before the resource is being removed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($set_id | is-empty) { error make --unspanned { msg: "path parameter 'setId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), set_id: (encode-path-segment $set_id)} | format pattern "/spots/{id}/sets/{set_id}") $auth.query)
  let req_body = {"delete": $delete} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get spotsets
#
# GET /spotsets
export def "spotsets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spotsets" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create spotset
#
# POST /spotsets
export def "spotsets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --setid: int # Spot set unique identifier. Must be unique within a single device
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spotsets" $auth.query)
  let req_body = {"setid": $setid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get spotset
#
# GET /spotsets/{id}
export def "spotsets get" [
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
]: nothing -> record<created_by: string, id: string, setid: int, spot_id: string, time_created: string, time_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spotsets/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing spotset
#
# PUT /spotsets/{id}
export def "spotsets update" [
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
  --delete: oneof<nothing, bool> # Request to delete a set. Remove request needs to be synchronized to the device, so it may take some time before the resource is being removed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spotsets/{id}") $auth.query)
  let req_body = {"delete": $delete} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all subscriptions
#
# GET /subscriptions
# operationId: getSubscriptions
export def "subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --topic-filter: string # Filter on the topic filter. Make sure to use [percent-encoding](https://en.wikipedia.org/wiki/Percent-encoding) in the query parameter.
  --description: string # Filter based on the description.
  --database-hold-time-h: int # Filter based on the number of hours events are retained in the database.
  --populate-events: oneof<nothing, bool> # Filter based on subscriptions that populate the events
  --verify-target-certificate: oneof<nothing, bool> # Filter on the verification of the target certificate.
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<custom: any, database_hold_time_h: int, description: string, events_url: string, id: string, populate_events: bool, target_delivery_last_failure: record, target_delivery_status: record, target_retry: bool, target_url: string, time_created: string, time_updated: string, topic_filter: string, url: string, verify_target_certificate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "topic_filter" $topic_filter "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "database_hold_time_h" $database_hold_time_h "scalar") (serialize-qp "populate_events" $populate_events "scalar") (serialize-qp "verify_target_certificate" $verify_target_certificate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "topic_filter": $topic_filter, "description": $description, "database_hold_time_h": $database_hold_time_h, "populate_events": $populate_events, "verify_target_certificate": $verify_target_certificate} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create subscription
#
# POST /subscriptions
# operationId: addSubscription
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --database-hold-time-h: int # The number of hours this event is retained in the database. *Only use larger numbers if you know what you are doing.* A couple of hours is enough for most use cases. (e.g. 2)
  --description: string # Additional field to add some notes about this subscription. (nullable, e.g. Item events)
  --populate-events: oneof<nothing, bool> # If set to `true`, resource references in an event (e.g. the location an item moved to) are resolved and populated with data instead of giving just an ID.
  --target-retry: oneof<nothing, bool> # Set to `true` if you want our server to retry if `target_url` is not giving back a `2xx` success code.
  --target-url: string # Url to an external service that all applicable events are pushed to (webhook). Configure to `null` if you don't wish to use this (default).
  --topic-filter: string # MQTT filter that is applied to all events. Allows you to select and filter events. See [Event filtering](https://intellifi.zendesk.com/hc/en-us/articles/360008791494) for more information (e.g. items/#)
  --verify-target-certificate: oneof<nothing, bool> # Whether or not the `target_url` endpoint TLS certificate is verified to be valid.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions" $auth.query)
  let req_body = {"custom": $custom, "database_hold_time_h": $database_hold_time_h, "description": $description, "populate_events": $populate_events, "target_retry": $target_retry, "target_url": $target_url, "topic_filter": $topic_filter, "verify_target_certificate": $verify_target_certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete subscription
#
# DELETE /subscriptions/{id}
# operationId: deleteSubscription
export def "subscriptions delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get subscription
#
# GET /subscriptions/{id}
# operationId: getSubscriptionById
export def "subscriptions get" [
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
]: nothing -> record<custom: any, database_hold_time_h: int, description: string, events_url: string, id: string, populate_events: bool, target_delivery_last_failure: record, target_delivery_status: record, target_retry: bool, target_url: string, time_created: string, time_updated: string, topic_filter: string, url: string, verify_target_certificate: bool> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing subscription
#
# PUT /subscriptions/{id}
# operationId: updateSubscription
export def "subscriptions update" [
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
  --custom: any # The `custom` value is only for your custom references, you may use it to save additional attributes. The custom value is not used in any other place. This field may contain any datatype that you like: null (default), string, integer, boolean, object etc... (nullable, e.g. {foo: bar})
  --database-hold-time-h: int # The number of hours this event is retained in the database. *Only use larger numbers if you know what you are doing.* A couple of hours is enough for most use cases. (e.g. 2)
  --description: string # Additional field to add some notes about this subscription. (nullable, e.g. Item events)
  --populate-events: oneof<nothing, bool> # If set to `true`, resource references in an event (e.g. the location an item moved to) are resolved and populated with data instead of giving just an ID.
  --target-retry: oneof<nothing, bool> # Set to `true` if you want our server to retry if `target_url` is not giving back a `2xx` success code.
  --target-url: string # Url to an external service that all applicable events are pushed to (webhook). Configure to `null` if you don't wish to use this (default).
  --topic-filter: string # MQTT filter that is applied to all events. Allows you to select and filter events. See [Event filtering](https://intellifi.zendesk.com/hc/en-us/articles/360008791494) for more information (e.g. items/#)
  --verify-target-certificate: oneof<nothing, bool> # Whether or not the `target_url` endpoint TLS certificate is verified to be valid.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}") $auth.query)
  let req_body = {"custom": $custom, "database_hold_time_h": $database_hold_time_h, "description": $description, "populate_events": $populate_events, "target_retry": $target_retry, "target_url": $target_url, "topic_filter": $topic_filter, "verify_target_certificate": $verify_target_certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get subscription events
#
# GET /subscriptions/{id}/events
# operationId: getEventsForSubscriptionById
export def "subscriptions-events get-for" [
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
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --topic-resource-type: string@topic-resource-type-completer # Filter on the topic resource type (e.g. items)
  --topic-action: string@topic-action-completer # Filter on the topic action (e.g. created)
  --topic-resource: string # Filter on the topic resource id (e.g. 5b7d6cbd7503c445552a1664)
  --time-event: string # Filter on the time the event was generated on the device. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-expire: string # Filter on the time the event will expire. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<id: string, payload: any, time_created: string, time_event: string, time_expire: string, topic: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "topic.resource_type" $topic_resource_type "scalar") (serialize-qp "topic.action" $topic_action "scalar") (serialize-qp "topic.resource" $topic_resource "scalar") (serialize-qp "time_event" $time_event "scalar") (serialize-qp "time_expire" $time_expire "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}/events") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "topic.resource_type": $topic_resource_type, "topic.action": $topic_action, "topic.resource": $topic_resource, "time_event": $time_event, "time_expire": $time_expire} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all users
#
# GET /users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Limits on `time_created`, Marks the start of a range, optionally use `before` to set the end. Result output excludes the given timestamp. (format: date-time, e.g. 2016-01-27T08:38:55.255Z)
  --after-id: string # Limits directly on `id`. Marks the start of a range, optionally use `before_id` to set the end. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --before: string # Limits on `time_created`. Marks the end of a range, optionally use `after` to set the start. Result output excludes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --before-id: string # Limits directly on `id`. Marks the end of a range, optionally use `after_id` to set the start. Result output excludes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --qp-from: string # Limits on `time_created`. Marks the start of a range, optionally use `until` to set the end. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --from-id: string # Limits on `id`. Marks the start of a range, optionally use `until_id` to set the end. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --id-only: oneof<nothing, bool> # Removes `url` fields from output and shows `_id` instead of `_url` in references. (default: false, allows empty value)
  --limit: int # Sets the maximum number of returned resources. You may increase this number to large values, keep in mind that query times could become large. We advise you to use the pagination feature whenever you can. (default: 100, e.g. 5)
  --populate: string # Expand a reference into the actual resource (lookup). You may add multiple fields by giving a comma separated value. (e.g. location,item)
  --results-only: oneof<nothing, bool> # Removes response envelope with information about query, only sends back a JSON array with the applicable resources. (default: false, allows empty value)
  --select: string # Select which properties should be returned. You may add multiple fields by giving a comma separated value. Select can also be used together with populate: Specify the resource first, then a period(.) followed by the field.
  --qp-sort: string # Allows you to sort on on or more fields in the resource. You may append a minus sign (`-`) to request reverse order (new to old). (default: -id, e.g. -move_count,technology)
  --until: string # Limits on `time_created`. Marks the end of a range, optionally use `from` to set the start. Result output includes the given timestamp. (format: dateTime, e.g. 2016-01-27T08:38:55.255Z)
  --until-id: string # Limits on `id`. Marks the end of a range, optionally use `from_id` to set the start. Result output includes the given `id` value. Please note that `id` is in chronological order. (e.g. 56a88364e783152127d15340)
  --timeout-s: float # Overrides the default query timeout (in seconds). A value of 0 means unlimited. IMPORTANT: using high timeouts in production code is strongly discouraged as it may lead to stability issues. (e.g. 60)
  --id: string # Unique identifier (e.g. 5b7d6cbd7503c445552a1664)
  --time-created: string # Filter on the time the resource was created. (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --time-updated: string # Filter on the time the resource was last updated (format: dateTime, e.g. 2018-08-30T09:51:59.737Z)
  --email: string # Filter on the email address.
  --first-name: string # Filter on the first name.
  --last-name: string # Filter on the last name.
  --is-admin: oneof<nothing, bool> # Filter on the administrator status.
  --is-locked: oneof<nothing, bool> # Filter on the locked status.
]: nothing -> record<count: int, count_current: int, is_limited: bool, next_url: string, query_duration_ms: int, url: string, results: table<email: string, first_name: string, id: string, is_admin: bool, is_locked: bool, last_name: string, password: string, time_created: string, time_updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "id_only" $id_only "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "populate" $populate "scalar") (serialize-qp "results_only" $results_only "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "until_id" $until_id "scalar") (serialize-qp "timeout_s" $timeout_s "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_created" $time_created "scalar") (serialize-qp "time_updated" $time_updated "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "is_admin" $is_admin "scalar") (serialize-qp "is_locked" $is_locked "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"after": $after, "after_id": $after_id, "before": $before, "before_id": $before_id, "from": $qp_from, "from_id": $from_id, "id_only": $id_only, "limit": $limit, "populate": $populate, "results_only": $results_only, "select": $select, "sort": $qp_sort, "until": $until, "until_id": $until_id, "timeout_s": $timeout_s, "id": $id, "time_created": $time_created, "time_updated": $time_updated, "email": $email, "first_name": $first_name, "last_name": $last_name, "is_admin": $is_admin, "is_locked": $is_locked} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create user
#
# POST /users
# operationId: addUser
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email address (e.g. user@intellifi.nl)
  --first-name: string # First name (e.g. Foo)
  --is-admin: oneof<nothing, bool> # Whether or not this is an administrator.
  --is-locked: oneof<nothing, bool> # Whether or not this user is locked and can't change the password.
  --last-name: string # Last name (e.g. Bar)
  --password: string # Password of the user (e.g. password1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users" $auth.query)
  let req_body = {"email": $email, "first_name": $first_name, "is_admin": $is_admin, "is_locked": $is_locked, "last_name": $last_name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete user
#
# DELETE /users/{id}
# operationId: deleteUser
export def "users delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get user
#
# GET /users/{id}
# operationId: getUserById
export def "users get" [
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
]: nothing -> record<email: string, first_name: string, id: string, is_admin: bool, is_locked: bool, last_name: string, password: string, time_created: string, time_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update existing user
#
# PUT /users/{id}
# operationId: updateUser
export def "users update" [
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
  --email: string # Email address (e.g. user@intellifi.nl)
  --first-name: string # First name (e.g. Foo)
  --is-admin: oneof<nothing, bool> # Whether or not this is an administrator.
  --is-locked: oneof<nothing, bool> # Whether or not this user is locked and can't change the password.
  --last-name: string # Last name (e.g. Bar)
  --password: string # Password of the user (e.g. password1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-brain.sid"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}") $auth.query)
  let req_body = {"email": $email, "first_name": $first_name, "is_admin": $is_admin, "is_locked": $is_locked, "last_name": $last_name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
