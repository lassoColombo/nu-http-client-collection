# Auto-generated client for Akamai: Akamai MFA API vv1
# Source: https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/amfa/v1/openapi.json
# Auth: --token flag or $env.AKAMAI_AKAMAI_MFA_API_TOKEN

const BASE_URL = "https://{hostname}/amfa/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AKAMAI_AKAMAI_MFA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://{hostname}/amfa/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["ACTIVE" "DEVICES_DISABLED" "PROVISIONING_DISABLED" "UNENROLLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "email-enrollments post-send-enrollment-email" } } | get name | first)
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

# Send enrollment email
#
# POST /email-enrollments
# Docs: https://techdocs.akamai.com/mfa/reference/post-send-enrollment-email — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-send-enrollment-email
export def "email-enrollments post-send-enrollment-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  userIds: list # A set of users to send enrollment emails.
]: any -> record<userIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email-enrollments" $qp)
  let body = {userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a group
#
# POST /groups
# Docs: https://techdocs.akamai.com/mfa/reference/post-group — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-group
export def "groups post-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  groupName: string # Descriptive label for the group.
  --summary: string # Summary of the group. Indicates what the group represents.
]: any -> record<createdDate: string, groupId: string, groupName: string, modifiedDate: string, summary: string, usersCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let body = {groupName: $groupName, summary: $summary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List groups
#
# GET /groups
# Docs: https://techdocs.akamai.com/mfa/reference/get-groups — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-groups
export def "groups get-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number index starting at the default value of `1`. (default: 1, e.g. 2)
  --page-size: int # The number of records displayed on each page. (e.g. 50)
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<page: table<createdDate: string, groupId: string, groupName: string, modifiedDate: string, summary: string, usersCount: int>, totalItemCount: int, totalPageCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a group
#
# GET /groups/{groupId}
# Docs: https://techdocs.akamai.com/mfa/reference/get-group — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-group
export def "groups get-group" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdDate: string, groupId: string, groupName: string, modifiedDate: string, summary: string, usersCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a group
#
# DELETE /groups/{groupId}
# Docs: https://techdocs.akamai.com/mfa/reference/delete-group — See documentation for this operation in Akamai's Akamai MFA API
# operationId: delete-group
export def "groups delete-group" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a user to a group
#
# POST /groups/{groupId}/users/{userId}
# Docs: https://techdocs.akamai.com/mfa/reference/post-user-to-group — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-user-to-group
export def "groups-users post-user-to-group" [
  groupId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a user from a group
#
# DELETE /groups/{groupId}/users/{userId}
# Docs: https://techdocs.akamai.com/mfa/reference/delete-user-from-group — See documentation for this operation in Akamai's Akamai MFA API
# operationId: delete-user-from-group
export def "groups-users delete-user-from-group" [
  groupId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupId)/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a user
#
# POST /users
# Docs: https://techdocs.akamai.com/mfa/reference/post-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-user
export def "users post-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --email: string # The user's email address.
  --firstName: string # The user's first name.
  --lastName: string # The user's last name.
  username: string # The user's username. The username is unique for the tenant.
]: any -> record<aliases: table<alias: string, aliasId: string, createdDate: string, modifiedDate: string>, createdDate: string, deviceCount: int, devices: table<createdDate: string, deviceId: string, deviceName: string, deviceType: string, isDeviceEnabled: bool, modifiedDate: string, platform: string>, email: string, firstName: string, groups: table<groupId: string, groupName: string, summary: string>, importSource: record<id: string, type: string>, lastName: string, modifiedDate: string, userId: string, userStatus: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let body = {email: $email, firstName: $firstName, lastName: $lastName, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /users
# Docs: https://techdocs.akamai.com/mfa/reference/get-users — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-users
export def "users get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number index starting at the default value of `1`. (default: 1, e.g. 2)
  --pageSize: int # The number of records displayed on each page. The default value is `25`. (default: 25, e.g. 50)
  --status: string@status-completer # __Enum__ Filter user records by the specific status and display a list of user accounts that have this status. (e.g. ACTIVE)
  --includeDevices: oneof<nothing, bool> # Whether the response should include device details for listed users. The default value is `false`. (default: false, e.g. true)
  --policyId: string # Optionally filter users subject to a specific policy. (e.g. policy_4HZnCV)
  --policyName: string # Optionally filter users subject to a specific policy, referred to by name. (e.g. Policy-A)
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<page: int, totalItems: int, totalPages: int, users: table<aliases: list, createdDate: string, deviceCount: int, devices: list, email: string, firstName: string, groups: list, importSource: record, lastName: string, modifiedDate: string, userId: string, userStatus: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "includeDevices" $includeDevices "scalar") (serialize-qp "policyId" $policyId "scalar") (serialize-qp "policyName" $policyName "scalar") (serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{userId}
# Docs: https://techdocs.akamai.com/mfa/reference/get-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-user
export def "users get-user" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<aliases: table<alias: string, aliasId: string, createdDate: string, modifiedDate: string>, createdDate: string, deviceCount: int, devices: table<createdDate: string, deviceId: string, deviceName: string, deviceType: string, isDeviceEnabled: bool, modifiedDate: string, platform: string>, email: string, firstName: string, groups: table<groupId: string, groupName: string, summary: string>, importSource: record<id: string, type: string>, lastName: string, modifiedDate: string, userId: string, userStatus: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /users/{userId}
# Docs: https://techdocs.akamai.com/mfa/reference/put-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: put-user
export def "users put-user" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  email: string # The user's email address.
  firstName: string # The user's first name.
  lastName: string # The user's last name.
  username: string # The user's username. The username is unique for the tenant.
]: any -> record<aliases: table<alias: string, aliasId: string, createdDate: string, modifiedDate: string>, createdDate: string, deviceCount: int, devices: table<createdDate: string, deviceId: string, deviceName: string, deviceType: string, isDeviceEnabled: bool, modifiedDate: string, platform: string>, email: string, firstName: string, groups: table<groupId: string, groupName: string, summary: string>, importSource: record<id: string, type: string>, lastName: string, modifiedDate: string, userId: string, userStatus: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)" $qp)
  let body = {email: $email, firstName: $firstName, lastName: $lastName, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/{userId}
# Docs: https://techdocs.akamai.com/mfa/reference/delete-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: delete-user
export def "users delete-user" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an alias to a user
#
# POST /users/{userId}/aliases
# Docs: https://techdocs.akamai.com/mfa/reference/post-alias-to-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-alias-to-user
export def "users-aliases post-alias-to-user" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  alias: string # Alternate usernames for the user.
]: any -> record<alias: string, aliasId: string, createdDate: string, modifiedDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/aliases" $qp)
  let body = {alias: $alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an alias assigned to a user
#
# DELETE /users/{userId}/aliases/{userAliasId}
# Docs: https://techdocs.akamai.com/mfa/reference/delete-user-alias — See documentation for this operation in Akamai's Akamai MFA API
# operationId: delete-user-alias
export def "users-aliases delete-user-alias" [
  userId: string
  userAliasId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/aliases/($userAliasId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign groups
#
# POST /users/{userId}/assign-groups
# Docs: https://techdocs.akamai.com/mfa/reference/post-assign-groups-to-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-assign-groups-to-user
export def "users-assign-groups post-assign-groups-to-user" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  groupIds: list # A set of groups to assign to a specific user account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/assign-groups" $qp)
  let body = {groupIds: $groupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign policies
#
# POST /users/{userId}/assign-policies
# Docs: https://techdocs.akamai.com/mfa/reference/post-assign-policies-to-user — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-assign-policies-to-user
export def "users-assign-policies post-assign-policies-to-user" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  policyIds: list # A set of policies to assign to a specific user account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/assign-policies" $qp)
  let body = {policyIds: $policyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a bypass code
#
# POST /users/{userId}/bypass-codes
# Docs: https://techdocs.akamai.com/mfa/reference/post-bypass-code — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-bypass-code
export def "users-bypass-codes post-bypass-code" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  expirationDate: string # ISO 8601 timestamp indicating when the bypass code expires. (format: date-time)
  remainingUses: int # The bypass code reuse count at a given time. The maximum reuse number is `10`.
]: any -> record<bypassCode: string, bypassCodeId: string, createdDate: string, expirationDate: string, modifiedDate: string, remainingUses: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/bypass-codes" $qp)
  let body = {expirationDate: $expirationDate, remainingUses: $remainingUses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List bypass codes
#
# GET /users/{userId}/bypass-codes
# Docs: https://techdocs.akamai.com/mfa/reference/get-bypass-codes — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-bypass-codes
export def "users-bypass-codes get-bypass-codes" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<bypassCodes: table<bypassCode: string, bypassCodeId: string, createdDate: string, expirationDate: string, modifiedDate: string, remainingUses: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/bypass-codes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a bypass code
#
# GET /users/{userId}/bypass-codes/{bypassCodeId}
# Docs: https://techdocs.akamai.com/mfa/reference/get-bypass-code — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-bypass-code
export def "users-bypass-codes get-bypass-code" [
  userId: string
  bypassCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<bypassCode: string, bypassCodeId: string, createdDate: string, expirationDate: string, modifiedDate: string, remainingUses: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/bypass-codes/($bypassCodeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the user's devices
#
# GET /users/{userId}/devices
# Docs: https://techdocs.akamai.com/mfa/reference/get-user-devices — See documentation for this operation in Akamai's Akamai MFA API
# operationId: get-user-devices
export def "users-devices get-user-devices" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<devices: table<createdDate: string, deviceId: string, deviceName: string, deviceType: string, isDeviceEnabled: bool, modifiedDate: string, platform: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a hardware token
#
# POST /users/{userId}/devices/assign-hardware-token
# Docs: https://techdocs.akamai.com/mfa/reference/post-assign-hardware-token — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-assign-hardware-token
export def "users-devices-assign-hardware-token post-assign-hardware-token" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  deviceId: string # A unique identifier for the hardware token. You can assign only one token to a specific user account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/devices/assign-hardware-token" $qp)
  let body = {deviceId: $deviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable a device
#
# POST /users/{userId}/devices/{deviceId}/disable
# Docs: https://techdocs.akamai.com/mfa/reference/post-disable-user-device — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-disable-user-device
export def "users-devices-disable post-disable-user-device" [
  userId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdDate: string, deviceId: string, deviceName: string, deviceType: string, isDeviceEnabled: bool, modifiedDate: string, platform: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/devices/($deviceId)/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable a device
#
# POST /users/{userId}/devices/{deviceId}/enable
# Docs: https://techdocs.akamai.com/mfa/reference/post-enable-user-device — See documentation for this operation in Akamai's Akamai MFA API
# operationId: post-enable-user-device
export def "users-devices-enable post-enable-user-device" [
  userId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contractId: string # Unique identifier for the contract. (e.g. C-0N7RAC71)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdDate: string, deviceId: string, deviceName: string, deviceType: string, isDeviceEnabled: bool, modifiedDate: string, platform: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/devices/($deviceId)/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
