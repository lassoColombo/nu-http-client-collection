# Auto-generated client for Docusign Admin API vv2.1
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/admin.rest.swagger-v2.1.json
# Auth: --token flag or $env.DOCUSIGN_ADMIN_API_TOKEN

const BASE_URL = "https://api.docusign.net/Management"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DOCUSIGN_ADMIN_API_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://api.docusign.net/Management"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "organizations GetListV2" } } | get name | first)
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

# Returns a list of organizations that the authenticated user belongs to.
#
# GET /v2/organizations
# operationId: Organization_Organization_GetListV2
export def "organizations GetListV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string # Specifies how to select the organizations. Valid values:  - `org_admin`: Returns organizations for which the authenticated user is an admin. - `account_membership`: Returns organizations that contain an account of which the authenticated user is a member  Default value: `org_admin`
]: nothing -> record<organizations: table<id: string, name: string, description: string, default_account_id: string, default_permission_profile_id: int, created_on: string, created_by: string, last_modified_on: string, last_modified_by: string, accounts: list, users: list, reserved_domains: list, identity_providers: list, links: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes membership data for a user on an account.
#
# POST /v2/data_redaction/accounts/{accountId}/user
# operationId: DataRedaction_RedactIndividualMembershipData
export def "data-redaction-accounts-user RedactIndividualMembershipData" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user whose data you want to delete. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
]: any -> record<user_id: string, status: string, membership_results: table<account_id: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/data_redaction/accounts/($accountId)/user")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the list of permission profiles in an account.
#
# GET /v2/organizations/{organizationId}/accounts/{accountId}/permissions
# operationId: Account_Accounts_GetPermissionProfilesV2
export def "organizations-accounts-permissions GetPermissionProfilesV2" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/accounts/($accountId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of groups in an account.
#
# GET /v2/organizations/{organizationId}/accounts/{accountId}/groups
# operationId: Account_Accounts_GetGroupsV2
export def "organizations-accounts-groups GetGroupsV2" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Index of first item to include in the response. The default value is 0. (format: int32)
  --take: int # Page size of the response. The default value is 20. (format: int32)
  --end: int # Index of the last item to include in the response. Ignored if `take` parameter is specified. (format: int32)
]: nothing -> record<groups: table<id: int, name: string, type: string>, paging: record<result_set_size: int, result_set_start_position: int, result_set_end_position: int, total_set_size: int, next: string, previous: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/accounts/($accountId)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of pending and completed export requests.
#
# GET /v2/organizations/{organizationId}/exports/user_list
# operationId: OrganizationExport_OrganizationExport_Get
export def "organizations-exports-user-list Get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<exports: table<id: string, type: string, requestor: record, created: string, last_modified: string, completed: string, expires: string, status: string, selected_accounts: list, selected_domains: list, metadata_url: string, percent_completed: int, number_rows: int, size_bytes: int, results: list, success: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/user_list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a user list export request.
#
# POST /v2/organizations/{organizationId}/exports/user_list
# operationId: OrganizationExport_OrganizationExport_Insert
# --accounts item shape: {account_id?: string}
# --domains item shape: {domain?: string}
export def "organizations-exports-user-list Insert" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type of export requested. One of:  - `organization_domain_users_export`: All users of the reserved domains. - `organization_external_memberships_export`: Users whose email address domain is *not* linked to the organization.  - `organization_memberships_export`: Every user in every account in the organization. Users in multiple accounts will appear more than once. - `organization_account_settings_export`: This value only applies to requests to export account settings.
  --accounts: list # item shape: {account_id?: string}
  --domains: list # item shape: {domain?: string}
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, completed: string, expires: string, status: string, selected_accounts: table<account_id: string>, selected_domains: table<domain: string>, metadata_url: string, percent_completed: int, number_rows: int, size_bytes: int, results: table<id: string, site_id: int, url: string, number_rows: int, size_bytes: int, error_details: record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/user_list")
  let body = {type: $type, accounts: $accounts, domains: $domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of pending and completed account settings export request.
#
# GET /v2/organizations/{organizationId}/exports/account_settings
# operationId: OrganizationExport_OrganizationExport_GetAccountCompare
export def "organizations-exports-account-settings GetAccountCompare" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<exports: table<id: string, type: string, requestor: record, created: string, last_modified: string, completed: string, expires: string, status: string, selected_accounts: list, selected_domains: list, metadata_url: string, percent_completed: int, number_rows: int, size_bytes: int, results: list, success: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/account_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a  new account settings export request.
#
# POST /v2/organizations/{organizationId}/exports/account_settings
# operationId: OrganizationExport_OrganizationExport_AccountCompare
# --accounts item shape: {account_id: string}
export def "organizations-exports-account-settings AccountCompare" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounts: list # item shape: {account_id: string}
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, completed: string, expires: string, status: string, selected_accounts: table<account_id: string>, selected_domains: table<domain: string>, metadata_url: string, percent_completed: int, number_rows: int, size_bytes: int, results: table<id: string, site_id: int, url: string, number_rows: int, size_bytes: int, error_details: record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/account_settings")
  let body = {accounts: $accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the results for single user list export request.
#
# GET /v2/organizations/{organizationId}/exports/user_list/{exportId}
# operationId: OrganizationExport_OrganizationExport_GetByExportId
export def "organizations-exports-user-list GetByExportId" [
  organizationId: string
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, completed: string, expires: string, status: string, selected_accounts: table<account_id: string>, selected_domains: table<domain: string>, metadata_url: string, percent_completed: int, number_rows: int, size_bytes: int, results: table<id: string, site_id: int, url: string, number_rows: int, size_bytes: int, error_details: record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/user_list/($exportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a single user list export request.
#
# DELETE /v2/organizations/{organizationId}/exports/user_list/{exportId}
# operationId: OrganizationExport_OrganizationExport_DeleteByExportId
export def "organizations-exports-user-list DeleteByExportId" [
  organizationId: string
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/user_list/($exportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the results for a single account settings export request.
#
# GET /v2/organizations/{organizationId}/exports/account_settings/{exportId}
# operationId: OrganizationExport_OrganizationExport_GetAccountSettingsExportByExportId
export def "organizations-exports-account-settings GetAccountSettingsExportByExportId" [
  organizationId: string
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, completed: string, expires: string, status: string, selected_accounts: table<account_id: string>, selected_domains: table<domain: string>, metadata_url: string, percent_completed: int, number_rows: int, size_bytes: int, results: table<id: string, site_id: int, url: string, number_rows: int, size_bytes: int, error_details: record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/account_settings/($exportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a single account settings export request.
#
# DELETE /v2/organizations/{organizationId}/exports/account_settings/{exportId}
# operationId: OrganizationExport_OrganizationExport_DeleteByAccountSettingsExportId
export def "organizations-exports-account-settings DeleteByAccountSettingsExportId" [
  organizationId: string
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/exports/account_settings/($exportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the details and metadata for Bulk Account Settings Import requests in the organization.
#
# GET /v2/organizations/{organizationId}/imports/account_settings
# operationId: OrganizationImport_OrganizationImportAccountSettings_Get
export def "organizations-imports-account-settings Get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created: string, last_modified: string, completed: string, expires: string, percent_completed: int, number_processed_accounts: int, number_unprocessed_accounts: int, results: list<record>, success: bool, skipped_settings_by_account: record, id: string, organization_id: string, status: string, type: string, requestor: record<id: string, type: string, name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/account_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new account settings import request.
#
# POST /v2/organizations/{organizationId}/imports/account_settings
# operationId: OrganizationImport_OrganizationImportAccountSettings_Post
export def "organizations-imports-account-settings Post" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filecsv: path # CSV file.
]: any -> record<created: string, last_modified: string, completed: string, expires: string, percent_completed: int, number_processed_accounts: int, number_unprocessed_accounts: int, results: table<id: string, site_id: int, url: string, number_processed_accounts: int, error_details: record, processing_issues_by_account: list, number_unprocessed_accounts: int>, success: bool, skipped_settings_by_account: record, id: string, organization_id: string, status: string, type: string, requestor: record<id: string, type: string, name: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/account_settings")
  let body = {file.csv: $filecsv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($filecsv | is-not-empty) { $body | upsert file.csv (open -r $filecsv) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Returns the details/metadata for a Bulk Account Settings Import request.
#
# GET /v2/organizations/{organizationId}/imports/account_settings/{importId}
# operationId: OrganizationImport_OrganizationImportAccountSettings_GetById
export def "organizations-imports-account-settings GetById" [
  organizationId: string
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, last_modified: string, completed: string, expires: string, percent_completed: int, number_processed_accounts: int, number_unprocessed_accounts: int, results: table<id: string, site_id: int, url: string, number_processed_accounts: int, error_details: record, processing_issues_by_account: list, number_unprocessed_accounts: int>, success: bool, skipped_settings_by_account: record, id: string, organization_id: string, status: string, type: string, requestor: record<id: string, type: string, name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/account_settings/($importId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Bulk Account Settings Import request.
#
# DELETE /v2/organizations/{organizationId}/imports/account_settings/{importId}
# operationId: OrganizationImport_OrganizationImportAccountSettings_DeleteById
export def "organizations-imports-account-settings DeleteById" [
  organizationId: string
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/account_settings/($importId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a request to import new users into an account.
#
# POST /v2/organizations/{organizationId}/imports/bulk_users/add
# operationId: OrganizationImport_OrganizationImportUsers_Insert
export def "organizations-imports-bulk-users-add Insert" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filecsv: path # CSV file.
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/add")
  let body = {file.csv: $filecsv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($filecsv | is-not-empty) { $body | upsert file.csv (open -r $filecsv) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Import request for adding a user to a single account within the organization.
#
# POST /v2/organizations/{organizationId}/accounts/{accountId}/imports/bulk_users/add
# operationId: OrganizationImport_OrganizationImportSingleAccountUsers_Insert
export def "organizations-accounts-imports-bulk-users-add Insert" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filecsv: path # CSV file.
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/accounts/($accountId)/imports/bulk_users/add")
  let body = {file.csv: $filecsv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($filecsv | is-not-empty) { $body | upsert file.csv (open -r $filecsv) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Bulk updates information for existing users.
#
# POST /v2/organizations/{organizationId}/imports/bulk_users/update
# operationId: OrganizationImport_OrganizationImportUsers_Update
export def "organizations-imports-bulk-users-update Update" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filecsv: path # CSV file.
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/update")
  let body = {file.csv: $filecsv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($filecsv | is-not-empty) { $body | upsert file.csv (open -r $filecsv) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Import request for updating users for a single account within the organization.
#
# POST /v2/organizations/{organizationId}/accounts/{accountId}/imports/bulk_users/update
# operationId: OrganizationImport_OrganizationImportSingleAccountUsers_Update
export def "organizations-accounts-imports-bulk-users-update Update" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filecsv: path # CSV file.
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/accounts/($accountId)/imports/bulk_users/update")
  let body = {file.csv: $filecsv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($filecsv | is-not-empty) { $body | upsert file.csv (open -r $filecsv) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Creates a request to close the accounts of existing users.
#
# POST /v2/organizations/{organizationId}/imports/bulk_users/close
# operationId: OrganizationImport_OrganizationImportUsers_Close
export def "organizations-imports-bulk-users-close Close" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  filecsv: path # CSV file.
]: any -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/close")
  let body = {file.csv: $filecsv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($filecsv | is-not-empty) { $body | upsert file.csv (open -r $filecsv) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Closes external memberships.
#
# POST /v2/organizations/{organizationId}/imports/bulk_users/close_external
# operationId: OrganizationImport_OrganizationImportUsers_CloseExternal
export def "organizations-imports-bulk-users-close-external CloseExternal" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/close_external")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all of the user import requests.
#
# GET /v2/organizations/{organizationId}/imports/bulk_users
# operationId: OrganizationImport_OrganizationImportUsers_Get
export def "organizations-imports-bulk-users Get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<imports: table<id: string, type: string, requestor: record, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: list, user_level_error_rollups: list, user_level_warning_rollups: list, has_csv_results: bool, results_uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the details of a single user import request.
#
# GET /v2/organizations/{organizationId}/imports/bulk_users/{importId}
# operationId: OrganizationImport_OrganizationImportUsers_GetById
export def "organizations-imports-bulk-users GetById" [
  organizationId: string
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, requestor: record<name: string, id: string, type: string, email: string>, created: string, last_modified: string, status: string, user_count: int, processed_user_count: int, added_user_count: int, updated_user_count: int, closed_user_count: int, no_action_required_user_count: int, error_count: int, warning_count: int, invalid_column_headers: string, imports_not_found_or_not_available_for_accounts: string, imports_failed_for_accounts: string, imports_timed_out_for_accounts: string, imports_not_found_or_not_available_for_sites: string, imports_failed_for_sites: string, imports_timed_out_for_sites: string, file_level_error_rollups: table<error_type: string, count: int>, user_level_error_rollups: table<error_type: string, count: int>, user_level_warning_rollups: table<warning_type: string, count: int>, has_csv_results: bool, results_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/($importId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a specific user import request.
#
# DELETE /v2/organizations/{organizationId}/imports/bulk_users/{importId}
# operationId: OrganizationImport_OrganizationImportUsers_DeleteById
export def "organizations-imports-bulk-users DeleteById" [
  organizationId: string
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/($importId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Given the ID of a user import request, return the CSV file that was imported.
#
# GET /v2/organizations/{organizationId}/imports/bulk_users/{importId}/results_csv
# operationId: OrganizationImport_OrganizationImportUsers_GetCSVResults
export def "organizations-imports-bulk-users-results-csv GetCSVResults" [
  organizationId: string
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/imports/bulk_users/($importId)/results_csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of identity providers for an organization.
#
# GET /v2/organizations/{organizationId}/identity_providers
# operationId: Organization_GetIdentityProviders
export def "organizations-identity-providers GetIdentityProviders" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<identity_providers: table<id: string, friendly_name: string, auto_provision_users: bool, type: string, saml_20: record, links: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/identity_providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes data for one or more of a user's account memberships.
#
# POST /v2/data_redaction/organizations/{organizationId}/user
# operationId: DataRedaction_RedactIndividualUserData
# --memberships item shape: {account_id?: string}
export def "data-redaction-organizations-user RedactIndividualUserData" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user whose data you want to delete. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --memberships: list # A list of accounts from which you want to delete the user's data. At least one account is required. — item shape: {account_id?: string}
]: any -> record<user_id: string, status: string, membership_results: table<account_id: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/data_redaction/organizations/($organizationId)/user")
  let body = {user_id: $user_id, memberships: $memberships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the list of reserved domains for the organization.
#
# GET /v2/organizations/{organizationId}/reserved_domains
# operationId: Organization_GetReservedDomains
export def "organizations-reserved-domains GetReservedDomains" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<reserved_domains: table<id: string, status: string, host_name: string, txt_token: string, identity_provider_id: string, settings: list, links: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/reserved_domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a user's information.
#
# POST /v2/organizations/{organizationId}/users/profiles
# operationId: User_Users_UpdateV2
# --users item shape: {id: string, site_id: int, user_name?: string, first_name?: string, last_name?: string, email?: string, default_account_id?: string, language_culture?: string, selected_languages?: string, federated_status?: string, force_password_change?: bool, memberships?: list, device_verification_enabled?: bool}
export def "organizations-users-profiles UpdateV2" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-license-override: oneof<nothing, bool>
  --users: list # A list of users whose information you want to change. — item shape: {id: string, site_id: int, user_name?: string, first_name?: string, last_name?: string, email?: string, default_account_id?: string, language_culture?: string, selected_languages?: string, federated_status?: string, force_password_change?: bool, memberships?: list, device_verification_enabled?: bool}
  --auto-activate-memberships-on-reactivation: oneof<nothing, bool>
]: any -> record<success: bool, users: table<id: string, site_id: int, email: string, error_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apply_license_override" $apply_license_override "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/profiles" $qp)
  let body = {users: $users, auto_activate_memberships_on_reactivation: $auto_activate_memberships_on_reactivation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a user's email address.
#
# POST /v2/organizations/{organizationId}/users/email_addresses
# operationId: User_Users_UpdateEmailAddressesV2
# --users item shape: {id: string, site_id: int, email: string}
export def "organizations-users-email-addresses UpdateEmailAddressesV2" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --users: list # A list of users whose email address to change. — item shape: {id: string, site_id: int, email: string}
]: any -> record<success: bool, users: table<id: string, site_id: int, email: string, error_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/email_addresses")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Closes a user's memberships.
#
# DELETE /v2/organizations/{organizationId}/users/{userId}/accounts
# operationId: User_Users_CloseMembershipsV2
# --accounts item shape: {id: string}
export def "organizations-users-accounts CloseMembershipsV2" [
  organizationId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accounts: list # A list of accounts to close for a user. — item shape: {id: string}
]: any -> record<success: bool, accounts: table<id: string, error_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/($userId)/accounts")
  let body = {accounts: $accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the users in an organization.
#
# GET /v2/organizations/{organizationId}/users
# operationId: OrganizationUser_OrganizationUsers_GetV2
export def "organizations-users GetV2" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Index of first item to include in the response. The default value is 0. (format: int32)
  --take: int # Page size of the response. The default value is 20. (format: int32)
  --end: int # Index of the last item to include in the response. Ignored if `take` parameter is specified. (format: int32)
  --email: string # Email address of the desired user. At least one of `email`, `account_id` or `organization_reserved_domain_id` must be specified.
  --email-user-name-like: string # Selects users by pattern matching on the user's email address
  --status: string # Status.
  --membership-status: string # The user's membership status. One of:  - `activation_required` - `activation_sent` - `active` - `closed` - `disabled`
  --account-id: string # Select users that are members of the specified account. At least one of `email`, `account_id` or `organization_reserved_domain_id` must be specified. (format: uuid)
  --organization-reserved-domain-id: string # Select users that are in the specified domain. At least one of `email`, `account_id` or `organization_reserved_domain_id` must be specified. (format: uuid)
  --last-modified-since: string # Select users whose data have been modified since the date specified. `account_id` or `organization_reserved_domain_id` must be specified.
  --include-ds-groups: oneof<nothing, bool> # Select users with groups the users belong to; The organization must have entitlement `AllowMultiApplication` enabled.
  --include-license: oneof<nothing, bool>
]: nothing -> record<users: table<id: string, user_name: string, first_name: string, last_name: string, user_status: string, membership_status: string, email: string, created_on: string, closed_on: string, membership_created_on: string, membership_closed_on: string, ds_groups: list, membership_id: string, is_membership_managed_by_scim: bool, is_managed_by_scim: bool, license_type: string, subscription_id: string, plan_name: string>, paging: record<result_set_size: int, result_set_start_position: int, result_set_end_position: int, total_set_size: int, next: string, previous: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "email_user_name_like" $email_user_name_like "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "membership_status" $membership_status "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "organization_reserved_domain_id" $organization_reserved_domain_id "scalar") (serialize-qp "last_modified_since" $last_modified_since "scalar") (serialize-qp "include_ds_groups" $include_ds_groups "scalar") (serialize-qp "include_license" $include_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new eSignature user.
#
# POST /v2/organizations/{organizationId}/users
# operationId: OrganizationUser_Users_AddV2
# --accounts item shape: {id: string, permission_profile?: record, groups?: list, company_name?: string, job_title?: string}
export def "organizations-users AddV2" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accounts: list # A list of accounts the user will belong to. — item shape: {id: string, permission_profile?: record, groups?: list, company_name?: string, job_title?: string}
  --user-name: string # The full name of the user.
  --first-name: string # The user's first name.
  --last-name: string # The user's last name.
  email: string # The email address.
  --default-account-id: string # The account ID of the user's default account. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --language-culture: string # The language and culture of the user.    * Chinese Simplified: `zh_CN`   * Chinese Traditional: `zh_TW`   * Dutch: `nl`   * English: `en`   * French: `fr`   * German: `de`   * Italian: `it`   * Japanese: `ja`   * Korean: `ko`   * Portuguese: `pt`   * Portuguese Brazil: `pt_BR`   * Russian: `ru`   * Spanish: `es`
  --selected-languages: string
  --access-code: string # The access code that the user needs to activate an account.
  --federated-status: string # The user's federated status. One of:  - `RemoveStatus` - `FedAuthRequired` - `FedAuthBypass` - `Evicted`
  --auto-activate-memberships: oneof<nothing, bool> # When **true,** the user's account is activated automatically.
]: any -> record<id: string, site_id: int, user_name: string, first_name: string, last_name: string, email: string, language_culture: string, federated_status: string, accounts: table<id: string, site_id: int, permission_profile: record, groups: list, company_name: string, job_title: string, license_type: string, subscription_id: string, plan_name: string, license_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users")
  let body = {accounts: $accounts, user_name: $user_name, first_name: $first_name, last_name: $last_name, email: $email, default_account_id: $default_account_id, language_culture: $language_culture, selected_languages: $selected_languages, access_code: $access_code, federated_status: $federated_status, auto_activate_memberships: $auto_activate_memberships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activates user memberships.
#
# POST /v2/organizations/{organizationId}/users/{userId}/memberships/{membershipId}
# operationId: OrganizationUser_Users_ActivateMembershipV2
export def "organizations-users-memberships ActivateMembershipV2" [
  organizationId: string
  userId: string
  membershipId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  site_id: int # format: int32
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/($userId)/memberships/($membershipId)")
  let body = {site_id: $site_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns historical information about users with a specific email address.
#
# GET /v2/organizations/{organizationId}/users/profile
# operationId: OrganizationUser_OrganizationUsers_GetProfileV2
export def "organizations-users-profile GetProfileV2" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address associated with the users you want to retrieve.  **Note:** This property is required.
  --include-license: oneof<nothing, bool>
]: nothing -> record<users: table<id: string, site_id: int, site_name: string, user_name: string, first_name: string, last_name: string, user_status: string, default_account_id: string, default_account_name: string, language_culture: string, selected_languages: string, federated_status: string, is_organization_admin: bool, created_on: string, last_login: string, memberships: list, identities: list, device_verification_enabled: bool, require_two_step_verification: bool, allow_two_step_verification_snooze: bool, allow_extend_org_admin_rights_to_self: bool, is_managed_by_scim: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "include_license" $include_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user identities for a specified identity provider.
#
# DELETE /v2/organizations/{organizationId}/users/{userId}/identities
# operationId: OrganizationUser_DeleteIdentitiesV2
# --identities item shape: {id?: string}
export def "organizations-users-identities DeleteIdentitiesV2" [
  organizationId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identities: list # A list of identities. — item shape: {id?: string}
]: any -> record<success: bool, identities: table<id: string, provider_id: string, user_id: string, immutable_id: string, error_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/users/($userId)/identities")
  let body = {identities: $identities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds users to an account.
#
# POST /v2/organizations/{organizationId}/accounts/{accountId}/users
# operationId: OrganizationUser_OrganizationUsers_PostAccountUsersV2
# --permission_profile shape: {id: int, name?: string}
# --groups item shape: {id: int, name?: string, type?: string}
export def "organizations-accounts-users PostAccountUsersV2" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission-profile: record # A permission profile. — shape: {id: int, name?: string}
  --groups: list # The new user's requested groups. — item shape: {id: int, name?: string, type?: string}
  --user-name: string # The full name of the user.
  --first-name: string # The user's first name.
  --last-name: string # The user's last name.
  email: string # The email address of the user.
  --default-account-id: string # The account ID of the user's default account. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --language-culture: string # The language and culture of the user.    * Chinese Simplified: `zh_CN`   * Chinese Traditional: `zh_TW`   * Dutch: `nl`   * English: `en`   * French: `fr`   * German: `de`   * Italian: `it`   * Japanese: `ja`   * Korean: `ko`   * Portuguese: `pt`   * Portuguese Brazil: `pt_BR`   * Russian: `ru`   * Spanish: `es`
  --selected-languages: string
  --access-code: string # The access code that the user needs to activate an account.
  --federated-status: string # The user's federated status. One of:  - `RemoveStatus` - `FedAuthRequired` - `FedAuthBypass` - `Evicted`
  --auto-activate-memberships: oneof<nothing, bool> # When **true,** the user's account is activated automatically.
  --license-type: string
]: any -> record<id: string, site_id: int, user_name: string, first_name: string, last_name: string, email: string, language_culture: string, federated_status: string, accounts: table<id: string, site_id: int, permission_profile: record, groups: list, company_name: string, job_title: string, license_type: string, subscription_id: string, plan_name: string, license_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/accounts/($accountId)/users")
  let body = {permission_profile: $permission_profile, groups: $groups, user_name: $user_name, first_name: $first_name, last_name: $last_name, email: $email, default_account_id: $default_account_id, language_culture: $language_culture, selected_languages: $selected_languages, access_code: $access_code, federated_status: $federated_status, auto_activate_memberships: $auto_activate_memberships, license_type: $license_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of DSGroups.
#
# GET /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups
# operationId: DocuSignGroupsv21_GetDSGroups_V2_1
export def "v21-organizations-accounts-dsgroups V2-by-organizationId-accountId-by-organizationId-accountId" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Start page of DSGroups. (format: int32)
  --page-size: int # Page size of DSGroups. (format: int32)
]: nothing -> record<page: int, page_size: int, total_count: int, account_id: string, ds_groups: table<ds_group_id: string, account_id: string, source_product_name: string, group_id: string, group_name: string, description: string, is_admin: bool, last_modified_on: string, user_count: int, external_account_id: int, account_name: string, is_managed_by_scim: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new DSGroup.
#
# POST /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups
# operationId: DocuSignGroupsv21_AddDSGroup_V2_1
export def "v21-organizations-accounts-dsgroups V2-by-organizationId-accountId-by-organizationId-accountId-1" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_name: string
  --description: string
]: any -> record<ds_group_id: string, account_id: string, source_product_name: string, group_id: string, group_name: string, description: string, is_admin: bool, last_modified_on: string, user_count: int, external_account_id: int, account_name: string, is_managed_by_scim: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups")
  let body = {group_name: $group_name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns details about a single DSGroup.
#
# GET /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups/{dsGroupId}
# operationId: DocuSignGroupsv21_GetDSGroup_V2_1
export def "v21-organizations-accounts-dsgroups V2-by-organizationId-accountId-dsGroupId-by-organizationId-accountId-dsGroupId" [
  organizationId: string
  accountId: string
  dsGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ds_group_id: string, account_id: string, source_product_name: string, group_id: string, group_name: string, description: string, is_admin: bool, last_modified_on: string, user_count: int, external_account_id: int, account_name: string, is_managed_by_scim: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups/($dsGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a DSGroup.
#
# DELETE /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups/{dsGroupId}
# operationId: DocuSignGroupsv21_DeleteDSGroup_V2_1
export def "v21-organizations-accounts-dsgroups V2-by-organizationId-accountId-dsGroupId-by-organizationId-accountId-dsGroupId-1" [
  organizationId: string
  accountId: string
  dsGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups/($dsGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of users in a DSGroup.
#
# GET /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups/{dsGroupId}/users
# operationId: DocuSignGroupsv21_GetDSGroupUsers_V2_1
export def "v21-organizations-accounts-dsgroups-users V2-by-organizationId-accountId-dsGroupId-by-organizationId-accountId-dsGroupId" [
  organizationId: string
  accountId: string
  dsGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Start page of DSGroups.  (format: int32)
  --page-size: int # Page size of DSGroups. (format: int32)
]: nothing -> record<group: record<ds_group_id: string, account_id: string, source_product_name: string, group_id: string, group_name: string, description: string, is_admin: bool, last_modified_on: string, user_count: int, external_account_id: int, account_name: string, is_managed_by_scim: bool>, group_users: record<page: int, page_size: int, total_count: int, users: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups/($dsGroupId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a list of users to a DSGroup.
#
# POST /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups/{dsGroupId}/users
# operationId: DocuSignGroupsv21_AddDSGroupUsers_V2_1
export def "v21-organizations-accounts-dsgroups-users V2-by-organizationId-accountId-dsGroupId-by-organizationId-accountId-dsGroupId-1" [
  organizationId: string
  accountId: string
  dsGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list
]: any -> record<group: record<ds_group_id: string, account_id: string, source_product_name: string, group_id: string, group_name: string, description: string, is_admin: bool, last_modified_on: string, user_count: int, external_account_id: int, account_name: string, is_managed_by_scim: bool>, group_users: record<is_success: bool, TotalCount: int, users: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups/($dsGroupId)/users")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a list of users from a DSGroup.
#
# DELETE /v2.1/organizations/{organizationId}/accounts/{accountId}/dsgroups/{dsGroupId}/users
# operationId: DocuSignGroupsv21_RemoveDSGroupUsers_V2_1
export def "v21-organizations-accounts-dsgroups-users V2-by-organizationId-accountId-dsGroupId-by-organizationId-accountId-dsGroupId-2" [
  organizationId: string
  accountId: string
  dsGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-ids: list # An array of IDs corresponding to users to remove from the group.
  --user-emails: list # An array of emails associated with users to remove from the group. **Note:** If `user_ids` is also specified, this parameter will be ignored.
]: any -> record<is_success: bool, failed_users: table<user_id: string, account_id: string, user_name: string, first_name: string, last_name: string, middle_name: string, status: string, error_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/dsgroups/($dsGroupId)/users")
  let body = {user_ids: $user_ids, user_emails: $user_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets products associated with the account and the available permission profiles.
#
# GET /v2.1/organizations/{organizationId}/accounts/{accountId}/products/permission_profiles
# operationId: OrganizationProductPermissionProfile_GetProductPermissionProfiles
export def "v21-organizations-accounts-products-permission-profiles GetProductPermissionProfiles" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<product_permission_profiles: table<product_id: string, product_name: string, permission_profiles: list, error_message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/products/permission_profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a user's product permission profiles by user ID.
#
# GET /v2.1/organizations/{organizationId}/accounts/{accountId}/products/users/{userId}/permission_profiles
# operationId: OrganizationProductPermissionProfile_GetUserProductPermissionProfiles
export def "v21-organizations-accounts-products-users-permission-profiles GetUserProductPermissionProfiles" [
  organizationId: string
  accountId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<product_permission_profiles: table<product_id: string, product_name: string, permission_profiles: list, error_message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/products/users/($userId)/permission_profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns permission profiles for a user by user ID.
#
# POST /v2.1/organizations/{organizationId}/accounts/{accountId}/products/users/{userId}/permission_profiles
# operationId: OrganizationProductPermissionProfile_PostUserProductPermissionProfiles
# --product_permission_profiles item shape: {product_id: string, permission_profile_id: string}
export def "v21-organizations-accounts-products-users-permission-profiles PostUserProductPermissionProfiles" [
  organizationId: string
  accountId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  product_permission_profiles: list # A list of one or more products and their respective permissions. — item shape: {product_id: string, permission_profile_id: string}
]: any -> record<user_id: string, account_id: string, product_permission_profiles: table<product_id: string, product_name: string, permission_profiles: list, error_message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/products/users/($userId)/permission_profiles")
  let body = {product_permission_profiles: $product_permission_profiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a multi-product user.
#
# POST /v2.1/organizations/{organizationId}/accounts/{accountId}/users
# operationId: OrganizationUser_OrganizationUsers_PostAccountUsersV2_1
# --product_permission_profiles item shape: {product_id: string, permission_profile_id: string}
# --ds_groups item shape: {ds_group_id: string}
export def "v21-organizations-accounts-users PostAccountUsersV2-by-organizationId-accountId" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  product_permission_profiles: list # A list of one or more products and their respective permissions. — item shape: {product_id: string, permission_profile_id: string}
  --ds-groups: list # item shape: {ds_group_id: string}
  --user-name: string # The full name of the user.
  --first-name: string # The user's first name.
  --last-name: string # The user's last name.
  email: string # The email address.
  --default-account-id: string # format: uuid, e.g. 00000000-0000-0000-0000-000000000000
  --language-culture: string # The language and culture of the user.    * Chinese Simplified: `zh_CN`   * Chinese Traditional: `zh_TW`   * Dutch: `nl`   * English: `en`   * French: `fr`   * German: `de`   * Italian: `it`   * Japanese: `ja`   * Korean: `ko`   * Portuguese: `pt`   * Portuguese Brazil: `pt_BR`   * Russian: `ru`   * Spanish: `es`
  --access-code: string # The access code that the user needs to activate an account.
  --federated-status: string # The user's federated status. One of:  - `RemoveStatus` - `FedAuthRequired` - `FedAuthBypass` - `Evicted`
  --auto-activate-memberships: oneof<nothing, bool> # When **true,** the user's account is activated automatically.
  --license-type: string
]: any -> record<id: string, site_id: int, user_name: string, first_name: string, last_name: string, email: string, language_culture: string, federated_status: string, accounts: table<id: string, site_id: int, product_permission_profiles: list, ds_groups: list, company_name: string, job_title: string, license_type: string, subscription_id: string, plan_name: string, license_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/users")
  let body = {product_permission_profiles: $product_permission_profiles, ds_groups: $ds_groups, user_name: $user_name, first_name: $first_name, last_name: $last_name, email: $email, default_account_id: $default_account_id, language_culture: $language_culture, access_code: $access_code, federated_status: $federated_status, auto_activate_memberships: $auto_activate_memberships, license_type: $license_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the DS profile for a user specified by email address.
#
# GET /v2.1/organizations/{organizationId}/users/dsprofile
# operationId: OrganizationUser_OrganizationUsers_GetDSProfiles
export def "v21-organizations-users-dsprofile GetDSProfiles" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.  **Note:** This property is required.
  --qp-sort: oneof<nothing, bool> # When **true,** sorts the results in ascending order by account name.
  --include-license: oneof<nothing, bool>
]: nothing -> record<users: table<id: string, site_id: int, site_name: string, user_name: string, first_name: string, last_name: string, user_status: string, default_account_id: string, default_account_name: string, language_culture: string, selected_languages: string, federated_status: string, is_organization_admin: bool, created_on: string, last_login: string, memberships: list, identities: list, device_verification_enabled: bool, require_two_step_verification: bool, allow_two_step_verification_snooze: bool, allow_extend_org_admin_rights_to_self: bool, is_managed_by_scim: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_license" $include_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/users/dsprofile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the DS profile for a user specified by ID.
#
# GET /v2.1/organizations/{organizationId}/users/{userId}/dsprofile
# operationId: OrganizationUser_OrganizationUsers_GetDSProfileByUserId
export def "v21-organizations-users-dsprofile GetDSProfileByUserId" [
  organizationId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: oneof<nothing, bool> # When **true,** sorts the results in ascending order by account name.
  --include-license: oneof<nothing, bool>
]: nothing -> record<users: table<id: string, site_id: int, site_name: string, user_name: string, first_name: string, last_name: string, user_status: string, default_account_id: string, default_account_name: string, language_culture: string, selected_languages: string, federated_status: string, is_organization_admin: bool, created_on: string, last_login: string, memberships: list, identities: list, device_verification_enabled: bool, require_two_step_verification: bool, allow_two_step_verification_snooze: bool, allow_extend_org_admin_rights_to_self: bool, is_managed_by_scim: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_license" $include_license "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/users/($userId)/dsprofile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revokes a user's access to one or more products.
#
# DELETE /v2.1/organizations/{organizationId}/accounts/{accountId}/products/users
# operationId: OrganizationProductPermissionProfile_RemoveUserProducts
export def "v21-organizations-accounts-products-users RemoveUserProducts" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-email: string # The user's email address.
  --user-id: string # The user's unique ID. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  product_ids: list # A list of IDs corresponding to the products for which the user's access will be revoked.  For example:  `["230546a7-xxxx-xxxx-xxxx-af205d5494ad", "984800b7-xxxx-xxxx-xxxx-kt374a5922lk"]`
]: any -> record<is_success: bool, user_email: string, user_id: string, user_product_results: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/products/users")
  let body = {user_email: $user_email, user_id: $user_id, product_ids: $product_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a user's product permission profiles by email address.
#
# GET /v2.1/organizations/{organizationId}/accounts/{accountId}/products/permission_profiles/users
# operationId: OrganizationProductPermissionProfile_GetUserProductPermissionProfilesByEmail
export def "v21-organizations-accounts-products-permission-profiles-users GetUserProductPermissionProfilesByEmail" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.  **Note:** This property is required.
]: nothing -> record<user_id: string, account_id: string, product_permission_profiles: table<product_id: string, product_name: string, permission_profiles: list, error_message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/products/permission_profiles/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns permission profiles for a user by email address.
#
# POST /v2.1/organizations/{organizationId}/accounts/{accountId}/products/permission_profiles/users
# operationId: OrganizationProductPermissionProfile_PostUserProductPermissionProfilesByEmail
# --product_permission_profiles item shape: {product_id: string, permission_profile_id: string}
export def "v21-organizations-accounts-products-permission-profiles-users PostUserProductPermissionProfilesByEmail" [
  organizationId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address associated with the user whose permissions you want to update. This property is required.
  product_permission_profiles: list # A list of one or more products and their associated permissions. — item shape: {product_id: string, permission_profile_id: string}
]: any -> record<user_id: string, account_id: string, product_permission_profiles: table<product_id: string, product_name: string, permission_profiles: list, error_message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2.1/organizations/($organizationId)/accounts/($accountId)/products/permission_profiles/users")
  let body = {email: $email, product_permission_profiles: $product_permission_profiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get asset group accounts for an organization.
#
# GET /v2/organizations/{organizationId}/assetGroups/accounts
# operationId: OrganizationProvisionAssetGroup_GetAssetGroupAccountsByOrg
export def "organizations-asset-groups-accounts GetAssetGroupAccountsByOrg" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --compliant: oneof<nothing, bool> # When **true,** only compliant accounts are returned and account responses do not include the `compliant` field. The default value is **false.**
]: nothing -> record<assetGroupAccounts: table<assetGroupId: string, assetGroupName: string, accountId: string, accountName: string, externalAccountId: int, compliant: bool, siteId: int, siteName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "compliant" $compliant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/assetGroups/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clone an existing Docusign account.
#
# POST /v2/organizations/{organizationId}/assetGroups/accountClone
# operationId: OrganizationProvisionAssetGroup_CloneAssetGroupAccount
# --sourceAccount shape: {id: string}
# --targetAccount shape: {id?: string, name?: string, region?: string, countryCode?: string, site?: string, admin?: record}
export def "organizations-asset-groups-account-clone CloneAssetGroupAccount" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceAccount: record # shape: {id: string}
  targetAccount: record # An object describing the target cloned account. — shape: {id?: string, name?: string, region?: string, countryCode?: string, site?: string, admin?: record}
  --cloneProcessingFailureDetails: record
]: any -> record<sourceAccount: record<id: string, externalAccountId: int, site: string, name: string>, targetAccount: record<id: string, name: string, region: string, countryCode: string, site: string, admin: record<email: string, firstName: string, lastName: string, locale: string>>, assetGroupWorkId: string, assetGroupId: string, assetGroupWorkType: string, status: string, cloneRequestId: string, orderId: string, attempts: int, createdDate: string, createdByName: string, createdByEmail: string, message: string, cloneProcessingFailureDetails: record<error: string, errorDescription: string, isSystemError: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/assetGroups/accountClone")
  let body = {sourceAccount: $sourceAccount, targetAccount: $targetAccount, cloneProcessingFailureDetails: $cloneProcessingFailureDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all asset group account clones for an organization.
#
# GET /v2/organizations/{organizationId}/assetGroups/accountClones
# operationId: OrganizationProvisionAssetGroup_GetAssetGroupAccountClonesByOrgId
export def "organizations-asset-groups-account-clones GetAssetGroupAccountClonesByOrgId" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since-updated-date: string # Use this parameter to retrieve only account clones that were created on or after a specified date. (format: date-time)
  --include-details: oneof<nothing, bool> # When **true,** include additional details for the asset group account clones. The default value is **false.**
]: nothing -> record<assetGroupWorks: table<sourceAccount: record, targetAccount: record, assetGroupWorkId: string, assetGroupId: string, assetGroupWorkType: string, status: string, cloneRequestId: string, orderId: string, attempts: int, createdDate: string, createdByName: string, createdByEmail: string, message: string, cloneProcessingFailureDetails: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_updated_date" $since_updated_date "scalar") (serialize-qp "include_details" $include_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/assetGroups/accountClones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a single cloned account.
#
# GET /v2/organizations/{organizationId}/assetGroups/{assetGroupId}/accountClones/{assetGroupWorkId}
# operationId: OrganizationProvisionAssetGroup_GetAssetGroupAccountClone
export def "organizations-asset-groups-account-clones GetAssetGroupAccountClone" [
  organizationId: string
  assetGroupId: string
  assetGroupWorkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-details: oneof<nothing, bool> # When **true,** include additional details about the cloned account. The default value is **false.**
]: nothing -> record<sourceAccount: record<id: string, externalAccountId: int, site: string, name: string>, targetAccount: record<id: string, name: string, region: string, countryCode: string, site: string, admin: record<email: string, firstName: string, lastName: string, locale: string>>, assetGroupWorkId: string, assetGroupId: string, assetGroupWorkType: string, status: string, cloneRequestId: string, orderId: string, attempts: int, createdDate: string, createdByName: string, createdByEmail: string, message: string, cloneProcessingFailureDetails: record<error: string, errorDescription: string, isSystemError: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_details" $include_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/assetGroups/($assetGroupId)/accountClones/($assetGroupWorkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about plan items within an organization.
#
# GET /v2/organizations/{organizationId}/planItems
# operationId: OrganizationSubAccount_GetOrganizationPlanItems
export def "organizations-plan-items GetOrganizationPlanItems" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<plan_id: string, plan_name: string, associated_accounts_count: int, asset_group_name: string, asset_group_id: string, subscription_name: string, subscription_id: string, modules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/planItems")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Docusign account using the plan and modules specified in request body.
#
# POST /v2/organizations/{organizationId}/assetGroups/accountCreate
# operationId: OrganizationSubAccount_CreateSubAccount
# --subscriptionDetails shape: {id?: string, planId?: string, modules?: list}
# --targetAccount shape: {id?: string, address?: record, admin?: record, name?: string, countryCode?: string, region?: string, site?: string}
export def "organizations-asset-groups-account-create CreateSubAccount" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscriptionDetails: record # shape: {id?: string, planId?: string, modules?: list}
  --targetAccount: record # shape: {id?: string, address?: record, admin?: record, name?: string, countryCode?: string, region?: string, site?: string}
]: any -> record<AssetGroupWork: record<AssetGroupWorkId: string, AssetGroupId: string, AssetGroupWorkType: string, Status: string, OrderId: string, TargetAccountId: string, SourceAccountId: string, SourceAccountExternalId: int, SourceAccountName: string, SourceAccountSite: string, CloneRequestId: string, CloneAccountDetails: record<Name: string, CountryCode: string, Region: string, Site: string, Address: record, AdminUser: record, BillingProfileType: int>, CreateSubAccountDetails: record<SubscriptionDetails: record, Name: string, CountryCode: string, Region: string, Site: string, Address: record, AdminUser: record, BillingProfileType: int>, Attempts: int, RetryOn: string, Message: string, CreatedByName: string, CreatedByEmail: string, ErrorDetails: record<ErrorCode: string, PublicErrorCode: string, ErrorDescription: string, IsSystemError: bool>, OldAssetGroupSubscriptionId: string, NewAssetGroupSubscriptionId: string, SourceSystem: string, SourceId: string, CreatedBy: string, CreatedByType: int, CreatedDate: string, UpdatedBy: string, UpdatedByType: int, UpdatedDate: string, UpdateHistory: list<record>>, Message: string, Success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/assetGroups/accountCreate")
  let body = {subscriptionDetails: $subscriptionDetails, targetAccount: $targetAccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all ongoing account creation processes for an Organization.
#
# GET /v2/organizations/{organizationId}/subAccountsCreated
# operationId: OrganizationSubAccount_GetSubAccountCreateProcessesByOrgId
export def "organizations-sub-accounts-created GetSubAccountCreateProcessesByOrgId" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since-updated-date: string # Specifies that the request will only return information for accounts that were created after the date passed in the format YYYY-MM-DD. (format: date-time)
  --include-details: oneof<nothing, bool> # When `true`, include additional details about the account creation process. The default value is `false`.
]: nothing -> record<assetGroupWorks: table<targetAccount: record, subscriptionDetails: record, assetGroupWorkId: string, assetGroupId: string, assetGroupWorkType: string, status: string, orderId: string, attempts: int, createdDate: string, createdByName: string, createdByEmail: string, message: string, createAccountProcessingFailureDetails: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_updated_date" $since_updated_date "scalar") (serialize-qp "include_details" $include_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/subAccountsCreated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single account creation process.
#
# GET /v2/organizations/{organizationId}/assetGroup/{assetGroupId}/subAccountCreated/{assetGroupWorkId}
# operationId: OrganizationSubAccount_GetSubAccountCreateProcessByAssetGroupWorkId
export def "organizations-asset-group-sub-account-created GetSubAccountCreateProcessByAssetGroupWorkId" [
  organizationId: string
  assetGroupId: string
  assetGroupWorkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-details: oneof<nothing, bool> # When true, include details for the asset group account clone.
]: nothing -> record<targetAccount: record<id: string, name: string, region: string, countryCode: string, site: string, admin: record<email: string, firstName: string, lastName: string, locale: string>>, subscriptionDetails: record<id: string, planId: string, planName: string, modules: list<record>>, assetGroupWorkId: string, assetGroupId: string, assetGroupWorkType: string, status: string, orderId: string, attempts: int, createdDate: string, createdByName: string, createdByEmail: string, message: string, createAccountProcessingFailureDetails: record<error: string, errorDescription: string, isSystemError: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_details" $include_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/assetGroup/($assetGroupId)/subAccountCreated/($assetGroupWorkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/organizations/{organizationId}/connect
#
# operationId: OrganizationConnect_GetOrganizationConnectConfigs
export def "organizations-connect GetOrganizationConnectConfigs" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sortBy: string
  --siteId: int # The site ID of the account.  (format: int32)
  --accountId: string # The account ID GUID. (format: uuid)
  --allowEnvelopePublish: oneof<nothing, bool>
  --q: string
]: nothing -> record<configurations: table<connectId: string, configurationType: string, disabledBy: string, allowSalesforcePublish: string, name: string, accountId: string, accountName: string, allowEnvelopePublish: string, siteId: int, pausePublish: string, requiresAcknowledgement: string>, totalSetSize: int, errorDetail: record<errorMessage: string, referenceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "siteId" $siteId "scalar") (serialize-qp "accountId" $accountId "scalar") (serialize-qp "allowEnvelopePublish" $allowEnvelopePublish "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/organizations/{organizationId}/connect
#
# operationId: OrganizationConnect_CreateOrganizationConnectConfig
# --eventData shape: {version?: string, includeData?: list}
export def "organizations-connect CreateOrganizationConnectConfig" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connectId: string # format: uuid, e.g. 00000000-0000-0000-0000-000000000000
  --configurationType: string
  --allowEnvelopePublish: string
  --urlToPublishTo: string
  --deliveryMode: string
  --events: list
  --associatedFilterSelection: string
  --groupIds: list
  --accountIds: list
  --userIds: list
  --name: string
  --signMessageWithX509Certificate: string
  --includeOAuth: string
  --includeHMAC: string
  --pausePublish: string
  --eventData: record # shape: {version?: string, includeData?: list}
]: any -> record<connectId: string, configurationType: string, allowEnvelopePublish: string, urlToPublishTo: string, deliveryMode: string, events: list<string>, associatedFilterSelection: string, accountIds: list<string>, userIds: list<string>, groupIds: list<string>, name: string, signMessageWithX509Certificate: string, includeOAuth: string, includeHMAC: string, pausePublish: string, eventData: record<version: string, includeData: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect")
  let body = {connectId: $connectId, configurationType: $configurationType, allowEnvelopePublish: $allowEnvelopePublish, urlToPublishTo: $urlToPublishTo, deliveryMode: $deliveryMode, events: $events, associatedFilterSelection: $associatedFilterSelection, groupIds: $groupIds, accountIds: $accountIds, userIds: $userIds, name: $name, signMessageWithX509Certificate: $signMessageWithX509Certificate, includeOAuth: $includeOAuth, includeHMAC: $includeHMAC, pausePublish: $pausePublish, eventData: $eventData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v2/organizations/{organizationId}/connect/{connectId}
#
# operationId: OrganizationConnect_GetOrganizationConnectConfig
export def "organizations-connect GetOrganizationConnectConfig" [
  organizationId: string
  connectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectId: string, configurationType: string, allowEnvelopePublish: string, urlToPublishTo: string, deliveryMode: string, events: list<string>, associatedFilterSelection: string, accountIds: list<string>, userIds: list<string>, groupIds: list<string>, name: string, signMessageWithX509Certificate: string, includeOAuth: string, includeHMAC: string, pausePublish: string, eventData: record<version: string, includeData: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/($connectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/organizations/{organizationId}/connect/{connectId}
#
# operationId: OrganizationConnect_DeleteOrganizationConnectConfig
export def "organizations-connect DeleteOrganizationConnectConfig" [
  organizationId: string
  connectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/($connectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /v2/organizations/{organizationId}/connect/{connectId}
#
# operationId: OrganizationConnect_UpdateOrganizationConnectConfig
# --eventData shape: {version?: string, includeData?: list}
export def "organizations-connect UpdateOrganizationConnectConfig" [
  organizationId: string
  connectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-connectId: string # format: uuid, e.g. 00000000-0000-0000-0000-000000000000
  --configurationType: string
  --allowEnvelopePublish: string
  --urlToPublishTo: string
  --deliveryMode: string
  --events: list
  --associatedFilterSelection: string
  --groupIds: list
  --accountIds: list
  --userIds: list
  --name: string
  --signMessageWithX509Certificate: string
  --includeOAuth: string
  --includeHMAC: string
  --pausePublish: string
  --eventData: record # shape: {version?: string, includeData?: list}
]: any -> record<connectId: string, configurationType: string, allowEnvelopePublish: string, urlToPublishTo: string, deliveryMode: string, events: list<string>, associatedFilterSelection: string, accountIds: list<string>, userIds: list<string>, groupIds: list<string>, name: string, signMessageWithX509Certificate: string, includeOAuth: string, includeHMAC: string, pausePublish: string, eventData: record<version: string, includeData: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/($connectId)")
  let body = {connectId: $body_connectId, configurationType: $configurationType, allowEnvelopePublish: $allowEnvelopePublish, urlToPublishTo: $urlToPublishTo, deliveryMode: $deliveryMode, events: $events, associatedFilterSelection: $associatedFilterSelection, groupIds: $groupIds, accountIds: $accountIds, userIds: $userIds, name: $name, signMessageWithX509Certificate: $signMessageWithX509Certificate, includeOAuth: $includeOAuth, includeHMAC: $includeHMAC, pausePublish: $pausePublish, eventData: $eventData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v2/organizations/{organizationId}/connect/oauth
#
# operationId: OrganizationConnectOAuthConfiguration_DeleteOrganizationConnectOAuthConfiguration
export def "organizations-connect-oauth DeleteOrganizationConnectOAuthConfiguration" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/oauth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/organizations/{organizationId}/connect/oauth
#
# operationId: OrganizationConnectOAuthConfiguration_GetOrganizationConnectOAuthConfiguration
export def "organizations-connect-oauth GetOrganizationConnectOAuthConfiguration" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/oauth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/organizations/{organizationId}/connect/oauth
#
# operationId: OrganizationConnectOAuthConfiguration_PostOrganizationConnectOAuthConfiguration
export def "organizations-connect-oauth PostOrganizationConnectOAuthConfiguration" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizationServerUrl: string # format: uri
  --clientId: string
  --clientSecret: string
  --scope: string
  --customParameter: record
]: any -> record<authorizationServerUrl: string, clientId: string, clientSecret: string, scope: string, customParameter: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/oauth")
  let body = {authorizationServerUrl: $authorizationServerUrl, clientId: $clientId, clientSecret: $clientSecret, scope: $scope, customParameter: $customParameter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /v2/organizations/{organizationId}/connect/oauth
#
# operationId: OrganizationConnectOAuthConfiguration_PutOrganizationConnectOAuthConfiguration
export def "organizations-connect-oauth PutOrganizationConnectOAuthConfiguration" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizationServerUrl: string # format: uri
  --clientId: string
  --clientSecret: string
  --scope: string
  --customParameter: record
]: any -> record<authorizationServerUrl: string, clientId: string, clientSecret: string, scope: string, customParameter: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/oauth")
  let body = {authorizationServerUrl: $authorizationServerUrl, clientId: $clientId, clientSecret: $clientSecret, scope: $scope, customParameter: $customParameter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v2/organizations/{organizationId}/connect/secret
#
# operationId: OrganizationConnectHmac_GetConnectHmacSecrets
export def "organizations-connect-secret GetConnectHmacSecrets" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<secrets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/organizations/{organizationId}/connect/secret
#
# operationId: OrganizationConnectHmac_PostConnectHmacSecret
export def "organizations-connect-secret PostConnectHmacSecret" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<secrets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/organizations/{organizationId}/connect/secret/{keyId}
#
# operationId: OrganizationConnectHmac_DeleteConnectHmacSecret
export def "organizations-connect-secret DeleteConnectHmacSecret" [
  organizationId: string
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<secrets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/organizations/($organizationId)/connect/secret/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
