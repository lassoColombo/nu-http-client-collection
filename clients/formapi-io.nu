# Auto-generated client for API v1 vv1
# Source: https://api.apis.guru/v2/specs/formapi.io/v1/openapi.json
# Auth: --token flag or $env.API_V1_TOKEN

const BASE_URL = "https://api.docspring.com/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
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

def base-url-completer [] { ["https://api.docspring.com/api/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def auth-second-factor-type-completer [] { ["fingerprint" "mobile_push" "none" "phone_number" "security_key" "totp"] }
def auth-type-completer [] { ["email_link" "ldap" "none" "oauth" "password" "phone_number" "saml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authentication test" } } | get name | first)
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

# Test Authentication
#
# GET /authentication
# operationId: testAuthentication
export def "authentication test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of all combined submissions
#
# GET /combined_submissions
# operationId: listCombinedSubmissions
export def "combined-submissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Default: 1 (e.g. 2)
  --per-page: int # Default: 50 (e.g. 1)
]: nothing -> table<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/combined_submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Merge generated PDFs together
#
# POST /combined_submissions
# operationId: combineSubmissions
export def "combined-submissions create-combine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-in: int
  --metadata: record
  --password: string
  submission_ids: list<string>
  --test: oneof<nothing, bool>
]: any -> record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/combined_submissions")
  let req_body = {"expires_in": $expires_in, "metadata": $metadata, "password": $password, "submission_ids": $submission_ids, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Expire a combined submission
#
# DELETE /combined_submissions/{combined_submission_id}
# operationId: expireCombinedSubmission
export def "combined-submissions delete-expire" [
  combined_submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($combined_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'combined_submission_id' must be non-empty" } }
  let full_url = (build-url $base ({combined_submission_id: (encode-path-segment $combined_submission_id)} | format pattern "/combined_submissions/{combined_submission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check the status of a combined submission (merged PDFs)
#
# GET /combined_submissions/{combined_submission_id}
# operationId: getCombinedSubmission
export def "combined-submissions get" [
  combined_submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($combined_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'combined_submission_id' must be non-empty" } }
  let full_url = (build-url $base ({combined_submission_id: (encode-path-segment $combined_submission_id)} | format pattern "/combined_submissions/{combined_submission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Merge submission PDFs, template PDFs, or custom files
#
# POST /combined_submissions?v=2
# operationId: combinePdfs
export def "combined-submissions-v2 create-combine-pdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-custom-files: oneof<nothing, bool>
  --expires-in: int
  --metadata: record
  --password: string
  source_pdfs: list
  --test: oneof<nothing, bool>
]: any -> record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/combined_submissions?v=2")
  let req_body = {"delete_custom_files": $delete_custom_files, "expires_in": $expires_in, "metadata": $metadata, "password": $password, "source_pdfs": $source_pdfs, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new custom file from a cached presign upload
#
# POST /custom_files
# operationId: createCustomFileFromUpload
export def "custom-files create-from-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cache_id: string
]: any -> record<custom_file: record<id: string, url: string>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_files")
  let req_body = {"cache_id": $cache_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Look up a submission data request
#
# GET /data_requests/{data_request_id}
# operationId: getDataRequest
export def "data-requests get" [
  data_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($data_request_id | is-empty) { error make --unspanned { msg: "path parameter 'data_request_id' must be non-empty" } }
  let full_url = (build-url $base ({data_request_id: (encode-path-segment $data_request_id)} | format pattern "/data_requests/{data_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a submission data request
#
# PUT /data_requests/{data_request_id}
# operationId: updateDataRequest
export def "data-requests update" [
  data_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-phone-number-hash: string # nullable
  --auth-provider: string # nullable
  --auth-second-factor-type: string@auth-second-factor-type-completer
  --auth-session-id-hash: string # nullable
  --auth-session-started-at: string # nullable
  --auth-type: string@auth-type-completer
  --auth-user-id-hash: string # nullable
  --auth-username-hash: string # nullable
  --email: string # nullable
  --fields: list<string>
  --metadata: record
  --name: string # nullable
  --order: int
]: any -> record<data_request: record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($data_request_id | is-empty) { error make --unspanned { msg: "path parameter 'data_request_id' must be non-empty" } }
  let full_url = (build-url $base ({data_request_id: (encode-path-segment $data_request_id)} | format pattern "/data_requests/{data_request_id}"))
  let req_body = {"auth_phone_number_hash": $auth_phone_number_hash, "auth_provider": $auth_provider, "auth_second_factor_type": $auth_second_factor_type, "auth_session_id_hash": $auth_session_id_hash, "auth_session_started_at": $auth_session_started_at, "auth_type": $auth_type, "auth_user_id_hash": $auth_user_id_hash, "auth_username_hash": $auth_username_hash, "email": $email, "fields": $fields, "metadata": $metadata, "name": $name, "order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new data request token for form authentication
#
# POST /data_requests/{data_request_id}/tokens
# operationId: createDataRequestToken
export def "data-requests-tokens create" [
  data_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: list<string>, status: string, token: record<data_request_url: string, expires_at: string, id: string, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($data_request_id | is-empty) { error make --unspanned { msg: "path parameter 'data_request_id' must be non-empty" } }
  let full_url = (build-url $base ({data_request_id: (encode-path-segment $data_request_id)} | format pattern "/data_requests/{data_request_id}/tokens"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of all folders
#
# GET /folders/
# operationId: listFolders
export def "folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-folder-id: string # Filter By Folder Id (e.g. fld_000000000000000002)
]: nothing -> table<id: string, name: string, parent_folder_id: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_folder_id" $parent_folder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"parent_folder_id": $parent_folder_id} | compact), body: null}
}

# Create a folder
#
# POST /folders/
# operationId: createFolder
# --folder shape: {name: string, parent_folder_id?: string}
export def "folders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  folder: record # shape: {name: string, parent_folder_id?: string}
]: any -> record<id: string, name: string, parent_folder_id: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/folders/")
  let req_body = {"folder": $folder} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a folder
#
# DELETE /folders/{folder_id}
# operationId: deleteFolder
export def "folders delete" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, parent_folder_id: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'folder_id' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Move a folder
#
# POST /folders/{folder_id}/move
# operationId: moveFolderToFolder
export def "folders-move move" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-folder-id: string
]: any -> record<id: string, name: string, parent_folder_id: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'folder_id' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/folders/{folder_id}/move"))
  let req_body = {"parent_folder_id": $parent_folder_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Rename a folder
#
# POST /folders/{folder_id}/rename
# operationId: renameFolder
export def "folders-rename rename" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'folder_id' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/folders/{folder_id}/rename"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all submissions
#
# GET /submissions
# operationId: listSubmissions
export def "submissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # e.g. sub_list_000012
  --limit: float # e.g. 3
  --created-after: string # e.g. 2019-01-01T09:00:00-05:00
  --created-before: string # e.g. 2020-01-01T09:00:00-05:00
  --type: string # e.g. test
  --include-data: oneof<nothing, bool> # e.g. true
]: nothing -> record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include_data" $include_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cursor": $cursor, "limit": $limit, "created_after": $created_after, "created_before": $created_before, "type": $type, "include_data": $include_data} | compact), body: null}
}

# Generates multiple PDFs
#
# POST /submissions/batches
# operationId: batchGeneratePdfs
# --submissions item shape: {css?: string, data: record, html?: string, metadata?: record, template_id: string, test?: bool}
export def "submissions-batches generate-batch-pdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record
  submissions: list # item shape: {css?: string, data: record, html?: string, metadata?: record, template_id: string, test?: bool}
  --template-id: string # nullable
  --test: oneof<nothing, bool>
]: any -> record<error: string, errors: list<string>, status: string, submission_batch: record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: list<record>, total_count: int>, submissions: table<errors: list, status: string, submission: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/batches")
  let req_body = {"metadata": $metadata, "submissions": $submissions, "template_id": $template_id, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check the status of a submission batch job
#
# GET /submissions/batches/{submission_batch_id}
# operationId: getSubmissionBatch
export def "submissions-batches get" [
  submission_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-submissions: oneof<nothing, bool> # e.g. true
]: nothing -> record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_batch_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_batch_id' must be non-empty" } }
  let qp = [(serialize-qp "include_submissions" $include_submissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({submission_batch_id: (encode-path-segment $submission_batch_id)} | format pattern "/submissions/batches/{submission_batch_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_submissions": $include_submissions} | compact), body: null}
}

# Expire a PDF submission
#
# DELETE /submissions/{submission_id}
# operationId: expireSubmission
export def "submissions delete-expire" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_id' must be non-empty" } }
  let full_url = (build-url $base ({submission_id: (encode-path-segment $submission_id)} | format pattern "/submissions/{submission_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check the status of a PDF
#
# GET /submissions/{submission_id}
# operationId: getSubmission
export def "submissions get" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-data: oneof<nothing, bool> # e.g. true
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($submission_id | is-empty) { error make --unspanned { msg: "path parameter 'submission_id' must be non-empty" } }
  let qp = [(serialize-qp "include_data" $include_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({submission_id: (encode-path-segment $submission_id)} | format pattern "/submissions/{submission_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_data": $include_data} | compact), body: null}
}

# Get a list of all templates
#
# GET /templates
# operationId: listTemplates
export def "templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search By Name (e.g. 2)
  --parent-folder-id: string # Filter By Folder Id (e.g. fld_000000000000000001)
  --page: int # Default: 1 (e.g. 2)
  --per-page: int # Default: 50 (e.g. 1)
]: nothing -> table<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "parent_folder_id" $parent_folder_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "parent_folder_id": $parent_folder_id, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Create a new PDF template with a form POST file upload
#
# POST /templates
# operationId: createPDFTemplate
export def "templates create-pdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template_document: string # format: binary, e.g. <Uploaded File>
  template_name: string # e.g. Test Template
  --template-parent-folder-id: string # e.g. fld_000000000000000001
]: any -> record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let req_body = {"template[document]": $template_document, "template[name]": $template_name, "template[parent_folder_id]": $template_parent_folder_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["template[document]"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Check the status of an uploaded template
#
# GET /templates/{template_id}
# operationId: getTemplate
export def "templates get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Template
#
# PUT /templates/{template_id}
# operationId: updateTemplate
# --template shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name?: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, webhook_url?: string}
export def "templates update" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template: record # shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name?: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, webhook_url?: string}
]: any -> record<errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}"))
  let req_body = {"template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add new fields to a Template
#
# PUT /templates/{template_id}/add_fields
# operationId: addFieldsToTemplate
# --fields item shape: {alignment?: "left"|"center"|"right", autoCalculateMaxLength?: bool, backgroundColor?: string, backgroundColorFieldName?: string, backgroundColorFieldRequired?: bool, barcodeSymbology?: string, bold?: bool, characterSpacing?: float, checkCharacter?: "&#10003;"|"&#10004;"|"&#10006;"|"&#10007;"|"&#10008;", checkColor?: string, checkColorFieldName?: string, checkColorFieldRequired?: bool, color?: string, colorFieldName?: string, colorFieldRequired?: bool, comb?: bool, combNumberOfCells?: float, ... (69 more fields)}
export def "templates-add-fields create" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fields: list # item shape: {alignment?: "left"|"center"|"right", autoCalculateMaxLength?: bool, backgroundColor?: string, backgroundColorFieldName?: string, backgroundColorFieldRequired?: bool, barcodeSymbology?: string, bold?: bool, characterSpacing?: float, checkCharacter?: "&#10003;"|"&#10004;"|"&#10006;"|"&#10007;"|"&#10008;", checkColor?: string, checkColorFieldName?: string, checkColorFieldRequired?: bool, color?: string, colorFieldName?: string, colorFieldRequired?: bool, comb?: bool, combNumberOfCells?: float, ... (69 more fields)}
]: any -> record<errors: list<string>, new_field_ids: list<int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/add_fields"))
  let req_body = {"fields": $fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Copy a Template
#
# POST /templates/{template_id}/copy
# operationId: copyTemplate
export def "templates-copy copy" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  parent_folder_id: string
]: any -> record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/copy"))
  let req_body = {"name": $name, "parent_folder_id": $parent_folder_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Move Template to folder
#
# POST /templates/{template_id}/move
# operationId: moveTemplateToFolder
export def "templates-move move-to-folder" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parent_folder_id: string
]: any -> record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/move"))
  let req_body = {"parent_folder_id": $parent_folder_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch the JSON schema for a template
#
# GET /templates/{template_id}/schema
# operationId: getTemplateSchema
export def "templates-schema get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_schema: string, additionalProperties: bool, definitions: record, description: string, id: string, properties: record, required: list<any>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/schema"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all submissions for a given template
#
# GET /templates/{template_id}/submissions
export def "templates-submissions get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: float
  --created-after: string
  --created-before: string
  --type: string
  --include-data: oneof<nothing, bool> # e.g. true
]: nothing -> record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include_data" $include_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/submissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cursor": $cursor, "limit": $limit, "created_after": $created_after, "created_before": $created_before, "type": $type, "include_data": $include_data} | compact), body: null}
}

# Generates a new PDF
#
# POST /templates/{template_id}/submissions
# operationId: generatePDF
# --data_requests item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list<string>, metadata?: record, name?: string, order?: int}
export def "templates-submissions generate-pdf" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string
  data: record
  --data-requests: list # item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list<string>, metadata?: record, name?: string, order?: int}
  --expires-in: int
  --field-overrides: record
  --html: string
  --metadata: record
  --password: string
  --test: oneof<nothing, bool>
]: any -> record<errors: list<string>, status: string, submission: record<actions: list<record>, batch_id: string, data: record, data_requests: list<record>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/submissions"))
  let req_body = {"css": $css, "data": $data, "data_requests": $data_requests, "expires_in": $expires_in, "field_overrides": $field_overrides, "html": $html, "metadata": $metadata, "password": $password, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generates multiple PDFs
#
# POST /templates/{template_id}/submissions/batch
# operationId: batchGeneratePdfV1
# --data_requests item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list<string>, metadata?: record, name?: string, order?: int}
export def "templates-submissions-batch generate-pdf" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string
  data: record
  --data-requests: list # item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list<string>, metadata?: record, name?: string, order?: int}
  --html: string
  --metadata: record
  --test: oneof<nothing, bool>
]: any -> table<errors: list<string>, status: string, submission: record<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}/submissions/batch"))
  let req_body = {"css": $css, "data": $data, "data_requests": $data_requests, "html": $html, "metadata": $metadata, "test": $test} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch the full template attributes
#
# GET /templates/{template_id}?full=true
# operationId: getFullTemplate
export def "templates get-full" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_additional_properties: bool, defaults: record<color: string, fontSize: float, typeface: string>, demo: bool, description: string, document_filename: string, document_md5: string, document_parse_error: bool, document_processed: bool, document_state: string, document_url: string, editable_submissions: bool, embed_domains: list<string>, encrypt_pdfs: bool, encrypt_pdfs_password: string, expiration_interval: string, expire_after: float, expire_submissions: bool, field_order: list<list<float>>, fields: record, first_template: bool, footer_html: string, header_html: string, html: string, id: string, locked: bool, name: string, page_count: float, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, scss: string, shared_field_data: record, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_id | is-empty) { error make --unspanned { msg: "path parameter 'template_id' must be non-empty" } }
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}?full=true"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new PDF template from a cached presign upload
#
# POST /templates?desc=cached_upload
# operationId: createPDFTemplateFromUpload
# --template shape: {allow_additional_properties?: bool, description?: string, document?: record, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
export def "templates-desccached-upload create-pdf-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template: record # shape: {allow_additional_properties?: bool, description?: string, document?: record, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
]: any -> record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates?desc=cached_upload")
  let req_body = {"template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new HTML template
#
# POST /templates?desc=html
# operationId: createHTMLTemplate
# --template shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
export def "templates-deschtml create-html-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template: record # shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
]: any -> record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates?desc=html")
  let req_body = {"template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a presigned URL so that you can upload a file to our AWS S3 bucket
#
# GET /uploads/presign
# operationId: getPresignUrl
export def "uploads-presign get-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fields: record<key: string, policy: string, x_amz_algorithm: string, x_amz_credential: string, x_amz_date: string, x_amz_signature: string>, headers: record, method: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/presign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
