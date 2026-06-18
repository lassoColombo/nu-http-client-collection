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
def add-remove-completer [] { ["Add" "Remove"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-lab-services-operations list" } } | get name | first)
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
export def "providers-microsoft-lab-services-operations list" [
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
export def "providers-microsoft-lab-services-users-get-environment get-global" [
  user_name: string
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
  environment_id: string # The resourceId of the environment
]: any -> record<environment: record<description: string, environmentState: string, id: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record<lastKnownPowerState: string, privateIpAddress: string, provisioningState: string, rdpAuthority: string, sshAuthority: string, userName: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/getEnvironment") $qp)
  let req_body = {"environmentId": $environment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get batch operation status
#
# POST /providers/Microsoft.LabServices/users/{userName}/getOperationBatchStatus
# operationId: GlobalUsers_GetOperationBatchStatus
export def "providers-microsoft-lab-services-users-get-operation-batch-status get-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  urls: list<string> # The operation url of long running operation
]: any -> record<items: table<operationUrl: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/getOperationBatchStatus") $qp)
  let req_body = {"urls": $urls} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the status of long running operation
#
# POST /providers/Microsoft.LabServices/users/{userName}/getOperationStatus
# operationId: GlobalUsers_GetOperationStatus
export def "providers-microsoft-lab-services-users-get-operation-status get-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  operation_url: string # The operation url of long running operation
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/getOperationStatus") $qp)
  let req_body = {"operationUrl": $operation_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get personal preferences for a user
#
# POST /providers/Microsoft.LabServices/users/{userName}/getPersonalPreferences
# operationId: GlobalUsers_GetPersonalPreferences
export def "providers-microsoft-lab-services-users-get-personal-preferences get-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --add-remove: string@add-remove-completer # Enum indicating if user is adding or removing a favorite lab
  --lab-account-resource-id: string # Resource Id of the lab account
  --lab-resource-id: string # Resource Id of the lab to add/remove from the favorites list
]: any -> record<favoriteLabResourceIds: list<string>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/getPersonalPreferences") $qp)
  let req_body = {"addRemove": $add_remove, "labAccountResourceId": $lab_account_resource_id, "labResourceId": $lab_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Environments for the user
#
# POST /providers/Microsoft.LabServices/users/{userName}/listEnvironments
# operationId: GlobalUsers_ListEnvironments
export def "providers-microsoft-lab-services-users-list-environments list-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --lab-id: string # The resource Id of the lab
]: any -> record<environments: table<description: string, environmentState: string, id: string, latestOperationResult: record, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/listEnvironments") $qp)
  let req_body = {"labId": $lab_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List labs for the user.
#
# POST /providers/Microsoft.LabServices/users/{userName}/listLabs
# operationId: GlobalUsers_ListLabs
export def "providers-microsoft-lab-services-users-list-labs list-global" [
  user_name: string
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
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/listLabs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a user to a managed lab
#
# POST /providers/Microsoft.LabServices/users/{userName}/register
# operationId: GlobalUsers_Register
export def "providers-microsoft-lab-services-users-register create-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --registration-code: string # The registration code of the lab.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/register") $qp)
  let req_body = {"registrationCode": $registration_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resets the user password on an environment This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/resetPassword
# operationId: GlobalUsers_ResetPassword
export def "providers-microsoft-lab-services-users-reset-password reset-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environment_id: string # The resourceId of the environment
  --password: string # The password to assign to the user specified in
  --username: string # The username for which the password will be reset.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/resetPassword") $qp)
  let req_body = {"environmentId": $environment_id, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts an environment by starting all resources inside the environment. This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/startEnvironment
# operationId: GlobalUsers_StartEnvironment
export def "providers-microsoft-lab-services-users-start-environment start-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environment_id: string # The resourceId of the environment
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/startEnvironment") $qp)
  let req_body = {"environmentId": $environment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops an environment by stopping all resources inside the environment This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/stopEnvironment
# operationId: GlobalUsers_StopEnvironment
export def "providers-microsoft-lab-services-users-stop-environment stop-global" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environment_id: string # The resourceId of the environment
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.LabServices/users/{user_name}/stopEnvironment") $qp)
  let req_body = {"environmentId": $environment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List lab accounts in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.LabServices/labaccounts
# operationId: LabAccounts_ListBySubscription
export def "subscriptions-providers-microsoft-lab-services-labaccounts list-accounts" [
  subscription_id: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.LabServices/labaccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get operation
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.LabServices/locations/{locationName}/operations/{operationName}
# operationId: Operations_Get
export def "subscriptions-providers-microsoft-lab-services-locations-operations get" [
  subscription_id: string
  location_name: string
  operation_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name), operation_name: (encode-path-segment $operation_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.LabServices/locations/{location_name}/operations/{operation_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List lab accounts in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts
# operationId: LabAccounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts list-accounts" [
  subscription_id: string
  resource_group_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lab account. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts delete-accounts" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lab account
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts get-accounts" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of lab accounts.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Update
# --properties shape: {enabledRegionSelection?: bool, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts update-accounts" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or replace an existing Lab Account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_CreateOrUpdate
# --properties shape: {enabledRegionSelection?: bool, latestOperationResult?: record, provisioningState?: string, sizeConfiguration?: record, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts create-accounts-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a lab in a lab account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/createLab
# operationId: LabAccounts_CreateLab
# --environmentSettingCreationParameters shape: {resourceSettingCreationParameters: record}
# --labCreationParameters shape: {maxUsersInLab?: int}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-create-lab create-accounts" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --environment-setting-creation-parameters: record # Settings related to creating an environment setting — shape: {resourceSettingCreationParameters: record}
  lab_creation_parameters: record # Settings related to creating a lab — shape: {maxUsersInLab?: int}
  --location: string # The location of the resource
  name: string # The name of the resource
  --tags: record # The tags of the resource.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/createLab") $qp)
  let req_body = {"environmentSettingCreationParameters": $environment_setting_creation_parameters, "labCreationParameters": $lab_creation_parameters, "location": $location, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List gallery images in a given lab account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages
# operationId: GalleryImages_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages list-gallery-images" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/galleryimages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete gallery image.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages delete-gallery-images" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), gallery_image_name: (encode-path-segment $gallery_image_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/galleryimages/{gallery_image_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get gallery image
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages get-gallery-images" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), gallery_image_name: (encode-path-segment $gallery_image_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/galleryimages/{gallery_image_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of gallery images.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Update
# --properties shape: {isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages update-gallery-images" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), gallery_image_name: (encode-path-segment $gallery_image_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/galleryimages/{gallery_image_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or replace an existing Gallery Image.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_CreateOrUpdate
# --properties shape: {imageReference?: record, isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-galleryimages create-gallery-images-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), gallery_image_name: (encode-path-segment $gallery_image_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/galleryimages/{gallery_image_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get regional availability information for each size category configured under a lab account
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/getRegionalAvailability
# operationId: LabAccounts_GetRegionalAvailability
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-get-regional-availability get-accounts" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/getRegionalAvailability") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List labs in a given lab account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs
# operationId: Labs_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lab. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lab
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of labs.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Update
# --properties shape: {maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or replace an existing Lab.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_CreateOrUpdate
# --properties shape: {latestOperationResult?: record, maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add users to a lab
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/addUsers
# operationId: Labs_AddUsers
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-add-users create" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  email_addresses: list<string> # List of user emails addresses to add to the lab.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/addUsers") $qp)
  let req_body = {"emailAddresses": $email_addresses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List environment setting in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings
# operationId: EnvironmentSettings_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings list-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete environment setting. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings delete-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get environment setting
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings get-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of environment setting.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Update
# --properties shape: {configurationState?: "NotApplicable"|"Completed", description?: string, provisioningState?: string, resourceSettings?: record, title?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings update-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or replace an existing Environment Setting. This operation can take a while to complete
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_CreateOrUpdate
# --properties shape: {configurationState?: "NotApplicable"|"Completed", description?: string, latestOperationResult?: record, provisioningState?: string, resourceSettings: record, title?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings create-environment-settings-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Claims a random environment for a user in an environment settings
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/claimAny
# operationId: EnvironmentSettings_ClaimAny
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-claim-any create-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/claimAny") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List environments in a given environment setting.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments
# operationId: Environments_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete environment. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get environment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of environments.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Update
# --properties shape: {provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or replace an existing Environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_CreateOrUpdate
# --properties shape: {latestOperationResult?: record, networkInterface?: record, provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Claims the environment and assigns it to the user
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/claim
# operationId: Environments_Claim
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-claim create" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}/claim") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resets the user password on an environment This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/resetPassword
# operationId: Environments_ResetPassword
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-reset-password reset" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  environment_id: string # The resourceId of the environment
  --password: string # The password to assign to the user specified in
  --username: string # The username for which the password will be reset.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}/resetPassword") $qp)
  let req_body = {"environmentId": $environment_id, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts an environment by starting all resources inside the environment. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/start
# operationId: Environments_Start
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-start start" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops an environment by stopping all resources inside the environment This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/stop
# operationId: Environments_Stop
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-environments-stop stop" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/environments/{environment_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provisions/deprovisions required resources for an environment setting based on current state of the lab/environment setting.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/publish
# operationId: EnvironmentSettings_Publish
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-publish publish-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-10-15)
  --use-existing-image: oneof<nothing, bool> # Whether to use existing VM custom image when publishing.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/publish") $qp)
  let req_body = {"useExistingImage": $use_existing_image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a template by starting all resources inside the template. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/start
# operationId: EnvironmentSettings_Start
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-start start-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a template by starting all resources inside the template. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/stop
# operationId: EnvironmentSettings_Stop
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-environmentsettings-stop stop-environment-settings" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), environment_setting_name: (encode-path-segment $environment_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/environmentsettings/{environment_setting_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register to managed lab.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/register
# operationId: Labs_Register
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-register create" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/register") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users
# operationId: Users_List
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Delete
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/users/{user_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Get
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/users/{user_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify properties of users.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Update
# --properties shape: {provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/users/{user_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or replace an existing User.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_CreateOrUpdate
# --properties shape: {latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
export def "subscriptions-resource-groups-providers-microsoft-lab-services-labaccounts-labs-users create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_account_name: (encode-path-segment $lab_account_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.LabServices/labaccounts/{lab_account_name}/labs/{lab_name}/users/{user_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
