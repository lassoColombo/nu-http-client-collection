# Auto-generated client for Files.com API v0.0.1
# Source: https://api.apis.guru/v2/specs/files.com/0.0.1/openapi.json
# Auth: --token flag or $env.FILES_COM_API_TOKEN

const BASE_URL = "http://localhost//app.files.com/api/rest/v1"
const DEFAULT_AUTH = "x-filesapi-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FILES_COM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-filesapi-key" => { {headers: {X-FilesAPI-Key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
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

def base-url-completer [] { ["http://localhost//app.files.com/api/rest/v1"] }
def auth-scheme-completer [] { ["x-filesapi-key"] }

# Completers for enum parameters
def permission-set-completer [] { ["desktop_app" "full" "mobile_app" "none" "office_integration" "sync_app"] }
def automation-completer [] { ["as2_send" "copy_file" "copy_newest_file" "create_folder" "delete_file" "move_file" "request_file" "request_move" "run_sync"] }
def trigger-completer [] { ["action" "custom_schedule" "daily" "email" "realtime" "webhook"] }
def permissions-completer [] { ["full" "none" "preview_only" "read" "read_write" "write"] }
def use-with-bundles-completer [] { ["available" "none" "require"] }
def use-with-inboxes-completer [] { ["available" "none" "require"] }
def use-with-users-completer [] { ["none" "require"] }
def status-completer [] { ["failure" "in_progress" "partial_failure" "skipped" "success"] }
def authentication-method-completer [] { ["email_signup" "none" "password" "password_with_imported_hash" "sso" "unused_former_ldap"] }
def require-2fa-completer [] { ["always_require" "never_require" "use_system_setting"] }
def ssl-required-completer [] { ["always_require" "never_require" "use_system_setting"] }
def files-agent-permission-set-completer [] { ["read_only" "read_write" "write_only"] }
def one-drive-account-type-completer [] { ["business_other" "personal"] }
def server-certificate-completer [] { ["allow_any" "require_match"] }
def server-type-completer [] { ["azure" "azure_files" "backblaze_b2" "box" "dropbox" "filebase" "files_agent" "ftp" "google_cloud_storage" "google_drive" "one_drive" "rackspace" "s3" "s3_compatible" "sftp" "sharepoint" "wasabi" "webdav"] }
def ssl-completer [] { ["if_available" "never" "require" "require_implicit"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "action-notification-export-results get" } } | get name | first)
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

# List Action Notification Export Results
#
# GET /action_notification_export_results
# operationId: GetActionNotificationExportResults
export def "action-notification-export-results get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --action-notification-export-id: int # ID of the associated action notification export. (format: int32)
]: nothing -> table<created_at: int, folder: string, id: int, message: string, path: string, request_headers: string, request_method: string, request_url: string, status: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "action_notification_export_id" $action_notification_export_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/action_notification_export_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Action Notification Export
#
# POST /action_notification_exports
# operationId: PostActionNotificationExports
export def "action-notification-exports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-at: string # End date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --query-folder: string # Return notifications that were triggered by actions in this folder. (e.g. MyFolder)
  --query-message: string # Error message associated with the request, if any. (e.g. Connection Refused)
  --query-path: string # Return notifications that were triggered by actions on this specific path. (e.g. MyFile.txt)
  --query-request-method: string # The HTTP request method used by the webhook. (e.g. GET)
  --query-request-url: string # The target webhook URL. (e.g. http://example.com/webhook)
  --query-status: string # The HTTP status returned from the server in response to the webhook request. (e.g. 200)
  --query-success: oneof<nothing, bool> # true if the webhook request succeeded (i.e. returned a 200 or 204 response status). false otherwise. (e.g. true)
  --start-at: string # Start date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<end_at: string, export_version: string, id: int, query_folder: string, query_message: string, query_path: string, query_request_method: string, query_request_url: string, query_status: string, query_success: bool, results_url: string, start_at: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/action_notification_exports")
  let req_body = {"end_at": $end_at, "query_folder": $query_folder, "query_message": $query_message, "query_path": $query_path, "query_request_method": $query_request_method, "query_request_url": $query_request_url, "query_status": $query_status, "query_success": $query_success, "start_at": $start_at, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show Action Notification Export
#
# GET /action_notification_exports/{id}
# operationId: GetActionNotificationExportsId
export def "action-notification-exports get" [
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
]: nothing -> record<end_at: string, export_version: string, id: int, query_folder: string, query_message: string, query_path: string, query_request_method: string, query_request_url: string, query_status: string, query_success: bool, results_url: string, start_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/action_notification_exports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# retry Action Webhook Failure
#
# POST /action_webhook_failures/{id}/retry
# operationId: PostActionWebhookFailuresIdRetry
export def "action-webhook-failures-retry create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/action_webhook_failures/{id}/retry"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete current API key. (Requires current API connection to be using an API key.)
#
# DELETE /api_key
# operationId: ApiKeyDeleteCurrent
export def "api-key delete-get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show information about current API key. (Requires current API connection to be using an API key.)
#
# GET /api_key
# operationId: ApiKeyFindCurrent
export def "api-key find-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update current API key. (Requires current API connection to be using an API key.)
#
# PATCH /api_key
# operationId: ApiKeyUpdateCurrent
export def "api-key update-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (e.g. full)
]: any -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_key")
  let req_body = {"expires_at": $expires_at, "name": $name, "permission_set": $permission_set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Api Keys
#
# GET /api_keys
# operationId: GetApiKeys
export def "api-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Api Key
#
# POST /api_keys
# operationId: PostApiKeys
export def "api-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys")
  let req_body = {"description": $description, "expires_at": $expires_at, "name": $name, "path": $path, "permission_set": $permission_set, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Api Key
#
# DELETE /api_keys/{id}
# operationId: DeleteApiKeysId
export def "api-keys delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api_keys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Api Key
#
# GET /api_keys/{id}
# operationId: GetApiKeysId
export def "api-keys get" [
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
]: nothing -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api_keys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Api Key
#
# PATCH /api_keys/{id}
# operationId: PatchApiKeysId
export def "api-keys update" [
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
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (e.g. full)
]: any -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api_keys/{id}"))
  let req_body = {"description": $description, "expires_at": $expires_at, "name": $name, "permission_set": $permission_set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Apps
#
# GET /apps
# operationId: GetApps
export def "apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[name]=desc`). Valid fields are `name` and `app_type`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `name` and `app_type`. Valid field combinations are `[ name, app_type ]` and `[ app_type, name ]`.
]: nothing -> table<app_type: string, documentation_links: record, extended_description: string, external_homepage_url: string, featured: bool, folder_behavior_type: string, icon_url: string, logo_thumbnail_url: string, logo_url: string, marketing_youtube_url: string, name: string, remote_server_type: string, screenshot_list_urls: list<string>, short_description: string, sso_strategy_type: string, tutorial_youtube_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List As2 Incoming Messages
#
# GET /as2_incoming_messages
# operationId: GetAs2IncomingMessages
export def "as2-incoming-messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `as2_partner_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --as2-partner-id: int # As2 Partner ID. If provided, will return message specific to that partner. (format: int32)
]: nothing -> table<activity_log: string, as2_from: string, as2_partner_id: int, as2_station_id: int, as2_to: string, attachment_filename: string, body_size: string, content_type: string, created_at: string, date: string, encrypted_uri: string, hex_recipient_serial: string, http_headers: record, http_response_code: string, http_response_headers: record, id: int, ip: string, mdn_response_uri: string, message_decrypted: bool, message_id: string, message_mdn_returned: bool, message_processing_success: bool, message_received: bool, message_signature_verified: bool, mic: string, mic_algo: string, processing_result: string, processing_result_description: string, raw_uri: string, recipient_issuer: string, recipient_serial: string, smime_signed_uri: string, smime_uri: string, subject: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "as2_partner_id" $as2_partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/as2_incoming_messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List As2 Outgoing Messages
#
# GET /as2_outgoing_messages
# operationId: GetAs2OutgoingMessages
export def "as2-outgoing-messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `as2_partner_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --as2-partner-id: int # As2 Partner ID. If provided, will return message specific to that partner. (format: int32)
]: nothing -> table<activity_log: string, as2_from: string, as2_partner_id: int, as2_station_id: int, as2_to: string, attachment_filename: string, body_size: string, created_at: string, date: string, encrypted_uri: string, http_headers: record, http_response_code: string, http_response_headers: record, http_transmission_duration: float, id: int, mdn_message_id_matched: bool, mdn_mic_matched: bool, mdn_processing_success: bool, mdn_received: bool, mdn_response_uri: string, mdn_signature_verified: bool, mdn_valid: bool, message_id: string, mic: string, mic_sha_256: string, processing_result: string, processing_result_description: string, raw_uri: string, smime_signed_uri: string, smime_uri: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "as2_partner_id" $as2_partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/as2_outgoing_messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List As2 Partners
#
# GET /as2_partners
# operationId: GetAs2Partners
export def "as2-partners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/as2_partners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create As2 Partner
#
# POST /as2_partners
# operationId: PostAs2Partners
export def "as2-partners create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  as2_station_id: int # Id of As2Station for this partner (format: int32)
  name: string # AS2 Name
  public_certificate: string
  --server-certificate: string # Remote server certificate security setting
  uri: string # URL base for AS2 responses
]: any -> record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/as2_partners")
  let req_body = {"as2_station_id": $as2_station_id, "name": $name, "public_certificate": $public_certificate, "server_certificate": $server_certificate, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete As2 Partner
#
# DELETE /as2_partners/{id}
# operationId: DeleteAs2PartnersId
export def "as2-partners delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/as2_partners/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show As2 Partner
#
# GET /as2_partners/{id}
# operationId: GetAs2PartnersId
export def "as2-partners get" [
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
]: nothing -> record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/as2_partners/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update As2 Partner
#
# PATCH /as2_partners/{id}
# operationId: PatchAs2PartnersId
export def "as2-partners update" [
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
  --name: string # AS2 Name
  --public-certificate: string
  --server-certificate: string # Remote server certificate security setting
  --uri: string # URL base for AS2 responses
]: any -> record<as2_station_id: int, hex_public_certificate_serial: string, id: int, name: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, server_certificate: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/as2_partners/{id}"))
  let req_body = {"name": $name, "public_certificate": $public_certificate, "server_certificate": $server_certificate, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List As2 Stations
#
# GET /as2_stations
# operationId: GetAs2Stations
export def "as2-stations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/as2_stations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create As2 Station
#
# POST /as2_stations
# operationId: PostAs2Stations
export def "as2-stations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # AS2 Name
  private_key: string
  --private-key-password: string
  public_certificate: string
]: any -> record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/as2_stations")
  let req_body = {"name": $name, "private_key": $private_key, "private_key_password": $private_key_password, "public_certificate": $public_certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete As2 Station
#
# DELETE /as2_stations/{id}
# operationId: DeleteAs2StationsId
export def "as2-stations delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/as2_stations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show As2 Station
#
# GET /as2_stations/{id}
# operationId: GetAs2StationsId
export def "as2-stations get" [
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
]: nothing -> record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/as2_stations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update As2 Station
#
# PATCH /as2_stations/{id}
# operationId: PatchAs2StationsId
export def "as2-stations update" [
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
  --name: string # AS2 Name
  --private-key: string
  --private-key-password: string
  --public-certificate: string
]: any -> record<domain: string, hex_public_certificate_serial: string, id: int, name: string, private_key_md5: string, private_key_password_md5: string, public_certificate_issuer: string, public_certificate_md5: string, public_certificate_not_after: string, public_certificate_not_before: string, public_certificate_serial: string, public_certificate_subject: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/as2_stations/{id}"))
  let req_body = {"name": $name, "private_key": $private_key, "private_key_password": $private_key_password, "public_certificate": $public_certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Automation Runs
#
# GET /automation_runs
# operationId: GetAutomationRuns
export def "automation-runs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `status`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `status`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `status`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `status`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `status`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `status`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `status`.
  --automation-id: int # ID of the associated Automation. (format: int32, e.g. 1)
]: nothing -> table<automation_id: int, completed_at: string, created_at: string, id: int, status: string, status_messages_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "automation_id" $automation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/automation_runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Automation Run
#
# GET /automation_runs/{id}
# operationId: GetAutomationRunsId
export def "automation-runs get" [
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
]: nothing -> record<automation_id: int, completed_at: string, created_at: string, id: int, status: string, status_messages_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/automation_runs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Automations
#
# GET /automations
# operationId: GetAutomations
export def "automations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[automation]=desc`). Valid fields are `automation`, `disabled`, `last_modified_at` or `name`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `automation`, `last_modified_at` or `disabled`. Valid field combinations are `[ automation, disabled ]` and `[ disabled, automation ]`.
  --with-deleted: oneof<nothing, bool> # Set to true to include deleted automations in the results.
  --automation: string # DEPRECATED: Type of automation to filter by. Use `filter[automation]` instead.
]: nothing -> table<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "with_deleted" $with_deleted "scalar") (serialize-qp "automation" $automation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/automations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Automation
#
# POST /automations
# operationId: PostAutomations
export def "automations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  automation: string@automation-completer # Automation type (e.g. create_folder)
  --description: string # Description for the this Automation. (e.g. example)
  --destination: string # DEPRECATED: Destination Path. Use `destinations` instead.
  --destination-replace-from: string # If set, this string in the destination path will be replaced with the value in `destination_replace_to`.
  --destination-replace-to: string # If set, this string will replace the value `destination_replace_from` in the destination filename. You can use special patterns here.
  --destinations: list<string> # A list of String destination paths or Hash of folder_path and optional file_path. (e.g. [folder_a/file_a.txt, {file_path: file_b.txt, folder_path: folder_b}, {folder_path: folder_c}])
  --disabled: oneof<nothing, bool> # If true, this automation will not run. (e.g. true)
  --group-ids: string # A list of group IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --interval: string # How often to run this automation? One of: `day`, `week`, `week_end`, `month`, `month_end`, `quarter`, `quarter_end`, `year`, `year_end` (e.g. year)
  --name: string # Name for this automation. (e.g. example)
  --path: string # Path on which this Automation runs. Supports globs.
  --schedule: record # Custom schedule for running this automation. (e.g. {days_of_week: [0, 1, 3], time_zone: Eastern Time (US & Canada), times_of_day: [7:30, 11:30]})
  --body-source: string # Source Path (e.g. source)
  --sync-ids: string # A list of sync IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --trigger: string@trigger-completer # How this automation is triggered to run. One of: `realtime`, `daily`, `custom_schedule`, `webhook`, `email`, or `action`. (e.g. realtime)
  --trigger-actions: list<string> # If trigger is `action`, this is the list of action types on which to trigger the automation. Valid actions are create, read, update, destroy, move, copy (e.g. [create])
  --user-ids: string # A list of user IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --value: record # A Hash of attributes specific to the automation type. (e.g. {limit: 1})
]: any -> record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automations")
  let req_body = {"automation": $automation, "description": $description, "destination": $destination, "destination_replace_from": $destination_replace_from, "destination_replace_to": $destination_replace_to, "destinations": $destinations, "disabled": $disabled, "group_ids": $group_ids, "interval": $interval, "name": $name, "path": $path, "schedule": $schedule, "source": $body_source, "sync_ids": $sync_ids, "trigger": $trigger, "trigger_actions": $trigger_actions, "user_ids": $user_ids, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Automation
#
# DELETE /automations/{id}
# operationId: DeleteAutomationsId
export def "automations delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/automations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Automation
#
# GET /automations/{id}
# operationId: GetAutomationsId
export def "automations get" [
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
]: nothing -> record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/automations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Automation
#
# PATCH /automations/{id}
# operationId: PatchAutomationsId
export def "automations update" [
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
  --automation: string@automation-completer # Automation type (e.g. create_folder)
  --description: string # Description for the this Automation. (e.g. example)
  --destination: string # DEPRECATED: Destination Path. Use `destinations` instead.
  --destination-replace-from: string # If set, this string in the destination path will be replaced with the value in `destination_replace_to`.
  --destination-replace-to: string # If set, this string will replace the value `destination_replace_from` in the destination filename. You can use special patterns here.
  --destinations: list<string> # A list of String destination paths or Hash of folder_path and optional file_path. (e.g. [folder_a/file_a.txt, {file_path: file_b.txt, folder_path: folder_b}, {folder_path: folder_c}])
  --disabled: oneof<nothing, bool> # If true, this automation will not run. (e.g. true)
  --group-ids: string # A list of group IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --interval: string # How often to run this automation? One of: `day`, `week`, `week_end`, `month`, `month_end`, `quarter`, `quarter_end`, `year`, `year_end` (e.g. year)
  --name: string # Name for this automation. (e.g. example)
  --path: string # Path on which this Automation runs. Supports globs.
  --schedule: record # Custom schedule for running this automation. (e.g. {days_of_week: [0, 1, 3], time_zone: Eastern Time (US & Canada), times_of_day: [7:30, 11:30]})
  --body-source: string # Source Path (e.g. source)
  --sync-ids: string # A list of sync IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --trigger: string@trigger-completer # How this automation is triggered to run. One of: `realtime`, `daily`, `custom_schedule`, `webhook`, `email`, or `action`. (e.g. realtime)
  --trigger-actions: list<string> # If trigger is `action`, this is the list of action types on which to trigger the automation. Valid actions are create, read, update, destroy, move, copy (e.g. [create])
  --user-ids: string # A list of user IDs the automation is associated with. If sent as a string, it should be comma-delimited.
  --value: record # A Hash of attributes specific to the automation type. (e.g. {limit: 1})
]: any -> record<automation: string, deleted: bool, description: string, destination_replace_from: string, destination_replace_to: string, destinations: list<string>, disabled: bool, group_ids: list<int>, id: int, interval: string, last_modified_at: string, name: string, path: string, schedule: record, source: string, sync_ids: list<int>, trigger: string, trigger_actions: list<string>, user_id: int, user_ids: list<int>, value: record, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/automations/{id}"))
  let req_body = {"automation": $automation, "description": $description, "destination": $destination, "destination_replace_from": $destination_replace_from, "destination_replace_to": $destination_replace_to, "destinations": $destinations, "disabled": $disabled, "group_ids": $group_ids, "interval": $interval, "name": $name, "path": $path, "schedule": $schedule, "source": $body_source, "sync_ids": $sync_ids, "trigger": $trigger, "trigger_actions": $trigger_actions, "user_ids": $user_ids, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Bandwidth Snapshots
#
# GET /bandwidth_snapshots
# operationId: GetBandwidthSnapshots
export def "bandwidth-snapshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[logged_at]=desc`). Valid fields are `logged_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `logged_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `logged_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `logged_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `logged_at`.
]: nothing -> table<bytes_received: float, bytes_sent: float, id: int, logged_at: string, requests_get: float, requests_other: float, requests_put: float, sync_bytes_received: float, sync_bytes_sent: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/bandwidth_snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Behaviors
#
# GET /behaviors
# operationId: GetBehaviors
export def "behaviors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[behavior]=desc`). Valid fields are `behavior`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `behavior`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `behavior`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `behavior`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `behavior`.
  --behavior: string # If set, only shows folder behaviors matching this behavior type.
]: nothing -> table<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "behavior" $behavior "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/behaviors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Behavior
#
# POST /behaviors
# operationId: PostBehaviors
export def "behaviors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment-file: string # Certain behaviors may require a file, for instance, the "watermark" behavior requires a watermark image (format: binary)
  behavior: string # Behavior type. (e.g. webhook)
  --description: string # Description for this behavior. (e.g. example)
  --name: string # Name for this behavior. (e.g. example)
  path: string # Folder behaviors path.
  --value: string # The value of the folder behavior. Can be a integer, array, or hash depending on the type of folder behavior. See The Behavior Types section for example values for each type of behavior. (e.g. {"method": "GET"})
]: any -> record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/behaviors")
  let req_body = {"attachment_file": $attachment_file, "behavior": $behavior, "description": $description, "name": $name, "path": $path, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["attachment_file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Behaviors by path
#
# GET /behaviors/folders/{path}
# operationId: BehaviorListForPath
export def "behaviors-folders list" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[behavior]=desc`). Valid fields are `behavior`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `behavior`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `behavior`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `behavior`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `behavior`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `behavior`.
  --recursive: string # Show behaviors above this path?
  --behavior: string # DEPRECATED: If set only shows folder behaviors matching this behavior type. Use `filter[behavior]` instead.
]: nothing -> table<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "behavior" $behavior "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/behaviors/folders/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Test webhook.
#
# POST /behaviors/webhook/test
# operationId: PostBehaviorsWebhookTest
export def "behaviors-webhook-test create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action for test body (e.g. test)
  --body: record # Additional body parameters. (e.g. {test-param: testvalue})
  --encoding: string # HTTP encoding method. Can be JSON, XML, or RAW (form data). (e.g. RAW)
  --headers: record # Additional request headers. (e.g. {x-test-header: testvalue})
  --method: string # HTTP method(GET or POST). (e.g. GET)
  url: string # URL for testing the webhook. (e.g. https://www.site.com/...)
]: any -> record<clickwrap_body: string, clickwrap_id: int, code: int, data: record<dynamic: record>, errors: table<fields: list, messages: list>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/behaviors/webhook/test")
  let req_body = {"action": $action, "body": $body, "encoding": $encoding, "headers": $headers, "method": $method, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Behavior
#
# DELETE /behaviors/{id}
# operationId: DeleteBehaviorsId
export def "behaviors delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/behaviors/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Behavior
#
# GET /behaviors/{id}
# operationId: GetBehaviorsId
export def "behaviors get" [
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
]: nothing -> record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/behaviors/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Behavior
#
# PATCH /behaviors/{id}
# operationId: PatchBehaviorsId
export def "behaviors update" [
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
  --attachment-delete: oneof<nothing, bool> # If true, will delete the file stored in attachment
  --attachment-file: string # Certain behaviors may require a file, for instance, the "watermark" behavior requires a watermark image (format: binary)
  --behavior: string # Behavior type. (e.g. webhook)
  --description: string # Description for this behavior. (e.g. example)
  --name: string # Name for this behavior. (e.g. example)
  --path: string # Folder behaviors path.
  --value: string # The value of the folder behavior. Can be a integer, array, or hash depending on the type of folder behavior. See The Behavior Types section for example values for each type of behavior. (e.g. {"method": "GET"})
]: any -> record<attachment_url: string, behavior: string, description: string, id: int, name: string, path: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/behaviors/{id}"))
  let req_body = {"attachment_delete": $attachment_delete, "attachment_file": $attachment_file, "behavior": $behavior, "description": $description, "name": $name, "path": $path, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["attachment_file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Bundle Downloads
#
# GET /bundle_downloads
# operationId: GetBundleDownloads
export def "bundle-downloads get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --bundle-id: int # Bundle ID (format: int32)
  --bundle-registration-id: int # BundleRegistration ID (format: int32)
]: nothing -> table<bundle_registration: record<bundle_code: string, bundle_id: int, bundle_recipient_id: int, clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_code: string, ip: string, name: string>, created_at: string, download_method: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "bundle_id" $bundle_id "scalar") (serialize-qp "bundle_registration_id" $bundle_registration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bundle_downloads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Bundle Notifications
#
# GET /bundle_notifications
# operationId: GetBundleNotifications
export def "bundle-notifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --bundle-id: int # Bundle ID to notify on (format: int32, e.g. 1)
]: nothing -> table<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "bundle_id" $bundle_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bundle_notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Bundle Notification
#
# POST /bundle_notifications
# operationId: PostBundleNotifications
export def "bundle-notifications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: int # Bundle ID to notify on (format: int32, e.g. 1)
  --notify-on-registration: oneof<nothing, bool> # Triggers bundle notification when a registration action occurs for it. (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers bundle notification when a upload action occurs for it. (e.g. true)
  --user-id: int # The id of the user to notify. (format: int32, e.g. 1)
]: any -> record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bundle_notifications")
  let req_body = {"bundle_id": $bundle_id, "notify_on_registration": $notify_on_registration, "notify_on_upload": $notify_on_upload, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Bundle Notification
#
# DELETE /bundle_notifications/{id}
# operationId: DeleteBundleNotificationsId
export def "bundle-notifications delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundle_notifications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Bundle Notification
#
# GET /bundle_notifications/{id}
# operationId: GetBundleNotificationsId
export def "bundle-notifications get" [
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
]: nothing -> record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundle_notifications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Bundle Notification
#
# PATCH /bundle_notifications/{id}
# operationId: PatchBundleNotificationsId
export def "bundle-notifications update" [
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
  --notify-on-registration: oneof<nothing, bool> # Triggers bundle notification when a registration action occurs for it. (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers bundle notification when a upload action occurs for it. (e.g. true)
]: any -> record<bundle_id: int, id: int, notify_on_registration: bool, notify_on_upload: bool, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundle_notifications/{id}"))
  let req_body = {"notify_on_registration": $notify_on_registration, "notify_on_upload": $notify_on_upload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Bundle Recipients
#
# GET /bundle_recipients
# operationId: GetBundleRecipients
export def "bundle-recipients get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[has_registrations]=desc`). Valid fields are `has_registrations`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `has_registrations`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `has_registrations`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `has_registrations`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `has_registrations`.
  --bundle-id: int # List recipients for the bundle with this ID. (format: int32)
]: nothing -> table<company: string, name: string, note: string, recipient: string, sent_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "bundle_id" $bundle_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bundle_recipients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Bundle Recipient
#
# POST /bundle_recipients
# operationId: PostBundleRecipients
export def "bundle-recipients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: int # Bundle to share. (format: int32)
  --company: string # Company of recipient. (e.g. Acme Ltd)
  --name: string # Name of recipient. (e.g. John Smith)
  --note: string # Note to include in email. (e.g. Just a note.)
  recipient: string # Email addresses to share this bundle with. (e.g. johndoe@gmail.com)
  --share-after-create: oneof<nothing, bool> # Set to true to share the link with the recipient upon creation.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<company: string, name: string, note: string, recipient: string, sent_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bundle_recipients")
  let req_body = {"bundle_id": $bundle_id, "company": $company, "name": $name, "note": $note, "recipient": $recipient, "share_after_create": $share_after_create, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Bundle Registrations
#
# GET /bundle_registrations
# operationId: GetBundleRegistrations
export def "bundle-registrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --bundle-id: int # ID of the associated Bundle (format: int32)
]: nothing -> table<bundle_code: string, bundle_id: int, bundle_recipient_id: int, clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_code: string, ip: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "bundle_id" $bundle_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bundle_registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Bundles
#
# GET /bundles
# operationId: GetBundles
export def "bundles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at` and `code`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
]: nothing -> table<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list, form_layout: list, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/bundles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Bundle
#
# POST /bundles
# operationId: PostBundles
export def "bundles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clickwrap-id: int # ID of the clickwrap to use with this bundle. (format: int32, e.g. 1)
  --code: string # Bundle code. This code forms the end part of the Public URL. (e.g. abc123)
  --description: string # Public description (e.g. The public description of the bundle.)
  --dont-separate-submissions-by-folder: oneof<nothing, bool> # Do not create subfolders for files uploaded to this share. Note: there are subtle security pitfalls with allowing anonymous uploads from multiple users to live in the same folder. We strongly discourage use of this option unless absolutely required. (e.g. true)
  --expires-at: string # Bundle expiration date/time (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --form-field-set-id: int # Id of Form Field Set to use with this bundle (format: int32)
  --inbox-id: int # ID of the associated inbox, if available. (format: int32, e.g. 1)
  --max-uses: int # Maximum number of times bundle can be accessed (format: int32, e.g. 1)
  --note: string # Bundle internal note (e.g. The internal note on the bundle.)
  --password: string # Password for this bundle. (e.g. Password)
  --path-template: string # Template for creating submission subfolders. Can use the uploader's name, email address, ip, company, and any custom form data. (e.g. {{name}}_{{ip}})
  paths: list<string> # A list of paths to include in this bundle. (e.g. [file.txt])
  --permissions: string@permissions-completer # Permissions that apply to Folders in this Share Link. (e.g. read)
  --preview-only: oneof<nothing, bool> # Restrict users to previewing files only?
  --require-registration: oneof<nothing, bool> # Show a registration page that captures the downloader's name and email address?
  --require-share-recipient: oneof<nothing, bool> # Only allow access to recipients who have explicitly received the share via an email sent through the Files.com UI?
  --send-email-receipt-to-uploader: oneof<nothing, bool> # Send delivery receipt to the uploader. Note: For writable share only (e.g. true)
  --skip-company: oneof<nothing, bool> # BundleRegistrations can be saved without providing company? (e.g. true)
  --skip-email: oneof<nothing, bool> # BundleRegistrations can be saved without providing email? (e.g. true)
  --skip-name: oneof<nothing, bool> # BundleRegistrations can be saved without providing name? (e.g. true)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --watermark-attachment-file: string # Preview watermark image applied to all bundle items. (format: binary)
]: any -> record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bundles")
  let req_body = {"clickwrap_id": $clickwrap_id, "code": $code, "description": $description, "dont_separate_submissions_by_folder": $dont_separate_submissions_by_folder, "expires_at": $expires_at, "form_field_set_id": $form_field_set_id, "inbox_id": $inbox_id, "max_uses": $max_uses, "note": $note, "password": $password, "path_template": $path_template, "paths": $paths, "permissions": $permissions, "preview_only": $preview_only, "require_registration": $require_registration, "require_share_recipient": $require_share_recipient, "send_email_receipt_to_uploader": $send_email_receipt_to_uploader, "skip_company": $skip_company, "skip_email": $skip_email, "skip_name": $skip_name, "user_id": $user_id, "watermark_attachment_file": $watermark_attachment_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["watermark_attachment_file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Bundle
#
# DELETE /bundles/{id}
# operationId: DeleteBundlesId
export def "bundles delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Bundle
#
# GET /bundles/{id}
# operationId: GetBundlesId
export def "bundles get" [
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
]: nothing -> record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Bundle
#
# PATCH /bundles/{id}
# operationId: PatchBundlesId
export def "bundles update" [
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
  --clickwrap-id: int # ID of the clickwrap to use with this bundle. (format: int32, e.g. 1)
  --code: string # Bundle code. This code forms the end part of the Public URL. (e.g. abc123)
  --description: string # Public description (e.g. The public description of the bundle.)
  --dont-separate-submissions-by-folder: oneof<nothing, bool> # Do not create subfolders for files uploaded to this share. Note: there are subtle security pitfalls with allowing anonymous uploads from multiple users to live in the same folder. We strongly discourage use of this option unless absolutely required. (e.g. true)
  --expires-at: string # Bundle expiration date/time (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --form-field-set-id: int # Id of Form Field Set to use with this bundle (format: int32)
  --inbox-id: int # ID of the associated inbox, if available. (format: int32, e.g. 1)
  --max-uses: int # Maximum number of times bundle can be accessed (format: int32, e.g. 1)
  --note: string # Bundle internal note (e.g. The internal note on the bundle.)
  --password: string # Password for this bundle. (e.g. Password)
  --path-template: string # Template for creating submission subfolders. Can use the uploader's name, email address, ip, company, and any custom form data. (e.g. {{name}}_{{ip}})
  --paths: list<string> # A list of paths to include in this bundle. (e.g. [file.txt])
  --permissions: string@permissions-completer # Permissions that apply to Folders in this Share Link. (e.g. read)
  --preview-only: oneof<nothing, bool> # Restrict users to previewing files only?
  --require-registration: oneof<nothing, bool> # Show a registration page that captures the downloader's name and email address?
  --require-share-recipient: oneof<nothing, bool> # Only allow access to recipients who have explicitly received the share via an email sent through the Files.com UI?
  --send-email-receipt-to-uploader: oneof<nothing, bool> # Send delivery receipt to the uploader. Note: For writable share only (e.g. true)
  --skip-company: oneof<nothing, bool> # BundleRegistrations can be saved without providing company? (e.g. true)
  --skip-email: oneof<nothing, bool> # BundleRegistrations can be saved without providing email? (e.g. true)
  --skip-name: oneof<nothing, bool> # BundleRegistrations can be saved without providing name? (e.g. true)
  --watermark-attachment-delete: oneof<nothing, bool> # If true, will delete the file stored in watermark_attachment
  --watermark-attachment-file: string # Preview watermark image applied to all bundle items. (format: binary)
]: any -> record<clickwrap_body: string, clickwrap_id: int, code: string, created_at: string, description: string, dont_separate_submissions_by_folder: bool, expires_at: string, form_field_set: record<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string>, has_inbox: bool, id: int, inbox_id: int, max_uses: int, note: string, password_protected: bool, path_template: string, paths: list<string>, permissions: string, preview_only: bool, require_registration: bool, require_share_recipient: bool, send_email_receipt_to_uploader: bool, skip_company: bool, skip_email: bool, skip_name: bool, url: string, user_id: int, username: string, watermark_attachment: record<name: string, uri: string>, watermark_value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundles/{id}"))
  let req_body = {"clickwrap_id": $clickwrap_id, "code": $code, "description": $description, "dont_separate_submissions_by_folder": $dont_separate_submissions_by_folder, "expires_at": $expires_at, "form_field_set_id": $form_field_set_id, "inbox_id": $inbox_id, "max_uses": $max_uses, "note": $note, "password": $password, "path_template": $path_template, "paths": $paths, "permissions": $permissions, "preview_only": $preview_only, "require_registration": $require_registration, "require_share_recipient": $require_share_recipient, "send_email_receipt_to_uploader": $send_email_receipt_to_uploader, "skip_company": $skip_company, "skip_email": $skip_email, "skip_name": $skip_name, "watermark_attachment_delete": $watermark_attachment_delete, "watermark_attachment_file": $watermark_attachment_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["watermark_attachment_file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Send email(s) with a link to bundle
#
# POST /bundles/{id}/share
# operationId: PostBundlesIdShare
export def "bundles-share create" [
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
  --note: string # Note to include in email. (e.g. Just a note.)
  --recipients: list # A list of recipients to share this bundle with. Required unless `to` is used. (e.g. [{company: Acme Ltd, name: John Doe, recipient: johndoe@gmail.com}])
  --body-to: list<string> # A list of email addresses to share this bundle with. Required unless `recipients` is used. (e.g. [johndoe@gmail.com])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundles/{id}/share"))
  let req_body = {"note": $note, "recipients": $recipients, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Clickwraps
#
# GET /clickwraps
# operationId: GetClickwraps
export def "clickwraps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clickwraps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Clickwrap
#
# POST /clickwraps
# operationId: PostClickwraps
export def "clickwraps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # Body text of Clickwrap (supports Markdown formatting). (e.g. [Legal body text])
  --name: string # Name of the Clickwrap agreement (used when selecting from multiple Clickwrap agreements.) (e.g. Example Site NDA for Files.com Use)
  --use-with-bundles: string@use-with-bundles-completer # Use this Clickwrap for Bundles? (e.g. example)
  --use-with-inboxes: string@use-with-inboxes-completer # Use this Clickwrap for Inboxes? (e.g. example)
  --use-with-users: string@use-with-users-completer # Use this Clickwrap for User Registrations? Note: This only applies to User Registrations where the User is invited to your Files.com site using an E-Mail invitation process where they then set their own password. (e.g. example)
]: any -> record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clickwraps")
  let req_body = {"body": $body, "name": $name, "use_with_bundles": $use_with_bundles, "use_with_inboxes": $use_with_inboxes, "use_with_users": $use_with_users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Clickwrap
#
# DELETE /clickwraps/{id}
# operationId: DeleteClickwrapsId
export def "clickwraps delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/clickwraps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Clickwrap
#
# GET /clickwraps/{id}
# operationId: GetClickwrapsId
export def "clickwraps get" [
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
]: nothing -> record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/clickwraps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Clickwrap
#
# PATCH /clickwraps/{id}
# operationId: PatchClickwrapsId
export def "clickwraps update" [
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
  --body: string # Body text of Clickwrap (supports Markdown formatting). (e.g. [Legal body text])
  --name: string # Name of the Clickwrap agreement (used when selecting from multiple Clickwrap agreements.) (e.g. Example Site NDA for Files.com Use)
  --use-with-bundles: string@use-with-bundles-completer # Use this Clickwrap for Bundles? (e.g. example)
  --use-with-inboxes: string@use-with-inboxes-completer # Use this Clickwrap for Inboxes? (e.g. example)
  --use-with-users: string@use-with-users-completer # Use this Clickwrap for User Registrations? Note: This only applies to User Registrations where the User is invited to your Files.com site using an E-Mail invitation process where they then set their own password. (e.g. example)
]: any -> record<body: string, id: int, name: string, use_with_bundles: string, use_with_inboxes: string, use_with_users: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/clickwraps/{id}"))
  let req_body = {"body": $body, "name": $name, "use_with_bundles": $use_with_bundles, "use_with_inboxes": $use_with_inboxes, "use_with_users": $use_with_users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show site DNS configuration.
#
# GET /dns_records
# operationId: GetDnsRecords
export def "dns-records get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<domain: string, id: string, rrtype: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dns_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List External Events
#
# GET /external_events
# operationId: GetExternalEvents
export def "external-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[remote_server_type]=desc`). Valid fields are `remote_server_type`, `site_id`, `folder_behavior_id`, `event_type`, `created_at` or `status`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`, `event_type`, `remote_server_type`, `status` or `folder_behavior_id`. Valid field combinations are `[ event_type, status, created_at ]`, `[ event_type, created_at ]` or `[ status, created_at ]`.
]: nothing -> table<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/external_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create External Event
#
# POST /external_events
# operationId: PostExternalEvents
export def "external-events create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Event body (e.g. example)
  status: string@status-completer # Status of event. (e.g. example)
]: any -> record<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/external_events")
  let req_body = {"body": $body, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show External Event
#
# GET /external_events/{id}
# operationId: GetExternalEventsId
export def "external-events get" [
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
]: nothing -> record<body: string, body_url: string, bytes_synced: int, created_at: string, errored_files: int, event_type: string, folder_behavior_id: int, id: int, remote_server_type: string, status: string, successful_files: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/external_events/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Begin file upload
#
# POST /file_actions/begin_upload/{path}
# operationId: FileActionBeginUpload
export def "file-actions-begin-upload upload" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mkdir-parents: oneof<nothing, bool> # Create parent directories if they do not exist?
  --part: int # Part if uploading a part. (format: int32)
  --parts: int # How many parts to fetch? (format: int32)
  --ref: string
  --restart: int # File byte offset to restart from. (format: int32)
  --size: int # Total bytes of file being uploaded (include bytes being retained if appending/restarting). (format: int32)
  --with-rename: oneof<nothing, bool> # Allow file rename instead of overwrite?
]: any -> table<action: string, ask_about_overwrites: bool, available_parts: int, expires: string, headers: record, http_method: string, next_partsize: int, parallel_parts: bool, parameters: record, part_number: int, partsize: int, path: string, ref: string, send: record, upload_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/file_actions/begin_upload/{path}"))
  let req_body = {"mkdir_parents": $mkdir_parents, "part": $part, "parts": $parts, "ref": $ref, "restart": $restart, "size": $size, "with_rename": $with_rename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Copy file/folder
#
# POST /file_actions/copy/{path}
# operationId: FileActionCopy
export def "file-actions-copy copy" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Copy destination path.
  --structure: oneof<nothing, bool> # Copy structure only?
]: any -> record<file_migration_id: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/file_actions/copy/{path}"))
  let req_body = {"destination": $destination, "structure": $structure} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Find file/folder by path
#
# GET /file_actions/metadata/{path}
# operationId: FileActionFind
export def "file-actions-metadata find" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preview-size: string # Request a preview size. Can be `small` (default), `large`, `xlarge`, or `pdf`.
  --with-previews: oneof<nothing, bool> # Include file preview information?
  --with-priority-color: oneof<nothing, bool> # Include file priority color information?
]: nothing -> record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, subfolders_locked_: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preview_size" $preview_size "scalar") (serialize-qp "with_previews" $with_previews "scalar") (serialize-qp "with_priority_color" $with_priority_color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/file_actions/metadata/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Move file/folder
#
# POST /file_actions/move/{path}
# operationId: FileActionMove
export def "file-actions-move move" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Move destination path.
]: any -> record<file_migration_id: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/file_actions/move/{path}"))
  let req_body = {"destination": $destination} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create File Comment Reaction
#
# POST /file_comment_reactions
# operationId: PostFileCommentReactions
export def "file-comment-reactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji: string # Emoji to react with.
  file_comment_id: int # ID of file comment to attach reaction to. (format: int32)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<emoji: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file_comment_reactions")
  let req_body = {"emoji": $emoji, "file_comment_id": $file_comment_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete File Comment Reaction
#
# DELETE /file_comment_reactions/{id}
# operationId: DeleteFileCommentReactionsId
export def "file-comment-reactions delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/file_comment_reactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create File Comment
#
# POST /file_comments
# operationId: PostFileComments
export def "file-comments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Comment body.
  path: string # File path.
]: any -> record<body: string, id: int, reactions: table<emoji: string, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/file_comments")
  let req_body = {"body": $body, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List File Comments by path
#
# GET /file_comments/files/{path}
# operationId: FileCommentListForPath
export def "file-comments-files list" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<body: string, id: int, reactions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/file_comments/files/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete File Comment
#
# DELETE /file_comments/{id}
# operationId: DeleteFileCommentsId
export def "file-comments delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/file_comments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update File Comment
#
# PATCH /file_comments/{id}
# operationId: PatchFileCommentsId
export def "file-comments update" [
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
  body: string # Comment body.
]: any -> record<body: string, id: int, reactions: table<emoji: string, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/file_comments/{id}"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show File Migration
#
# GET /file_migrations/{id}
# operationId: GetFileMigrationsId
export def "file-migrations get" [
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
]: nothing -> record<dest_path: string, files_moved: int, files_total: int, id: int, log_url: string, operation: string, path: string, region: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/file_migrations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete file/folder
#
# DELETE /files/{path}
# operationId: DeleteFilesPath
export def "files delete" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # If true, will recursively delete folers. Otherwise, will error on non-empty folders.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recursive" $recursive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/files/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download file
#
# GET /files/{path}
# operationId: FileDownload
export def "files download" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # Can be blank, `redirect` or `stat`. If set to `stat`, we will return file information but without a download URL, and without logging a download. If set to `redirect` we will serve a 302 redirect directly to the file. This is used for integrations with Zapier, and is not recommended for most integrations.
  --preview-size: string # Request a preview size. Can be `small` (default), `large`, `xlarge`, or `pdf`.
  --with-previews: oneof<nothing, bool> # Include file preview information?
  --with-priority-color: oneof<nothing, bool> # Include file priority color information?
]: nothing -> record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, subfolders_locked_: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "preview_size" $preview_size "scalar") (serialize-qp "with_previews" $with_previews "scalar") (serialize-qp "with_priority_color" $with_priority_color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/files/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update file/folder metadata
#
# PATCH /files/{path}
# operationId: PatchFilesPath
export def "files update" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority-color: string # Priority/Bookmark color of file. (e.g. red)
  --provided-mtime: string # Modified time of file. (format: date-time)
]: any -> record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, subfolders_locked_: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/files/{path}"))
  let req_body = {"priority_color": $priority_color, "provided_mtime": $provided_mtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Upload file
#
# POST /files/{path}
# operationId: PostFilesPath
export def "files create" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # The action to perform. Can be `append`, `attachment`, `end`, `upload`, `put`, or may not exist
  etags_etag: list<string> # etag identifier.
  etags_part: list<int> # Part number.
  --length: int # Length of file. (format: int32)
  --mkdir-parents: oneof<nothing, bool> # Create parent directories if they do not exist?
  --part: int # Part if uploading a part. (format: int32)
  --parts: int # How many parts to fetch? (format: int32)
  --provided-mtime: string # User provided modification time. (format: date-time)
  --ref: string
  --restart: int # File byte offset to restart from. (format: int32)
  --size: int # Size of file. (format: int32)
  --structure: string # If copying folder, copy just the structure?
  --with-rename: oneof<nothing, bool> # Allow file rename instead of overwrite?
]: any -> record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, subfolders_locked_: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/files/{path}"))
  let req_body = {"action": $action, "etags[etag]": $etags_etag, "etags[part]": $etags_part, "length": $length, "mkdir_parents": $mkdir_parents, "part": $part, "parts": $parts, "provided_mtime": $provided_mtime, "ref": $ref, "restart": $restart, "size": $size, "structure": $structure, "with_rename": $with_rename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Folders by path
#
# GET /folders/{path}
# operationId: FolderListForPath
export def "folders list" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Send cursor to resume an existing list from the point at which you left off. Get a cursor from an existing list via the X-Files-Cursor-Next header or the X-Files-Cursor-Prev header.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --filter: string # If specified, will filter folders/files list by this string. Wildcards of `*` and `?` are acceptable here.
  --preview-size: string # Request a preview size. Can be `small` (default), `large`, `xlarge`, or `pdf`.
  --search: string # If `search_all` is `true`, provide the search string here. Otherwise, this parameter acts like an alias of `filter`.
  --search-all: oneof<nothing, bool> # Search entire site? If set, we will ignore the folder path provided and search the entire site. This is the same API used by the search bar in the UI. Search results are a best effort, not real time, and not guaranteed to match every file. This field should only be used for ad-hoc (human) searching, and not as part of an automated process.
  --with-previews: oneof<nothing, bool> # Include file previews?
  --with-priority-color: oneof<nothing, bool> # Include file priority color information?
]: nothing -> table<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, subfolders_locked_: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "preview_size" $preview_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "search_all" $search_all "scalar") (serialize-qp "with_previews" $with_previews "scalar") (serialize-qp "with_priority_color" $with_priority_color "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/folders/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create folder
#
# POST /folders/{path}
# operationId: PostFoldersPath
export def "folders create" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mkdir-parents: oneof<nothing, bool> # Create parent directories if they do not exist?
  --provided-mtime: string # User provided modification time. (format: date-time)
]: any -> record<crc32: string, created_at: string, display_name: string, download_uri: string, is_locked: bool, md5: string, mime_type: string, mtime: string, path: string, permissions: string, preview: record<download_uri: string, id: int, size: string, status: string, type: string>, preview_id: int, priority_color: string, provided_mtime: string, region: string, size: int, subfolders_locked_: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/folders/{path}"))
  let req_body = {"mkdir_parents": $mkdir_parents, "provided_mtime": $provided_mtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Form Field Sets
#
# GET /form_field_sets
# operationId: GetFormFieldSets
export def "form-field-sets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<form_fields: list<record>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/form_field_sets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Form Field Set
#
# POST /form_field_sets
# operationId: PostFormFieldSets
# --form_fields item shape: {default_option?: string, field_type?: string, help_text?: string, id?: int, label?: string, options_for_select?: string, required?: bool}
export def "form-field-sets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-fields: list # item shape: {default_option?: string, field_type?: string, help_text?: string, id?: int, label?: string, options_for_select?: string, required?: bool}
  --skip-company: oneof<nothing, bool> # Skip validating company
  --skip-email: oneof<nothing, bool> # Skip validating form email
  --skip-name: oneof<nothing, bool> # Skip validating form name
  --title: string # Title to be displayed
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/form_field_sets")
  let req_body = {"form_fields": $form_fields, "skip_company": $skip_company, "skip_email": $skip_email, "skip_name": $skip_name, "title": $title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Form Field Set
#
# DELETE /form_field_sets/{id}
# operationId: DeleteFormFieldSetsId
export def "form-field-sets delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/form_field_sets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Form Field Set
#
# GET /form_field_sets/{id}
# operationId: GetFormFieldSetsId
export def "form-field-sets get" [
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
]: nothing -> record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/form_field_sets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Form Field Set
#
# PATCH /form_field_sets/{id}
# operationId: PatchFormFieldSetsId
# --form_fields item shape: {default_option?: string, field_type?: string, help_text?: string, id?: int, label?: string, options_for_select?: string, required?: bool}
export def "form-field-sets update" [
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
  --form-fields: list # item shape: {default_option?: string, field_type?: string, help_text?: string, id?: int, label?: string, options_for_select?: string, required?: bool}
  --skip-company: oneof<nothing, bool> # Skip validating company
  --skip-email: oneof<nothing, bool> # Skip validating form email
  --skip-name: oneof<nothing, bool> # Skip validating form name
  --title: string # Title to be displayed
]: any -> record<form_fields: table<default_option: string, field_type: string, form_field_set_id: int, help_text: string, id: int, label: string, options_for_select: list, required: bool>, form_layout: list<int>, id: int, skip_company: bool, skip_email: bool, skip_name: bool, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/form_field_sets/{id}"))
  let req_body = {"form_fields": $form_fields, "skip_company": $skip_company, "skip_email": $skip_email, "skip_name": $skip_name, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Group Users
#
# GET /group_users
# operationId: GetGroupUsers
export def "group-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. If provided, will return group_users of this user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --group-id: int # Group ID. If provided, will return group_users of this group. (format: int32)
]: nothing -> table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/group_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Group User
#
# POST /group_users
# operationId: PostGroupUsers
export def "group-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool> # Is the user a group administrator?
  group_id: int # Group ID to add user to. (format: int32)
  user_id: int # User ID to add to group. (format: int32)
]: any -> record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/group_users")
  let req_body = {"admin": $admin, "group_id": $group_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Group User
#
# DELETE /group_users/{id}
# operationId: DeleteGroupUsersId
export def "group-users delete" [
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
  --group-id: int # Group ID from which to remove user. (format: int32)
  --user-id: int # User ID to remove from group. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_id" $group_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/group_users/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Group User
#
# PATCH /group_users/{id}
# operationId: PatchGroupUsersId
export def "group-users update" [
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
  --admin: oneof<nothing, bool> # Is the user a group administrator?
  group_id: int # Group ID to add user to. (format: int32)
  user_id: int # User ID to add to group. (format: int32)
]: any -> record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/group_users/{id}"))
  let req_body = {"admin": $admin, "group_id": $group_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Groups
#
# GET /groups
# operationId: GetGroups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[name]=desc`). Valid fields are `name`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `name`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `name`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `name`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `name`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `name`.
  --ids: string # Comma-separated list of group ids to include in results.
]: nothing -> table<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Group
#
# POST /groups
# operationId: PostGroups
export def "groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-ids: string # A list of group admin user ids. If sent as a string, should be comma-delimited.
  --name: string # Group name.
  --notes: string # Group notes.
  --user-ids: string # A list of user ids. If sent as a string, should be comma-delimited.
]: any -> record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let req_body = {"admin_ids": $admin_ids, "name": $name, "notes": $notes, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Group User
#
# DELETE /groups/{group_id}/memberships/{user_id}
# operationId: DeleteGroupsGroupIdMembershipsUserId
export def "groups-memberships delete" [
  group_id: int
  user_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), user_id: (encode-path-segment $user_id)} | format pattern "/groups/{group_id}/memberships/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Group User
#
# PATCH /groups/{group_id}/memberships/{user_id}
# operationId: PatchGroupsGroupIdMembershipsUserId
export def "groups-memberships update" [
  group_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool> # Is the user a group administrator?
]: any -> record<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), user_id: (encode-path-segment $user_id)} | format pattern "/groups/{group_id}/memberships/{user_id}"))
  let req_body = {"admin": $admin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Permissions
#
# GET /groups/{group_id}/permissions
# operationId: GetGroupsGroupIdPermissions
export def "groups-permissions get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[group_id]=desc`). Valid fields are `group_id`, `path`, `user_id` or `permission`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --path: string # DEPRECATED: Permission path. If provided, will scope permissions to this path. Use `filter[path]` instead.
  --user-id: string # DEPRECATED: User ID. If provided, will scope permissions to this user. Use `filter[user_id]` instead.`
  --include-groups: oneof<nothing, bool> # If searching by user or group, also include user's permissions that are inherited from its groups?
]: nothing -> table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "path" $path "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "include_groups" $include_groups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Group Users
#
# GET /groups/{group_id}/users
# operationId: GetGroupsGroupIdUsers
export def "groups-users get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. If provided, will return group_users of this user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create User
#
# POST /groups/{group_id}/users
# operationId: PostGroupsGroupIdUsers
export def "groups-users create" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/users"))
  let req_body = {"allowed_ips": $allowed_ips, "announcements_read": $announcements_read, "attachments_permission": $attachments_permission, "authenticate_until": $authenticate_until, "authentication_method": $authentication_method, "avatar_delete": $avatar_delete, "avatar_file": $avatar_file, "billing_permission": $billing_permission, "bypass_inactive_disable": $bypass_inactive_disable, "bypass_site_allowed_ips": $bypass_site_allowed_ips, "change_password": $change_password, "change_password_confirmation": $change_password_confirmation, "company": $company, "dav_permission": $dav_permission, "disabled": $disabled, "email": $email, "ftp_permission": $ftp_permission, "grant_permission": $grant_permission, "group_ids": $group_ids, "header_text": $header_text, "imported_password_hash": $imported_password_hash, "language": $language, "name": $name, "notes": $notes, "notification_daily_send_time": $notification_daily_send_time, "office_integration_enabled": $office_integration_enabled, "password": $password, "password_confirmation": $password_confirmation, "password_validity_days": $password_validity_days, "receive_admin_alerts": $receive_admin_alerts, "require_2fa": $require_2fa, "require_password_change": $require_password_change, "restapi_permission": $restapi_permission, "self_managed": $self_managed, "sftp_permission": $sftp_permission, "site_admin": $site_admin, "skip_welcome_screen": $skip_welcome_screen, "ssl_required": $ssl_required, "sso_strategy_id": $sso_strategy_id, "subscribe_to_newsletter": $subscribe_to_newsletter, "time_zone": $time_zone, "user_root": $user_root, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatar_file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Group
#
# DELETE /groups/{id}
# operationId: DeleteGroupsId
export def "groups delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Group
#
# GET /groups/{id}
# operationId: GetGroupsId
export def "groups get" [
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
]: nothing -> record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Group
#
# PATCH /groups/{id}
# operationId: PatchGroupsId
export def "groups update" [
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
  --admin-ids: string # A list of group admin user ids. If sent as a string, should be comma-delimited.
  --name: string # Group name.
  --notes: string # Group notes.
  --user-ids: string # A list of user ids. If sent as a string, should be comma-delimited.
]: any -> record<admin_ids: string, id: int, name: string, notes: string, user_ids: string, usernames: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}"))
  let req_body = {"admin_ids": $admin_ids, "name": $name, "notes": $notes, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List site full action history.
#
# GET /history
# operationId: HistoryList
export def "history list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[path]=desc`). Valid fields are `path`, `folder`, `user_id` or `created_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `user_id`, `folder` or `path`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `user_id`, `folder` or `path`.
]: nothing -> table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List history for specific file.
#
# GET /history/files/{path}
# operationId: HistoryListForFile
export def "history-files list" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/history/files/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List history for specific folder.
#
# GET /history/folders/{path}
# operationId: HistoryListForFolder
export def "history-folders list" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/history/folders/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List site login history.
#
# GET /history/login
# operationId: HistoryListLogins
export def "history-login list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/history/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List history for specific user.
#
# GET /history/users/{user_id}
# operationId: HistoryListForUser
export def "history-users list" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Leave blank or set to a date/time to filter earlier entries. (format: date-time)
  --end-at: string # Leave blank or set to a date/time to filter later entries. (format: date-time)
  --display: string # Display format. Leave blank or set to `full` or `parent`.
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[user_id]=desc`). Valid fields are `user_id` and `created_at`.
]: nothing -> table<action: string, destination: string, display: string, failure_type: string, id: int, interface: string, ip: string, path: string, source: string, targets: list<record>, user_id: int, username: string, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/history/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List History Export Results
#
# GET /history_export_results
# operationId: GetHistoryExportResults
export def "history-export-results get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --history-export-id: int # ID of the associated history export. (format: int32)
]: nothing -> table<action: string, created_at: int, created_at_iso8601: int, destination: string, failure_type: string, file_id: int, folder: string, id: int, interface: string, ip: string, parent_id: int, path: string, src: string, target_expires_at: int, target_id: int, target_name: string, target_permission: string, target_permission_set: string, target_platform: string, target_recursive: bool, target_user_id: int, target_username: string, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "history_export_id" $history_export_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/history_export_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create History Export
#
# POST /history_exports
# operationId: PostHistoryExports
export def "history-exports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-at: string # End date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --query-action: string # Filter results by this this action type. Valid values: `create`, `read`, `update`, `destroy`, `move`, `login`, `failedlogin`, `copy`, `user_create`, `user_update`, `user_destroy`, `group_create`, `group_update`, `group_destroy`, `permission_create`, `permission_destroy`, `api_key_create`, `api_key_update`, `api_key_destroy` (e.g. read)
  --query-destination: string # Return results that are file moves with this path as destination. (e.g. DestFolder)
  --query-failure-type: string # If searching for Histories about login failures, this parameter restricts results to failures of this specific type. Valid values: `expired_trial`, `account_overdue`, `locked_out`, `ip_mismatch`, `password_mismatch`, `site_mismatch`, `username_not_found`, `none`, `no_ftp_permission`, `no_web_permission`, `no_directory`, `errno_enoent`, `no_sftp_permission`, `no_dav_permission`, `no_restapi_permission`, `key_mismatch`, `region_mismatch`, `expired_access`, `desktop_ip_mismatch`, `desktop_api_key_not_used_quickly_enough`, `disabled`, `country_mismatch` (e.g. bad_password)
  --query-file-id: string # Return results that are file actions related to the file indicated by this File ID (e.g. 1)
  --query-folder: string # Return results that are file actions related to files or folders inside this folder path. (e.g. Folder)
  --query-interface: string # Filter results by this this interface type. Valid values: `web`, `ftp`, `robot`, `jsapi`, `webdesktopapi`, `sftp`, `dav`, `desktop`, `restapi`, `scim`, `office`, `mobile`, `as2`, `inbound_email`, `remote` (e.g. ftp)
  --query-ip: string # Filter results by this IP address. (e.g. 127.0.0.1)
  --query-parent-id: string # Return results that are file actions inside the parent folder specified by this folder ID (e.g. 1)
  --query-path: string # Return results that are file actions related to this path. (e.g. MyFile.txt)
  --query-src: string # Return results that are file moves originating from this path. (e.g. SrcFolder)
  --query-target-id: string # If searching for Histories about specific objects (such as Users, or API Keys), this paremeter restricts results to objects that match this ID. (e.g. 1)
  --query-target-name: string # If searching for Histories about Users, Groups or other objects with names, this parameter restricts results to objects with this name/username. (e.g. full)
  --query-target-permission: string # If searching for Histories about Permisisons, this parameter restricts results to permissions of this level. (e.g. full)
  --query-target-permission-set: string # If searching for Histories about API keys, this parameter restricts results to API keys with this permission set. (e.g. desktop_app)
  --query-target-platform: string # If searching for Histories about API keys, this parameter restricts results to API keys associated with this platform. (e.g. windows)
  --query-target-user-id: string # If searching for Histories about API keys, this parameter restricts results to API keys created by/for this user ID. (e.g. 1)
  --query-target-username: string # If searching for Histories about API keys, this parameter restricts results to API keys created by/for this username. (e.g. jerry)
  --query-user-id: string # Return results that are actions performed by the user indiciated by this User ID (e.g. 1)
  --query-username: string # Filter results by this username. (e.g. jerry)
  --start-at: string # Start date/time of export range. (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<end_at: string, history_version: string, id: int, query_action: string, query_destination: string, query_failure_type: string, query_file_id: string, query_folder: string, query_interface: string, query_ip: string, query_parent_id: string, query_path: string, query_src: string, query_target_id: string, query_target_name: string, query_target_permission: string, query_target_permission_set: string, query_target_platform: string, query_target_user_id: string, query_target_username: string, query_user_id: string, query_username: string, results_url: string, start_at: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/history_exports")
  let req_body = {"end_at": $end_at, "query_action": $query_action, "query_destination": $query_destination, "query_failure_type": $query_failure_type, "query_file_id": $query_file_id, "query_folder": $query_folder, "query_interface": $query_interface, "query_ip": $query_ip, "query_parent_id": $query_parent_id, "query_path": $query_path, "query_src": $query_src, "query_target_id": $query_target_id, "query_target_name": $query_target_name, "query_target_permission": $query_target_permission, "query_target_permission_set": $query_target_permission_set, "query_target_platform": $query_target_platform, "query_target_user_id": $query_target_user_id, "query_target_username": $query_target_username, "query_user_id": $query_user_id, "query_username": $query_username, "start_at": $start_at, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show History Export
#
# GET /history_exports/{id}
# operationId: GetHistoryExportsId
export def "history-exports get" [
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
]: nothing -> record<end_at: string, history_version: string, id: int, query_action: string, query_destination: string, query_failure_type: string, query_file_id: string, query_folder: string, query_interface: string, query_ip: string, query_parent_id: string, query_path: string, query_src: string, query_target_id: string, query_target_name: string, query_target_permission: string, query_target_permission_set: string, query_target_platform: string, query_target_user_id: string, query_target_username: string, query_user_id: string, query_username: string, results_url: string, start_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/history_exports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Inbox Recipients
#
# GET /inbox_recipients
# operationId: GetInboxRecipients
export def "inbox-recipients get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[has_registrations]=desc`). Valid fields are `has_registrations`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `has_registrations`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `has_registrations`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `has_registrations`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `has_registrations`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `has_registrations`.
  --inbox-id: int # List recipients for the inbox with this ID. (format: int32)
]: nothing -> table<company: string, name: string, note: string, recipient: string, sent_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "inbox_id" $inbox_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inbox_recipients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Inbox Recipient
#
# POST /inbox_recipients
# operationId: PostInboxRecipients
export def "inbox-recipients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company: string # Company of recipient. (e.g. Acme Ltd)
  inbox_id: int # Inbox to share. (format: int32)
  --name: string # Name of recipient. (e.g. John Smith)
  --note: string # Note to include in email. (e.g. Just a note.)
  recipient: string # Email address to share this inbox with. (e.g. johndoe@gmail.com)
  --share-after-create: oneof<nothing, bool> # Set to true to share the link with the recipient upon creation.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<company: string, name: string, note: string, recipient: string, sent_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inbox_recipients")
  let req_body = {"company": $company, "inbox_id": $inbox_id, "name": $name, "note": $note, "recipient": $recipient, "share_after_create": $share_after_create, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Inbox Registrations
#
# GET /inbox_registrations
# operationId: GetInboxRegistrations
export def "inbox-registrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --folder-behavior-id: int # ID of the associated Inbox. (format: int32)
]: nothing -> table<clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_id: int, inbox_recipient_id: int, inbox_title: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "folder_behavior_id" $folder_behavior_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inbox_registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Inbox Uploads
#
# GET /inbox_uploads
# operationId: GetInboxUploads
export def "inbox-uploads get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[created_at]=desc`). Valid fields are `created_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `created_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `created_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `created_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `created_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `created_at`.
  --inbox-registration-id: int # InboxRegistration ID (format: int32)
  --inbox-id: int # Inbox ID (format: int32)
]: nothing -> table<created_at: string, inbox_registration: record<clickwrap_body: string, code: string, company: string, created_at: string, email: string, form_field_data: record, form_field_set_id: int, inbox_id: int, inbox_recipient_id: int, inbox_title: string, name: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "inbox_registration_id" $inbox_registration_id "scalar") (serialize-qp "inbox_id" $inbox_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inbox_uploads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Invoices
#
# GET /invoices
# operationId: GetInvoices
export def "invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: list<record>, method: string, payment_line_items: list<record>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Invoice
#
# GET /invoices/{id}
# operationId: GetInvoicesId
export def "invoices get" [
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
]: nothing -> record<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: table<amount: float, created_at: string, description: string, plan: string, service_end_at: string, service_start_at: string, site: string, type: string, updated_at: string>, method: string, payment_line_items: table<amount: float, created_at: string, invoice_id: int, payment_id: int>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoices/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List IP Addresses associated with the current site
#
# GET /ip_addresses
# operationId: GetIpAddresses
export def "ip-addresses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<associated_with: string, group_id: int, id: string, ip_addresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip_addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all possible public ExaVault IP addresses
#
# GET /ip_addresses/exavault-reserved
# operationId: GetIpAddressesExavaultReserved
export def "ip-addresses-exavault-reserved get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<ftp_enabled: bool, ip_address: string, server_name: string, sftp_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip_addresses/exavault-reserved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all possible public IP addresses
#
# GET /ip_addresses/reserved
# operationId: GetIpAddressesReserved
export def "ip-addresses-reserved get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<ftp_enabled: bool, ip_address: string, server_name: string, sftp_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip_addresses/reserved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Lock
#
# DELETE /locks/{path}
# operationId: DeleteLocksPath
export def "locks delete" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Lock token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/locks/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Locks by path
#
# GET /locks/{path}
# operationId: LockListForPath
export def "locks list" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --include-children: oneof<nothing, bool> # Include locks from children objects?
]: nothing -> table<allow_access_by_any_user: bool, depth: string, exclusive: bool, owner: string, path: string, recursive: bool, scope: string, timeout: int, token: string, type: string, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_children" $include_children "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/locks/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Lock
#
# POST /locks/{path}
# operationId: PostLocksPath
export def "locks create" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-access-by-any-user: oneof<nothing, bool> # Allow lock to be updated by any user?
  --exclusive: oneof<nothing, bool> # Is lock exclusive?
  --recursive: string # Does lock apply to subfolders?
  --timeout: int # Lock timeout length (format: int32)
]: any -> record<allow_access_by_any_user: bool, depth: string, exclusive: bool, owner: string, path: string, recursive: bool, scope: string, timeout: int, token: string, type: string, user_id: int, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/locks/{path}"))
  let req_body = {"allow_access_by_any_user": $allow_access_by_any_user, "exclusive": $exclusive, "recursive": $recursive, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Message Comment Reactions
#
# GET /message_comment_reactions
# operationId: GetMessageCommentReactions
export def "message-comment-reactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --message-comment-id: int # Message comment to return reactions for. (format: int32)
]: nothing -> table<emoji: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "message_comment_id" $message_comment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/message_comment_reactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Message Comment Reaction
#
# POST /message_comment_reactions
# operationId: PostMessageCommentReactions
export def "message-comment-reactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji: string # Emoji to react with.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<emoji: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/message_comment_reactions")
  let req_body = {"emoji": $emoji, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Message Comment Reaction
#
# DELETE /message_comment_reactions/{id}
# operationId: DeleteMessageCommentReactionsId
export def "message-comment-reactions delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_comment_reactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Message Comment Reaction
#
# GET /message_comment_reactions/{id}
# operationId: GetMessageCommentReactionsId
export def "message-comment-reactions get" [
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
]: nothing -> record<emoji: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_comment_reactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Message Comments
#
# GET /message_comments
# operationId: GetMessageComments
export def "message-comments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --message-id: int # Message comment to return comments for. (format: int32)
]: nothing -> table<body: string, id: int, reactions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "message_id" $message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/message_comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Message Comment
#
# POST /message_comments
# operationId: PostMessageComments
export def "message-comments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Comment body.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<body: string, id: int, reactions: table<emoji: string, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/message_comments")
  let req_body = {"body": $body, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Message Comment
#
# DELETE /message_comments/{id}
# operationId: DeleteMessageCommentsId
export def "message-comments delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_comments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Message Comment
#
# GET /message_comments/{id}
# operationId: GetMessageCommentsId
export def "message-comments get" [
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
]: nothing -> record<body: string, id: int, reactions: table<emoji: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_comments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Message Comment
#
# PATCH /message_comments/{id}
# operationId: PatchMessageCommentsId
export def "message-comments update" [
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
  body: string # Comment body.
]: any -> record<body: string, id: int, reactions: table<emoji: string, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_comments/{id}"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Message Reactions
#
# GET /message_reactions
# operationId: GetMessageReactions
export def "message-reactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --message-id: int # Message to return reactions for. (format: int32)
]: nothing -> table<emoji: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "message_id" $message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/message_reactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Message Reaction
#
# POST /message_reactions
# operationId: PostMessageReactions
export def "message-reactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji: string # Emoji to react with.
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<emoji: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/message_reactions")
  let req_body = {"emoji": $emoji, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Message Reaction
#
# DELETE /message_reactions/{id}
# operationId: DeleteMessageReactionsId
export def "message-reactions delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_reactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Message Reaction
#
# GET /message_reactions/{id}
# operationId: GetMessageReactionsId
export def "message-reactions get" [
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
]: nothing -> record<emoji: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_reactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Messages
#
# GET /messages
# operationId: GetMessages
export def "messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --project-id: int # Project for which to return messages. (format: int32)
]: nothing -> table<body: string, comments: list<record>, id: int, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Message
#
# POST /messages
# operationId: PostMessages
export def "messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Message body. (e.g. We should upgrade our Files.com account!)
  project_id: int # Project to which the message should be attached. (format: int32)
  subject: string # Message subject. (e.g. Files.com Account Upgrade)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages")
  let req_body = {"body": $body, "project_id": $project_id, "subject": $subject, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Message
#
# DELETE /messages/{id}
# operationId: DeleteMessagesId
export def "messages delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Message
#
# GET /messages/{id}
# operationId: GetMessagesId
export def "messages get" [
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
]: nothing -> record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Message
#
# PATCH /messages/{id}
# operationId: PatchMessagesId
export def "messages update" [
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
  body: string # Message body. (e.g. We should upgrade our Files.com account!)
  project_id: int # Project to which the message should be attached. (format: int32)
  subject: string # Message subject. (e.g. Files.com Account Upgrade)
]: any -> record<body: string, comments: table<body: string, id: int, reactions: list>, id: int, subject: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let req_body = {"body": $body, "project_id": $project_id, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Notifications
#
# GET /notifications
# operationId: GetNotifications
export def "notifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # DEPRECATED: Show notifications for this User ID. Use `filter[user_id]` instead. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[path]=desc`). Valid fields are `path`, `user_id` or `group_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `user_id`, `group_id` or `path`.
  --group-id: int # DEPRECATED: Show notifications for this Group ID. Use `filter[group_id]` instead. (format: int32)
  --path: string # Show notifications for this Path.
  --include-ancestors: oneof<nothing, bool> # If `include_ancestors` is `true` and `path` is specified, include notifications for any parent paths. Ignored if `path` is not specified.
]: nothing -> table<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "include_ancestors" $include_ancestors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Notification
#
# POST /notifications
# operationId: PostNotifications
export def "notifications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # The ID of the group to notify. Provide `user_id`, `username` or `group_id`. (format: int32)
  --message: string # Custom message to include in notification emails. (e.g. custom notification email message)
  --notify-on-copy: oneof<nothing, bool> # If `true`, copying or moving resources into this path will trigger a notification, in addition to just uploads.
  --notify-on-delete: oneof<nothing, bool> # Triggers notification when deleting files from this path (e.g. true)
  --notify-on-download: oneof<nothing, bool> # Triggers notification when downloading files from this path (e.g. true)
  --notify-on-move: oneof<nothing, bool> # Triggers notification when moving files to this path (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers notification when uploading new files to this path (e.g. true)
  --notify-user-actions: oneof<nothing, bool> # If `true` actions initiated by the user will still result in a notification
  --path: string # Path
  --recursive: oneof<nothing, bool> # If `true`, enable notifications for each subfolder in this path
  --send-interval: string # The time interval that notifications are aggregated by. Can be `five_minutes`, `fifteen_minutes`, `hourly`, or `daily`. (e.g. daily)
  --trigger-by-share-recipients: oneof<nothing, bool> # Notify when actions are performed by a share recipient? (e.g. true)
  --triggering-filenames: list<string> # Array of filenames (possibly with wildcards) to match for action path (e.g. [*.jpg, notify_file.txt])
  --triggering-group-ids: list<int> # Only notify on actions made by a member of one of the specified groups (e.g. [1])
  --triggering-user-ids: list<int> # Only notify on actions made one of the specified users (e.g. [1])
  --user-id: int # The id of the user to notify. Provide `user_id`, `username` or `group_id`. (format: int32)
  --username: string # The username of the user to notify. Provide `user_id`, `username` or `group_id`.
]: any -> record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications")
  let req_body = {"group_id": $group_id, "message": $message, "notify_on_copy": $notify_on_copy, "notify_on_delete": $notify_on_delete, "notify_on_download": $notify_on_download, "notify_on_move": $notify_on_move, "notify_on_upload": $notify_on_upload, "notify_user_actions": $notify_user_actions, "path": $path, "recursive": $recursive, "send_interval": $send_interval, "trigger_by_share_recipients": $trigger_by_share_recipients, "triggering_filenames": $triggering_filenames, "triggering_group_ids": $triggering_group_ids, "triggering_user_ids": $triggering_user_ids, "user_id": $user_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Notification
#
# DELETE /notifications/{id}
# operationId: DeleteNotificationsId
export def "notifications delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notifications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Notification
#
# GET /notifications/{id}
# operationId: GetNotificationsId
export def "notifications get" [
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
]: nothing -> record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notifications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Notification
#
# PATCH /notifications/{id}
# operationId: PatchNotificationsId
export def "notifications update" [
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
  --message: string # Custom message to include in notification emails. (e.g. custom notification email message)
  --notify-on-copy: oneof<nothing, bool> # If `true`, copying or moving resources into this path will trigger a notification, in addition to just uploads.
  --notify-on-delete: oneof<nothing, bool> # Triggers notification when deleting files from this path (e.g. true)
  --notify-on-download: oneof<nothing, bool> # Triggers notification when downloading files from this path (e.g. true)
  --notify-on-move: oneof<nothing, bool> # Triggers notification when moving files to this path (e.g. true)
  --notify-on-upload: oneof<nothing, bool> # Triggers notification when uploading new files to this path (e.g. true)
  --notify-user-actions: oneof<nothing, bool> # If `true` actions initiated by the user will still result in a notification
  --recursive: oneof<nothing, bool> # If `true`, enable notifications for each subfolder in this path
  --send-interval: string # The time interval that notifications are aggregated by. Can be `five_minutes`, `fifteen_minutes`, `hourly`, or `daily`. (e.g. daily)
  --trigger-by-share-recipients: oneof<nothing, bool> # Notify when actions are performed by a share recipient? (e.g. true)
  --triggering-filenames: list<string> # Array of filenames (possibly with wildcards) to match for action path (e.g. [*.jpg, notify_file.txt])
  --triggering-group-ids: list<int> # Only notify on actions made by a member of one of the specified groups (e.g. [1])
  --triggering-user-ids: list<int> # Only notify on actions made one of the specified users (e.g. [1])
]: any -> record<group_id: int, group_name: string, id: int, message: string, notify_on_copy: bool, notify_on_delete: bool, notify_on_download: bool, notify_on_move: bool, notify_on_upload: bool, notify_user_actions: bool, path: string, recursive: bool, send_interval: string, suppressed_email: bool, trigger_by_share_recipients: bool, triggering_filenames: list<string>, triggering_group_ids: list<int>, triggering_user_ids: list<int>, unsubscribed: bool, unsubscribed_reason: string, user_id: int, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notifications/{id}"))
  let req_body = {"message": $message, "notify_on_copy": $notify_on_copy, "notify_on_delete": $notify_on_delete, "notify_on_download": $notify_on_download, "notify_on_move": $notify_on_move, "notify_on_upload": $notify_on_upload, "notify_user_actions": $notify_user_actions, "recursive": $recursive, "send_interval": $send_interval, "trigger_by_share_recipients": $trigger_by_share_recipients, "triggering_filenames": $triggering_filenames, "triggering_group_ids": $triggering_group_ids, "triggering_user_ids": $triggering_user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Payments
#
# GET /payments
# operationId: GetPayments
export def "payments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: list<record>, method: string, payment_line_items: list<record>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Payment
#
# GET /payments/{id}
# operationId: GetPaymentsId
export def "payments get" [
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
]: nothing -> record<amount: float, balance: float, created_at: string, currency: string, download_uri: string, id: int, invoice_line_items: table<amount: float, created_at: string, description: string, plan: string, service_end_at: string, service_start_at: string, site: string, type: string, updated_at: string>, method: string, payment_line_items: table<amount: float, created_at: string, invoice_id: int, payment_id: int>, payment_reversed_at: string, payment_type: string, site_name: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Permissions
#
# GET /permissions
# operationId: GetPermissions
export def "permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[group_id]=desc`). Valid fields are `group_id`, `path`, `user_id` or `permission`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --path: string # DEPRECATED: Permission path. If provided, will scope permissions to this path. Use `filter[path]` instead.
  --group-id: string # DEPRECATED: Group ID. If provided, will scope permissions to this group. Use `filter[group_id]` instead.`
  --user-id: string # DEPRECATED: User ID. If provided, will scope permissions to this user. Use `filter[user_id]` instead.`
  --include-groups: oneof<nothing, bool> # If searching by user or group, also include user's permissions that are inherited from its groups?
]: nothing -> table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "path" $path "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "include_groups" $include_groups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Permission
#
# POST /permissions
# operationId: PostPermissions
export def "permissions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Group ID (format: int32)
  --path: string # Folder path
  --permission: string # Permission type. Can be `admin`, `full`, `readonly`, `writeonly`, `list`, or `history`
  --recursive: oneof<nothing, bool> # Apply to subfolders recursively?
  --user-id: int # User ID. Provide `username` or `user_id` (format: int32)
  --username: string # User username. Provide `username` or `user_id`
]: any -> record<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let req_body = {"group_id": $group_id, "path": $path, "permission": $permission, "recursive": $recursive, "user_id": $user_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Permission
#
# DELETE /permissions/{id}
# operationId: DeletePermissionsId
export def "permissions delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/permissions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Priorities
#
# GET /priorities
# operationId: GetPriorities
export def "priorities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --path: string # The path to query for priorities
]: nothing -> table<color: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/priorities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Projects
#
# GET /projects
# operationId: GetProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<global_access: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Project
#
# POST /projects
# operationId: PostProjects
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  global_access: string # Global permissions. Can be: `none`, `anyone_with_read`, `anyone_with_full`.
]: any -> record<global_access: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let req_body = {"global_access": $global_access} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Project
#
# DELETE /projects/{id}
# operationId: DeleteProjectsId
export def "projects delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Project
#
# GET /projects/{id}
# operationId: GetProjectsId
export def "projects get" [
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
]: nothing -> record<global_access: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Project
#
# PATCH /projects/{id}
# operationId: PatchProjectsId
export def "projects update" [
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
  global_access: string # Global permissions. Can be: `none`, `anyone_with_read`, `anyone_with_full`.
]: any -> record<global_access: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}"))
  let req_body = {"global_access": $global_access} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Public Keys
#
# GET /public_keys
# operationId: GetPublicKeys
export def "public-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<created_at: string, fingerprint: string, id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Public Key
#
# POST /public_keys
# operationId: PostPublicKeys
export def "public-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  public_key: string # Actual contents of SSH key.
  title: string # Internal reference for key. (e.g. My Main Key)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<created_at: string, fingerprint: string, id: int, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public_keys")
  let req_body = {"public_key": $public_key, "title": $title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Public Key
#
# DELETE /public_keys/{id}
# operationId: DeletePublicKeysId
export def "public-keys delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/public_keys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Public Key
#
# GET /public_keys/{id}
# operationId: GetPublicKeysId
export def "public-keys get" [
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
]: nothing -> record<created_at: string, fingerprint: string, id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/public_keys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Public Key
#
# PATCH /public_keys/{id}
# operationId: PatchPublicKeysId
export def "public-keys update" [
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
  title: string # Internal reference for key. (e.g. My Main Key)
]: any -> record<created_at: string, fingerprint: string, id: int, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/public_keys/{id}"))
  let req_body = {"title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Remote Bandwidth Snapshots
#
# GET /remote_bandwidth_snapshots
# operationId: GetRemoteBandwidthSnapshots
export def "remote-bandwidth-snapshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[logged_at]=desc`). Valid fields are `logged_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `logged_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `logged_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `logged_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `logged_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `logged_at`.
]: nothing -> table<id: int, logged_at: string, remote_server_id: int, sync_bytes_received: float, sync_bytes_sent: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/remote_bandwidth_snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Remote Servers
#
# GET /remote_servers
# operationId: GetRemoteServers
export def "remote-servers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/remote_servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Remote Server
#
# POST /remote_servers
# operationId: PostRemoteServers
export def "remote-servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key: string # AWS Access Key. (e.g. example)
  --aws-secret-key: string # AWS secret key.
  --azure-blob-storage-access-key: string # Azure Blob Storage secret key.
  --azure-blob-storage-account: string # Azure Blob Storage Account name (e.g. storage-account-name)
  --azure-blob-storage-container: string # Azure Blob Storage Container name (e.g. container-name)
  --azure-blob-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-access-key: string # Azure File Storage access key.
  --azure-files-storage-account: string # Azure File Storage Account name (e.g. storage-account-name)
  --azure-files-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-share-name: string # Azure File Storage Share name (e.g. share-name)
  --backblaze-b2-application-key: string # Backblaze B2 Cloud Storage applicationKey.
  --backblaze-b2-bucket: string # Backblaze B2 Cloud Storage Bucket name (e.g. my-bucket)
  --backblaze-b2-key-id: string # Backblaze B2 Cloud Storage keyID.
  --backblaze-b2-s3-endpoint: string # Backblaze B2 Cloud Storage S3 Endpoint (e.g. s3.us-west-001.backblazeb2.com)
  --enable-dedicated-ips: oneof<nothing, bool> # `true` if remote server only accepts connections from dedicated IPs (e.g. true)
  --filebase-access-key: string # Filebase Access Key. (e.g. example)
  --filebase-bucket: string # Filebase Bucket name (e.g. my-bucket)
  --filebase-secret-key: string # Filebase secret key
  --files-agent-permission-set: string@files-agent-permission-set-completer # Local permissions for files agent. read_only, write_only, or read_write (e.g. read_write)
  --files-agent-root: string # Agent local root path (e.g. example)
  --google-cloud-storage-bucket: string # Google Cloud Storage bucket name (e.g. my-bucket)
  --google-cloud-storage-credentials-json: string # A JSON file that contains the private key. To generate see https://cloud.google.com/storage/docs/json_api/v1/how-tos/authorizing#APIKey
  --google-cloud-storage-project-id: string # Google Cloud Project ID (e.g. my-project)
  --hostname: string # Hostname or IP address (e.g. remote-server.com)
  --max-connections: int # Max number of parallel connections. Ignored for S3 connections (we will parallelize these as much as possible). (format: int32, e.g. 1)
  --name: string # Internal name for your reference (e.g. My Remote server)
  --one-drive-account-type: string@one-drive-account-type-completer # Either personal or business_other account types (e.g. personal)
  --password: string # Password if needed.
  --pin-to-site-region: oneof<nothing, bool> # If true, we will ensure that all communications with this remote server are made through the primary region of the site. This setting can also be overridden by a sitewide setting which will force it to true. (e.g. true)
  --port: int # Port for remote server. Not needed for S3. (format: int32, e.g. 1)
  --private-key: string # Private key if needed.
  --private-key-passphrase: string # Passphrase for private key if needed.
  --rackspace-api-key: string # Rackspace API key from the Rackspace Cloud Control Panel.
  --rackspace-container: string # The name of the container (top level directory) where files will sync. (e.g. my-container)
  --rackspace-region: string # Three letter airport code for Rackspace region. See https://support.rackspace.com/how-to/about-regions/ (e.g. dfw)
  --rackspace-username: string # Rackspace username used to login to the Rackspace Cloud Control Panel. (e.g. rackspaceuser)
  --reset-authentication: oneof<nothing, bool> # Reset authenticated account
  --s3-bucket: string # S3 bucket name (e.g. my-bucket)
  --s3-compatible-access-key: string # S3-compatible Access Key. (e.g. example)
  --s3-compatible-bucket: string # S3-compatible Bucket name (e.g. my-bucket)
  --s3-compatible-endpoint: string # S3-compatible endpoint (e.g. mys3platform.com)
  --s3-compatible-region: string # S3-compatible endpoint (e.g. us-east-1)
  --s3-compatible-secret-key: string # S3-compatible secret key
  --s3-region: string # S3 region (e.g. us-east-1)
  --server-certificate: string@server-certificate-completer # Remote server certificate (e.g. require_match)
  --server-host-key: string # Remote server SSH Host Key. If provided, we will require that the server host key matches the provided key. Uses OpenSSH format similar to what would go into ~/.ssh/known_hosts (e.g. [public key])
  --server-type: string@server-type-completer # Remote server type. (e.g. s3)
  --ssl: string@ssl-completer # Should we require SSL? (e.g. if_available)
  --ssl-certificate: string # SSL client certificate.
  --username: string # Remote server username. Not needed for S3 buckets. (e.g. user)
  --wasabi-access-key: string # Wasabi access key. (e.g. example)
  --wasabi-bucket: string # Wasabi Bucket name (e.g. my-bucket)
  --wasabi-region: string # Wasabi region (e.g. us-west-1)
  --wasabi-secret-key: string # Wasabi secret key.
]: any -> record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/remote_servers")
  let req_body = {"aws_access_key": $aws_access_key, "aws_secret_key": $aws_secret_key, "azure_blob_storage_access_key": $azure_blob_storage_access_key, "azure_blob_storage_account": $azure_blob_storage_account, "azure_blob_storage_container": $azure_blob_storage_container, "azure_blob_storage_sas_token": $azure_blob_storage_sas_token, "azure_files_storage_access_key": $azure_files_storage_access_key, "azure_files_storage_account": $azure_files_storage_account, "azure_files_storage_sas_token": $azure_files_storage_sas_token, "azure_files_storage_share_name": $azure_files_storage_share_name, "backblaze_b2_application_key": $backblaze_b2_application_key, "backblaze_b2_bucket": $backblaze_b2_bucket, "backblaze_b2_key_id": $backblaze_b2_key_id, "backblaze_b2_s3_endpoint": $backblaze_b2_s3_endpoint, "enable_dedicated_ips": $enable_dedicated_ips, "filebase_access_key": $filebase_access_key, "filebase_bucket": $filebase_bucket, "filebase_secret_key": $filebase_secret_key, "files_agent_permission_set": $files_agent_permission_set, "files_agent_root": $files_agent_root, "google_cloud_storage_bucket": $google_cloud_storage_bucket, "google_cloud_storage_credentials_json": $google_cloud_storage_credentials_json, "google_cloud_storage_project_id": $google_cloud_storage_project_id, "hostname": $hostname, "max_connections": $max_connections, "name": $name, "one_drive_account_type": $one_drive_account_type, "password": $password, "pin_to_site_region": $pin_to_site_region, "port": $port, "private_key": $private_key, "private_key_passphrase": $private_key_passphrase, "rackspace_api_key": $rackspace_api_key, "rackspace_container": $rackspace_container, "rackspace_region": $rackspace_region, "rackspace_username": $rackspace_username, "reset_authentication": $reset_authentication, "s3_bucket": $s3_bucket, "s3_compatible_access_key": $s3_compatible_access_key, "s3_compatible_bucket": $s3_compatible_bucket, "s3_compatible_endpoint": $s3_compatible_endpoint, "s3_compatible_region": $s3_compatible_region, "s3_compatible_secret_key": $s3_compatible_secret_key, "s3_region": $s3_region, "server_certificate": $server_certificate, "server_host_key": $server_host_key, "server_type": $server_type, "ssl": $ssl, "ssl_certificate": $ssl_certificate, "username": $username, "wasabi_access_key": $wasabi_access_key, "wasabi_bucket": $wasabi_bucket, "wasabi_region": $wasabi_region, "wasabi_secret_key": $wasabi_secret_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Remote Server
#
# DELETE /remote_servers/{id}
# operationId: DeleteRemoteServersId
export def "remote-servers delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/remote_servers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Remote Server
#
# GET /remote_servers/{id}
# operationId: GetRemoteServersId
export def "remote-servers get" [
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
]: nothing -> record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/remote_servers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Remote Server
#
# PATCH /remote_servers/{id}
# operationId: PatchRemoteServersId
export def "remote-servers update" [
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
  --aws-access-key: string # AWS Access Key. (e.g. example)
  --aws-secret-key: string # AWS secret key.
  --azure-blob-storage-access-key: string # Azure Blob Storage secret key.
  --azure-blob-storage-account: string # Azure Blob Storage Account name (e.g. storage-account-name)
  --azure-blob-storage-container: string # Azure Blob Storage Container name (e.g. container-name)
  --azure-blob-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-access-key: string # Azure File Storage access key.
  --azure-files-storage-account: string # Azure File Storage Account name (e.g. storage-account-name)
  --azure-files-storage-sas-token: string # Shared Access Signature (SAS) token (e.g. storage-sas-token)
  --azure-files-storage-share-name: string # Azure File Storage Share name (e.g. share-name)
  --backblaze-b2-application-key: string # Backblaze B2 Cloud Storage applicationKey.
  --backblaze-b2-bucket: string # Backblaze B2 Cloud Storage Bucket name (e.g. my-bucket)
  --backblaze-b2-key-id: string # Backblaze B2 Cloud Storage keyID.
  --backblaze-b2-s3-endpoint: string # Backblaze B2 Cloud Storage S3 Endpoint (e.g. s3.us-west-001.backblazeb2.com)
  --enable-dedicated-ips: oneof<nothing, bool> # `true` if remote server only accepts connections from dedicated IPs (e.g. true)
  --filebase-access-key: string # Filebase Access Key. (e.g. example)
  --filebase-bucket: string # Filebase Bucket name (e.g. my-bucket)
  --filebase-secret-key: string # Filebase secret key
  --files-agent-permission-set: string@files-agent-permission-set-completer # Local permissions for files agent. read_only, write_only, or read_write (e.g. read_write)
  --files-agent-root: string # Agent local root path (e.g. example)
  --google-cloud-storage-bucket: string # Google Cloud Storage bucket name (e.g. my-bucket)
  --google-cloud-storage-credentials-json: string # A JSON file that contains the private key. To generate see https://cloud.google.com/storage/docs/json_api/v1/how-tos/authorizing#APIKey
  --google-cloud-storage-project-id: string # Google Cloud Project ID (e.g. my-project)
  --hostname: string # Hostname or IP address (e.g. remote-server.com)
  --max-connections: int # Max number of parallel connections. Ignored for S3 connections (we will parallelize these as much as possible). (format: int32, e.g. 1)
  --name: string # Internal name for your reference (e.g. My Remote server)
  --one-drive-account-type: string@one-drive-account-type-completer # Either personal or business_other account types (e.g. personal)
  --password: string # Password if needed.
  --pin-to-site-region: oneof<nothing, bool> # If true, we will ensure that all communications with this remote server are made through the primary region of the site. This setting can also be overridden by a sitewide setting which will force it to true. (e.g. true)
  --port: int # Port for remote server. Not needed for S3. (format: int32, e.g. 1)
  --private-key: string # Private key if needed.
  --private-key-passphrase: string # Passphrase for private key if needed.
  --rackspace-api-key: string # Rackspace API key from the Rackspace Cloud Control Panel.
  --rackspace-container: string # The name of the container (top level directory) where files will sync. (e.g. my-container)
  --rackspace-region: string # Three letter airport code for Rackspace region. See https://support.rackspace.com/how-to/about-regions/ (e.g. dfw)
  --rackspace-username: string # Rackspace username used to login to the Rackspace Cloud Control Panel. (e.g. rackspaceuser)
  --reset-authentication: oneof<nothing, bool> # Reset authenticated account
  --s3-bucket: string # S3 bucket name (e.g. my-bucket)
  --s3-compatible-access-key: string # S3-compatible Access Key. (e.g. example)
  --s3-compatible-bucket: string # S3-compatible Bucket name (e.g. my-bucket)
  --s3-compatible-endpoint: string # S3-compatible endpoint (e.g. mys3platform.com)
  --s3-compatible-region: string # S3-compatible endpoint (e.g. us-east-1)
  --s3-compatible-secret-key: string # S3-compatible secret key
  --s3-region: string # S3 region (e.g. us-east-1)
  --server-certificate: string@server-certificate-completer # Remote server certificate (e.g. require_match)
  --server-host-key: string # Remote server SSH Host Key. If provided, we will require that the server host key matches the provided key. Uses OpenSSH format similar to what would go into ~/.ssh/known_hosts (e.g. [public key])
  --server-type: string@server-type-completer # Remote server type. (e.g. s3)
  --ssl: string@ssl-completer # Should we require SSL? (e.g. if_available)
  --ssl-certificate: string # SSL client certificate.
  --username: string # Remote server username. Not needed for S3 buckets. (e.g. user)
  --wasabi-access-key: string # Wasabi access key. (e.g. example)
  --wasabi-bucket: string # Wasabi Bucket name (e.g. my-bucket)
  --wasabi-region: string # Wasabi region (e.g. us-west-1)
  --wasabi-secret-key: string # Wasabi secret key.
]: any -> record<auth_account_name: string, auth_setup_link: string, auth_status: string, authentication_method: string, aws_access_key: string, azure_blob_storage_account: string, azure_blob_storage_container: string, azure_blob_storage_sas_token: string, azure_files_storage_account: string, azure_files_storage_sas_token: string, azure_files_storage_share_name: string, backblaze_b2_bucket: string, backblaze_b2_s3_endpoint: string, disabled: bool, enable_dedicated_ips: bool, filebase_access_key: string, filebase_bucket: string, files_agent_api_token: string, files_agent_permission_set: string, files_agent_root: string, google_cloud_storage_bucket: string, google_cloud_storage_project_id: string, hostname: string, id: int, max_connections: int, name: string, one_drive_account_type: string, pin_to_site_region: bool, pinned_region: string, port: int, rackspace_container: string, rackspace_region: string, rackspace_username: string, remote_home_path: string, s3_bucket: string, s3_compatible_access_key: string, s3_compatible_bucket: string, s3_compatible_endpoint: string, s3_compatible_region: string, s3_region: string, server_certificate: string, server_host_key: string, server_type: string, ssl: string, username: string, wasabi_access_key: string, wasabi_bucket: string, wasabi_region: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/remote_servers/{id}"))
  let req_body = {"aws_access_key": $aws_access_key, "aws_secret_key": $aws_secret_key, "azure_blob_storage_access_key": $azure_blob_storage_access_key, "azure_blob_storage_account": $azure_blob_storage_account, "azure_blob_storage_container": $azure_blob_storage_container, "azure_blob_storage_sas_token": $azure_blob_storage_sas_token, "azure_files_storage_access_key": $azure_files_storage_access_key, "azure_files_storage_account": $azure_files_storage_account, "azure_files_storage_sas_token": $azure_files_storage_sas_token, "azure_files_storage_share_name": $azure_files_storage_share_name, "backblaze_b2_application_key": $backblaze_b2_application_key, "backblaze_b2_bucket": $backblaze_b2_bucket, "backblaze_b2_key_id": $backblaze_b2_key_id, "backblaze_b2_s3_endpoint": $backblaze_b2_s3_endpoint, "enable_dedicated_ips": $enable_dedicated_ips, "filebase_access_key": $filebase_access_key, "filebase_bucket": $filebase_bucket, "filebase_secret_key": $filebase_secret_key, "files_agent_permission_set": $files_agent_permission_set, "files_agent_root": $files_agent_root, "google_cloud_storage_bucket": $google_cloud_storage_bucket, "google_cloud_storage_credentials_json": $google_cloud_storage_credentials_json, "google_cloud_storage_project_id": $google_cloud_storage_project_id, "hostname": $hostname, "max_connections": $max_connections, "name": $name, "one_drive_account_type": $one_drive_account_type, "password": $password, "pin_to_site_region": $pin_to_site_region, "port": $port, "private_key": $private_key, "private_key_passphrase": $private_key_passphrase, "rackspace_api_key": $rackspace_api_key, "rackspace_container": $rackspace_container, "rackspace_region": $rackspace_region, "rackspace_username": $rackspace_username, "reset_authentication": $reset_authentication, "s3_bucket": $s3_bucket, "s3_compatible_access_key": $s3_compatible_access_key, "s3_compatible_bucket": $s3_compatible_bucket, "s3_compatible_endpoint": $s3_compatible_endpoint, "s3_compatible_region": $s3_compatible_region, "s3_compatible_secret_key": $s3_compatible_secret_key, "s3_region": $s3_region, "server_certificate": $server_certificate, "server_host_key": $server_host_key, "server_type": $server_type, "ssl": $ssl, "ssl_certificate": $ssl_certificate, "username": $username, "wasabi_access_key": $wasabi_access_key, "wasabi_bucket": $wasabi_bucket, "wasabi_region": $wasabi_region, "wasabi_secret_key": $wasabi_secret_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Download configuration file (required for some Remote Server integrations, such as the Files.com Agent)
#
# GET /remote_servers/{id}/configuration_file
# operationId: GetRemoteServersIdConfigurationFile
export def "remote-servers-configuration-file get" [
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
]: nothing -> record<api_token: string, config_version: string, hostname: string, id: int, permission_set: string, port: int, private_key: string, public_key: string, root: string, server_host_key: string, status: string, subdomain: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/remote_servers/{id}/configuration_file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Post local changes, check in, and download configuration file (used by some Remote Server integrations, such as the Files.com Agent)
#
# POST /remote_servers/{id}/configuration_file
# operationId: PostRemoteServersIdConfigurationFile
export def "remote-servers-configuration-file create" [
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
  --api-token: string # Files Agent API Token (e.g. example)
  --config-version: string # agent config version (e.g. example)
  --hostname: string # e.g. example
  --permission-set: string # e.g. full
  --port: int # Incoming port for files agent connections (format: int32, e.g. 1)
  --private-key: string # private key (e.g. example)
  --public-key: string # public key (e.g. example)
  --root: string # Agent local root path (e.g. example)
  --server-host-key: string # e.g. example
  --status: string # either running or shutdown (e.g. example)
  --subdomain: string # e.g. example
]: any -> record<api_token: string, config_version: string, hostname: string, id: int, permission_set: string, port: int, private_key: string, public_key: string, root: string, server_host_key: string, status: string, subdomain: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/remote_servers/{id}/configuration_file"))
  let req_body = {"api_token": $api_token, "config_version": $config_version, "hostname": $hostname, "permission_set": $permission_set, "port": $port, "private_key": $private_key, "public_key": $public_key, "root": $root, "server_host_key": $server_host_key, "status": $status, "subdomain": $subdomain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Requests
#
# GET /requests
# operationId: GetRequests
export def "requests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[destination]=desc`). Valid fields are `destination`.
  --mine: oneof<nothing, bool> # Only show requests of the current user? (Defaults to true if current user is not a site admin.)
  --path: string # Path to show requests for. If omitted, shows all paths. Send `/` to represent the root directory.
]: nothing -> table<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "mine" $mine "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Request
#
# POST /requests
# operationId: PostRequests
export def "requests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Destination filename (without extension) to request.
  --group-ids: string # A list of group IDs to request the file from. If sent as a string, it should be comma-delimited.
  path: string # Folder path on which to request the file.
  --user-ids: string # A list of user IDs to request the file from. If sent as a string, it should be comma-delimited.
]: any -> record<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/requests")
  let req_body = {"destination": $destination, "group_ids": $group_ids, "path": $path, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Requests
#
# GET /requests/folders/{path}
# operationId: GetRequestsFoldersPath
export def "requests-folders get" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[destination]=desc`). Valid fields are `destination`.
  --mine: oneof<nothing, bool> # Only show requests of the current user? (Defaults to true if current user is not a site admin.)
]: nothing -> table<automation_id: string, destination: string, id: int, path: string, source: string, user_display_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/requests/folders/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Request
#
# DELETE /requests/{id}
# operationId: DeleteRequestsId
export def "requests delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/requests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete user session (log out)
#
# DELETE /sessions
# operationId: DeleteSessions
export def "sessions delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create user session (log in)
#
# POST /sessions
# operationId: PostSessions
export def "sessions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --otp: string # If this user has a 2FA device, provide its OTP or code here. (e.g. 123456)
  --partial-session-id: string # Identifier for a partially-completed login
  --password: string # Password for sign in (e.g. password)
  --username: string # Username to sign in as (e.g. username)
]: any -> record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sessions")
  let req_body = {"otp": $otp, "partial_session_id": $partial_session_id, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Settings Changes
#
# GET /settings_changes
# operationId: GetSettingsChanges
export def "settings-changes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[api_key_id]=desc`). Valid fields are `api_key_id`, `created_at` or `user_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `api_key_id` and `user_id`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `api_key_id` and `user_id`.
]: nothing -> table<changes: list<string>, created_at: string, user_id: int, user_is_files_support: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/settings_changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Sftp Host Keys
#
# GET /sftp_host_keys
# operationId: GetSftpHostKeys
export def "sftp-host-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sftp_host_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Sftp Host Key
#
# POST /sftp_host_keys
# operationId: PostSftpHostKeys
export def "sftp-host-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The friendly name of this SFTP Host Key.
  --private-key: string # The private key data.
]: any -> record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sftp_host_keys")
  let req_body = {"name": $name, "private_key": $private_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete Sftp Host Key
#
# DELETE /sftp_host_keys/{id}
# operationId: DeleteSftpHostKeysId
export def "sftp-host-keys delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sftp_host_keys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Sftp Host Key
#
# GET /sftp_host_keys/{id}
# operationId: GetSftpHostKeysId
export def "sftp-host-keys get" [
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
]: nothing -> record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sftp_host_keys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Sftp Host Key
#
# PATCH /sftp_host_keys/{id}
# operationId: PatchSftpHostKeysId
export def "sftp-host-keys update" [
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
  --name: string # The friendly name of this SFTP Host Key.
  --private-key: string # The private key data.
]: any -> record<fingerprint_md5: string, fingerprint_sha256: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sftp_host_keys/{id}"))
  let req_body = {"name": $name, "private_key": $private_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show site settings
#
# GET /site
# operationId: GetSite
export def "site get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active_sftp_host_key_id: int, admin_user_id: int, allow_bundle_names: bool, allowed_2fa_method_bypass_for_ftp_sftp_dav: bool, allowed_2fa_method_sms: bool, allowed_2fa_method_totp: bool, allowed_2fa_method_u2f: bool, allowed_2fa_method_webauthn: bool, allowed_2fa_method_yubi: bool, allowed_countries: string, allowed_ips: string, ask_about_overwrites: bool, bundle_activity_notifications: string, bundle_expiration: int, bundle_password_required: bool, bundle_registration_notifications: string, bundle_require_share_recipient: bool, bundle_upload_receipt_notifications: string, bundle_watermark_attachment: record<name: string, uri: string>, bundle_watermark_value: record, color2_left: string, color2_link: string, color2_text: string, color2_top: string, color2_top_text: string, contact_name: string, created_at: string, currency: string, custom_namespace: bool, days_to_retain_backups: int, default_time_zone: string, desktop_app: bool, desktop_app_session_ip_pinning: bool, desktop_app_session_lifetime: int, disable_files_certificate_generation: bool, disable_notifications: bool, disable_password_reset: bool, disable_users_from_inactivity_period_days: int, disallowed_countries: string, domain: string, domain_hsts_header: bool, domain_letsencrypt_chain: string, email: string, folder_permissions_groups_only: bool, ftp_enabled: bool, hipaa: bool, icon128: record<name: string, uri: string>, icon16: record<name: string, uri: string>, icon32: record<name: string, uri: string>, icon48: record<name: string, uri: string>, immutable_files_set_at: string, include_password_in_welcome_email: bool, language: string, ldap_base_dn: string, ldap_domain: string, ldap_enabled: bool, ldap_group_action: string, ldap_group_exclusion: string, ldap_group_inclusion: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_type: string, ldap_user_action: string, ldap_user_include_groups: string, ldap_username: string, ldap_username_field: string, login_help_text: string, logo: record<name: string, uri: string>, max_prior_passwords: int, mobile_app: bool, mobile_app_session_ip_pinning: bool, mobile_app_session_lifetime: int, motd_text: string, motd_use_for_ftp: bool, motd_use_for_sftp: bool, name: string, next_billing_amount: float, next_billing_date: string, non_sso_groups_allowed: bool, non_sso_users_allowed: bool, office_integration_available: bool, office_integration_type: string, oncehub_link: string, opt_out_global: bool, overage_notified_at: string, overage_notify: bool, overdue: bool, password_min_length: int, password_require_letter: bool, password_require_mixed: bool, password_require_number: bool, password_require_special: bool, password_require_unbreached: bool, password_requirements_apply_to_bundles: bool, password_validity_days: int, phone: string, pin_all_remote_servers_to_site_region: bool, reply_to_email: string, require_2fa: bool, require_2fa_stop_time: string, require_2fa_user_type: string, session: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>, session_expiry: float, session_expiry_minutes: int, session_pinned_by_ip: bool, sftp_enabled: bool, sftp_host_key_type: string, sftp_insecure_ciphers: bool, sftp_user_root_enabled: bool, sharing_enabled: bool, show_request_access_link: bool, site_footer: string, site_header: string, smtp_address: string, smtp_authentication: string, smtp_from: string, smtp_port: int, smtp_username: string, ssl_required: bool, subdomain: string, switch_to_plan_date: string, tls_disabled: bool, trial_days_left: int, trial_until: string, updated_at: string, uploads_via_email_authentication: bool, use_provided_modified_at: bool, user: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>, user_lockout: bool, user_lockout_lock_period: int, user_lockout_tries: int, user_lockout_within: int, user_requests_enabled: bool, user_requests_notify_admins: bool, welcome_custom_text: string, welcome_email_cc: string, welcome_email_enabled: bool, welcome_email_subject: string, welcome_screen: string, windows_mode_ftp: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update site settings.
#
# PATCH /site
# operationId: PatchSite
export def "site update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-sftp-host-key-id: int # Id of the currently selected custom SFTP Host Key (format: int32)
  --allow-bundle-names: oneof<nothing, bool> # Are manual Bundle names allowed?
  --allowed-2fa-method-bypass-for-ftp-sftp-dav: oneof<nothing, bool> # Are users allowed to configure their two factor authentication to be bypassed for FTP/SFTP/WebDAV?
  --allowed-2fa-method-sms: oneof<nothing, bool> # Is SMS two factor authentication allowed?
  --allowed-2fa-method-totp: oneof<nothing, bool> # Is TOTP two factor authentication allowed?
  --allowed-2fa-method-u2f: oneof<nothing, bool> # Is U2F two factor authentication allowed?
  --allowed-2fa-method-webauthn: oneof<nothing, bool> # Is WebAuthn two factor authentication allowed?
  --allowed-2fa-method-yubi: oneof<nothing, bool> # Is yubikey two factor authentication allowed?
  --allowed-countries: string # Comma seperated list of allowed Country codes
  --allowed-ips: string # List of allowed IP addresses
  --ask-about-overwrites: oneof<nothing, bool> # If false, rename conflicting files instead of asking for overwrite confirmation. Only applies to web interface.
  --bundle-activity-notifications: string # Do Bundle owners receive activity notifications?
  --bundle-expiration: int # Site-wide Bundle expiration in days (format: int32)
  --bundle-password-required: oneof<nothing, bool> # Do Bundles require password protection?
  --bundle-registration-notifications: string # Do Bundle owners receive registration notification?
  --bundle-require-share-recipient: oneof<nothing, bool> # Do Bundles require recipients for sharing?
  --bundle-upload-receipt-notifications: string # Do Bundle uploaders receive upload confirmation notifications?
  --bundle-watermark-attachment-delete: oneof<nothing, bool> # If true, will delete the file stored in bundle_watermark_attachment
  --bundle-watermark-attachment-file: string # format: binary
  --bundle-watermark-value: record # Preview watermark settings applied to all bundle items. Uses the same keys as Behavior.value
  --color2-left: string # Page link and button color
  --color2-link: string # Top bar link color
  --color2-text: string # Page link and button color
  --color2-top: string # Top bar background color
  --color2-top-text: string # Top bar text color
  --custom-namespace: oneof<nothing, bool> # Is this site using a custom namespace for users?
  --days-to-retain-backups: int # Number of days to keep deleted files (format: int32)
  --default-time-zone: string # Site default time zone
  --desktop-app: oneof<nothing, bool> # Is the desktop app enabled?
  --desktop-app-session-ip-pinning: oneof<nothing, bool> # Is desktop app session IP pinning enabled?
  --desktop-app-session-lifetime: int # Desktop app session lifetime (in hours) (format: int32)
  --disable-2fa-with-delay: oneof<nothing, bool> # If set to true, we will begin the process of disabling 2FA on this site.
  --disable-files-certificate-generation: oneof<nothing, bool> # If set, Files.com will not set the CAA records required to generate future SSL certificates for this domain.
  --disable-password-reset: oneof<nothing, bool> # Is password reset disabled?
  --disable-users-from-inactivity-period-days: int # If greater than zero, users will unable to login if they do not show activity within this number of days. (format: int32)
  --disallowed-countries: string # Comma seperated list of disallowed Country codes
  --domain: string # Custom domain
  --domain-hsts-header: oneof<nothing, bool> # Send HSTS (HTTP Strict Transport Security) header when visitors access the site via a custom domain?
  --domain-letsencrypt-chain: string # Letsencrypt chain to use when registering SSL Certificate for domain.
  --email: string # Main email for this site
  --folder-permissions-groups-only: oneof<nothing, bool> # If true, permissions for this site must be bound to a group (not a user). Otherwise, permissions must be bound to a user.
  --ftp-enabled: oneof<nothing, bool> # Is FTP enabled?
  --icon128-delete: oneof<nothing, bool> # If true, will delete the file stored in icon128
  --icon128-file: string # format: binary
  --icon16-delete: oneof<nothing, bool> # If true, will delete the file stored in icon16
  --icon16-file: string # format: binary
  --icon32-delete: oneof<nothing, bool> # If true, will delete the file stored in icon32
  --icon32-file: string # format: binary
  --icon48-delete: oneof<nothing, bool> # If true, will delete the file stored in icon48
  --icon48-file: string # format: binary
  --immutable-files: oneof<nothing, bool> # Are files protected from modification?
  --include-password-in-welcome-email: oneof<nothing, bool> # Include password in emails to new users?
  --language: string # Site default language
  --ldap-base-dn: string # Base DN for looking up users in LDAP server
  --ldap-domain: string # Domain name that will be appended to usernames
  --ldap-enabled: oneof<nothing, bool> # Main LDAP setting: is LDAP enabled?
  --ldap-group-action: string # Should we sync groups from LDAP server?
  --ldap-group-exclusion: string # Comma or newline separated list of group names (with optional wildcards) to exclude when syncing.
  --ldap-group-inclusion: string # Comma or newline separated list of group names (with optional wildcards) to include when syncing.
  --ldap-host: string # LDAP host
  --ldap-host-2: string # LDAP backup host
  --ldap-host-3: string # LDAP backup host
  --ldap-password-change: string # New LDAP password.
  --ldap-password-change-confirmation: string # Confirm new LDAP password.
  --ldap-port: int # LDAP port (format: int32)
  --ldap-secure: oneof<nothing, bool> # Use secure LDAP?
  --ldap-type: string # LDAP type
  --ldap-user-action: string # Should we sync users from LDAP server?
  --ldap-user-include-groups: string # Comma or newline separated list of group names (with optional wildcards) - if provided, only users in these groups will be added or synced.
  --ldap-username: string # Username for signing in to LDAP server.
  --ldap-username-field: string # LDAP username field
  --login-help-text: string # Login help text
  --logo-delete: oneof<nothing, bool> # If true, will delete the file stored in logo
  --logo-file: string # format: binary
  --max-prior-passwords: int # Number of prior passwords to disallow (format: int32)
  --mobile-app: oneof<nothing, bool> # Is the mobile app enabled?
  --mobile-app-session-ip-pinning: oneof<nothing, bool> # Is mobile app session IP pinning enabled?
  --mobile-app-session-lifetime: int # Mobile app session lifetime (in hours) (format: int32)
  --motd-text: string # A message to show users when they connect via FTP or SFTP.
  --motd-use-for-ftp: oneof<nothing, bool> # Show message to users connecting via FTP
  --motd-use-for-sftp: oneof<nothing, bool> # Show message to users connecting via SFTP
  --name: string # Site name
  --non-sso-groups-allowed: oneof<nothing, bool> # If true, groups can be manually created / modified / deleted by Site Admins. Otherwise, groups can only be managed via your SSO provider.
  --non-sso-users-allowed: oneof<nothing, bool> # If true, users can be manually created / modified / deleted by Site Admins. Otherwise, users can only be managed via your SSO provider.
  --office-integration-available: oneof<nothing, bool> # Allow users to use Office for the web?
  --office-integration-type: string # Office integration application used to edit and view the MS Office documents
  --opt-out-global: oneof<nothing, bool> # Use servers in the USA only?
  --overage-notify: oneof<nothing, bool> # Notify site email of overages?
  --password-min-length: int # Shortest password length for users (format: int32)
  --password-require-letter: oneof<nothing, bool> # Require a letter in passwords?
  --password-require-mixed: oneof<nothing, bool> # Require lower and upper case letters in passwords?
  --password-require-number: oneof<nothing, bool> # Require a number in passwords?
  --password-require-special: oneof<nothing, bool> # Require special characters in password?
  --password-require-unbreached: oneof<nothing, bool> # Require passwords that have not been previously breached? (see https://haveibeenpwned.com/)
  --password-requirements-apply-to-bundles: oneof<nothing, bool> # Require bundles' passwords, and passwords for other items (inboxes, public shares, etc.) to conform to the same requirements as users' passwords?
  --password-validity-days: int # Number of days password is valid (format: int32)
  --pin-all-remote-servers-to-site-region: oneof<nothing, bool> # If true, we will ensure that all internal communications with any remote server are made through the primary region of the site. This setting overrides individual remote server settings.
  --reply-to-email: string # Reply-to email for this site
  --require-2fa: oneof<nothing, bool> # Require two-factor authentication for all users?
  --require-2fa-user-type: string # What type of user is required to use two-factor authentication (when require_2fa is set to `true` for this site)?
  --session-expiry: float # Session expiry in hours (format: double)
  --session-expiry-minutes: int # Session expiry in minutes (format: int32)
  --session-pinned-by-ip: oneof<nothing, bool> # Are sessions locked to the same IP? (i.e. do users need to log in again if they change IPs?)
  --sftp-enabled: oneof<nothing, bool> # Is SFTP enabled?
  --sftp-host-key-type: string # Sftp Host Key Type
  --sftp-insecure-ciphers: oneof<nothing, bool> # Are Insecure Ciphers allowed for SFTP? Note: Settting TLS Disabled -> True will always allow insecure ciphers for SFTP as well. Enabling this is insecure.
  --sftp-user-root-enabled: oneof<nothing, bool> # Use user FTP roots also for SFTP?
  --sharing-enabled: oneof<nothing, bool> # Allow bundle creation
  --show-request-access-link: oneof<nothing, bool> # Show request access link for users without access? Currently unused.
  --site-footer: string # Custom site footer text
  --site-header: string # Custom site header text
  --smtp-address: string # SMTP server hostname or IP
  --smtp-authentication: string # SMTP server authentication type
  --smtp-from: string # From address to use when mailing through custom SMTP
  --smtp-password: string # Password for SMTP server.
  --smtp-port: int # SMTP server port (format: int32)
  --smtp-username: string # SMTP server username
  --ssl-required: oneof<nothing, bool> # Is SSL required? Disabling this is insecure.
  --subdomain: string # Site subdomain
  --tls-disabled: oneof<nothing, bool> # Are Insecure TLS and SFTP Ciphers allowed? Enabling this is insecure.
  --uploads-via-email-authentication: oneof<nothing, bool> # Do incoming emails in the Inboxes require checking for SPF/DKIM/DMARC?
  --use-provided-modified-at: oneof<nothing, bool> # Allow uploaders to set `provided_modified_at` for uploaded files?
  --user-lockout: oneof<nothing, bool> # Will users be locked out after incorrect login attempts?
  --user-lockout-lock-period: int # How many hours to lock user out for failed password? (format: int32)
  --user-lockout-tries: int # Number of login tries within `user_lockout_within` hours before users are locked out (format: int32)
  --user-lockout-within: int # Number of hours for user lockout window (format: int32)
  --user-requests-enabled: oneof<nothing, bool> # Enable User Requests feature
  --user-requests-notify-admins: oneof<nothing, bool> # Send email to site admins when a user request is received?
  --welcome-custom-text: string # Custom text send in user welcome email
  --welcome-email-cc: string # Include this email in welcome emails if enabled
  --welcome-email-enabled: oneof<nothing, bool> # Will the welcome email be sent to new users?
  --welcome-email-subject: string # Include this email subject in welcome emails if enabled
  --welcome-screen: string # Does the welcome screen appear?
  --windows-mode-ftp: oneof<nothing, bool> # Does FTP user Windows emulation mode?
]: any -> record<active_sftp_host_key_id: int, admin_user_id: int, allow_bundle_names: bool, allowed_2fa_method_bypass_for_ftp_sftp_dav: bool, allowed_2fa_method_sms: bool, allowed_2fa_method_totp: bool, allowed_2fa_method_u2f: bool, allowed_2fa_method_webauthn: bool, allowed_2fa_method_yubi: bool, allowed_countries: string, allowed_ips: string, ask_about_overwrites: bool, bundle_activity_notifications: string, bundle_expiration: int, bundle_password_required: bool, bundle_registration_notifications: string, bundle_require_share_recipient: bool, bundle_upload_receipt_notifications: string, bundle_watermark_attachment: record<name: string, uri: string>, bundle_watermark_value: record, color2_left: string, color2_link: string, color2_text: string, color2_top: string, color2_top_text: string, contact_name: string, created_at: string, currency: string, custom_namespace: bool, days_to_retain_backups: int, default_time_zone: string, desktop_app: bool, desktop_app_session_ip_pinning: bool, desktop_app_session_lifetime: int, disable_files_certificate_generation: bool, disable_notifications: bool, disable_password_reset: bool, disable_users_from_inactivity_period_days: int, disallowed_countries: string, domain: string, domain_hsts_header: bool, domain_letsencrypt_chain: string, email: string, folder_permissions_groups_only: bool, ftp_enabled: bool, hipaa: bool, icon128: record<name: string, uri: string>, icon16: record<name: string, uri: string>, icon32: record<name: string, uri: string>, icon48: record<name: string, uri: string>, immutable_files_set_at: string, include_password_in_welcome_email: bool, language: string, ldap_base_dn: string, ldap_domain: string, ldap_enabled: bool, ldap_group_action: string, ldap_group_exclusion: string, ldap_group_inclusion: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_type: string, ldap_user_action: string, ldap_user_include_groups: string, ldap_username: string, ldap_username_field: string, login_help_text: string, logo: record<name: string, uri: string>, max_prior_passwords: int, mobile_app: bool, mobile_app_session_ip_pinning: bool, mobile_app_session_lifetime: int, motd_text: string, motd_use_for_ftp: bool, motd_use_for_sftp: bool, name: string, next_billing_amount: float, next_billing_date: string, non_sso_groups_allowed: bool, non_sso_users_allowed: bool, office_integration_available: bool, office_integration_type: string, oncehub_link: string, opt_out_global: bool, overage_notified_at: string, overage_notify: bool, overdue: bool, password_min_length: int, password_require_letter: bool, password_require_mixed: bool, password_require_number: bool, password_require_special: bool, password_require_unbreached: bool, password_requirements_apply_to_bundles: bool, password_validity_days: int, phone: string, pin_all_remote_servers_to_site_region: bool, reply_to_email: string, require_2fa: bool, require_2fa_stop_time: string, require_2fa_user_type: string, session: record<id: string, language: string, read_only: bool, sftp_insecure_ciphers: bool>, session_expiry: float, session_expiry_minutes: int, session_pinned_by_ip: bool, sftp_enabled: bool, sftp_host_key_type: string, sftp_insecure_ciphers: bool, sftp_user_root_enabled: bool, sharing_enabled: bool, show_request_access_link: bool, site_footer: string, site_header: string, smtp_address: string, smtp_authentication: string, smtp_from: string, smtp_port: int, smtp_username: string, ssl_required: bool, subdomain: string, switch_to_plan_date: string, tls_disabled: bool, trial_days_left: int, trial_until: string, updated_at: string, uploads_via_email_authentication: bool, use_provided_modified_at: bool, user: record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string>, user_lockout: bool, user_lockout_lock_period: int, user_lockout_tries: int, user_lockout_within: int, user_requests_enabled: bool, user_requests_notify_admins: bool, welcome_custom_text: string, welcome_email_cc: string, welcome_email_enabled: bool, welcome_email_subject: string, welcome_screen: string, windows_mode_ftp: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site")
  let req_body = {"active_sftp_host_key_id": $active_sftp_host_key_id, "allow_bundle_names": $allow_bundle_names, "allowed_2fa_method_bypass_for_ftp_sftp_dav": $allowed_2fa_method_bypass_for_ftp_sftp_dav, "allowed_2fa_method_sms": $allowed_2fa_method_sms, "allowed_2fa_method_totp": $allowed_2fa_method_totp, "allowed_2fa_method_u2f": $allowed_2fa_method_u2f, "allowed_2fa_method_webauthn": $allowed_2fa_method_webauthn, "allowed_2fa_method_yubi": $allowed_2fa_method_yubi, "allowed_countries": $allowed_countries, "allowed_ips": $allowed_ips, "ask_about_overwrites": $ask_about_overwrites, "bundle_activity_notifications": $bundle_activity_notifications, "bundle_expiration": $bundle_expiration, "bundle_password_required": $bundle_password_required, "bundle_registration_notifications": $bundle_registration_notifications, "bundle_require_share_recipient": $bundle_require_share_recipient, "bundle_upload_receipt_notifications": $bundle_upload_receipt_notifications, "bundle_watermark_attachment_delete": $bundle_watermark_attachment_delete, "bundle_watermark_attachment_file": $bundle_watermark_attachment_file, "bundle_watermark_value": $bundle_watermark_value, "color2_left": $color2_left, "color2_link": $color2_link, "color2_text": $color2_text, "color2_top": $color2_top, "color2_top_text": $color2_top_text, "custom_namespace": $custom_namespace, "days_to_retain_backups": $days_to_retain_backups, "default_time_zone": $default_time_zone, "desktop_app": $desktop_app, "desktop_app_session_ip_pinning": $desktop_app_session_ip_pinning, "desktop_app_session_lifetime": $desktop_app_session_lifetime, "disable_2fa_with_delay": $disable_2fa_with_delay, "disable_files_certificate_generation": $disable_files_certificate_generation, "disable_password_reset": $disable_password_reset, "disable_users_from_inactivity_period_days": $disable_users_from_inactivity_period_days, "disallowed_countries": $disallowed_countries, "domain": $domain, "domain_hsts_header": $domain_hsts_header, "domain_letsencrypt_chain": $domain_letsencrypt_chain, "email": $email, "folder_permissions_groups_only": $folder_permissions_groups_only, "ftp_enabled": $ftp_enabled, "icon128_delete": $icon128_delete, "icon128_file": $icon128_file, "icon16_delete": $icon16_delete, "icon16_file": $icon16_file, "icon32_delete": $icon32_delete, "icon32_file": $icon32_file, "icon48_delete": $icon48_delete, "icon48_file": $icon48_file, "immutable_files": $immutable_files, "include_password_in_welcome_email": $include_password_in_welcome_email, "language": $language, "ldap_base_dn": $ldap_base_dn, "ldap_domain": $ldap_domain, "ldap_enabled": $ldap_enabled, "ldap_group_action": $ldap_group_action, "ldap_group_exclusion": $ldap_group_exclusion, "ldap_group_inclusion": $ldap_group_inclusion, "ldap_host": $ldap_host, "ldap_host_2": $ldap_host_2, "ldap_host_3": $ldap_host_3, "ldap_password_change": $ldap_password_change, "ldap_password_change_confirmation": $ldap_password_change_confirmation, "ldap_port": $ldap_port, "ldap_secure": $ldap_secure, "ldap_type": $ldap_type, "ldap_user_action": $ldap_user_action, "ldap_user_include_groups": $ldap_user_include_groups, "ldap_username": $ldap_username, "ldap_username_field": $ldap_username_field, "login_help_text": $login_help_text, "logo_delete": $logo_delete, "logo_file": $logo_file, "max_prior_passwords": $max_prior_passwords, "mobile_app": $mobile_app, "mobile_app_session_ip_pinning": $mobile_app_session_ip_pinning, "mobile_app_session_lifetime": $mobile_app_session_lifetime, "motd_text": $motd_text, "motd_use_for_ftp": $motd_use_for_ftp, "motd_use_for_sftp": $motd_use_for_sftp, "name": $name, "non_sso_groups_allowed": $non_sso_groups_allowed, "non_sso_users_allowed": $non_sso_users_allowed, "office_integration_available": $office_integration_available, "office_integration_type": $office_integration_type, "opt_out_global": $opt_out_global, "overage_notify": $overage_notify, "password_min_length": $password_min_length, "password_require_letter": $password_require_letter, "password_require_mixed": $password_require_mixed, "password_require_number": $password_require_number, "password_require_special": $password_require_special, "password_require_unbreached": $password_require_unbreached, "password_requirements_apply_to_bundles": $password_requirements_apply_to_bundles, "password_validity_days": $password_validity_days, "pin_all_remote_servers_to_site_region": $pin_all_remote_servers_to_site_region, "reply_to_email": $reply_to_email, "require_2fa": $require_2fa, "require_2fa_user_type": $require_2fa_user_type, "session_expiry": $session_expiry, "session_expiry_minutes": $session_expiry_minutes, "session_pinned_by_ip": $session_pinned_by_ip, "sftp_enabled": $sftp_enabled, "sftp_host_key_type": $sftp_host_key_type, "sftp_insecure_ciphers": $sftp_insecure_ciphers, "sftp_user_root_enabled": $sftp_user_root_enabled, "sharing_enabled": $sharing_enabled, "show_request_access_link": $show_request_access_link, "site_footer": $site_footer, "site_header": $site_header, "smtp_address": $smtp_address, "smtp_authentication": $smtp_authentication, "smtp_from": $smtp_from, "smtp_password": $smtp_password, "smtp_port": $smtp_port, "smtp_username": $smtp_username, "ssl_required": $ssl_required, "subdomain": $subdomain, "tls_disabled": $tls_disabled, "uploads_via_email_authentication": $uploads_via_email_authentication, "use_provided_modified_at": $use_provided_modified_at, "user_lockout": $user_lockout, "user_lockout_lock_period": $user_lockout_lock_period, "user_lockout_tries": $user_lockout_tries, "user_lockout_within": $user_lockout_within, "user_requests_enabled": $user_requests_enabled, "user_requests_notify_admins": $user_requests_notify_admins, "welcome_custom_text": $welcome_custom_text, "welcome_email_cc": $welcome_email_cc, "welcome_email_enabled": $welcome_email_enabled, "welcome_email_subject": $welcome_email_subject, "welcome_screen": $welcome_screen, "windows_mode_ftp": $windows_mode_ftp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["bundle_watermark_attachment_file" "icon128_file" "icon16_file" "icon32_file" "icon48_file" "logo_file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Api Keys
#
# GET /site/api_keys
# operationId: GetSiteApiKeys
export def "site-api-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/site/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Api Key
#
# POST /site/api_keys
# operationId: PostSiteApiKeys
export def "site-api-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site/api_keys")
  let req_body = {"description": $description, "expires_at": $expires_at, "name": $name, "path": $path, "permission_set": $permission_set, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show site DNS configuration.
#
# GET /site/dns_records
# operationId: GetSiteDnsRecords
export def "site-dns-records get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<domain: string, id: string, rrtype: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/site/dns_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List IP Addresses associated with the current site
#
# GET /site/ip_addresses
# operationId: GetSiteIpAddresses
export def "site-ip-addresses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<associated_with: string, group_id: int, id: string, ip_addresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/site/ip_addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Test webhook.
#
# POST /site/test-webhook
# operationId: PostSiteTestWebhook
export def "site-test-webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action for test body (e.g. test)
  --body: record # Additional body parameters. (e.g. {test-param: testvalue})
  --encoding: string # HTTP encoding method. Can be JSON, XML, or RAW (form data). (e.g. RAW)
  --headers: record # Additional request headers. (e.g. {x-test-header: testvalue})
  --method: string # HTTP method(GET or POST). (e.g. GET)
  url: string # URL for testing the webhook. (e.g. https://www.site.com/...)
]: any -> record<clickwrap_body: string, clickwrap_id: int, code: int, data: record<dynamic: record>, errors: table<fields: list, messages: list>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site/test-webhook")
  let req_body = {"action": $action, "body": $body, "encoding": $encoding, "headers": $headers, "method": $method, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get the most recent usage snapshot (usage data for billing purposes) for a Site.
#
# GET /site/usage
# operationId: GetSiteUsage
export def "site-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bytes_sent: float, current_storage: float, deleted_files_counted_in_minimum: float, deleted_files_storage: float, end_at: string, high_water_storage: float, high_water_user_count: float, id: int, root_storage: float, start_at: string, sync_bytes_received: float, sync_bytes_sent: float, total_billable_transfer_usage: float, total_billable_usage: float, usage_by_top_level_dir: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Sso Strategies
#
# GET /sso_strategies
# operationId: GetSsoStrategies
export def "sso-strategies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<deprovision_behavior: string, deprovision_groups: bool, deprovision_users: bool, enabled: bool, id: int, label: string, ldap_base_dn: string, ldap_domain: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_username: string, ldap_username_field: string, logo_url: string, protocol: string, provider: string, provision_attachments_permission: bool, provision_company: string, provision_dav_permission: bool, provision_email_signup_groups: string, provision_ftp_permission: bool, provision_group_default: string, provision_group_exclusion: string, provision_group_inclusion: string, provision_group_required: string, provision_groups: bool, provision_sftp_permission: bool, provision_site_admin_groups: string, provision_time_zone: string, provision_users: bool, saml_provider_cert_fingerprint: string, saml_provider_issuer_url: string, saml_provider_metadata_content: string, saml_provider_metadata_url: string, saml_provider_slo_target_url: string, saml_provider_sso_target_url: string, scim_authentication_method: string, scim_oauth_access_token: string, scim_oauth_access_token_expires_at: string, scim_username: string, subdomain: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sso_strategies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Sso Strategy
#
# GET /sso_strategies/{id}
# operationId: GetSsoStrategiesId
export def "sso-strategies get" [
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
]: nothing -> record<deprovision_behavior: string, deprovision_groups: bool, deprovision_users: bool, enabled: bool, id: int, label: string, ldap_base_dn: string, ldap_domain: string, ldap_host: string, ldap_host_2: string, ldap_host_3: string, ldap_port: int, ldap_secure: bool, ldap_username: string, ldap_username_field: string, logo_url: string, protocol: string, provider: string, provision_attachments_permission: bool, provision_company: string, provision_dav_permission: bool, provision_email_signup_groups: string, provision_ftp_permission: bool, provision_group_default: string, provision_group_exclusion: string, provision_group_inclusion: string, provision_group_required: string, provision_groups: bool, provision_sftp_permission: bool, provision_site_admin_groups: string, provision_time_zone: string, provision_users: bool, saml_provider_cert_fingerprint: string, saml_provider_issuer_url: string, saml_provider_metadata_content: string, saml_provider_metadata_url: string, saml_provider_slo_target_url: string, saml_provider_sso_target_url: string, scim_authentication_method: string, scim_oauth_access_token: string, scim_oauth_access_token_expires_at: string, scim_username: string, subdomain: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sso_strategies/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Synchronize provisioning data with the SSO remote server.
#
# POST /sso_strategies/{id}/sync
# operationId: PostSsoStrategiesIdSync
export def "sso-strategies-sync create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sso_strategies/{id}/sync"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Style
#
# DELETE /styles/{path}
# operationId: DeleteStylesPath
export def "styles delete" [
  path: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/styles/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Style
#
# GET /styles/{path}
# operationId: GetStylesPath
export def "styles get" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, logo: record<name: string, uri: string>, path: string, thumbnail: record<name: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/styles/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Style
#
# PATCH /styles/{path}
# operationId: PatchStylesPath
export def "styles update" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Logo for custom branding. (format: binary)
]: any -> record<id: int, logo: record<name: string, uri: string>, path: string, thumbnail: record<name: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/styles/{path}"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Usage Daily Snapshots
#
# GET /usage_daily_snapshots
# operationId: GetUsageDailySnapshots
export def "usage-daily-snapshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[date]=desc`). Valid fields are `date` and `usage_snapshot_id`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `date` and `usage_snapshot_id`. Valid field combinations are `[ usage_snapshot_id, date ]`.
]: nothing -> table<api_usage_available: bool, current_storage: int, date: string, deleted_files_counted_in_minimum: int, deleted_files_storage: int, id: int, read_api_usage: int, root_storage: int, usage_by_top_level_dir: record, user_count: int, write_api_usage: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/usage_daily_snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Usage Snapshots
#
# GET /usage_snapshots
# operationId: GetUsageSnapshots
export def "usage-snapshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<bytes_sent: float, current_storage: float, deleted_files_counted_in_minimum: float, deleted_files_storage: float, end_at: string, high_water_storage: float, high_water_user_count: float, id: int, root_storage: float, start_at: string, sync_bytes_received: float, sync_bytes_sent: float, total_billable_transfer_usage: float, total_billable_usage: float, usage_by_top_level_dir: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage_snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update User
#
# PATCH /user
# operationId: PatchUser
export def "user update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-id: int # Group ID to associate this user with. (format: int32)
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let req_body = {"allowed_ips": $allowed_ips, "announcements_read": $announcements_read, "attachments_permission": $attachments_permission, "authenticate_until": $authenticate_until, "authentication_method": $authentication_method, "avatar_delete": $avatar_delete, "avatar_file": $avatar_file, "billing_permission": $billing_permission, "bypass_inactive_disable": $bypass_inactive_disable, "bypass_site_allowed_ips": $bypass_site_allowed_ips, "change_password": $change_password, "change_password_confirmation": $change_password_confirmation, "company": $company, "dav_permission": $dav_permission, "disabled": $disabled, "email": $email, "ftp_permission": $ftp_permission, "grant_permission": $grant_permission, "group_id": $group_id, "group_ids": $group_ids, "header_text": $header_text, "imported_password_hash": $imported_password_hash, "language": $language, "name": $name, "notes": $notes, "notification_daily_send_time": $notification_daily_send_time, "office_integration_enabled": $office_integration_enabled, "password": $password, "password_confirmation": $password_confirmation, "password_validity_days": $password_validity_days, "receive_admin_alerts": $receive_admin_alerts, "require_2fa": $require_2fa, "require_password_change": $require_password_change, "restapi_permission": $restapi_permission, "self_managed": $self_managed, "sftp_permission": $sftp_permission, "site_admin": $site_admin, "skip_welcome_screen": $skip_welcome_screen, "ssl_required": $ssl_required, "sso_strategy_id": $sso_strategy_id, "subscribe_to_newsletter": $subscribe_to_newsletter, "time_zone": $time_zone, "user_root": $user_root, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatar_file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Api Keys
#
# GET /user/api_keys
# operationId: GetUserApiKeys
export def "user-api-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Api Key
#
# POST /user/api_keys
# operationId: PostUserApiKeys
export def "user-api-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/api_keys")
  let req_body = {"description": $description, "expires_at": $expires_at, "name": $name, "path": $path, "permission_set": $permission_set, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List Group Users
#
# GET /user/groups
# operationId: GetUserGroups
export def "user-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. If provided, will return group_users of this user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --group-id: int # Group ID. If provided, will return group_users of this group. (format: int32)
]: nothing -> table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Public Keys
#
# GET /user/public_keys
# operationId: GetUserPublicKeys
export def "user-public-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<created_at: string, fingerprint: string, id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/public_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Public Key
#
# POST /user/public_keys
# operationId: PostUserPublicKeys
export def "user-public-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  public_key: string # Actual contents of SSH key.
  title: string # Internal reference for key. (e.g. My Main Key)
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
]: any -> record<created_at: string, fingerprint: string, id: int, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/public_keys")
  let req_body = {"public_key": $public_key, "title": $title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List User Cipher Uses
#
# GET /user_cipher_uses
# operationId: GetUserCipherUses
export def "user-cipher-uses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # User ID. Provide a value of `0` to operate the current session's user. (format: int32)
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<created_at: string, id: int, interface: string, protocol_cipher: string, updated_at: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_cipher_uses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List User Requests
#
# GET /user_requests
# operationId: GetUserRequests
export def "user-requests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<details: string, email: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create User Request
#
# POST /user_requests
# operationId: PostUserRequests
export def "user-requests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  details: string # Details of the user request
  email: string # Email of user requested
  name: string # Name of user requested
]: any -> record<details: string, email: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_requests")
  let req_body = {"details": $details, "email": $email, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete User Request
#
# DELETE /user_requests/{id}
# operationId: DeleteUserRequestsId
export def "user-requests delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user_requests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show User Request
#
# GET /user_requests/{id}
# operationId: GetUserRequestsId
export def "user-requests get" [
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
]: nothing -> record<details: string, email: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user_requests/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Users
#
# GET /users
# operationId: GetUsers
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
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[authenticate_until]=desc`). Valid fields are `authenticate_until`, `active`, `email`, `last_desktop_login_at`, `last_login_at`, `username`, `company`, `name`, `site_admin`, `receive_admin_alerts`, `password_validity_days`, `ssl_required` or `not_site_admin`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `username`, `email`, `company`, `site_admin`, `password_validity_days`, `ssl_required`, `last_login_at`, `authenticate_until` or `not_site_admin`. Valid field combinations are `[ not_site_admin, username ]`.
  --ids: string # comma-separated list of User IDs
  --q-username: string # List users matching username.
  --q-email: string # List users matching email.
  --q-notes: string # List users matching notes field.
  --q-admin: string # If `true`, list only admin users.
  --q-allowed-ips: string # If set, list only users with overridden allowed IP setting.
  --q-password-validity-days: string # If set, list only users with overridden password validity days setting.
  --q-ssl-required: string # If set, list only users with overridden SSL required setting.
  --search: string # Searches for partial matches of name, username, or email.
]: nothing -> table<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "ids" $ids "scalar") (serialize-qp "q[username]" $q_username "scalar") (serialize-qp "q[email]" $q_email "scalar") (serialize-qp "q[notes]" $q_notes "scalar") (serialize-qp "q[admin]" $q_admin "scalar") (serialize-qp "q[allowed_ips]" $q_allowed_ips "scalar") (serialize-qp "q[password_validity_days]" $q_password_validity_days "scalar") (serialize-qp "q[ssl_required]" $q_ssl_required "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create User
#
# POST /users
# operationId: PostUsers
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
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-id: int # Group ID to associate this user with. (format: int32)
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"allowed_ips": $allowed_ips, "announcements_read": $announcements_read, "attachments_permission": $attachments_permission, "authenticate_until": $authenticate_until, "authentication_method": $authentication_method, "avatar_delete": $avatar_delete, "avatar_file": $avatar_file, "billing_permission": $billing_permission, "bypass_inactive_disable": $bypass_inactive_disable, "bypass_site_allowed_ips": $bypass_site_allowed_ips, "change_password": $change_password, "change_password_confirmation": $change_password_confirmation, "company": $company, "dav_permission": $dav_permission, "disabled": $disabled, "email": $email, "ftp_permission": $ftp_permission, "grant_permission": $grant_permission, "group_id": $group_id, "group_ids": $group_ids, "header_text": $header_text, "imported_password_hash": $imported_password_hash, "language": $language, "name": $name, "notes": $notes, "notification_daily_send_time": $notification_daily_send_time, "office_integration_enabled": $office_integration_enabled, "password": $password, "password_confirmation": $password_confirmation, "password_validity_days": $password_validity_days, "receive_admin_alerts": $receive_admin_alerts, "require_2fa": $require_2fa, "require_password_change": $require_password_change, "restapi_permission": $restapi_permission, "self_managed": $self_managed, "sftp_permission": $sftp_permission, "site_admin": $site_admin, "skip_welcome_screen": $skip_welcome_screen, "ssl_required": $ssl_required, "sso_strategy_id": $sso_strategy_id, "subscribe_to_newsletter": $subscribe_to_newsletter, "time_zone": $time_zone, "user_root": $user_root, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatar_file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Delete User
#
# DELETE /users/{id}
# operationId: DeleteUsersId
export def "users delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show User
#
# GET /users/{id}
# operationId: GetUsersId
export def "users get" [
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
]: nothing -> record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update User
#
# PATCH /users/{id}
# operationId: PatchUsersId
export def "users update" [
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
  --allowed-ips: string # A list of allowed IPs if applicable. Newline delimited (e.g. 127.0.0.1)
  --announcements-read: oneof<nothing, bool> # Signifies that the user has read all the announcements in the UI.
  --attachments-permission: oneof<nothing, bool> # DEPRECATED: Can the user create Bundles (aka Share Links)? Use the bundle permission instead. (e.g. true)
  --authenticate-until: string # Scheduled Date/Time at which user will be deactivated (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --authentication-method: string@authentication-method-completer # How is this user authenticated? (e.g. password)
  --avatar-delete: oneof<nothing, bool> # If true, the avatar will be deleted.
  --avatar-file: string # An image file for your user avatar. (format: binary)
  --billing-permission: oneof<nothing, bool> # Allow this user to perform operations on the account, payments, and invoices?
  --bypass-inactive-disable: oneof<nothing, bool> # Exempt this user from being disabled based on inactivity?
  --bypass-site-allowed-ips: oneof<nothing, bool> # Allow this user to skip site-wide IP blacklists?
  --change-password: string # Used for changing a password on an existing user.
  --change-password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `change_password`.
  --company: string # User's company (e.g. ACME Corp.)
  --dav-permission: oneof<nothing, bool> # Can the user connect with WebDAV? (e.g. true)
  --disabled: oneof<nothing, bool> # Is user disabled? Disabled users cannot log in, and do not count for billing purposes. Users can be automatically disabled after an inactivity period via a Site setting. (e.g. true)
  --email: string # User's email.
  --ftp-permission: oneof<nothing, bool> # Can the user access with FTP/FTPS? (e.g. true)
  --grant-permission: string # Permission to grant on the user root. Can be blank or `full`, `read`, `write`, `list`, or `history`.
  --group-id: int # Group ID to associate this user with. (format: int32)
  --group-ids: string # A list of group ids to associate this user with. Comma delimited.
  --header-text: string # Text to display to the user in the header of the UI (e.g. User-specific message.)
  --imported-password-hash: string # Pre-calculated hash of the user's password. If supplied, this will be used to authenticate the user on first login. Supported hash menthods are MD5, SHA1, and SHA256.
  --language: string # Preferred language (e.g. en)
  --name: string # User's full name (e.g. John Doe)
  --notes: string # Any internal notes on the user (e.g. Internal notes on this user.)
  --notification-daily-send-time: int # Hour of the day at which daily notifications should be sent. Can be in range 0 to 23 (format: int32, e.g. 18)
  --office-integration-enabled: oneof<nothing, bool> # Enable integration with Office for the web? (e.g. true)
  --password: string # User password.
  --password-confirmation: string # Optional, but if provided, we will ensure that it matches the value sent in `password`.
  --password-validity-days: int # Number of days to allow user to use the same password (format: int32, e.g. 1)
  --receive-admin-alerts: oneof<nothing, bool> # Should the user receive admin alerts such a certificate expiration notifications and overages? (e.g. true)
  --require-2fa: string@require-2fa-completer # 2FA required setting (e.g. always_require)
  --require-password-change: oneof<nothing, bool> # Is a password change required upon next user login? (e.g. true)
  --restapi-permission: oneof<nothing, bool> # Can this user access the REST API? (e.g. true)
  --self-managed: oneof<nothing, bool> # Does this user manage it's own credentials or is it a shared/bot user? (e.g. true)
  --sftp-permission: oneof<nothing, bool> # Can the user access with SFTP? (e.g. true)
  --site-admin: oneof<nothing, bool> # Is the user an administrator for this site? (e.g. true)
  --skip-welcome-screen: oneof<nothing, bool> # Skip Welcome page in the UI? (e.g. true)
  --ssl-required: string@ssl-required-completer # SSL required setting (e.g. always_require)
  --sso-strategy-id: int # SSO (Single Sign On) strategy ID for the user, if applicable. (format: int32, e.g. 1)
  --subscribe-to-newsletter: oneof<nothing, bool> # Is the user subscribed to the newsletter? (e.g. true)
  --time-zone: string # User time zone (e.g. Pacific Time (US & Canada))
  --user-root: string # Root folder for FTP (and optionally SFTP if the appropriate site-wide setting is set.) Note that this is not used for API, Desktop, or Web interface. (e.g. example)
  --username: string # User's username (e.g. user)
]: any -> record<active_2fa: bool, admin_group_ids: list<int>, allowed_ips: string, api_keys_count: int, attachments_permission: bool, authenticate_until: string, authentication_method: string, avatar_url: string, billing_permission: bool, bypass_inactive_disable: bool, bypass_site_allowed_ips: bool, company: string, created_at: string, dav_permission: bool, days_remaining_until_password_expire: int, disabled: bool, email: string, externally_managed: bool, first_login_at: string, ftp_permission: bool, group_ids: string, header_text: string, id: int, language: string, last_active_at: string, last_api_use_at: string, last_dav_login_at: string, last_desktop_login_at: string, last_ftp_login_at: string, last_login_at: string, last_protocol_cipher: string, last_restapi_login_at: string, last_sftp_login_at: string, last_web_login_at: string, lockout_expires: string, name: string, notes: string, notification_daily_send_time: int, office_integration_enabled: bool, password_expire_at: string, password_expired: bool, password_set_at: string, password_validity_days: int, public_keys_count: int, receive_admin_alerts: bool, require_2fa: string, require_password_change: bool, restapi_permission: bool, self_managed: bool, sftp_permission: bool, site_admin: bool, skip_welcome_screen: bool, ssl_required: string, sso_strategy_id: int, subscribe_to_newsletter: bool, time_zone: string, type_of_2fa: string, user_root: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let req_body = {"allowed_ips": $allowed_ips, "announcements_read": $announcements_read, "attachments_permission": $attachments_permission, "authenticate_until": $authenticate_until, "authentication_method": $authentication_method, "avatar_delete": $avatar_delete, "avatar_file": $avatar_file, "billing_permission": $billing_permission, "bypass_inactive_disable": $bypass_inactive_disable, "bypass_site_allowed_ips": $bypass_site_allowed_ips, "change_password": $change_password, "change_password_confirmation": $change_password_confirmation, "company": $company, "dav_permission": $dav_permission, "disabled": $disabled, "email": $email, "ftp_permission": $ftp_permission, "grant_permission": $grant_permission, "group_id": $group_id, "group_ids": $group_ids, "header_text": $header_text, "imported_password_hash": $imported_password_hash, "language": $language, "name": $name, "notes": $notes, "notification_daily_send_time": $notification_daily_send_time, "office_integration_enabled": $office_integration_enabled, "password": $password, "password_confirmation": $password_confirmation, "password_validity_days": $password_validity_days, "receive_admin_alerts": $receive_admin_alerts, "require_2fa": $require_2fa, "require_password_change": $require_password_change, "restapi_permission": $restapi_permission, "self_managed": $self_managed, "sftp_permission": $sftp_permission, "site_admin": $site_admin, "skip_welcome_screen": $skip_welcome_screen, "ssl_required": $ssl_required, "sso_strategy_id": $sso_strategy_id, "subscribe_to_newsletter": $subscribe_to_newsletter, "time_zone": $time_zone, "user_root": $user_root, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatar_file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Trigger 2FA Reset process for user who has lost access to their existing 2FA methods.
#
# POST /users/{id}/2fa/reset
# operationId: PostUsersId2faReset
export def "users-2fa-reset create-id2fa" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/2fa/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resend user welcome email
#
# POST /users/{id}/resend_welcome_email
# operationId: PostUsersIdResendWelcomeEmail
export def "users-resend-welcome-email create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/resend_welcome_email"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Unlock user who has been locked out due to failed logins.
#
# POST /users/{id}/unlock
# operationId: PostUsersIdUnlock
export def "users-unlock create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/unlock"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Api Keys
#
# GET /users/{user_id}/api_keys
# operationId: GetUsersUserIdApiKeys
export def "users-api-keys get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[expires_at]=desc`). Valid fields are `expires_at`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `expires_at`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `expires_at`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `expires_at`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `expires_at`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `expires_at`.
]: nothing -> table<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/api_keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Api Key
#
# POST /users/{user_id}/api_keys
# operationId: PostUsersUserIdApiKeys
export def "users-api-keys create" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # User-supplied description of API key. (e.g. example)
  --expires-at: string # API Key expiration date (format: date-time, e.g. 2000-01-01T01:00:00Z)
  --name: string # Internal name for the API Key. For your use. (e.g. My Main API Key)
  --path: string # Folder path restriction for this api key. (e.g. shared/docs)
  --permission-set: string@permission-set-completer # Permissions for this API Key. Keys with the `desktop_app` permission set only have the ability to do the functions provided in our Desktop App (File and Share Link operations). Additional permission sets may become available in the future, such as for a Site Admin to give a key with no administrator privileges. If you have ideas for permission sets, please let us know. (default: full, e.g. full)
]: any -> record<created_at: string, description: string, descriptive_label: string, expires_at: string, id: int, key: string, last_use_at: string, name: string, path: string, permission_set: string, platform: string, url: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/api_keys"))
  let req_body = {"description": $description, "expires_at": $expires_at, "name": $name, "path": $path, "permission_set": $permission_set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List User Cipher Uses
#
# GET /users/{user_id}/cipher_uses
# operationId: GetUsersUserIdCipherUses
export def "users-cipher-uses get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<created_at: string, id: int, interface: string, protocol_cipher: string, updated_at: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/cipher_uses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Group Users
#
# GET /users/{user_id}/groups
# operationId: GetUsersUserIdGroups
export def "users-groups get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --group-id: int # Group ID. If provided, will return group_users of this group. (format: int32)
]: nothing -> table<admin: bool, group_id: int, group_name: string, user_id: int, usernames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Permissions
#
# GET /users/{user_id}/permissions
# operationId: GetUsersUserIdPermissions
export def "users-permissions get" [
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
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
  --sort-by: record # If set, sort records by the specified field in either `asc` or `desc` direction (e.g. `sort_by[group_id]=desc`). Valid fields are `group_id`, `path`, `user_id` or `permission`.
  --filter: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gt: record # If set, return records where the specified field is greater than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-gteq: record # If set, return records where the specified field is greater than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-like: record # If set, return records where the specified field is equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lt: record # If set, return records where the specified field is less than the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --filter-lteq: record # If set, return records where the specified field is less than or equal to the supplied value. Valid fields are `group_id`, `user_id` or `path`. Valid field combinations are `[ group_id, path ]` and `[ user_id, path ]`.
  --path: string # DEPRECATED: Permission path. If provided, will scope permissions to this path. Use `filter[path]` instead.
  --group-id: string # DEPRECATED: Group ID. If provided, will scope permissions to this group. Use `filter[group_id]` instead.`
  --include-groups: oneof<nothing, bool> # If searching by user or group, also include user's permissions that are inherited from its groups?
]: nothing -> table<group_id: int, group_name: string, id: int, path: string, permission: string, recursive: bool, user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "filter_gt" $filter_gt "multi") (serialize-qp "filter_gteq" $filter_gteq "multi") (serialize-qp "filter_like" $filter_like "multi") (serialize-qp "filter_lt" $filter_lt "multi") (serialize-qp "filter_lteq" $filter_lteq "multi") (serialize-qp "path" $path "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "include_groups" $include_groups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Public Keys
#
# GET /users/{user_id}/public_keys
# operationId: GetUsersUserIdPublicKeys
export def "users-public-keys get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Used for pagination. When a list request has more records available, cursors are provided in the response headers `X-Files-Cursor-Next` and `X-Files-Cursor-Prev`. Send one of those cursor value here to resume an existing list from the next available record. Note: many of our SDKs have iterator methods that will automatically handle cursor-based pagination.
  --per-page: int # Number of records to show per page. (Max: 10,000, 1,000 or less is recommended). (format: int32)
]: nothing -> table<created_at: string, fingerprint: string, id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/public_keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Public Key
#
# POST /users/{user_id}/public_keys
# operationId: PostUsersUserIdPublicKeys
export def "users-public-keys create" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  public_key: string # Actual contents of SSH key.
  title: string # Internal reference for key. (e.g. My Main Key)
]: any -> record<created_at: string, fingerprint: string, id: int, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/public_keys"))
  let req_body = {"public_key": $public_key, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create Webhook Test
#
# POST /webhook_tests
# operationId: PostWebhookTests
export def "webhook-tests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action for test body (e.g. test)
  --body: record # Additional body parameters. (e.g. {test-param: testvalue})
  --encoding: string # HTTP encoding method. Can be JSON, XML, or RAW (form data). (e.g. RAW)
  --file-as-body: oneof<nothing, bool> # Send the file data as the request body?
  --file-form-field: string # Send the file data as a named parameter in the request POST body (e.g. upload_file_data)
  --headers: record # Additional request headers. (e.g. {x-test-header: testvalue})
  --method: string # HTTP method(GET or POST). (e.g. GET)
  --raw-body: string # raw body text (e.g. test body)
  url: string # URL for testing the webhook. (e.g. https://www.site.com/...)
]: any -> record<code: int, data: record<dynamic: record>, message: string, status: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-filesapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_tests")
  let req_body = {"action": $action, "body": $body, "encoding": $encoding, "file_as_body": $file_as_body, "file_form_field": $file_form_field, "headers": $headers, "method": $method, "raw_body": $raw_body, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}
