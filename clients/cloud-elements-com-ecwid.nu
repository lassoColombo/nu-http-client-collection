# Auto-generated client for ecwid vapi-v2
# Source: https://api.apis.guru/v2/specs/cloud-elements.com/ecwid/api-v2/swagger.json
# Auth: --token flag or $env.ECWID_TOKEN

const BASE_URL = "https://api.cloud-elements.com/elements/api-v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ECWID_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bulk-download create" } } | get name | first)
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

# Create a new bulk download job (asynchronous)
#
# POST /bulk/download
# operationId: createBulkDownload
# --docsHubDetails shape: {instanceId?: string, path?: string}
# --query shape: {anyKey?: string}
export def "bulk-download create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --api-limit: int # format: int32
  --continue-from-job-id: int # format: int32
  --docs-hub-details: record # shape: {instanceId?: string, path?: string}
  --filter-date-field: string
  --filter-nulls: oneof<nothing, bool>
  format: string@format-completer
  --body-from: string # format: date-time
  --limit: int # format: int32
  --notification-url: string
  object_name: string
  --page-size: int # format: int32
  --query: record # shape: {anyKey?: string}
  --select-fields: string
  --body-to: string # format: date-time
  --body-where: string
]: any -> record<id: string, instance_id: float, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk/download" $auth.query)
  let req_body = {"apiLimit": $api_limit, "continueFromJobId": $continue_from_job_id, "docsHubDetails": $docs_hub_details, "filterDateField": $filter_date_field, "filterNulls": $filter_nulls, "format": $format, "from": $body_from, "limit": $limit, "notificationUrl": $notification_url, "objectName": $object_name, "pageSize": $page_size, "query": $query, "selectFields": $select_fields, "to": $body_to, "where": $body_where} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Fetch all the bulk jobs for an instance
#
# GET /bulk/jobs
# operationId: getBulkJobs
export def "bulk-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query. For example to get all upload jobs the expression would be where=job_direction='UPLOAD'. The following fields are valid search fields 'object_name', 'job_status', 'job_direction', 'record_count'
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --page-size: int # The page size for pagination, which defaults to 200 if not supplied (format: int64)
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<completion_time: int, createdDate: int, error_count: int, fileFormat: string, id: int, instanceId: int, job_direction: string, job_query: string, job_reset_attempt: int, job_state: string, notification_url: string, object_name: string, record_count: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk/jobs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"where": $qp_where, "nextPage": $next_page, "pageSize": $page_size, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an asynchronous bulk query job.
#
# POST /bulk/query
# operationId: createBulkQuery
export def "bulk-query create" [
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
  --qp-from: string # The created/updated date of the object to filter on - optional eg. '2014-10-06T13:22:17-08:00'
  --qp-to: string # The created/updated date of the object to filter on - optional eg. '2014-10-06T13:22:17-08:00'
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --elements-async-callback-url: string # The Url to send the notification to when the Job is completed
  --meta-data: string # Optional JSON MetaData that contains callback-payload and fileName, ex: {"callback-payload" : , "fileName" : "{Date format}_Name of the file"}. If the fileName is MyFile then pass metadata as {"fileName" : "{yyyy-MM-dd HH:mm:ss}_MyFile"}. The valid date formats are "yyyy-MM-dd'T'HH:mm:ssXXX", "yyyy-MM-dd'T'HH:mm:ss'Z'", "yyyy-MM-dd'T'HH:mm:ss.SXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd HH:mm:ss", "yyyy.MM.dd G 'at' HH:mm:ss z", "h:mm a", "yyyyy.MMMMM.dd GGG hh:mm aaa" and "yyMMddHHmmssZ". callback-payload - is passed back in bulk job notification
]: any -> record<id: string, instance_id: float, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lastRunDate" $last_run_date "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk/query" $qp $auth.query)
  let req_body = {"metaData": $meta_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Elements-Async-Callback-Url": $elements_async_callback_url} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: ({"q": $q, "lastRunDate": $last_run_date, "from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Cancel an asynchronous bulk query job.
#
# PUT /bulk/{id}/cancel
# operationId: replaceBulkCancel
export def "bulk-cancel update" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bulk/{id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve the errors of a bulk job.
#
# GET /bulk/{id}/errors
# operationId: getBulkErrors
export def "bulk-errors get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bulk/{id}/errors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the status of a bulk job.
#
# GET /bulk/{id}/status
# operationId: getBulkStatus
export def "bulk-status get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bulk/{id}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve the results of an asynchronous bulk query.
#
# GET /bulk/{id}/{objectName}
# operationId: getBulkByObjectName
export def "bulk get-by-object-name" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), object_name: (encode-path-segment $object_name)} | format pattern "/bulk/{id}/{object_name}") $auth.query)
  let accept_val = ($accept | default "text/csv")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Upload a file of objects to be bulk uploaded to the provider.
#
# POST /bulk/{objectName}
# operationId: createBulkByObjectName
export def "bulk create-by-object-name" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --elements-async-callback-url: string # The Url to send the notification to when the Job is completed
  --meta-data: string # Optional JSON MetaData that contains callback-payload, path or format, ex: {"path" :<path for the sub resource>, "format": <json/csv>, "callback-payload":<json>}. path - is passed to the endpoint for bulk loading the data into a nested object. Optional JSON Metadata that contains identifierFieldName, action, listId or campaignId. The identifierField name is used for upserts and the optional fields like listId or campaignId. Example: {"listId":"1014","action":"upsert"}. If the Upload format is JSON pass metadata as {"format":"json"}. callback-payload - is passed back in bulk job notification
  --file: path # The file of objects to bulk load. If the JSON file upload, each JSON record should be in a single line
]: any -> record<id: string, instanceId: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name)} | format pattern "/bulk/{object_name}") $auth.query)
  let req_body = {"metaData": $meta_data, "file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Elements-Async-Callback-Url": $elements_async_callback_url} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Find customers in the eCommerce system, using the provided CEQL search expression. If no search expression is provided, all records will be retrieved
#
# GET /customers
# operationId: getCustomers
export def "customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). Supported search terms: customer_id and customer_email. All other search criteria are ignored. NOTE: When searching by customer_id, do not quote the value (ex: customer_id=15693430), as the ID is a number rather than a string. When searching by email, quote the value (ex: customer_email='a@b.c'), as the email parameter is a string
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: list<record>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"where": $qp_where, "pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new customer in eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Customer' model are those required to create a new customer
#
# POST /customers
# operationId: createCustomer
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --shippingAddresses item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
export def "customers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --billing-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --customer-group-id: int # format: int64
  email: string # customer email
  --password: string # customer password
  --shipping-addresses: list # item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --tax-exempt: oneof<nothing, bool>
  --tax-id: float # format: double
  --tax-id-valid: oneof<nothing, bool>
]: any -> record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers" $auth.query)
  let req_body = {"billingPerson": $billing_person, "customerGroupId": $customer_group_id, "email": $email, "password": $password, "shippingAddresses": $shipping_addresses, "taxExempt": $tax_exempt, "taxId": $tax_id, "taxIdValid": $tax_id_valid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete a customer associated with a given ID from your eCommerce system. Specifying a customer associated with a given ID that does not exist will result in an error message
#
# DELETE /customers/{id}
# operationId: deleteCustomerById
export def "customers delete" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a customer associated with a given ID from the eCommerce system. Specifying a customer with an ID that does not exist will result in an error response
#
# GET /customers/{id}
# operationId: getCustomerById
export def "customers get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an customer associated with a given ID in the eCommerce system.The update API uses the PATCH HTTP verb, so only those fields provided in the customer object will be updated, and those fields not provided will be left alone. Updating a customer with a specified ID that does not exist will result in an error response
#
# PATCH /customers/{id}
# operationId: updateCustomerById
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --shippingAddresses item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
export def "customers update" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --billing-person: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --customer-group-id: int # format: int64
  --email: string # customer email
  --password: string # customer password
  --shipping-addresses: list # item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --tax-exempt: oneof<nothing, bool>
  --tax-id: float # format: double
  --tax-id-valid: oneof<nothing, bool>
]: any -> record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}") $auth.query)
  let req_body = {"billingPerson": $billing_person, "customerGroupId": $customer_group_id, "email": $email, "password": $password, "shippingAddresses": $shipping_addresses, "taxExempt": $tax_exempt, "taxId": $tax_id, "taxIdValid": $tax_id_valid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Find orders in the customer associated with a given ID. If the customer does not exist, an error response will be returned. If no orders are found in the given customer then an empty array will be returned
#
# GET /customers/{id}/orders
# operationId: getCustomersOrders
export def "customers-orders get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/orders") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of all the available objects.
#
# GET /objects
# operationId: getObjects
export def "objects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --elements-version: string@elements-version-completer # Elements Version to be used for getting metadata, possible options are Hydrogen, Helium. Default value is Hydrogen
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/objects" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Elements-Version": $elements_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get swagger docs for an object.
#
# GET /objects/{objectName}/docs
# operationId: getObjectsObjectNameDocs
export def "objects-docs get-name" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<basePath: string, definitions: record<definition_name: record<properties: record>>, host: string, info: record<contact: record<email: string>, title: string, version: string>, paths: record<_contacts: record<post: record>>, schemes: list<string>, swagger: string, tags: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  let qp = [(serialize-qp "discovery" $discovery "scalar") (serialize-qp "resolveReferences" $resolve_references "scalar") (serialize-qp "basic" $basic "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name)} | format pattern "/objects/{object_name}/docs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"discovery": $discovery, "resolveReferences": $resolve_references, "basic": $basic, "version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of all the field for an object.
#
# GET /objects/{objectName}/metadata
# operationId: getObjectsObjectNameMetadata
export def "objects-metadata get-name" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --elements-version: string@elements-version-completer # Elements Version to be used for getting metadata, possible options are Hydrogen, Helium. Default value is Hydrogen
]: nothing -> record<fields: table<mask: string, type: string, vendorDisplayName: string, vendorPath: string, vendorReadOnly: bool, vendorRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name)} | format pattern "/objects/{object_name}/metadata") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Elements-Version": $elements_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Find orders in the eCommerce system, using the provided CEQL search expression. If no search expression is provided, all records will be retrieved
#
# GET /orders
# operationId: getOrders
export def "orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). Supported search terms: date, from_date, to_date, from_update_date, to_update_date, order, from_order, to_order, customer_id, customer_email and statuses. All other search criteria are ignored
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"where": $qp_where, "pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an order in the eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Order' model are those required to create a new order.The paymentStatus can only be AWAITING_PAYMENT or INCOMPLETE.The fulfillmentStatus can only be AWAITING_PROCESSING
#
# POST /orders
# operationId: createOrder
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --items item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
# --shippingOption shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
# --shippingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
export def "orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
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
]: any -> record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders" $auth.query)
  let req_body = {"billingPerson": $billing_person, "couponDiscount": $coupon_discount, "customerId": $customer_id, "customerTaxExempt": $customer_tax_exempt, "customerTaxId": $customer_tax_id, "customerTaxIdValid": $customer_tax_id_valid, "discount": $discount, "email": $email, "fulfillmentStatus": $fulfillment_status, "globalReferer": $global_referer, "hidden": $hidden, "items": $items, "membershipBasedDiscount": $membership_based_discount, "orderComments": $order_comments, "paymentMethod": $payment_method, "paymentModule": $payment_module, "paymentStatus": $payment_status, "privateAdminNotes": $private_admin_notes, "refererUrl": $referer_url, "reversedTaxApplied": $reversed_tax_applied, "sample": $sample, "shippingMethod": $shipping_method, "shippingOption": $shipping_option, "shippingPerson": $shipping_person, "subtotal": $subtotal, "tax": $tax, "total": $total, "totalAndMembershipBasedDiscount": $total_and_membership_based_discount, "volumeDiscount": $volume_discount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete an order associated with a given ID from your eCommerce system. Specifying an order associated with a given ID that does not exist will result in an error message
#
# DELETE /orders/{id}
# operationId: deleteOrderById
export def "orders delete" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an order associated with a given ID from the eCommerce system. Specifying an order with an ID that does not exist will result in an error response
#
# GET /orders/{id}
# operationId: getOrderById
export def "orders get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an order associated with a given ID in the eCommerce system. The update API uses the PATCH HTTP verb, so only those fields provided in the order object will be updated, and those fields not provided will be left alone. Updating an order with a specified ID that does not exist will result in an error response
#
# PATCH /orders/{id}
# operationId: updateOrderById
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --items item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
# --shippingOption shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
# --shippingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --taxesOnShipping item shape: {name?: string, total?: float, value?: float}
export def "orders update" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
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
]: any -> record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}") $qp $auth.query)
  let req_body = {"billingPerson": $billing_person, "couponDiscount": $coupon_discount, "customerId": $customer_id, "customerTaxExempt": $customer_tax_exempt, "customerTaxId": $customer_tax_id, "customerTaxIdValid": $customer_tax_id_valid, "discount": $discount, "email": $email, "fulfillmentStatus": $fulfillment_status, "globalReferer": $global_referer, "hidden": $hidden, "items": $items, "membershipBasedDiscount": $membership_based_discount, "orderComments": $order_comments, "paymentModule": $payment_module, "paymentStatus": $payment_status, "privateAdminNotes": $private_admin_notes, "refererUrl": $referer_url, "reversedTaxApplied": $reversed_tax_applied, "sample": $sample, "shippingMethod": $shipping_method, "shippingOption": $shipping_option, "shippingPerson": $shipping_person, "subtotal": $subtotal, "tax": $tax, "taxesOnShipping": $taxes_on_shipping, "total": $total, "totalAndMembershipBasedDiscount": $total_and_membership_based_discount, "volumeDiscount": $volume_discount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"action": $action} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve the payments in the eCommerce system for the specified order
#
# GET /orders/{orderId}/payments
# operationId: getOrdersPayments
export def "orders-payments get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<paymentMethod: string, paymentStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/payments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the refunds in the eCommerce system for the specified order
#
# GET /orders/{orderId}/refunds
# operationId: getOrdersRefunds
export def "orders-refunds get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<paymentMethod: string, paymentStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/refunds") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Ping the Element to confirm that the Hub Element has a heartbeat. If the Element does not have a heartbeat, an error message will be returned.
#
# GET /ping
# operationId: getPing
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<dateTime: string, endpoint: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Find products in the eCommerce system, using the provided CEQL search expression. The search expression in CEQL is the WHERE clause in a typical SQL query, but without the WHERE keyword. If no search expression is provided, all records will be retrieved
#
# GET /products
# operationId: getProducts
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). Supported search terms: category, hidden_products. All other search criteria are ignored
  --page-size: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<attributes: list<record>, borderInfo: record<dominatingColor: record, homogeneity: bool>, categories: list<record>, categoryIds: list<int>, combinations: list<record>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: list<record>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: list<record>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list>, name: string, options: list<record>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list, relatedCategory: record>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list, enabledMethods: list, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list>, taxes: list<record>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"where": $qp_where, "pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new product in eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Product' model are those required to create a new product
#
# POST /products
# operationId: createProduct
# --attributes item shape: {id?: int, internalName?: string, name?: string, value?: string}
# --dimensions shape: {height?: float, length?: float, width?: float}
# --favorites shape: {count?: int, displayedCount?: string}
# --galleryImages item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
# --options item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
# --relatedProducts shape: {productIds?: list<float>, relatedCategory?: record}
# --shipping shape: {disabledMethods?: list<string>, enabledMethods?: list<string>, flatRate?: float, methodMarkup?: float, type?: string}
# --tax shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list<int>}
# --taxes item shape: {name?: string, total?: float, value?: float}
# --wholesalePrices shape: {{quantity}?: float}
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
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
]: any -> record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products" $auth.query)
  let req_body = {"attributes": $attributes, "categoryIds": $category_ids, "compareAtPrice": $compare_at_price, "compareToPrice": $compare_to_price, "created": $created, "defaultCategoryId": $default_category_id, "description": $description, "dimensions": $dimensions, "enabled": $enabled, "favorites": $favorites, "fixedShippingRate": $fixed_shipping_rate, "fixedShippingRateOnly": $fixed_shipping_rate_only, "galleryImages": $gallery_images, "googleItemCondition": $google_item_condition, "isShippingRequired": $is_shipping_required, "name": $name, "options": $options, "price": $price, "productClassId": $product_class_id, "quantity": $quantity, "relatedProducts": $related_products, "seoDescription": $seo_description, "seoTitle": $seo_title, "shipping": $shipping, "showOnFrontpage": $show_on_frontpage, "sku": $sku, "tax": $tax, "taxes": $taxes, "warningLimit": $warning_limit, "weight": $weight, "wholesalePrices": $wholesale_prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete a product associated with a given ID from your eCommerce system. Specifying a product associated with a given ID that does not exist will result in an error message
#
# DELETE /products/{id}
# operationId: deleteProductById
export def "products delete" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a product associated with a given ID from the eCommerce system. Specifying a product with an ID that does not exist will result in an error response
#
# GET /products/{id}
# operationId: getProductById
export def "products get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a product associated with a given ID in the eCommerce system. The update API uses the PATCH HTTP verb, so only those fields provided in the product object will be updated, and those fields not provided will be left alone. Updating a product with a specified ID that does not exist will result in an error response. Update supports the following fields: sku, quantity, trackQuantity, quantityDelta, warningLimit, name, price, weight, tangible, enabled, fixedShippingRateOnly, fixedShippingRate, description, wholesalePrices, compareAtPrice, productClassId
#
# PATCH /products/{id}
# operationId: updateProductById
# --attributes item shape: {id?: int, internalName?: string, name?: string, value?: string}
# --dimensions shape: {height?: float, length?: float, width?: float}
# --galleryImages item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
# --options item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
# --relatedProducts shape: {productIds?: list<float>, relatedCategory?: record}
# --shipping shape: {disabledMethods?: list<string>, enabledMethods?: list<string>, flatRate?: float, methodMarkup?: float, type?: string}
# --tax shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list<int>}
# --taxes item shape: {name?: string, total?: float, value?: float}
# --wholesalePrices shape: {{quantity}?: float}
export def "products update" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
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
]: any -> record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}") $auth.query)
  let req_body = {"attributes": $attributes, "categoryIds": $category_ids, "compareAtPrice": $compare_at_price, "compareToPrice": $compare_to_price, "defaultCategoryId": $default_category_id, "description": $description, "dimensions": $dimensions, "enabled": $enabled, "fixedShippingRate": $fixed_shipping_rate, "fixedShippingRateOnly": $fixed_shipping_rate_only, "galleryImages": $gallery_images, "googleItemCondition": $google_item_condition, "isShippingRequired": $is_shipping_required, "name": $name, "options": $options, "price": $price, "productClassId": $product_class_id, "quantity": $quantity, "relatedProducts": $related_products, "seoDescription": $seo_description, "seoTitle": $seo_title, "shipping": $shipping, "showOnFrontpage": $show_on_frontpage, "sku": $sku, "tax": $tax, "taxes": $taxes, "warningLimit": $warning_limit, "weight": $weight, "wholesalePrices": $wholesale_prices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Search for {objectName}
#
# GET /{objectName}
# operationId: getByObjectName
export def "object-name list" [
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
  --qp-where: string # The CEQL search expression.
  --page-size: int # The page size. Defaults to 200 if not provided. Maximum of 5000. (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name)} | format pattern "/{object_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"where": $qp_where, "pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an {objectName}
#
# POST /{objectName}
# operationId: createByObjectName
export def "object-name create" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --object-field: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name)} | format pattern "/{object_name}") $auth.query)
  let req_body = {"objectField": $object_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete an {objectName}
#
# DELETE /{objectName}/{objectId}
# operationId: deleteObjectNameByObjectId
export def "object-name delete" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id)} | format pattern "/{object_name}/{object_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an {objectName}
#
# GET /{objectName}/{objectId}
# operationId: getObjectNameByObjectId
export def "object-name get" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id)} | format pattern "/{object_name}/{object_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an {objectName}
#
# PATCH /{objectName}/{objectId}
# operationId: updateObjectNameByObjectId
export def "object-name update-by-object-name-object-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --object-field: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id)} | format pattern "/{object_name}/{object_id}") $auth.query)
  let req_body = {"objectField": $object_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update an {objectName}
#
# PUT /{objectName}/{objectId}
# operationId: replaceObjectNameByObjectId
export def "object-name update-by-object-name-object-id-1" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --object-field: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id)} | format pattern "/{object_name}/{object_id}") $auth.query)
  let req_body = {"objectField": $object_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Search for {childObjectName}
#
# GET /{objectName}/{objectId}/{childObjectName}
# operationId: getObjectNameByChildObjectName
export def "object-name list-1" [
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
  --qp-where: string # The CEQL search expression.
  --page-size: int # The page size. Defaults to 200 if not provided. Maximum of 5000. (format: int64)
  --next-page: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> table<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  if ($child_object_name | is-empty) { error make --unspanned { msg: "path parameter 'childObjectName' must be non-empty" } }
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "nextPage" $next_page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id), child_object_name: (encode-path-segment $child_object_name)} | format pattern "/{object_name}/{object_id}/{child_object_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"where": $qp_where, "pageSize": $page_size, "nextPage": $next_page, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an {objectName}
#
# POST /{objectName}/{objectId}/{childObjectName}
# operationId: createObjectNameByChildObjectName
export def "object-name create-by-child" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --object-field: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  if ($child_object_name | is-empty) { error make --unspanned { msg: "path parameter 'childObjectName' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id), child_object_name: (encode-path-segment $child_object_name)} | format pattern "/{object_name}/{object_id}/{child_object_name}") $auth.query)
  let req_body = {"objectField": $object_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete an {childObjectName}
#
# DELETE /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: deleteObjectNameByChildObjectId
export def "object-name delete-by-child" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  if ($child_object_name | is-empty) { error make --unspanned { msg: "path parameter 'childObjectName' must be non-empty" } }
  if ($child_object_id | is-empty) { error make --unspanned { msg: "path parameter 'childObjectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id), child_object_name: (encode-path-segment $child_object_name), child_object_id: (encode-path-segment $child_object_id)} | format pattern "/{object_name}/{object_id}/{child_object_name}/{child_object_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve an {childObjectName}
#
# GET /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: getObjectNameByChildObjectId
export def "object-name get-by-child" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
]: nothing -> record<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  if ($child_object_name | is-empty) { error make --unspanned { msg: "path parameter 'childObjectName' must be non-empty" } }
  if ($child_object_id | is-empty) { error make --unspanned { msg: "path parameter 'childObjectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id), child_object_name: (encode-path-segment $child_object_name), child_object_id: (encode-path-segment $child_object_id)} | format pattern "/{object_name}/{object_id}/{child_object_name}/{child_object_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an {childObjectName}
#
# PATCH /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: updateObjectNameByChildObjectId
export def "object-name update-by-child-by-object-name-object-id-child-object-name-child-object-id" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --object-field: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  if ($child_object_name | is-empty) { error make --unspanned { msg: "path parameter 'childObjectName' must be non-empty" } }
  if ($child_object_id | is-empty) { error make --unspanned { msg: "path parameter 'childObjectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id), child_object_name: (encode-path-segment $child_object_name), child_object_id: (encode-path-segment $child_object_id)} | format pattern "/{object_name}/{object_id}/{child_object_name}/{child_object_id}") $auth.query)
  let req_body = {"objectField": $object_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update an {childObjectName}
#
# PUT /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: replaceObjectNameByChildObjectId
export def "object-name update-by-child-by-object-name-object-id-child-object-name-child-object-id-1" [
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
  --authorization: string # The authorization tokens. The format for the header value is 'Element <token>, User <user secret>'
  --object-field: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_name | is-empty) { error make --unspanned { msg: "path parameter 'objectName' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'objectId' must be non-empty" } }
  if ($child_object_name | is-empty) { error make --unspanned { msg: "path parameter 'childObjectName' must be non-empty" } }
  if ($child_object_id | is-empty) { error make --unspanned { msg: "path parameter 'childObjectId' must be non-empty" } }
  let full_url = (build-url $base ({object_name: (encode-path-segment $object_name), object_id: (encode-path-segment $object_id), child_object_name: (encode-path-segment $child_object_name), child_object_id: (encode-path-segment $child_object_id)} | format pattern "/{object_name}/{object_id}/{child_object_name}/{child_object_id}") $auth.query)
  let req_body = {"objectField": $object_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
