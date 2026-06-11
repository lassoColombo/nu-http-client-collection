# Auto-generated client for Workspaces API vv1
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/workspaces.rest.swagger.json
# Auth: --token flag or $env.WORKSPACES_API_TOKEN

const BASE_URL = "https://api-d.docusign.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WORKSPACES_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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
def base-url-completer [] { ["https://api-d.docusign.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["complete" "draft" "in_progress" "overdue" "unknown"] }
def sort-completer [] { ["email_asc" "email_desc" "first_name_asc" "first_name_desc" "last_name_asc" "last_name_desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-workspaces-brand get" } } | get name | first)
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

# Returns details about the brand set for a workspace
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/brand
# operationId: getWorkspaceBrand
export def "accounts-workspaces-brand get" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<brand_id: string, brand_name: string, brand_company: string, colors: table<name: string, value: string>, logos: record<primary: string, secondary: string, email: string>, brand_languages: list<string>, default_brand_language: string, is_sending_default: bool, is_signing_default: bool, primary_logo_id: string, secondary_logo_id: string, email_logo_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/brand")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates brand for an existing workspace
#
# PUT /v1/accounts/{accountId}/workspaces/{workspaceId}/brand
# operationId: updateWorkspaceBrand
export def "accounts-workspaces-brand updateWorkspaceBrand" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand-id: string # A GUID value that identifies a brand. For more information, see <a href="https://developers.docusign.com/docs/esign-rest-api/esign101/concepts/branding/">Branding</a> (nullable, format: uuid)
]: any -> record<brand_id: string, brand_name: string, brand_company: string, colors: table<name: string, value: string>, logos: record<primary: string, secondary: string, email: string>, brand_languages: list<string>, default_brand_language: string, is_sending_default: bool, is_signing_default: bool, primary_logo_id: string, secondary_logo_id: string, email_logo_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/brand")
  let body = {brand_id: $brand_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get documents in the workspace accessible to the calling user
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/documents
# operationId: getWorkspaceDocuments
export def "accounts-workspaces-documents list" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of documents to return. Defaults to the maximum which is 100 (format: int32)
  --start-position: int # Position of the first item in the total results. Defaults to 0 (format: int32)
  --name-filter: string # Filter documents where Name contains the filter. Defaults to null, to not filter
]: nothing -> record<documents: table<document_id: string, name: string, owner_id: string, size: int, created_date: string, last_updated_date: string, owner: record>, result_set_size: int, start_position: int, end_position: int, total_row_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "start_position" $start_position "scalar") (serialize-qp "name_filter" $name_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a document to a workspace via file contents upload
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/documents
# operationId: addWorkspaceDocument
export def "accounts-workspaces-documents addWorkspaceDocument" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # The file within the multipart/form-data (format: binary)
]: any -> record<document_id: string, name: string, owner_id: string, size: int, created_date: string, last_updated_date: string, owner: record<user_id: string, first_name: string, last_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/documents")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get information about the document
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/documents/{documentId}
# operationId: getWorkspaceDocument
export def "accounts-workspaces-documents get" [
  accountId: string
  workspaceId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<workspace_id: string, document_id: string, name: string, owner_id: string, size: int, created_date: string, content_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a document in the workspace
#
# DELETE /v1/accounts/{accountId}/workspaces/{workspaceId}/documents/{documentId}
# operationId: deleteWorkspaceDocument
export def "accounts-workspaces-documents delete" [
  accountId: string
  workspaceId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the file contents of the document
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/documents/{documentId}/contents
# operationId: getWorkspaceDocumentContents
export def "accounts-workspaces-documents-contents get" [
  accountId: string
  workspaceId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/documents/($documentId)/contents")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new upload request within a workspace
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests
# operationId: createWorkspaceUploadRequest
# --assignments item shape: {assignee_user_id?: string, upload_request_responsibility_type_id: "watcher"|"assignee", first_name?: string, last_name?: string, email?: string}
export def "accounts-workspaces-upload-requests createWorkspaceUploadRequest" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the upload request (nullable)
  --description: string # The description of the upload request (nullable)
  due_date: string # The due date for the upload request (format: date-time)
  --assignments: list # List of user assignments for the upload request (nullable) — item shape: {assignee_user_id?: string, upload_request_responsibility_type_id: "watcher"|"assignee", first_name?: string, last_name?: string, email?: string}
  status: string@status-completer # Enum representing the status of a workspace upload request
]: any -> record<upload_request_id: string, workspace_id: string, name: string, description: string, upload_request_owner: record<user_id: string>, status: string, documents: table<document_name: string, document_id: string>, assignments: table<assignee_user_id: string, upload_request_responsibility_type_id: string>, created_date: string, updated_date: string, due_date: string, sent_date: string, completed_date: string, can_view: bool, can_edit: bool, can_delete: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests")
  let body = {name: $name, description: $description, due_date: $due_date, assignments: $assignments, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets upload requests within a workspace
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests
# operationId: getWorkspaceUploadRequests
export def "accounts-workspaces-upload-requests list" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<upload_request_id: string, workspace_id: string, name: string, description: string, upload_request_owner: record, status: string, documents: list, assignments: list, created_date: string, updated_date: string, due_date: string, sent_date: string, completed_date: string, can_view: bool, can_edit: bool, can_delete: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details for a specific upload request
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests/{uploadRequestId}
# operationId: getWorkspaceUploadRequest
export def "accounts-workspaces-upload-requests get" [
  accountId: string
  workspaceId: string
  uploadRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<upload_request_id: string, workspace_id: string, name: string, description: string, upload_request_owner: record<user_id: string>, status: string, documents: table<document_name: string, document_id: string>, assignments: table<assignee_user_id: string, upload_request_responsibility_type_id: string>, created_date: string, updated_date: string, due_date: string, sent_date: string, completed_date: string, can_view: bool, can_edit: bool, can_delete: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests/($uploadRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a specific upload request
#
# PUT /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests/{uploadRequestId}
# operationId: updateWorkspaceUploadRequest
# --upload_request_owner shape: {user_id: string}
# --documents item shape: {document_name?: string, document_id?: string}
# --assignments item shape: {assignee_user_id: string, upload_request_responsibility_type_id?: "watcher"|"assignee"}
export def "accounts-workspaces-upload-requests updateWorkspaceUploadRequest" [
  accountId: string
  workspaceId: string
  uploadRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --upload-request-id: string # The ID of the upload request (nullable, format: uuid)
  --workspace-id: string # The ID of the workspace (nullable, format: uuid)
  --name: string # The name of the upload request (editable) (nullable)
  --description: string # The description of the upload request (editable) (nullable)
  --upload-request-owner: record # shape: {user_id: string}
  status: string@status-completer # Enum representing the status of a workspace upload request
  --documents: list # List of documents associated with the upload request (nullable) — item shape: {document_name?: string, document_id?: string}
  --assignments: list # List of user assignments for the upload request (nullable) — item shape: {assignee_user_id: string, upload_request_responsibility_type_id?: "watcher"|"assignee"}
  --created-date: string # The date the upload request was created (nullable)
  --updated-date: string # The date the upload request was last updated (nullable)
  due_date: string # The due date for the upload request (editable) (format: date-time)
  --sent-date: string # The date the upload request was sent (nullable)
  --completed-date: string # The date the upload request was completed (nullable)
  --can-view: string@bool-completer # Whether the current user can view the upload request (nullable)
  --can-edit: string@bool-completer # Whether the current user can edit the upload request (nullable)
  --can-delete: string@bool-completer # Whether the current user can delete the upload request (nullable)
]: any -> record<upload_request_id: string, workspace_id: string, name: string, description: string, upload_request_owner: record<user_id: string>, status: string, documents: table<document_name: string, document_id: string>, assignments: table<assignee_user_id: string, upload_request_responsibility_type_id: string>, created_date: string, updated_date: string, due_date: string, sent_date: string, completed_date: string, can_view: bool, can_edit: bool, can_delete: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests/($uploadRequestId)")
  let body = {upload_request_id: $upload_request_id, workspace_id: $workspace_id, name: $name, description: $description, upload_request_owner: $upload_request_owner, status: $status, documents: $documents, assignments: $assignments, created_date: $created_date, updated_date: $updated_date, due_date: $due_date, sent_date: $sent_date, completed_date: $completed_date, can_view: $can_view, can_edit: $can_edit, can_delete: $can_delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a specific upload request
#
# DELETE /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests/{uploadRequestId}
# operationId: deleteWorkspaceUploadRequest
export def "accounts-workspaces-upload-requests delete" [
  accountId: string
  workspaceId: string
  uploadRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests/($uploadRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a document to an upload request via file upload
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests/{uploadRequestId}/documents
# operationId: addWorkspaceUploadRequestDocument
export def "accounts-workspaces-upload-requests-documents addWorkspaceUploadRequestDocument" [
  accountId: string
  workspaceId: string
  uploadRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # The file within the multipart/form-data (format: binary)
]: any -> record<upload_request_id: string, document_id: string, document_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests/($uploadRequestId)/documents")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Complete an upload request
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/upload-requests/{uploadRequestId}/actions/complete
# operationId: completeWorkspaceUploadRequest
export def "accounts-workspaces-upload-requests-actions-complete completeWorkspaceUploadRequest" [
  accountId: string
  workspaceId: string
  uploadRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/upload-requests/($uploadRequestId)/actions/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of users in the given workspace
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/users
# operationId: getWorkspaceUsers
export def "accounts-workspaces-users get" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of workspace users to return. Defaults to the maximum which is 100. (format: int32)
  --start-position: int # Position of the first item in the total results. Defaults to 0. (format: int32)
  --filter: string # Returns workspace users filtered by Name and Email
  --qp-sort: string@sort-completer # Sorts results. Options are `first_name_asc`, `first_name_desc`, `last_name_asc`, `last_name_desc`, `email_asc`, `email_desc`. Defaults to `last_name_desc`
]: nothing -> record<users: table<user_id: string, email: string, first_name: string, last_name: string, role_id: string, role_name: string>, result_set_size: int, start_position: int, end_position: int, total_row_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "start_position" $start_position "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a user to the workspace by email address
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/users
# operationId: addWorkspaceUser
export def "accounts-workspaces-users addWorkspaceUser" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the added user. May be an internal user to the account or an external user
  first_name: string # The first name of the added user
  last_name: string # The last name of the added user
  --role-id: string # The optional Role ID to assign to the user. Defaults to the "Participate" role (nullable, format: uuid)
]: any -> record<workspace_id: string, user_id: string, role_id: string, email: string, first_name: string, last_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/users")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the specified user's role
#
# PUT /v1/accounts/{accountId}/workspaces/{workspaceId}/users/{userId}
# operationId: updateWorkspaceUser
export def "accounts-workspaces-users updateWorkspaceUser" [
  accountId: string
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role-id: string # The ID of the role to update to (format: uuid)
]: any -> record<role_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/users/($userId)")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revokes the specified user's access to the workspace
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/users/{userId}/actions/revoke-access
# operationId: revokeWorkspaceUserAccess
export def "accounts-workspaces-users-actions-revoke-access revokeWorkspaceUserAccess" [
  accountId: string
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --revocation-date: string # The optional date in the future to initiate the revocation. If not specified, the revocation will be immediate (nullable, format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/users/($userId)/actions/revoke-access")
  let body = {revocation_date: $revocation_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restores the specified user's access to the workspace
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/users/{userId}/actions/restore-access
# operationId: restoreWorkspaceUserAccess
export def "accounts-workspaces-users-actions-restore-access restoreWorkspaceUserAccess" [
  accountId: string
  workspaceId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/users/($userId)/actions/restore-access")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets workspaces available to the calling user
#
# GET /v1/accounts/{accountId}/workspaces
# operationId: getWorkspaces
export def "accounts-workspaces list" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of workspaces to return. Defaults to the maximum which is 100 (format: int32)
  --start-position: int # Position of the first item in the total results. Defaults to 0 (format: int32)
]: nothing -> record<workspaces: table<workspace_id: string, name: string, created_date: string, created_by_user_id: string>, result_set_size: int, start_position: int, end_position: int, total_row_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "start_position" $start_position "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new workspace
#
# POST /v1/accounts/{accountId}/workspaces
# operationId: createWorkspace
export def "accounts-workspaces createWorkspace" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the workspace (nullable)
  --brand-id: string # A GUID value that identifies a brand. For more information, see <a href="https://developers.docusign.com/docs/esign-rest-api/esign101/concepts/branding/">Branding</a> (nullable, format: uuid)
]: any -> record<workspace_id: string, name: string, created_date: string, created_by_user_id: string, workspace_owner_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces")
  let body = {name: $name, brand_id: $brand_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an existing workspace
#
# PUT /v1/accounts/{accountId}/workspaces/{workspaceId}
# operationId: updateWorkspace
export def "accounts-workspaces updateWorkspace" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The updated name of the workspace (nullable)
]: any -> record<workspace_id: string, name: string, created_date: string, created_by_user_id: string, workspace_owner_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns details about the workspace
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}
# operationId: getWorkspace
export def "accounts-workspaces get" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<workspace_id: string, name: string, created_date: string, created_by_user_id: string, workspace_owner_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the roles the caller can assign to workspace users
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/assignable-roles
# operationId: getWorkspaceAssignableRoles
export def "accounts-workspaces-assignable-roles get" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A search filter that returns assignable roles by the beginning of the role name
  --start-position: int # The index position within the total result set from which to start returning values. The default value is 0 (format: int32)
  --count: int # The number of results to return. This value must be a number between 1 and 100 (default) (format: int32)
]: nothing -> record<roles: table<role_id: string, name: string, is_external: bool, created_date: string>, result_set_size: int, start_position: int, end_position: int, total_row_count: int, current_role_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start_position" $start_position "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/assignable-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an envelope with the given documents. Returns the ID of the created envelope
#
# POST /v1/accounts/{accountId}/workspaces/{workspaceId}/envelopes
# operationId: createWorkspaceEnvelope
export def "accounts-workspaces-envelopes createWorkspaceEnvelope" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --envelope-name: string # The name for the envelope (nullable)
  --document-ids: list # The optional list of document IDs to be added to the envelope (nullable)
]: any -> record<envelope_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/envelopes")
  let body = {envelope_name: $envelope_name, document_ids: $document_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the envelopes associated with the given workspace
#
# GET /v1/accounts/{accountId}/workspaces/{workspaceId}/envelopes
# operationId: getWorkspaceEnvelopes
export def "accounts-workspaces-envelopes get" [
  accountId: string
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<envelopes: table<envelope_id: string, status: string, name: string, subject: string, created_date: string, last_updated_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/workspaces/($workspaceId)/envelopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
