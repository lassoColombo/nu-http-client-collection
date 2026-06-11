# Auto-generated client for API v1 vv1
# Source: https://api.apis.guru/v2/specs/formapi.io/v1/openapi.json
# Auth: --token flag or $env.API_V1_TOKEN

const BASE_URL = "https://api.docspring.com/api/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.docspring.com/api/v1"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def auth-second-factor-type-completer [] { ["fingerprint" "mobile_push" "none" "phone_number" "security_key" "totp"] }
def auth-type-completer [] { ["email_link" "ldap" "none" "oauth" "password" "phone_number" "saml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authentication testAuthentication" } } | get name | first)
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
export def "authentication testAuthentication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all combined submissions
#
# GET /combined_submissions
# operationId: listCombinedSubmissions
export def "combined-submissions listCombinedSubmissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Default: 1 (e.g. 2)
  --per-page: int # Default: 50 (e.g. 1)
]: nothing -> table<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/combined_submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge generated PDFs together
#
# POST /combined_submissions
# operationId: combineSubmissions
export def "combined-submissions combineSubmissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-in: int
  --metadata: record
  --password: string
  submission_ids: list
  --test: string@bool-completer
]: any -> record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/combined_submissions")
  let body = {expires_in: $expires_in, metadata: $metadata, password: $password, submission_ids: $submission_ids, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Expire a combined submission
#
# DELETE /combined_submissions/{combined_submission_id}
# operationId: expireCombinedSubmission
export def "combined-submissions expireCombinedSubmission" [
  combined_submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/combined_submissions/($combined_submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/combined_submissions/($combined_submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge submission PDFs, template PDFs, or custom files
#
# POST /combined_submissions?v=2
# operationId: combinePdfs
export def "combined-submissions-v2 combinePdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-custom-files: string@bool-completer
  --expires-in: int
  --metadata: record
  --password: string
  source_pdfs: list
  --test: string@bool-completer
]: any -> record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/combined_submissions?v=2")
  let body = {delete_custom_files: $delete_custom_files, expires_in: $expires_in, metadata: $metadata, password: $password, source_pdfs: $source_pdfs, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new custom file from a cached presign upload
#
# POST /custom_files
# operationId: createCustomFileFromUpload
export def "custom-files createCustomFileFromUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cache_id: string
]: any -> record<custom_file: record<id: string, url: string>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_files")
  let body = {cache_id: $cache_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data_requests/($data_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a submission data request
#
# PUT /data_requests/{data_request_id}
# operationId: updateDataRequest
export def "data-requests updateDataRequest" [
  data_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-phone-number-hash: string # nullable
  --auth-provider: string # nullable
  --auth-second-factor-type: string@auth-second-factor-type-completer
  --auth-session-id-hash: string # nullable
  --auth-session-started-at: string # nullable
  --auth-type: string@auth-type-completer
  --auth-user-id-hash: string # nullable
  --auth-username-hash: string # nullable
  --email: string # nullable
  --body-fields: list
  --metadata: record
  --name: string # nullable
  --order: int
]: any -> record<data_request: record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data_requests/($data_request_id)")
  let body = {auth_phone_number_hash: $auth_phone_number_hash, auth_provider: $auth_provider, auth_second_factor_type: $auth_second_factor_type, auth_session_id_hash: $auth_session_id_hash, auth_session_started_at: $auth_session_started_at, auth_type: $auth_type, auth_user_id_hash: $auth_user_id_hash, auth_username_hash: $auth_username_hash, email: $email, fields: $body_fields, metadata: $metadata, name: $name, order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new data request token for form authentication
#
# POST /data_requests/{data_request_id}/tokens
# operationId: createDataRequestToken
export def "data-requests-tokens createDataRequestToken" [
  data_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<errors: list<string>, status: string, token: record<data_request_url: string, expires_at: string, id: string, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data_requests/($data_request_id)/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all folders
#
# GET /folders/
# operationId: listFolders
export def "folders listFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-folder-id: string # Filter By Folder Id (e.g. fld_000000000000000002)
]: nothing -> table<id: string, name: string, parent_folder_id: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_folder_id" $parent_folder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a folder
#
# POST /folders/
# operationId: createFolder
# --folder shape: {name: string, parent_folder_id?: string}
export def "folders createFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  folder: record # shape: {name: string, parent_folder_id?: string}
]: any -> record<id: string, name: string, parent_folder_id: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/folders/")
  let body = {folder: $folder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, name: string, parent_folder_id: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move a folder
#
# POST /folders/{folder_id}/move
# operationId: moveFolderToFolder
export def "folders-move moveFolderToFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-folder-id: string
]: any -> record<id: string, name: string, parent_folder_id: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/move")
  let body = {parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename a folder
#
# POST /folders/{folder_id}/rename
# operationId: renameFolder
export def "folders-rename renameFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/rename")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all submissions
#
# GET /submissions
# operationId: listSubmissions
export def "submissions listSubmissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # e.g. sub_list_000012
  --limit: float # e.g. 3
  --created-after: string # e.g. 2019-01-01T09:00:00-05:00
  --created-before: string # e.g. 2020-01-01T09:00:00-05:00
  --type: string # e.g. test
  --include-data: string@bool-completer # e.g. true
]: nothing -> record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include_data" $include_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generates multiple PDFs
#
# POST /submissions/batches
# operationId: batchGeneratePdfs
# --submissions item shape: {css?: string, data: record, html?: string, metadata?: record, template_id: string, test?: bool}
export def "submissions-batches batchGeneratePdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record
  submissions: list # item shape: {css?: string, data: record, html?: string, metadata?: record, template_id: string, test?: bool}
  --template-id: string # nullable
  --test: string@bool-completer
]: any -> record<error: string, errors: list<string>, status: string, submission_batch: record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: list<record>, total_count: int>, submissions: table<errors: list, status: string, submission: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/batches")
  let body = {metadata: $metadata, submissions: $submissions, template_id: $template_id, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --include-submissions: string@bool-completer # e.g. true
]: nothing -> record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_submissions" $include_submissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/submissions/batches/($submission_batch_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Expire a PDF submission
#
# DELETE /submissions/{submission_id}
# operationId: expireSubmission
export def "submissions expireSubmission" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/submissions/($submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --include-data: string@bool-completer # e.g. true
]: nothing -> record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_data" $include_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/submissions/($submission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all templates
#
# GET /templates
# operationId: listTemplates
export def "templates listTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search By Name (e.g. 2)
  --parent-folder-id: string # Filter By Folder Id (e.g. fld_000000000000000001)
  --page: int # Default: 1 (e.g. 2)
  --per-page: int # Default: 50 (e.g. 1)
]: nothing -> table<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "parent_folder_id" $parent_folder_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new PDF template with a form POST file upload
#
# POST /templates
# operationId: createPDFTemplate
export def "templates createPDFTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  templatedocument: string # format: binary, e.g. <Uploaded File>
  templatename: string # e.g. Test Template
  --templateparent-folder-id: string # e.g. fld_000000000000000001
]: any -> record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {template[document]: $templatedocument, template[name]: $templatename, template[parent_folder_id]: $templateparent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Check the status of an uploaded template
#
# GET /templates/{template_id}
# operationId: getTemplate
export def "templates get-by-template_id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Template
#
# PUT /templates/{template_id}
# operationId: updateTemplate
# --template shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name?: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, webhook_url?: string}
export def "templates updateTemplate" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: record # shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name?: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, webhook_url?: string}
]: any -> record<errors: list<string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add new fields to a Template
#
# PUT /templates/{template_id}/add_fields
# operationId: addFieldsToTemplate
# --fields item shape: {alignment?: "left"|"center"|"right", autoCalculateMaxLength?: bool, backgroundColor?: string, backgroundColorFieldName?: string, backgroundColorFieldRequired?: bool, barcodeSymbology?: string, bold?: bool, characterSpacing?: float, checkCharacter?: "&#10003;"|"&#10004;"|"&#10006;"|"&#10007;"|"&#10008;", checkColor?: string, checkColorFieldName?: string, checkColorFieldRequired?: bool, color?: string, colorFieldName?: string, colorFieldRequired?: bool, comb?: bool, combNumberOfCells?: float, combValueOffset?: float, combinedFieldFormat?: string, combinedFieldNames?: string, combinedFieldSeparator?: string, combinedFieldType?: string, condition?: string, currency?: bool, dateTimeFormat?: string, decimalPlaces?: float, default?: string, description?: string, displayType?: "text"|"check"|"qrcode"|"barcode"|"image"|"shape", exclusiveMaximum?: bool, exclusiveMinimum?: bool, falseText?: string, fontSize?: float, height?: float, hidden?: bool, id?: float, imageGravity?: "NorthWest"|"North"|"NorthEast"|"West"|"Center"|"East"|"SouthWest"|"South"|"SouthEast", imageScaleType?: "fit"|"fill"|"stretch", includeTime?: bool, integer?: bool, invertBooleanCondition?: bool, maxLength?: float, maximum?: float, metadata?: string, minLength?: float, minimum?: float, multiline?: bool, multilineLines?: float, name: string, numberConditionRangeExclusiveMax?: bool, numberConditionRangeExclusiveMin?: bool, numberConditionRangeMax?: float, numberConditionRangeMin?: float, numberConditionType?: "equals"|"range"|"gte"|"gt"|"lte"|"lt", opacity?: float, optionList?: string, overflow?: "shrink_to_fit"|"truncate", page: float, placeholder?: string, qrcodeColor?: string, qrcodeColorFieldName?: string, qrcodeColorFieldRequired?: bool, required?: bool, rotation?: float, shapeBorderColor?: string, shapeBorderColorFieldName?: string, shapeBorderColorFieldRequired?: bool, shapeBorderWidth?: float, shapeFillColor?: string, shapeFillColorFieldName?: string, shapeFillColorFieldRequired?: bool, shapeType?: "square"|"rectangle"|"circle"|"ellipse", signatureAllowDraw?: bool, signatureAllowType?: bool, static?: bool, strikethrough?: bool, stringConditionType?: "equals"|"contains"|"starts_with"|"ends_with"|"regex", title?: string, trueText?: string, type?: "string"|"number"|"boolean"|"date"|"address"|"country"|"email"|"url"|"image"|"signature"|"barcode"|"combined", typeface?: string, uppercase?: bool, vAlignment?: "bottom"|"center"|"top", width?: float, x?: float, y?: float}
export def "templates-add-fields addFieldsToTemplate" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-fields: list # item shape: {alignment?: "left"|"center"|"right", autoCalculateMaxLength?: bool, backgroundColor?: string, backgroundColorFieldName?: string, backgroundColorFieldRequired?: bool, barcodeSymbology?: string, bold?: bool, characterSpacing?: float, checkCharacter?: "&#10003;"|"&#10004;"|"&#10006;"|"&#10007;"|"&#10008;", checkColor?: string, checkColorFieldName?: string, checkColorFieldRequired?: bool, color?: string, colorFieldName?: string, colorFieldRequired?: bool, comb?: bool, combNumberOfCells?: float, combValueOffset?: float, combinedFieldFormat?: string, combinedFieldNames?: string, combinedFieldSeparator?: string, combinedFieldType?: string, condition?: string, currency?: bool, dateTimeFormat?: string, decimalPlaces?: float, default?: string, description?: string, displayType?: "text"|"check"|"qrcode"|"barcode"|"image"|"shape", exclusiveMaximum?: bool, exclusiveMinimum?: bool, falseText?: string, fontSize?: float, height?: float, hidden?: bool, id?: float, imageGravity?: "NorthWest"|"North"|"NorthEast"|"West"|"Center"|"East"|"SouthWest"|"South"|"SouthEast", imageScaleType?: "fit"|"fill"|"stretch", includeTime?: bool, integer?: bool, invertBooleanCondition?: bool, maxLength?: float, maximum?: float, metadata?: string, minLength?: float, minimum?: float, multiline?: bool, multilineLines?: float, name: string, numberConditionRangeExclusiveMax?: bool, numberConditionRangeExclusiveMin?: bool, numberConditionRangeMax?: float, numberConditionRangeMin?: float, numberConditionType?: "equals"|"range"|"gte"|"gt"|"lte"|"lt", opacity?: float, optionList?: string, overflow?: "shrink_to_fit"|"truncate", page: float, placeholder?: string, qrcodeColor?: string, qrcodeColorFieldName?: string, qrcodeColorFieldRequired?: bool, required?: bool, rotation?: float, shapeBorderColor?: string, shapeBorderColorFieldName?: string, shapeBorderColorFieldRequired?: bool, shapeBorderWidth?: float, shapeFillColor?: string, shapeFillColorFieldName?: string, shapeFillColorFieldRequired?: bool, shapeType?: "square"|"rectangle"|"circle"|"ellipse", signatureAllowDraw?: bool, signatureAllowType?: bool, static?: bool, strikethrough?: bool, stringConditionType?: "equals"|"contains"|"starts_with"|"ends_with"|"regex", title?: string, trueText?: string, type?: "string"|"number"|"boolean"|"date"|"address"|"country"|"email"|"url"|"image"|"signature"|"barcode"|"combined", typeface?: string, uppercase?: bool, vAlignment?: "bottom"|"center"|"top", width?: float, x?: float, y?: float}
]: any -> record<errors: list<string>, new_field_ids: list<int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/add_fields")
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy a Template
#
# POST /templates/{template_id}/copy
# operationId: copyTemplate
export def "templates-copy copyTemplate" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  parent_folder_id: string
]: any -> record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/copy")
  let body = {name: $name, parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move Template to folder
#
# POST /templates/{template_id}/move
# operationId: moveTemplateToFolder
export def "templates-move moveTemplateToFolder" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  parent_folder_id: string
]: any -> record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/move")
  let body = {parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<_schema: string, additionalProperties: bool, definitions: record, description: string, id: string, properties: record, required: list<any>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --cursor: string
  --limit: float
  --created-after: string
  --created-before: string
  --type: string
  --include-data: string@bool-completer # e.g. true
]: nothing -> record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include_data" $include_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($template_id)/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generates a new PDF
#
# POST /templates/{template_id}/submissions
# operationId: generatePDF
# --data_requests item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list, metadata?: record, name?: string, order?: int}
export def "templates-submissions generatePDF" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --css: string
  data: record
  --data-requests: list # item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list, metadata?: record, name?: string, order?: int}
  --expires-in: int
  --field-overrides: record
  --html: string
  --metadata: record
  --password: string
  --test: string@bool-completer
]: any -> record<errors: list<string>, status: string, submission: record<actions: list<record>, batch_id: string, data: record, data_requests: list<record>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/submissions")
  let body = {css: $css, data: $data, data_requests: $data_requests, expires_in: $expires_in, field_overrides: $field_overrides, html: $html, metadata: $metadata, password: $password, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generates multiple PDFs
#
# POST /templates/{template_id}/submissions/batch
# operationId: batchGeneratePdfV1
# --data_requests item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list, metadata?: record, name?: string, order?: int}
export def "templates-submissions-batch batchGeneratePdfV1" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --css: string
  data: record
  --data-requests: list # item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list, metadata?: record, name?: string, order?: int}
  --html: string
  --metadata: record
  --test: string@bool-completer
]: any -> table<errors: list<string>, status: string, submission: record<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/submissions/batch")
  let body = {css: $css, data: $data, data_requests: $data_requests, html: $html, metadata: $metadata, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch the full template attributes
#
# GET /templates/{template_id}?full=true
# operationId: getFullTemplate
export def "templates get-by-template_id-1" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allow_additional_properties: bool, defaults: record<color: string, fontSize: float, typeface: string>, demo: bool, description: string, document_filename: string, document_md5: string, document_parse_error: bool, document_processed: bool, document_state: string, document_url: string, editable_submissions: bool, embed_domains: list<string>, encrypt_pdfs: bool, encrypt_pdfs_password: string, expiration_interval: string, expire_after: float, expire_submissions: bool, field_order: list<list<float>>, fields: record, first_template: bool, footer_html: string, header_html: string, html: string, id: string, locked: bool, name: string, page_count: float, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, scss: string, shared_field_data: record, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)?full=true")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new PDF template from a cached presign upload
#
# POST /templates?desc=cached_upload
# operationId: createPDFTemplateFromUpload
# --template shape: {allow_additional_properties?: bool, description?: string, document?: record, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
export def "templates-desccached-upload createPDFTemplateFromUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: record # shape: {allow_additional_properties?: bool, description?: string, document?: record, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
]: any -> record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates?desc=cached_upload")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new HTML template
#
# POST /templates?desc=html
# operationId: createHTMLTemplate
# --template shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
export def "templates-deschtml createHTMLTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: record # shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
]: any -> record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates?desc=html")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a presigned URL so that you can upload a file to our AWS S3 bucket
#
# GET /uploads/presign
# operationId: getPresignUrl
export def "uploads-presign get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: record<key: string, policy: string, x_amz_algorithm: string, x_amz_credential: string, x_amz_date: string, x_amz_signature: string>, headers: record, method: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/presign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
