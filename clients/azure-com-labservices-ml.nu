# Auto-generated client for ManagedLabsClient v2018-10-15
# Source: https://api.apis.guru/v2/specs/azure.com/labservices-ML/2018-10-15/swagger.json
# Auth: --token flag or $env.MANAGEDLABSCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MANAGEDLABSCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def addRemove-completer [] { ["Add" "Remove"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-lab-services-operations List" } } | get name | first)
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

# Result of the request to list REST API operations
#
# GET /providers/Microsoft.LabServices/operations
# operationId: ProviderOperations_List
export def "providers-microsoft-lab-services-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.LabServices/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the virtual machine details
#
# POST /providers/Microsoft.LabServices/users/{userName}/getEnvironment
# operationId: GlobalUsers_GetEnvironment
export def "providers-microsoft-lab-services-users-get-environment GetEnvironment" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=environment)'
  --api-version: string # Client API version. (default: 2018-10-15)
  environmentId: string # The resourceId of the environment
]: any -> record<environment: record<description: string, environmentState: string, id: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record<lastKnownPowerState: string, privateIpAddress: string, provisioningState: string, rdpAuthority: string, sshAuthority: string, userName: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/getEnvironment" $qp)
  let body = {environmentId: $environmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get batch operation status
#
# POST /providers/Microsoft.LabServices/users/{userName}/getOperationBatchStatus
# operationId: GlobalUsers_GetOperationBatchStatus
export def "providers-microsoft-lab-services-users-get-operation-batch-status GetOperationBatchStatus" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  urls: list # The operation url of long running operation
]: any -> record<items: table<operationUrl: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/getOperationBatchStatus" $qp)
  let body = {urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the status of long running operation
#
# POST /providers/Microsoft.LabServices/users/{userName}/getOperationStatus
# operationId: GlobalUsers_GetOperationStatus
export def "providers-microsoft-lab-services-users-get-operation-status GetOperationStatus" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  operationUrl: string # The operation url of long running operation
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/getOperationStatus" $qp)
  let body = {operationUrl: $operationUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get personal preferences for a user
#
# POST /providers/Microsoft.LabServices/users/{userName}/getPersonalPreferences
# operationId: GlobalUsers_GetPersonalPreferences
export def "providers-microsoft-lab-services-users-get-personal-preferences GetPersonalPreferences" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --addRemove: string@addRemove-completer # Enum indicating if user is adding or removing a favorite lab
  --labAccountResourceId: string # Resource Id of the lab account
  --labResourceId: string # Resource Id of the lab to add/remove from the favorites list
]: any -> record<favoriteLabResourceIds: list<string>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/getPersonalPreferences" $qp)
  let body = {addRemove: $addRemove, labAccountResourceId: $labAccountResourceId, labResourceId: $labResourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Environments for the user
#
# POST /providers/Microsoft.LabServices/users/{userName}/listEnvironments
# operationId: GlobalUsers_ListEnvironments
export def "providers-microsoft-lab-services-users-list-environments ListEnvironments" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --labId: string # The resource Id of the lab
]: any -> record<environments: table<description: string, environmentState: string, id: string, latestOperationResult: record, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/listEnvironments" $qp)
  let body = {labId: $labId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List labs for the user.
#
# POST /providers/Microsoft.LabServices/users/{userName}/listLabs
# operationId: GlobalUsers_ListLabs
export def "providers-microsoft-lab-services-users-list-labs ListLabs" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<labs: table<id: string, name: string, provisioningState: string, usageQuota: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/listLabs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a user to a managed lab
#
# POST /providers/Microsoft.LabServices/users/{userName}/register
# operationId: GlobalUsers_Register
export def "providers-microsoft-lab-services-users-register Register" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --registrationCode: string # The registration code of the lab.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/register" $qp)
  let body = {registrationCode: $registrationCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resets the user password on an environment This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/resetPassword
# operationId: GlobalUsers_ResetPassword
export def "providers-microsoft-lab-services-users-reset-password ResetPassword" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environmentId: string # The resourceId of the environment
  --password: string # The password to assign to the user specified in
  --username: string # The username for which the password will be reset.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/resetPassword" $qp)
  let body = {environmentId: $environmentId, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts an environment by starting all resources inside the environment. This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/startEnvironment
# operationId: GlobalUsers_StartEnvironment
export def "providers-microsoft-lab-services-users-start-environment StartEnvironment" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environmentId: string # The resourceId of the environment
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/startEnvironment" $qp)
  let body = {environmentId: $environmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops an environment by stopping all resources inside the environment This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/stopEnvironment
# operationId: GlobalUsers_StopEnvironment
export def "providers-microsoft-lab-services-users-stop-environment StopEnvironment" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environmentId: string # The resourceId of the environment
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.LabServices/users/($userName)/stopEnvironment" $qp)
  let body = {environmentId: $environmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List lab accounts in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.LabServices/labaccounts
# operationId: LabAccounts_ListBySubscription
export def "subscriptions-providers-microsoft-lab-services-labaccounts ListBySubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=sizeConfiguration)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.LabServices/labaccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get operation
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.LabServices/locations/{locationName}/operations/{operationName}
# operationId: Operations_Get
export def "subscriptions-providers-microsoft-lab-services-locations-operations Get" [
  subscriptionId: string
  locationName: string
  operationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, message: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.LabServices/locations/($locationName)/operations/($operationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List lab accounts in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts
# operationId: LabAccounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts ListByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=sizeConfiguration)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lab account. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts Delete" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lab account
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts Get" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=sizeConfiguration)'
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of lab accounts.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Update
# --properties shape: {enabledRegionSelection?: bool, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts Update" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of a Lab Account. — shape: {enabledRegionSelection?: bool, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing Lab Account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_CreateOrUpdate
# --properties shape: {enabledRegionSelection?: bool, latestOperationResult?: record, provisioningState?: string, sizeConfiguration?: record, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of a Lab Account. — shape: {enabledRegionSelection?: bool, latestOperationResult?: record, provisioningState?: string, sizeConfiguration?: record, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a lab in a lab account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/createLab
# operationId: LabAccounts_CreateLab
# --environmentSettingCreationParameters shape: {resourceSettingCreationParameters: record}
# --labCreationParameters shape: {maxUsersInLab?: int}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-create-lab CreateLab" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --environmentSettingCreationParameters: record # Settings related to creating an environment setting — shape: {resourceSettingCreationParameters: record}
  labCreationParameters: record # Settings related to creating a lab — shape: {maxUsersInLab?: int}
  --location: string # The location of the resource
  name: string # The name of the resource
  --tags: record # The tags of the resource.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/createLab" $qp)
  let body = {environmentSettingCreationParameters: $environmentSettingCreationParameters, labCreationParameters: $labCreationParameters, location: $location, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List gallery images in a given lab account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages
# operationId: GalleryImages_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages List" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/galleryimages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete gallery image.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages Delete" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  galleryImageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/galleryimages/($galleryImageName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get gallery image
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages Get" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  galleryImageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/galleryimages/($galleryImageName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of gallery images.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Update
# --properties shape: {isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages Update" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  galleryImageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # The gallery image properties — shape: {isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/galleryimages/($galleryImageName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing Gallery Image.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_CreateOrUpdate
# --properties shape: {imageReference?: record, isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  galleryImageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # The gallery image properties — shape: {imageReference?: record, isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/galleryimages/($galleryImageName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get regional availability information for each size category configured under a lab account
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/getRegionalAvailability
# operationId: LabAccounts_GetRegionalAvailability
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-get-regional-availability GetRegionalAvailability" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<regionalAvailability: table<region: string, sizeAvailabilities: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/getRegionalAvailability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List labs in a given lab account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs
# operationId: Labs_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs List" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=maxUsersInLab)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lab. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs Delete" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lab
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs Get" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=maxUsersInLab)'
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of labs.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Update
# --properties shape: {maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs Update" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of a Lab. — shape: {maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing Lab.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_CreateOrUpdate
# --properties shape: {latestOperationResult?: record, maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of a Lab. — shape: {latestOperationResult?: record, maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add users to a lab
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/addUsers
# operationId: Labs_AddUsers
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-add-users AddUsers" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  emailAddresses: list # List of user emails addresses to add to the lab.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/addUsers" $qp)
  let body = {emailAddresses: $emailAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List environment setting in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings
# operationId: EnvironmentSettings_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings List" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=publishingState)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete environment setting. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings Delete" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get environment setting
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings Get" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=publishingState)'
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of environment setting.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Update
# --properties shape: {configurationState?: "NotApplicable"|"Completed", description?: string, provisioningState?: string, resourceSettings?: record, title?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings Update" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of an environment setting — shape: {configurationState?: "NotApplicable"|"Completed", description?: string, provisioningState?: string, resourceSettings?: record, title?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing Environment Setting. This operation can take a while to complete
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_CreateOrUpdate
# --properties shape: {configurationState?: "NotApplicable"|"Completed", description?: string, latestOperationResult?: record, provisioningState?: string, resourceSettings: record, title?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of an environment setting — shape: {configurationState?: "NotApplicable"|"Completed", description?: string, latestOperationResult?: record, provisioningState?: string, resourceSettings: record, title?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Claims a random environment for a user in an environment settings
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/claimAny
# operationId: EnvironmentSettings_ClaimAny
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-claim-any ClaimAny" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/claimAny" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List environments in a given environment setting.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments
# operationId: Environments_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments List" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=networkInterface)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete environment. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments Delete" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get environment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments Get" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=networkInterface)'
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of environments.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Update
# --properties shape: {provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments Update" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of an environment — shape: {provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing Environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_CreateOrUpdate
# --properties shape: {latestOperationResult?: record, networkInterface?: record, provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Properties of an environment — shape: {latestOperationResult?: record, networkInterface?: record, provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Claims the environment and assigns it to the user
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/claim
# operationId: Environments_Claim
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-claim Claim" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)/claim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resets the user password on an environment This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/resetPassword
# operationId: Environments_ResetPassword
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-reset-password ResetPassword" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environmentId: string # The resourceId of the environment
  --password: string # The password to assign to the user specified in
  --username: string # The username for which the password will be reset.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)/resetPassword" $qp)
  let body = {environmentId: $environmentId, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts an environment by starting all resources inside the environment. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/start
# operationId: Environments_Start
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-start Start" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops an environment by stopping all resources inside the environment This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/stop
# operationId: Environments_Stop
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  environmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/environments/($environmentName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provisions/deprovisions required resources for an environment setting based on current state of the lab/environment setting.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/publish
# operationId: EnvironmentSettings_Publish
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-publish Publish" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --useExistingImage: oneof<nothing, bool> # Whether to use existing VM custom image when publishing.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/publish" $qp)
  let body = {useExistingImage: $useExistingImage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a template by starting all resources inside the template. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/start
# operationId: EnvironmentSettings_Start
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-start Start" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a template by starting all resources inside the template. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/stop
# operationId: EnvironmentSettings_Stop
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  environmentSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/environmentsettings/($environmentSettingName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register to managed lab.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/register
# operationId: Labs_Register
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-register Register" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/register" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users
# operationId: Users_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users List" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=email)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users Delete" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/users/($userName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users Get" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=email)'
  --api-version: string # Client API version. (default: 2018-10-15)
]: nothing -> record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/users/($userName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of users.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Update
# --properties shape: {provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users Update" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Lab User properties — shape: {provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/users/($userName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing User.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_CreateOrUpdate
# --properties shape: {latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labAccountName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --properties: record # Lab User properties — shape: {latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.LabServices/labaccounts/($labAccountName)/labs/($labName)/users/($userName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
