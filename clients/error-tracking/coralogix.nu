# Auto-generated client for  v1.0.0
# Source: https://api.coralogix.com/mgmt/openapi/latest/openapi.yaml
# Auth: --token flag or $env.CORALOGIX_API_KEY

const BASE_URL = "https://api.coralogix.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CORALOGIX_API_KEY | default "" }
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

def base-url-completer [] { ["https://api.coralogix.com" "https://api.coralogix.com/mgmt/openapi/3" "https://api.eu2.coralogix.com/mgmt/openapi/3" "https://api.coralogix.us/mgmt/openapi/3" "https://api.cx498.coralogix.com/mgmt/openapi/3" "https://api.coralogix.in/mgmt/openapi/3" "https://api.coralogixsg.com/mgmt/openapi/3" "https://api.ap3.coralogix.com/mgmt/openapi/3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def groupType-completer [] { ["GROUP_TYPE_CLOSED" "GROUP_TYPE_OPEN" "GROUP_TYPE_RESTRICTED" "GROUP_TYPE_UNSPECIFIED"] }
def enableCoralogixCustomerSupportAccess-completer [] { ["CORALOGIX_CUSTOMER_SUPPORT_ACCESS_DISABLED" "CORALOGIX_CUSTOMER_SUPPORT_ACCESS_ENABLED" "CORALOGIX_CUSTOMER_SUPPORT_ACCESS_UNSPECIFIED"] }
def priority-completer [] { ["CASE_PRIORITY_P1" "CASE_PRIORITY_P2" "CASE_PRIORITY_P3" "CASE_PRIORITY_P4" "CASE_PRIORITY_P5" "CASE_PRIORITY_UNSPECIFIED"] }
def viewType-completer [] { ["VIEW_TYPE_ARCHIVE_LOGS" "VIEW_TYPE_ARCHIVE_TEMPLATES" "VIEW_TYPE_LOGS" "VIEW_TYPE_TEMPLATES" "VIEW_TYPE_UNSPECIFIED"] }
def range-completer [] { ["RANGE_CURRENT_MONTH" "RANGE_LAST_30_DAYS" "RANGE_LAST_90_DAYS" "RANGE_LAST_WEEK" "RANGE_LAST_YEAR" "RANGE_UNSPECIFIED"] }
def source-type-completer [] { ["SOURCE_TYPE_LOGS" "SOURCE_TYPE_SPANS" "SOURCE_TYPE_UNSPECIFIED"] }
def priority-completer-1 [] { ["PRIORITY_TYPE_BLOCK" "PRIORITY_TYPE_HIGH" "PRIORITY_TYPE_LOW" "PRIORITY_TYPE_MEDIUM" "PRIORITY_TYPE_UNSPECIFIED"] }
def sourceType-completer [] { ["SOURCE_TYPE_LOGS" "SOURCE_TYPE_SPANS" "SOURCE_TYPE_UNSPECIFIED"] }
def type-completer [] { ["E2M_TYPE_LOGS2METRICS" "E2M_TYPE_SPANS2METRICS" "E2M_TYPE_UNSPECIFIED"] }
def type-completer-1 [] { ["AWS_EVENT_BRIDGE" "DEMISTO" "EMAIL_GROUP" "GENERIC" "IBM_EVENT_NOTIFICATIONS" "JIRA" "MICROSOFT_TEAMS" "MS_TEAMS_WORKFLOW" "OPSGENIE" "PAGERDUTY" "SEND_LOG" "SLACK" "UNKNOWN"] }
def type-completer-2 [] { ["CONNECTOR_TYPE_UNSPECIFIED" "EMAIL" "GENERIC_HTTPS" "IBM_EVENT_NOTIFICATIONS" "PAGERDUTY" "SERVICE_NOW" "SLACK"] }
def connector-type-completer [] { ["CONNECTOR_TYPE_UNSPECIFIED" "EMAIL" "GENERIC_HTTPS" "IBM_EVENT_NOTIFICATIONS" "PAGERDUTY" "SERVICE_NOW" "SLACK"] }
def supported-by-entity-type-completer [] { ["ALERTS" "CASES" "ENTITY_TYPE_UNSPECIFIED" "TEST_NOTIFICATIONS"] }
def entityType-completer [] { ["ALERTS" "CASES" "ENTITY_TYPE_UNSPECIFIED" "TEST_NOTIFICATIONS"] }
def entity-type-completer [] { ["ALERTS" "CASES" "ENTITY_TYPE_UNSPECIFIED" "TEST_NOTIFICATIONS"] }
def sloTimeFrame-completer [] { ["SLO_TIME_FRAME_14_DAYS" "SLO_TIME_FRAME_21_DAYS" "SLO_TIME_FRAME_28_DAYS" "SLO_TIME_FRAME_7_DAYS" "SLO_TIME_FRAME_UNSPECIFIED"] }
def sourceType-completer-1 [] { ["SOURCE_TYPE_DATA_MAP" "SOURCE_TYPE_LOG" "SOURCE_TYPE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aaa-api-keys CreateApiKey" } } | get name | first)
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

# Create API Key
#
# POST /aaa/api-keys/v3
# operationId: ApiKeysService_CreateApiKey
# --keyPermissions shape: {permissions?: list, presets?: list}
export def "aaa-api-keys CreateApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessPolicy: string # JSON string representing the access policy for this API key. Defines granular permissions for users and groups. (e.g. {"version":"2025-01-01","default":{"permissions":{"data-ingest-api-keys:ReadAccessPolicy":"grant","data-ingest-api-keys:Manage":"deny","data-ingest-api-keys:UpdateAccessPolicy":"deny","data-ingest-api-keys:ReadConfig":"grant"}},"rules":[]})
  --hashed: oneof<nothing, bool> # e.g. true
  --keyPermissions: record # This data structure allows to specify loose permissions and permission presets for an API key. — shape: {permissions?: list, presets?: list}
  --name: string # e.g. my_api_key
  --owner: any
]: any -> record<keyId: string, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/api-keys/v3")
  let body = {accessPolicy: $accessPolicy, hashed: $hashed, keyPermissions: $keyPermissions, name: $name, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get "Send Data" API Keys
#
# GET /aaa/api-keys/v3/send_data
# operationId: ApiKeysService_GetSendDataApiKeys
export def "aaa-api-keys-send-data GetSendDataApiKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<accessPolicy: string, active: bool, hashed: bool, id: string, keyPermissions: record, name: string, owner: any, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/api-keys/v3/send_data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API Key
#
# GET /aaa/api-keys/v3/{key_id}
# operationId: ApiKeysService_GetApiKey
export def "aaa-api-keys GetApiKey" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keyInfo: record<accessPolicy: string, active: bool, hashed: bool, id: string, keyPermissions: record<permissions: list, presets: list>, name: string, owner: any, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/api-keys/v3/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update API Key
#
# PUT /aaa/api-keys/v3/{key_id}
# operationId: ApiKeysService_UpdateApiKey
# --permissions shape: {permissions?: list}
# --presets shape: {presets?: list}
export def "aaa-api-keys UpdateApiKey" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessPolicy: string # JSON string representing the access policy for this API key. Defines granular permissions for users and groups. To delete an existing policy, pass an empty string. (e.g. {"version":"2025-01-01","default":{"permissions":{"data-ingest-api-keys:ReadAccessPolicy":"grant","data-ingest-api-keys:Manage":"deny","data-ingest-api-keys:UpdateAccessPolicy":"deny","data-ingest-api-keys:ReadConfig":"grant"}},"rules":[]})
  --isActive: oneof<nothing, bool> # e.g. true
  --newName: string # e.g. my_new_name
  --permissions: record # This data structure represents a set of permissions on an API key. — shape: {permissions?: list}
  --presets: record # This data structure represents a set of permissions presets on an API key. — shape: {presets?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/api-keys/v3/($key_id)")
  let body = {accessPolicy: $accessPolicy, isActive: $isActive, newName: $newName, permissions: $permissions, presets: $presets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete API Key
#
# DELETE /aaa/api-keys/v3/{key_id}
# operationId: ApiKeysService_DeleteApiKey
export def "aaa-api-keys DeleteApiKey" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/api-keys/v3/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Groups
#
# GET /aaa/team-groups/v1
# operationId: TeamPermissionsMgmtService_GetTeamGroups
export def "aaa-team-groups GetTeamGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: record
]: nothing -> record<groups: table<createdAt: string, description: string, externalId: string, groupId: record, groupOrigin: string, groupType: string, name: string, nextGenScopeId: string, roles: list, scope: record, teamId: record, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-groups/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team Group
#
# PUT /aaa/team-groups/v1
# operationId: TeamPermissionsMgmtService_UpdateTeamGroup
# --groupId shape: {id?: int}
# --roleUpdates shape: {roleIds?: list}
# --scopeFilters shape: {applications?: list, subsystems?: list}
# --userUpdates shape: {userIds?: list}
export def "aaa-team-groups UpdateTeamGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --externalId: string
  --groupId: record # This data structure represents the information associated with a team group. — shape: {id?: int}
  --groupType: string@groupType-completer
  --name: string
  --nextGenScopeId: string
  --roleUpdates: record # This data structure represents the information associated with an API key. — shape: {roleIds?: list}
  --scopeFilters: record # shape: {applications?: list, subsystems?: list}
  --userUpdates: record # This data structure represents the information associated with an API key. — shape: {userIds?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-groups/v1")
  let body = {description: $description, externalId: $externalId, groupId: $groupId, groupType: $groupType, name: $name, nextGenScopeId: $nextGenScopeId, roleUpdates: $roleUpdates, scopeFilters: $scopeFilters, userUpdates: $userUpdates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Team Group
#
# POST /aaa/team-groups/v1
# operationId: TeamPermissionsMgmtService_CreateTeamGroup
# --roleIds item shape: {id?: int}
# --scopeFilters shape: {applications?: list, subsystems?: list}
# --teamId shape: {id?: int}
# --userIds item shape: {id?: string}
export def "aaa-team-groups CreateTeamGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --externalId: string
  --groupType: string@groupType-completer
  --name: string
  --nextGenScopeId: string
  --roleIds: list # item shape: {id?: int}
  --scopeFilters: record # shape: {applications?: list, subsystems?: list}
  --teamId: record # shape: {id?: int}
  --userIds: list # item shape: {id?: string}
]: any -> record<groupId: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-groups/v1")
  let body = {description: $description, externalId: $externalId, groupType: $groupType, name: $name, nextGenScopeId: $nextGenScopeId, roleIds: $roleIds, scopeFilters: $scopeFilters, teamId: $teamId, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Team Group
#
# GET /aaa/team-groups/v1/id/{id}
# operationId: TeamPermissionsMgmtService_GetTeamGroup
export def "aaa-team-groups-id GetTeamGroup" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group: record<createdAt: string, description: string, externalId: string, groupId: record<id: int>, groupOrigin: string, groupType: string, name: string, nextGenScopeId: string, roles: list<record>, scope: record<filters: record, id: record>, teamId: record<id: int>, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-groups/v1/id/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Group By Name
#
# GET /aaa/team-groups/v1/name/{name}
# operationId: TeamPermissionsMgmtService_GetTeamGroupByName
export def "aaa-team-groups-name GetTeamGroupByName" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group: record<createdAt: string, description: string, externalId: string, groupId: record<id: int>, groupOrigin: string, groupType: string, name: string, nextGenScopeId: string, roles: list<record>, scope: record<filters: record, id: record>, teamId: record<id: int>, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-groups/v1/name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Users To Team Groups
#
# POST /aaa/team-groups/v1/users
# operationId: TeamPermissionsMgmtService_AddUsersToTeamGroups
# --addUsersToGroup item shape: {groupId?: record, userIds?: list}
# --teamId shape: {id?: int}
export def "aaa-team-groups-users AddUsersToTeamGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addUsersToGroup: list # item shape: {groupId?: record, userIds?: list}
  --teamId: record # shape: {id?: int}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-groups/v1/users")
  let body = {addUsersToGroup: $addUsersToGroup, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Users From Team Groups
#
# DELETE /aaa/team-groups/v1/users
# operationId: TeamPermissionsMgmtService_RemoveUsersFromTeamGroups
export def "aaa-team-groups-users RemoveUsersFromTeamGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: record
  --remove-users-from-group: list
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "multi") (serialize-qp "remove_users_from_group" $remove_users_from_group "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-groups/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Team Group
#
# DELETE /aaa/team-groups/v1/{id}
# operationId: TeamPermissionsMgmtService_DeleteTeamGroup
export def "aaa-team-groups DeleteTeamGroup" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-groups/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Group Users
#
# GET /aaa/team-groups/v1/{id}/users
# operationId: TeamPermissionsMgmtService_GetGroupUsers
export def "aaa-team-groups-users GetGroupUsers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # format: int64
  --page-token: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/aaa/team-groups/v1/($id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Users To Team Group
#
# POST /aaa/team-groups/v1/{id}/users
# operationId: TeamPermissionsMgmtService_AddUsersToTeamGroup
# --userIds item shape: {id?: string}
export def "aaa-team-groups-users AddUsersToTeamGroup" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userIds: list # item shape: {id?: string}
]: any -> record<teamId: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-groups/v1/($id)/users")
  let body = {userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Users From Team Group
#
# DELETE /aaa/team-groups/v1/{id}/users
# operationId: TeamPermissionsMgmtService_RemoveUsersFromTeamGroup
export def "aaa-team-groups-users RemoveUsersFromTeamGroup" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-ids: list
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_ids" $user_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/aaa/team-groups/v1/($id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Roles
#
# GET /aaa/team-roles/v1/custom-roles
# operationId: RoleManagementService_ListCustomRoles
export def "aaa-team-roles-custom-roles ListCustomRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: int # format: int64
]: nothing -> record<roles: table<description: string, name: string, parentRoleId: int, parentRoleName: string, permissions: list, roleId: int, teamId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-roles/v1/custom-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Role
#
# PUT /aaa/team-roles/v1/custom-roles
# operationId: RoleManagementService_CreateRole
export def "aaa-team-roles-custom-roles CreateRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --name: string
  --parentRoleId: int # format: int64
  --permissions: list
  --teamId: int # format: int64
  --parentRoleName: string
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-roles/v1/custom-roles")
  let body = {description: $description, name: $name, parentRoleId: $parentRoleId, permissions: $permissions, teamId: $teamId, parentRoleName: $parentRoleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Custom Role
#
# GET /aaa/team-roles/v1/custom-roles/{role_id}
# operationId: RoleManagementService_GetCustomRole
export def "aaa-team-roles-custom-roles GetCustomRole" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<role: record<description: string, name: string, parentRoleId: int, parentRoleName: string, permissions: list<string>, roleId: int, teamId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-roles/v1/custom-roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Role
#
# POST /aaa/team-roles/v1/custom-roles/{role_id}
# operationId: RoleManagementService_UpdateRole
# --newPermissions shape: {permissions?: list}
export def "aaa-team-roles-custom-roles UpdateRole" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newDescription: string
  --newName: string
  --newPermissions: record # shape: {permissions?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-roles/v1/custom-roles/($role_id)")
  let body = {newDescription: $newDescription, newName: $newName, newPermissions: $newPermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Role
#
# DELETE /aaa/team-roles/v1/custom-roles/{role_id}
# operationId: RoleManagementService_DeleteRole
export def "aaa-team-roles-custom-roles DeleteRole" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-roles/v1/custom-roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List System Roles
#
# GET /aaa/team-roles/v1/system-roles
# operationId: RoleManagementService_ListSystemRoles
export def "aaa-team-roles-system-roles ListSystemRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<roles: table<description: string, name: string, permissions: list, roleId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-roles/v1/system-roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate/Deactivate SAML
#
# POST /aaa/team-saml/v1/active
# operationId: SamlConfigurationService_SetActive
export def "aaa-team-saml-active SetActive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isActive: oneof<nothing, bool>
  --teamId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-saml/v1/active")
  let body = {isActive: $isActive, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SAML Configuration
#
# GET /aaa/team-saml/v1/configuration
# operationId: SamlConfigurationService_GetConfiguration
export def "aaa-team-saml-configuration GetConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: int # format: int64
]: nothing -> record<idpDetails: record<icon: string, name: string>, idpParameters: any, spParameters: record<assertionConsumerServiceUrl: string, binding: string, metadataUrl: string, nameIdFormat: string, signingCertPem: string>, teamId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-saml/v1/configuration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set IDP Parameters
#
# POST /aaa/team-saml/v1/idp_parameters
# operationId: SamlConfigurationService_SetIDPParameters
export def "aaa-team-saml-idp-parameters SetIDPParameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --params: any
  --teamId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-saml/v1/idp_parameters")
  let body = {params: $params, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SP Parameters
#
# GET /aaa/team-saml/v1/sp_parameters
# operationId: SamlConfigurationService_GetSPParameters
export def "aaa-team-saml-sp-parameters GetSPParameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: int # format: int64, e.g. 1234567
]: nothing -> record<params: record<assertionConsumerServiceUrl: string, binding: string, metadataUrl: string, nameIdFormat: string, signingCertPem: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-saml/v1/sp_parameters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Scopes By Ids
#
# GET /aaa/team-scopes/v1
# operationId: ScopesService_GetTeamScopesByIds
export def "aaa-team-scopes GetTeamScopesByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: nothing -> record<scopes: table<defaultExpression: string, description: string, displayName: string, filters: list, id: string, teamId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-scopes/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Scope
#
# PUT /aaa/team-scopes/v1
# operationId: ScopesService_UpdateScope
# --filters item shape: {entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ENTITY_TYPE_LOGS"|"ENTITY_TYPE_SPANS", expression?: string}
export def "aaa-team-scopes UpdateScope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  defaultExpression: string # e.g. <v1>true
  --description: string # e.g. The best scope
  displayName: string # e.g. my-scope
  filters: list # item shape: {entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ENTITY_TYPE_LOGS"|"ENTITY_TYPE_SPANS", expression?: string}
  id: string # e.g. 60c82be2-413f-4b8e-8201-7f5c51e2ef2b
]: any -> record<scope: record<defaultExpression: string, description: string, displayName: string, filters: list<record>, id: string, teamId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-scopes/v1")
  let body = {defaultExpression: $defaultExpression, description: $description, displayName: $displayName, filters: $filters, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Scope
#
# POST /aaa/team-scopes/v1
# operationId: ScopesService_CreateScope
# --filters item shape: {entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ENTITY_TYPE_LOGS"|"ENTITY_TYPE_SPANS", expression?: string}
export def "aaa-team-scopes CreateScope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaultExpression: string # e.g. <v1>true
  --description: string # e.g. The best scope
  displayName: string # e.g. my-scope
  filters: list # item shape: {entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ENTITY_TYPE_LOGS"|"ENTITY_TYPE_SPANS", expression?: string}
]: any -> record<scope: record<defaultExpression: string, description: string, displayName: string, filters: list<record>, id: string, teamId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-scopes/v1")
  let body = {defaultExpression: $defaultExpression, description: $description, displayName: $displayName, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Team Scopes
#
# GET /aaa/team-scopes/v1/list
# operationId: ScopesService_GetTeamScopes
export def "aaa-team-scopes-list GetTeamScopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scopes: table<defaultExpression: string, description: string, displayName: string, filters: list, id: string, teamId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-scopes/v1/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Scope
#
# DELETE /aaa/team-scopes/v1/{id}
# operationId: ScopesService_DeleteScope
export def "aaa-team-scopes DeleteScope" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aaa/team-scopes/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company IP access settings
#
# GET /aaa/team-sec-ip-access/v1
# operationId: IpAccessService_GetCompanyIpAccessSettings
export def "aaa-team-sec-ip-access GetCompanyIpAccessSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # e.g. 
]: nothing -> record<settings: record<enableCoralogixCustomerSupportAccess: string, id: string, ipAccess: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-sec-ip-access/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace company IP access settings
#
# PUT /aaa/team-sec-ip-access/v1
# operationId: IpAccessService_ReplaceCompanyIpAccessSettings
# --ipAccess item shape: {enabled?: bool, ipRange?: string, name?: string}
export def "aaa-team-sec-ip-access ReplaceCompanyIpAccessSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enableCoralogixCustomerSupportAccess: string@enableCoralogixCustomerSupportAccess-completer
  --id: string # e.g. d662a2f1-21c3-493c-8f8a-595d3ab05ef3
  --ipAccess: list # item shape: {enabled?: bool, ipRange?: string, name?: string}
]: any -> record<settings: record<enableCoralogixCustomerSupportAccess: string, id: string, ipAccess: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-sec-ip-access/v1")
  let body = {enableCoralogixCustomerSupportAccess: $enableCoralogixCustomerSupportAccess, id: $id, ipAccess: $ipAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create company IP access settings
#
# POST /aaa/team-sec-ip-access/v1
# operationId: IpAccessService_CreateCompanyIpAccessSettings
# --ipAccess item shape: {enabled?: bool, ipRange?: string, name?: string}
export def "aaa-team-sec-ip-access CreateCompanyIpAccessSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enableCoralogixCustomerSupportAccess: string@enableCoralogixCustomerSupportAccess-completer
  --ipAccess: list # item shape: {enabled?: bool, ipRange?: string, name?: string}
]: any -> record<settings: record<enableCoralogixCustomerSupportAccess: string, id: string, ipAccess: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aaa/team-sec-ip-access/v1")
  let body = {enableCoralogixCustomerSupportAccess: $enableCoralogixCustomerSupportAccess, ipAccess: $ipAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete company IP access settings
#
# DELETE /aaa/team-sec-ip-access/v1
# operationId: IpAccessService_DeleteCompanyIpAccessSettings
export def "aaa-team-sec-ip-access DeleteCompanyIpAccessSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # e.g. d662a2f1-21c3-493c-8f8a-595d3ab05ef3
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aaa/team-sec-ip-access/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all accessible alert definitions
#
# GET /alerts/alerts-general/v3
# operationId: AlertDefsService_ListAlertDefs
export def "alerts-alerts-general ListAlertDefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --query-filter: record
  --pagination: record
  --order-bys: record
]: nothing -> record<alertDefs: table<alertDefProperties: any, alertVersionId: string, createdTime: string, id: string, lastTriggeredTime: string, status: string, updatedTime: string>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query_filter" $query_filter "multi") (serialize-qp "pagination" $pagination "multi") (serialize-qp "order_bys" $order_bys "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/alerts-general/v3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an alert definition
#
# PUT /alerts/alerts-general/v3
# operationId: AlertDefsService_ReplaceAlertDef
export def "alerts-alerts-general ReplaceAlertDef" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertDefProperties: any
  --id: string # Alert definition ID (e.g. 123e4567-e89b-12d3-a456-426614174000)
]: any -> record<alertDef: record<alertDefProperties: any, alertVersionId: string, createdTime: string, id: string, lastTriggeredTime: string, status: string, updatedTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/alerts-general/v3")
  let body = {alertDefProperties: $alertDefProperties, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an alert
#
# POST /alerts/alerts-general/v3
# operationId: AlertDefsService_CreateAlertDef
export def "alerts-alerts-general CreateAlertDef" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertDefProperties: any
]: any -> record<alertDef: record<alertDefProperties: any, alertVersionId: string, createdTime: string, id: string, lastTriggeredTime: string, status: string, updatedTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/alerts-general/v3")
  let body = {alertDefProperties: $alertDefProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get alert definition by alert version ID
#
# GET /alerts/alerts-general/v3/alert-version-id/{alert_version_id}
# operationId: AlertDefsService_GetAlertDefByVersionId
export def "alerts-alerts-general-alert-version-id GetAlertDefByVersionId" [
  alert_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alertDef: record<alertDefProperties: any, alertVersionId: string, createdTime: string, id: string, lastTriggeredTime: string, status: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/alerts-general/v3/alert-version-id/($alert_version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk replace alert definitions
#
# PUT /alerts/alerts-general/v3/bulk
# operationId: AlertDefsService_BulkReplaceAlertDefs
# --alertDefsToReplace item shape: {alertDefProperties?: any, id?: string}
export def "alerts-alerts-general-bulk BulkReplaceAlertDefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertDefsToReplace: list # item shape: {alertDefProperties?: any, id?: string}
]: any -> record<alertDefs: table<alertDefProperties: any, alertVersionId: string, createdTime: string, id: string, lastTriggeredTime: string, status: string, updatedTime: string>, failedToReplaceAlertDefs: table<id: string>, notFoundIds: list<string>, skippedIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/alerts-general/v3/bulk")
  let body = {alertDefsToReplace: $alertDefsToReplace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download alerts
#
# GET /alerts/alerts-general/v3/download
# operationId: AlertDefsService_DownloadAlerts
export def "alerts-alerts-general-download DownloadAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/alerts-general/v3/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get counts for filter options
#
# GET /alerts/alerts-general/v3/filter-option-counts
# operationId: AlertDefsService_FilterOptionCounts
export def "alerts-alerts-general-filter-option-counts FilterOptionCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --query-filter: record
]: nothing -> record<counts: record<enabledCounts: list<record>, entityLabelCounts: list<record>, priorityCounts: list<record>, statusCounts: list<record>, typeCounts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query_filter" $query_filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/alerts-general/v3/filter-option-counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alert definition by ID
#
# GET /alerts/alerts-general/v3/{id}
# operationId: AlertDefsService_GetAlertDef
export def "alerts-alerts-general GetAlertDef" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alertDef: record<alertDefProperties: any, alertVersionId: string, createdTime: string, id: string, lastTriggeredTime: string, status: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/alerts-general/v3/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DeleteAlertDef
#
# DELETE /alerts/alerts-general/v3/{id}
# operationId: AlertDefsService_DeleteAlertDef
export def "alerts-alerts-general DeleteAlertDef" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/alerts-general/v3/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable or enable an alert
#
# POST /alerts/alerts-general/v3/{id}:setActive
# operationId: AlertDefsService_SetActive
export def "alerts-alerts-general SetActive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # e.g. true
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts/alerts-general/v3/($id):setActive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Events
#
# GET /alerts/events/v3
# operationId: EventsService_ListEvents
export def "alerts-events ListEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
  --order-bys: list
  --pagination: record
]: nothing -> record<events: table<companyId: int, cxEventDedupKey: string, cxEventKey: string, cxEventLabels: record, cxEventMetadata: record, cxEventPayload: record, cxEventPayloadType: string, cxEventTimestamp: string, cxEventType: string>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi") (serialize-qp "order_bys" $order_bys "multi") (serialize-qp "pagination" $pagination "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/events/v3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alert Events
#
# GET /alerts/events/v3/alert-events
# operationId: EventsService_ListAlertEvents
export def "alerts-events-alert-events ListAlertEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alert-ids: list # e.g. [32144a8a-7ee0-4c16-a093-2bf1f9c12e1e]
  --timestamp-range: record
  --cx-event-labels: record
  --order-bys: list
  --pagination: record
]: nothing -> record<events: table<companyId: int, cxEventDedupKey: string, cxEventKey: string, cxEventLabels: record, cxEventMetadata: record, cxEventPayload: record, cxEventPayloadType: string, cxEventTimestamp: string, cxEventType: string>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alert_ids" $alert_ids "multi") (serialize-qp "timestamp_range" $timestamp_range "multi") (serialize-qp "cx_event_labels" $cx_event_labels "multi") (serialize-qp "order_bys" $order_bys "multi") (serialize-qp "pagination" $pagination "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/events/v3/alert-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Get Event
#
# GET /alerts/events/v3/batch
# operationId: EventsService_BatchGetEvent
export def "alerts-events-batch BatchGetEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
  --order-bys: list
  --pagination: record
  --filter: record
]: nothing -> record<events: record, notFoundIds: list<string>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "order_bys" $order_bys "multi") (serialize-qp "pagination" $pagination "multi") (serialize-qp "filter" $filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/events/v3/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Events Count
#
# GET /alerts/events/v3/count
# operationId: EventsService_ListEventsCount
export def "alerts-events-count ListEventsCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
]: nothing -> record<count: string, reachedLimit: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/events/v3/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Events Statistics
#
# GET /alerts/events/v3/statistics
# operationId: EventsService_GetEventsStatistics
export def "alerts-events-statistics GetEventsStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
]: nothing -> record<cxEventLabelsFieldStatistics: record, cxEventMetadataFieldStatistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/events/v3/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Event
#
# GET /alerts/events/v3/{id}
# operationId: EventsService_GetEvent
export def "alerts-events GetEvent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-bys: list
  --pagination: record
]: nothing -> record<event: any, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_bys" $order_bys "multi") (serialize-qp "pagination" $pagination "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts/events/v3/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Service SLOs
#
# GET /apm/apm-slo/v1
# operationId: ServiceSloService_ListServiceSlos
export def "apm-apm-slo ListServiceSlos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-by: record
  --service-names: list
]: nothing -> record<slos: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "multi") (serialize-qp "service_names" $service_names "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/apm/apm-slo/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace Service SLO
#
# PUT /apm/apm-slo/v1
# operationId: ServiceSloService_ReplaceServiceSlo
export def "apm-apm-slo ReplaceServiceSlo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slo: any
]: any -> record<slo: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apm/apm-slo/v1")
  let body = {slo: $slo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Service SLO
#
# POST /apm/apm-slo/v1
# operationId: ServiceSloService_CreateServiceSlo
export def "apm-apm-slo CreateServiceSlo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slo: any
]: any -> record<slo: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apm/apm-slo/v1")
  let body = {slo: $slo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch Get Service SLOs
#
# GET /apm/apm-slo/v1/batch
# operationId: ServiceSloService_BatchGetServiceSlos
export def "apm-apm-slo-batch BatchGetServiceSlos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # e.g. [slo_id1, slo_id2]
]: nothing -> record<notFoundIds: list<string>, slos: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/apm/apm-slo/v1/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Service SLO
#
# GET /apm/apm-slo/v1/{id}
# operationId: ServiceSloService_GetServiceSlo
export def "apm-apm-slo GetServiceSlo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<slo: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apm/apm-slo/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Service SLO
#
# DELETE /apm/apm-slo/v1/{id}
# operationId: ServiceSloService_DeleteServiceSlo
export def "apm-apm-slo DeleteServiceSlo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apm/apm-slo/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team configuration
#
# POST /cases/cases/team-configs/v1/configs
# operationId: TeamConfigService_CreateTeamConfig
# --settings shape: {manualResolutionSnoozePeriod?: string, suppressionPeriod?: string}
export def "cases-cases-team-configs-configs CreateTeamConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Optional display name for the team configuration (e.g. Primary Team Config)
  settings: record # Team-level configuration options for case management, including suppression and snooze periods. — shape: {manualResolutionSnoozePeriod?: string, suppressionPeriod?: string}
]: any -> record<teamConfig: record<createTime: string, id: string, name: string, settings: record<manualResolutionSnoozePeriod: string, suppressionPeriod: string>, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cases/cases/team-configs/v1/configs")
  let body = {name: $name, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the active team configuration
#
# GET /cases/cases/team-configs/v1/configs/active
# operationId: TeamConfigService_GetActiveTeamConfig
export def "cases-cases-team-configs-configs-active GetActiveTeamConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<teamConfig: record<createTime: string, id: string, name: string, settings: record<manualResolutionSnoozePeriod: string, suppressionPeriod: string>, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cases/cases/team-configs/v1/configs/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get system default team configuration settings
#
# GET /cases/cases/team-configs/v1/configs/system-defaults
# operationId: TeamConfigService_GetSystemDefaults
export def "cases-cases-team-configs-configs-system-defaults GetSystemDefaults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<manualResolutionSnoozePeriod: string, suppressionPeriod: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cases/cases/team-configs/v1/configs/system-defaults")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a team configuration
#
# GET /cases/cases/team-configs/v1/configs/{id}
# operationId: TeamConfigService_GetTeamConfig
export def "cases-cases-team-configs-configs GetTeamConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<teamConfig: record<createTime: string, id: string, name: string, settings: record<manualResolutionSnoozePeriod: string, suppressionPeriod: string>, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/team-configs/v1/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a team configuration
#
# DELETE /cases/cases/team-configs/v1/configs/{id}
# operationId: TeamConfigService_DeleteTeamConfig
export def "cases-cases-team-configs-configs DeleteTeamConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/team-configs/v1/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team configuration
#
# PATCH /cases/cases/team-configs/v1/configs/{id}
# operationId: TeamConfigService_UpdateTeamConfig
# --settings shape: {manualResolutionSnoozePeriod?: string, suppressionPeriod?: string}
export def "cases-cases-team-configs-configs UpdateTeamConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New display name for the team configuration (e.g. SRE Team Config)
  --settings: record # Team-level configuration options for case management, including suppression and snooze periods. — shape: {manualResolutionSnoozePeriod?: string, suppressionPeriod?: string}
]: any -> record<teamConfig: record<createTime: string, id: string, name: string, settings: record<manualResolutionSnoozePeriod: string, suppressionPeriod: string>, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/team-configs/v1/configs/($id)")
  let body = {name: $name, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List cases with filters
#
# POST /cases/cases/v1
# operationId: CasesService_ListCases
# --filters shape: {assignees?: list, categories?: list, dateRange?: record, groupings?: list, labels?: list, priorities?: list, states?: list, statuses?: list, textSearch?: string}
# --orderBy shape: {direction?: "CASE_ORDER_BY_DIRECTION_UNSPECIFIED"|"CASE_ORDER_BY_DIRECTION_ASCENDING"|"CASE_ORDER_BY_DIRECTION_DESCENDING", field?: "CASE_ORDER_BY_FIELD_UNSPECIFIED"|"CASE_ORDER_BY_FIELD_PRIORITY"|"CASE_ORDER_BY_FIELD_STATUS"|"CASE_ORDER_BY_FIELD_STATE"|"CASE_ORDER_BY_FIELD_UPDATED_AT"|"CASE_ORDER_BY_FIELD_CATEGORY"}
# --pagination shape: {pageSize?: int, pageToken?: string, skip?: int}
export def "cases-cases ListCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: record # Filters applied when querying cases, including states, priorities, categories, groupings, and labels. — shape: {assignees?: list, categories?: list, dateRange?: record, groupings?: list, labels?: list, priorities?: list, states?: list, statuses?: list, textSearch?: string}
  --orderBy: record # Defines how cases should be sorted in the response. By default, cases are sorted by creation time and id in descending order. With this field, one can specify the primary sorting field and direction. — shape: {direction?: "CASE_ORDER_BY_DIRECTION_UNSPECIFIED"|"CASE_ORDER_BY_DIRECTION_ASCENDING"|"CASE_ORDER_BY_DIRECTION_DESCENDING", field?: "CASE_ORDER_BY_FIELD_UNSPECIFIED"|"CASE_ORDER_BY_FIELD_PRIORITY"|"CASE_ORDER_BY_FIELD_STATUS"|"CASE_ORDER_BY_FIELD_STATE"|"CASE_ORDER_BY_FIELD_UPDATED_AT"|"CASE_ORDER_BY_FIELD_CATEGORY"}
  --pagination: record # Pagination parameters for list requests. — shape: {pageSize?: int, pageToken?: string, skip?: int}
]: any -> record<cases: table<acknowledgeTime: string, alertIndicators: list, assignee: record, category: string, createTime: string, description: string, groupings: list, id: string, labels: list, priority: string, priorityDetails: record, readableId: string, resolutionDetails: record, state: string, status: string, title: string, updateTime: string>, pagination: record<nextPageToken: string, totalSize: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cases/cases/v1")
  let body = {filters: $filters, orderBy: $orderBy, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a comment event
#
# POST /cases/cases/v1/events/comment/{case_id}
# operationId: CaseEventsService_CreateComment
export def "cases-cases-events-comment CreateComment" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # Comment text to update (e.g. This is updated text)
]: any -> record<event: record<actor: any, createTime: string, eventData: any, eventId: string, eventTime: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/events/comment/($case_id)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment event
#
# DELETE /cases/cases/v1/events/comment/{event_id}
# operationId: CaseEventsService_DeleteComment
export def "cases-cases-events-comment DeleteComment" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/events/comment/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a comment event
#
# PATCH /cases/cases/v1/events/comment/{event_id}
# operationId: CaseEventsService_UpdateComment
export def "cases-cases-events-comment UpdateComment" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # Comment text to update (e.g. This is updated text)
]: any -> record<event: record<actor: any, createTime: string, eventData: any, eventId: string, eventTime: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/events/comment/($event_id)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List events for a case
#
# GET /cases/cases/v1/events/{case_id}
# operationId: CaseEventsService_ListEvents
export def "cases-cases-events ListEvents" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<events: table<actor: any, createTime: string, eventData: any, eventId: string, eventTime: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/events/($case_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an event by ID
#
# GET /cases/cases/v1/events/{event_id}
# operationId: CaseEventsService_GetEvent
export def "cases-cases-events GetEvent" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<event: record<actor: any, createTime: string, eventData: any, eventId: string, eventTime: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get case by ID
#
# GET /cases/cases/v1/{id}
# operationId: CasesService_GetCase
export def "cases-cases GetCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update case fields
#
# PATCH /cases/cases/v1/{id}
# operationId: CasesService_UpdateCase
export def "cases-cases UpdateCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # New case description (e.g. Investigate intermittent connection drops)
  --title: string # New case title (e.g. Database connection investigation)
]: any -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id)")
  let body = {description: $description, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Acknowledge a case
#
# POST /cases/cases/v1/{id}:acknowledge
# operationId: CasesService_AcknowledgeCase
# --actor shape: {userId?: string}
export def "cases-cases AcknowledgeCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actor: record # Minimal user identity information used in case assignments. — shape: {userId?: string}
]: any -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id):acknowledge")
  let body = {actor: $actor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a case to a user
#
# POST /cases/cases/v1/{id}:assign
# operationId: CasesService_AssignCase
# --assignee shape: {userId?: string}
export def "cases-cases AssignCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  assignee: record # Minimal user identity information used in case assignments. — shape: {userId?: string}
]: any -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id):assign")
  let body = {assignee: $assignee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Close a case
#
# POST /cases/cases/v1/{id}:close
# operationId: CasesService_CloseCase
export def "cases-cases CloseCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # e.g. This case is not applicable.
]: nothing -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cases/cases/v1/($id):close" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a case
#
# POST /cases/cases/v1/{id}:resolve
# operationId: CasesService_ResolveCase
export def "cases-cases ResolveCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # e.g. This case is not applicable.
]: nothing -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cases/cases/v1/($id):resolve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set priority override
#
# POST /cases/cases/v1/{id}:setPriorityOverride
# operationId: CasesService_SetPriorityOverride
export def "cases-cases SetPriorityOverride" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  priority: string@priority-completer
]: any -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id):setPriorityOverride")
  let body = {priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove case assignment
#
# POST /cases/cases/v1/{id}:unassign
# operationId: CasesService_UnassignCase
export def "cases-cases UnassignCase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id):unassign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove priority override
#
# POST /cases/cases/v1/{id}:unsetPriorityOverride
# operationId: CasesService_UnsetPriorityOverride
export def "cases-cases UnsetPriorityOverride" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<case: record<acknowledgeTime: string, alertIndicators: list<record>, assignee: record<userId: string>, category: string, createTime: string, description: string, groupings: list<record>, id: string, labels: list<record>, priority: string, priorityDetails: record<override: string, system: string>, readableId: string, resolutionDetails: record<resolveTime: string, resolvedBy: string>, state: string, status: string, title: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cases/cases/v1/($id):unsetPriorityOverride")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available filter values
#
# POST /cases/cases/v1:get-filter-values
# operationId: CasesService_GetFilterValues
# --filters shape: {assignees?: list, categories?: list, dateRange?: record, groupings?: list, labels?: list, priorities?: list, states?: list, statuses?: list, textSearch?: string}
export def "cases-cases-v1-get-filter-values GetFilterValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: record # Filters applied when querying cases, including states, priorities, categories, groupings, and labels. — shape: {assignees?: list, categories?: list, dateRange?: record, groupings?: list, labels?: list, priorities?: list, states?: list, statuses?: list, textSearch?: string}
]: any -> record<assigneeAggregations: record<assignedCounts: list<record>, unassignedCount: int>, categoryAggregations: table<category: string, count: int>, groupingAggregations: table<key: string, valueCounts: list>, labelAggregations: table<key: string, valueCounts: list>, priorityAggregations: table<count: int, priority: string>, stateAggregations: table<count: int, state: string>, statusAggregations: table<count: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cases/cases/v1:get-filter-values")
  let body = {filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get dashboard catalog
#
# GET /dashboards/dashboards/v1/catalog
# operationId: DashboardCatalogService_GetDashboardCatalog
export def "dashboards-dashboards-catalog GetDashboardCatalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<authorId: string, createTime: string, description: string, folder: record, id: string, isDefault: bool, isLocked: bool, isPinned: bool, lockerAuthorId: string, name: string, slugName: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards/dashboards/v1/catalog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List dashboard folders
#
# GET /dashboards/dashboards/v1/folders
# operationId: DashboardFoldersService_ListDashboardFolders
export def "dashboards-dashboards-folders ListDashboardFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<folder: table<id: string, name: string, parentId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards/dashboards/v1/folders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace a dashboard folder
#
# PUT /dashboards/dashboards/v1/folders
# operationId: DashboardFoldersService_ReplaceDashboardFolder
# --folder shape: {id?: string, name?: string, parentId?: string}
export def "dashboards-dashboards-folders ReplaceDashboardFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folder: record # shape: {id?: string, name?: string, parentId?: string}
  --requestId: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards/dashboards/v1/folders")
  let body = {folder: $folder, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a dashboard folder
#
# POST /dashboards/dashboards/v1/folders
# operationId: DashboardFoldersService_CreateDashboardFolder
# --folder shape: {id?: string, name?: string, parentId?: string}
export def "dashboards-dashboards-folders CreateDashboardFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folder: record # shape: {id?: string, name?: string, parentId?: string}
  --requestId: string
]: any -> record<folderId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards/dashboards/v1/folders")
  let body = {folder: $folder, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a dashboard folder
#
# GET /dashboards/dashboards/v1/folders/{folder_id}
# operationId: DashboardFoldersService_GetDashboardFolder
export def "dashboards-dashboards-folders GetDashboardFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-id: string
]: nothing -> record<folder: record<id: string, name: string, parentId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request_id" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dashboards/dashboards/v1/folders/($folder_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a dashboard folder
#
# DELETE /dashboards/dashboards/v1/folders/{folder_id}
# operationId: DashboardFoldersService_DeleteDashboardFolder
export def "dashboards-dashboards-folders DeleteDashboardFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-id: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request_id" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dashboards/dashboards/v1/folders/($folder_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List views service
#
# GET /data-exploration/saved-views/v1
# operationId: ViewsService_ListViews
export def "data-exploration-saved-views ListViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<views: table<filters: record, folderId: string, id: int, isCompactMode: bool, name: string, searchQuery: record, timeSelection: any, viewType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-exploration/saved-views/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a view service
#
# POST /data-exploration/saved-views/v1
# operationId: ViewsService_CreateView
# --filters shape: {filters?: list}
# --searchQuery shape: {query: string, syntaxType?: "SYNTAX_TYPE_UNSPECIFIED"|"SYNTAX_TYPE_LUCENE"|"SYNTAX_TYPE_DATAPRIME"}
export def "data-exploration-saved-views CreateView" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: record # shape: {filters?: list}
  --folderId: string # Unique identifier for folders (e.g. 3dc02998-0b50-4ea8-b68a-4779d716fa1f)
  name: string # View name (e.g. Logs view)
  --searchQuery: record # shape: {query: string, syntaxType?: "SYNTAX_TYPE_UNSPECIFIED"|"SYNTAX_TYPE_LUCENE"|"SYNTAX_TYPE_DATAPRIME"}
  timeSelection: any
  --viewType: string@viewType-completer
]: any -> record<filters: record<filters: list<record>>, folderId: string, id: int, isCompactMode: bool, name: string, searchQuery: record<query: string, syntaxType: string>, timeSelection: any, viewType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-exploration/saved-views/v1")
  let body = {filters: $filters, folderId: $folderId, name: $name, searchQuery: $searchQuery, timeSelection: $timeSelection, viewType: $viewType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List view folders service
#
# GET /data-exploration/saved-views/v1/folders
# operationId: ViewsFoldersService_ListViewFolders
export def "data-exploration-saved-views-folders ListViewFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<folders: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-exploration/saved-views/v1/folders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace View Folder service
#
# PUT /data-exploration/saved-views/v1/folders
# operationId: ViewsFoldersService_ReplaceViewFolder
export def "data-exploration-saved-views-folders ReplaceViewFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Unique identifier for folders (e.g. 3dc02998-0b50-4ea8-b68a-4779d716fa1f)
  name: string # Folder name (e.g. My Folder)
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-exploration/saved-views/v1/folders")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create View Folder service
#
# POST /data-exploration/saved-views/v1/folders
# operationId: ViewsFoldersService_CreateViewFolder
export def "data-exploration-saved-views-folders CreateViewFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Folder name (e.g. My Folder)
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-exploration/saved-views/v1/folders")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get View Folder service
#
# GET /data-exploration/saved-views/v1/folders/{id}
# operationId: ViewsFoldersService_GetViewFolder
export def "data-exploration-saved-views-folders GetViewFolder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-exploration/saved-views/v1/folders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete View Folder service
#
# DELETE /data-exploration/saved-views/v1/folders/{id}
# operationId: ViewsFoldersService_DeleteViewFolder
export def "data-exploration-saved-views-folders DeleteViewFolder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-exploration/saved-views/v1/folders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get view service
#
# GET /data-exploration/saved-views/v1/{id}
# operationId: ViewsService_GetView
export def "data-exploration-saved-views GetView" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<filters: record<filters: list<record>>, folderId: string, id: int, isCompactMode: bool, name: string, searchQuery: record<query: string, syntaxType: string>, timeSelection: any, viewType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-exploration/saved-views/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace a view service
#
# PUT /data-exploration/saved-views/v1/{id}
# operationId: ViewsService_ReplaceView
# --filters shape: {filters?: list}
# --searchQuery shape: {query: string, syntaxType?: "SYNTAX_TYPE_UNSPECIFIED"|"SYNTAX_TYPE_LUCENE"|"SYNTAX_TYPE_DATAPRIME"}
export def "data-exploration-saved-views ReplaceView" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: record # shape: {filters?: list}
  --folderId: string # Unique identifier for folders (e.g. 3dc02998-0b50-4ea8-b68a-4779d716fa1f)
  --isCompactMode: oneof<nothing, bool>
  name: string # View name (e.g. Logs view)
  --searchQuery: record # shape: {query: string, syntaxType?: "SYNTAX_TYPE_UNSPECIFIED"|"SYNTAX_TYPE_LUCENE"|"SYNTAX_TYPE_DATAPRIME"}
  timeSelection: any
  --viewType: string@viewType-completer
]: any -> record<filters: record<filters: list<record>>, folderId: string, id: int, isCompactMode: bool, name: string, searchQuery: record<query: string, syntaxType: string>, timeSelection: any, viewType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-exploration/saved-views/v1/($id)")
  let body = {filters: $filters, folderId: $folderId, isCompactMode: $isCompactMode, name: $name, searchQuery: $searchQuery, timeSelection: $timeSelection, viewType: $viewType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete view service
#
# DELETE /data-exploration/saved-views/v1/{id}
# operationId: ViewsService_DeleteView
export def "data-exploration-saved-views DeleteView" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-exploration/saved-views/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Retentions
#
# GET /dataengine/retention-tags/v1
# operationId: RetentionsService_GetRetentions
export def "dataengine-retention-tags GetRetentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<retentions: table<editable: bool, id: string, name: string, order: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataengine/retention-tags/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Retentions
#
# POST /dataengine/retention-tags/v1
# operationId: RetentionsService_UpdateRetentions
# --retentionUpdateElements item shape: {id?: string, name?: string}
export def "dataengine-retention-tags UpdateRetentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  retentionUpdateElements: list # item shape: {id?: string, name?: string}
]: any -> record<retentions: table<editable: bool, id: string, name: string, order: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataengine/retention-tags/v1")
  let body = {retentionUpdateElements: $retentionUpdateElements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate Retentions
#
# POST /dataengine/retention-tags/v1/activate
# operationId: RetentionsService_ActivateRetentions
export def "dataengine-retention-tags-activate ActivateRetentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activateRetentions: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataengine/retention-tags/v1/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Retentions Enabled
#
# GET /dataengine/retention-tags/v1/enabled
# operationId: RetentionsService_GetRetentionsEnabled
export def "dataengine-retention-tags-enabled GetRetentionsEnabled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enableTags: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataengine/retention-tags/v1/enabled")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Data Usage
#
# GET /dataplans/data-usage/v2
# operationId: DataUsageService_GetDataUsage
export def "dataplans-data-usage GetDataUsage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-range: record
  --resolution: string
  --aggregate: list
  --dimension-filters: list
]: nothing -> record<entries: table<dimensions: list, sizeGb: float, timestamp: string, units: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "multi") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "aggregate" $aggregate "multi") (serialize-qp "dimension_filters" $dimension_filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/dataplans/data-usage/v2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Daily Usage Evaluation Tokens
#
# POST /dataplans/data-usage/v2/daily:evaluation-tokens
# operationId: DataUsageService_GetDailyUsageEvaluationTokens
# --dateRange shape: {fromDate?: string, toDate?: string}
export def "dataplans-data-usage-daily-evaluation-tokens GetDailyUsageEvaluationTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --range: string@range-completer
  --dateRange: record # This data structure represents a date range. — shape: {fromDate?: string, toDate?: string}
]: any -> record<tokens: table<evaluations: list, statsDate: string, totalTokens: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/data-usage/v2/daily:evaluation-tokens")
  let body = {range: $range, dateRange: $dateRange} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Daily Usage Processed GBs
#
# POST /dataplans/data-usage/v2/daily:processed-gbs
# operationId: DataUsageService_GetDailyUsageProcessedGbs
# --dateRange shape: {fromDate?: string, toDate?: string}
export def "dataplans-data-usage-daily-processed-gbs GetDailyUsageProcessedGbs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateRange: record # This data structure represents a date range. — shape: {fromDate?: string, toDate?: string}
  --range: string@range-completer
]: any -> record<gbs: table<blockedGbs: record, blockedMetricsGbs: record, cpuProfilesGbs: record, highLogsGbs: record, highMetricsGbs: record, highTracingGbs: record, lowLogsGbs: record, lowSessionRecordingGbs: record, lowTracingGbs: record, mediumLogsGbs: record, mediumTracingGbs: record, statsDate: string, totalGbs: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/data-usage/v2/daily:processed-gbs")
  let body = {dateRange: $dateRange, range: $range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Daily Usage Units
#
# POST /dataplans/data-usage/v2/daily:units
# operationId: DataUsageService_GetDailyUsageUnits
# --dateRange shape: {fromDate?: string, toDate?: string}
export def "dataplans-data-usage-daily-units GetDailyUsageUnits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --range: string@range-completer
  --dateRange: record # This data structure represents a date range. — shape: {fromDate?: string, toDate?: string}
]: any -> record<units: table<blockedMetricsUnits: record, blockedUnits: record, cpuProfilesUnits: record, evaluationUnits: record, highLogsUnits: record, highMetricsUnits: record, highTracingUnits: record, lowLogsUnits: record, lowSessionRecordingUnits: record, lowTracingUnits: record, mediumLogsUnits: record, mediumTracingUnits: record, statsDate: string, totalUnits: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/data-usage/v2/daily:units")
  let body = {range: $range, dateRange: $dateRange} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Data Usage Metrics Export Status
#
# GET /dataplans/data-usage/v2/export-status
# operationId: DataUsageService_GetDataUsageMetricsExportStatus
export def "dataplans-data-usage-export-status GetDataUsageMetricsExportStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/data-usage/v2/export-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Data Usage Metrics Export Status
#
# POST /dataplans/data-usage/v2/export-status
# operationId: DataUsageService_UpdateDataUsageMetricsExportStatus
export def "dataplans-data-usage-export-status UpdateDataUsageMetricsExportStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # e.g. true
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/data-usage/v2/export-status")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Logs Count
#
# GET /dataplans/data-usage/v2/logs:count
# operationId: DataUsageService_GetLogsCount
export def "dataplans-data-usage-logs-count GetLogsCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-range: record
  --resolution: string
  --filters: record
  --subsystem-aggregation: oneof<nothing, bool>
  --application-aggregation: oneof<nothing, bool>
]: nothing -> record<logsCount: table<applicationName: string, logsCount: string, priority: string, severity: string, subsystemName: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "multi") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "subsystem_aggregation" $subsystem_aggregation "scalar") (serialize-qp "application_aggregation" $application_aggregation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataplans/data-usage/v2/logs:count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Spans Count
#
# GET /dataplans/data-usage/v2/spans:count
# operationId: DataUsageService_GetSpansCount
export def "dataplans-data-usage-spans-count GetSpansCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-range: record
  --resolution: string
  --filters: record
]: nothing -> record<spansCount: table<errorSpanCount: string, lowErrorSpanCount: string, lowSuccessSpanCount: string, mediumErrorSpanCount: string, mediumSuccessSpanCount: string, successSpanCount: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "multi") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/dataplans/data-usage/v2/spans:count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Policies
#
# GET /dataplans/policies/v1
# operationId: PoliciesService_GetCompanyPolicies
export def "dataplans-policies GetCompanyPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled-only: oneof<nothing, bool> # e.g. true
  --source-type: string@source-type-completer
]: nothing -> record<policies: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled_only" $enabled_only "scalar") (serialize-qp "source_type" $source_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataplans/policies/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Policy
#
# PUT /dataplans/policies/v1
# operationId: PoliciesService_UpdatePolicy
# --applicationRule shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
# --archiveRetention shape: {id?: string}
# --logRules shape: {severities: list}
# --subsystemRule shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
# --spanRules shape: {actionRule?: record, serviceRule?: record, tagRules?: list}
export def "dataplans-policies UpdatePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationRule: record # shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
  --archiveRetention: record # shape: {id?: string}
  --description: string # e.g. My Policy Description
  --enabled: oneof<nothing, bool> # e.g. true
  --id: string # e.g. policy_id
  --logRules: record # Log rules for a policy. — shape: {severities: list}
  --name: string # e.g. My Policy
  --priority: string@priority-completer-1
  --subsystemRule: record # shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
  --spanRules: record # shape: {actionRule?: record, serviceRule?: record, tagRules?: list}
]: any -> record<policy: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1")
  let body = {applicationRule: $applicationRule, archiveRetention: $archiveRetention, description: $description, enabled: $enabled, id: $id, logRules: $logRules, name: $name, priority: $priority, subsystemRule: $subsystemRule, spanRules: $spanRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Policy
#
# POST /dataplans/policies/v1
# operationId: PoliciesService_CreatePolicy
# --applicationRule shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
# --archiveRetention shape: {id?: string}
# --spanRules shape: {actionRule?: record, serviceRule?: record, tagRules?: list}
# --subsystemRule shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
# --logRules shape: {severities: list}
export def "dataplans-policies CreatePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationRule: record # shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
  --archiveRetention: record # shape: {id?: string}
  --description: string # e.g. My Policy Description
  --disabled: oneof<nothing, bool>
  --name: string # e.g. My Policy
  --placement: any
  --priority: string@priority-completer-1
  --spanRules: record # shape: {actionRule?: record, serviceRule?: record, tagRules?: list}
  --subsystemRule: record # shape: {name?: string, ruleTypeId?: "RULE_TYPE_ID_UNSPECIFIED"|"RULE_TYPE_ID_IS"|"RULE_TYPE_ID_IS_NOT"|"RULE_TYPE_ID_START_WITH"|"RULE_TYPE_ID_INCLUDES"}
  --logRules: record # Log rules for a policy. — shape: {severities: list}
]: any -> record<policy: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1")
  let body = {applicationRule: $applicationRule, archiveRetention: $archiveRetention, description: $description, disabled: $disabled, name: $name, placement: $placement, priority: $priority, spanRules: $spanRules, subsystemRule: $subsystemRule, logRules: $logRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Atomic Overwrite Log Policies
#
# POST /dataplans/policies/v1/atomicOverwriteLogPolicies
# operationId: PoliciesService_AtomicOverwriteLogPolicies
# --policies item shape: {logRules: record, policy: record}
export def "dataplans-policies-atomic-overwrite-log-policies AtomicOverwriteLogPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  policies: list # item shape: {logRules: record, policy: record}
]: any -> record<createResponses: table<policy: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/atomicOverwriteLogPolicies")
  let body = {policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Atomic Overwrite Span Policies
#
# POST /dataplans/policies/v1/atomicOverwriteSpanPolicies
# operationId: PoliciesService_AtomicOverwriteSpanPolicies
# --policies item shape: {policy: record, spanRules: record}
export def "dataplans-policies-atomic-overwrite-span-policies AtomicOverwriteSpanPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  policies: list # item shape: {policy: record, spanRules: record}
]: any -> record<createResponses: table<policy: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/atomicOverwriteSpanPolicies")
  let body = {policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Atomic Batch Create Policy
#
# POST /dataplans/policies/v1/bulkCreate
# operationId: PoliciesService_AtomicBatchCreatePolicy
export def "dataplans-policies-bulk-create AtomicBatchCreatePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  policyRequests: list
]: any -> record<createResponses: table<policy: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/bulkCreate")
  let body = {policyRequests: $policyRequests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Test Log Policies
#
# POST /dataplans/policies/v1/bulkTestLog
# operationId: PoliciesService_BulkTestLogPolicies
# --metaFieldsValuesList item shape: {applicationNameValues: string, severityValues: string, subsystemNameValues: string}
export def "dataplans-policies-bulk-test-log BulkTestLogPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metaFieldsValuesList: list # item shape: {applicationNameValues: string, severityValues: string, subsystemNameValues: string}
]: any -> record<testPoliciesBulkResult: table<matched: bool, metaFieldsValues: record, policy: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/bulkTestLog")
  let body = {metaFieldsValuesList: $metaFieldsValuesList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Policy Priority Settings
#
# GET /dataplans/policies/v1/getPolicyPrioritySettings
# operationId: PoliciesService_GetPolicySettings
export def "dataplans-policies-get-policy-priority-settings GetPolicySettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logsPolicySettings: record<defaultPriority: string>, spansPolicySettings: record<defaultPriority: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/getPolicyPrioritySettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Policies
#
# POST /dataplans/policies/v1/reorder
# operationId: PoliciesService_ReorderPolicies
# --orders item shape: {id: string, order: int}
export def "dataplans-policies-reorder ReorderPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  orders: list # item shape: {id: string, order: int}
  sourceType: string@sourceType-completer
]: any -> record<orders: table<id: string, order: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/reorder")
  let body = {orders: $orders, sourceType: $sourceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace Policy Settings
#
# POST /dataplans/policies/v1/replacePolicySettings
# operationId: PoliciesService_ReplacePolicySettings
# --logsPolicySettings shape: {defaultPriority?: "PRIORITY_TYPE_UNSPECIFIED"|"PRIORITY_TYPE_BLOCK"|"PRIORITY_TYPE_LOW"|"PRIORITY_TYPE_MEDIUM"|"PRIORITY_TYPE_HIGH"}
# --spansPolicySettings shape: {defaultPriority?: "PRIORITY_TYPE_UNSPECIFIED"|"PRIORITY_TYPE_BLOCK"|"PRIORITY_TYPE_LOW"|"PRIORITY_TYPE_MEDIUM"|"PRIORITY_TYPE_HIGH"}
export def "dataplans-policies-replace-policy-settings ReplacePolicySettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logsPolicySettings: record # shape: {defaultPriority?: "PRIORITY_TYPE_UNSPECIFIED"|"PRIORITY_TYPE_BLOCK"|"PRIORITY_TYPE_LOW"|"PRIORITY_TYPE_MEDIUM"|"PRIORITY_TYPE_HIGH"}
  --spansPolicySettings: record # shape: {defaultPriority?: "PRIORITY_TYPE_UNSPECIFIED"|"PRIORITY_TYPE_BLOCK"|"PRIORITY_TYPE_LOW"|"PRIORITY_TYPE_MEDIUM"|"PRIORITY_TYPE_HIGH"}
]: any -> record<logsPolicySettings: record<defaultPriority: string>, spansPolicySettings: record<defaultPriority: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/replacePolicySettings")
  let body = {logsPolicySettings: $logsPolicySettings, spansPolicySettings: $spansPolicySettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toggle Policies
#
# POST /dataplans/policies/v1/toggle
# operationId: PoliciesService_TogglePolicy
export def "dataplans-policies-toggle TogglePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # e.g. true
  id: string # e.g. id
]: any -> record<enabled: bool, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataplans/policies/v1/toggle")
  let body = {enabled: $enabled, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Policy by ID
#
# GET /dataplans/policies/v1/{id}
# operationId: PoliciesService_GetPolicy
export def "dataplans-policies GetPolicy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<policy: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataplans/policies/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Policy
#
# DELETE /dataplans/policies/v1/{id}
# operationId: PoliciesService_DeletePolicy
export def "dataplans-policies DeletePolicy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataplans/policies/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Enrichments
#
# GET /enrichment-rules/custom-enrichment-rules/v1
# operationId: CustomEnrichmentService_GetCustomEnrichments
export def "enrichment-rules-custom-enrichment-rules GetCustomEnrichments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customEnrichments: table<description: string, fileName: string, fileSize: int, id: int, isQueryOnly: bool, name: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/custom-enrichment-rules/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Enrichment
#
# PUT /enrichment-rules/custom-enrichment-rules/v1
# operationId: CustomEnrichmentService_UpdateCustomEnrichment
export def "enrichment-rules-custom-enrichment-rules UpdateCustomEnrichment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customEnrichmentId: int # format: int64, e.g. 1
  description: string # e.g. custom_enrichment_description
  file: any
  name: string # e.g. custom_enrichment_name
]: any -> record<customEnrichment: record<description: string, fileName: string, fileSize: int, id: int, isQueryOnly: bool, name: string, version: int>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/custom-enrichment-rules/v1")
  let body = {customEnrichmentId: $customEnrichmentId, description: $description, file: $file, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Custom Enrichments
#
# POST /enrichment-rules/custom-enrichment-rules/v1
# operationId: CustomEnrichmentService_CreateCustomEnrichment
export def "enrichment-rules-custom-enrichment-rules CreateCustomEnrichment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # e.g. custom_enrichment_description
  file: any
  name: string # e.g. custom_enrichment_name
]: any -> record<customEnrichment: record<description: string, fileName: string, fileSize: int, id: int, isQueryOnly: bool, name: string, version: int>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/custom-enrichment-rules/v1")
  let body = {description: $description, file: $file, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Custom Enrichment Data
#
# POST /enrichment-rules/custom-enrichment-rules/v1/all/contents
# operationId: CustomEnrichmentService_SearchCustomEnrichmentData
export def "enrichment-rules-custom-enrichment-rules-all-contents SearchCustomEnrichmentData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search-clauses: list
]: nothing -> record<customEnrichmentsData: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_clauses" $search_clauses "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/enrichment-rules/custom-enrichment-rules/v1/all/contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Custom Enrichments
#
# DELETE /enrichment-rules/custom-enrichment-rules/v1/{custom_enrichment_id}
# operationId: CustomEnrichmentService_DeleteCustomEnrichment
export def "enrichment-rules-custom-enrichment-rules DeleteCustomEnrichment" [
  custom_enrichment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customEnrichmentId: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enrichment-rules/custom-enrichment-rules/v1/($custom_enrichment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Enrichment
#
# GET /enrichment-rules/custom-enrichment-rules/v1/{id}
# operationId: CustomEnrichmentService_GetCustomEnrichment
export def "enrichment-rules-custom-enrichment-rules GetCustomEnrichment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customEnrichment: record<description: string, fileName: string, fileSize: int, id: int, isQueryOnly: bool, name: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/enrichment-rules/custom-enrichment-rules/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Enrichments
#
# GET /enrichment-rules/enrichment-rules/v1
# operationId: EnrichmentService_GetEnrichments
export def "enrichment-rules-enrichment-rules GetEnrichments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enrichments: table<enrichedFieldName: string, enrichmentType: any, fieldName: string, id: int, selectedColumns: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/enrichment-rules/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Atomic Overwrite Enrichments
#
# PUT /enrichment-rules/enrichment-rules/v1
# operationId: EnrichmentService_AtomicOverwriteEnrichments
# --enrichmentFields item shape: {enrichedFieldName?: string, fieldName?: string, selectedColumns?: list}
# --requestEnrichments item shape: {enrichedFieldName?: string, enrichmentType: any, fieldName: string, selectedColumns?: list}
export def "enrichment-rules-enrichment-rules AtomicOverwriteEnrichments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enrichmentFields: list # item shape: {enrichedFieldName?: string, fieldName?: string, selectedColumns?: list}
  --enrichmentType: any
  --requestEnrichments: list # item shape: {enrichedFieldName?: string, enrichmentType: any, fieldName: string, selectedColumns?: list}
]: any -> record<enrichments: table<enrichedFieldName: string, enrichmentType: any, fieldName: string, id: int, selectedColumns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/enrichment-rules/v1")
  let body = {enrichmentFields: $enrichmentFields, enrichmentType: $enrichmentType, requestEnrichments: $requestEnrichments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Enrichments
#
# POST /enrichment-rules/enrichment-rules/v1
# operationId: EnrichmentService_AddEnrichments
# --requestEnrichments item shape: {enrichedFieldName?: string, enrichmentType: any, fieldName: string, selectedColumns?: list}
export def "enrichment-rules-enrichment-rules AddEnrichments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requestEnrichments: list # item shape: {enrichedFieldName?: string, enrichmentType: any, fieldName: string, selectedColumns?: list}
]: any -> record<enrichments: table<enrichedFieldName: string, enrichmentType: any, fieldName: string, id: int, selectedColumns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/enrichment-rules/v1")
  let body = {requestEnrichments: $requestEnrichments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Enrichments
#
# DELETE /enrichment-rules/enrichment-rules/v1
# operationId: EnrichmentService_RemoveEnrichments
export def "enrichment-rules-enrichment-rules RemoveEnrichments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enrichment-ids: list # e.g. [1, 2, 3]
]: nothing -> record<remainingEnrichments: table<enrichedFieldName: string, enrichmentType: any, fieldName: string, id: int, selectedColumns: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enrichment_ids" $enrichment_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/enrichment-rules/enrichment-rules/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Enrichment Limit
#
# GET /enrichment-rules/enrichment-rules/v1/limit
# operationId: EnrichmentService_GetEnrichmentLimit
export def "enrichment-rules-enrichment-rules-limit GetEnrichmentLimit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<limit: int, used: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/enrichment-rules/v1/limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Enrichment Settings
#
# GET /enrichment-rules/enrichment-rules/v1/settings
# operationId: EnrichmentService_GetCompanyEnrichmentSettings
export def "enrichment-rules-enrichment-rules-settings GetCompanyEnrichmentSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enrichmentSettings: record<enrichmentAmountLimit: int, enrichmentsInUse: int, queryOnlyRowLimit: int, queryOnlySizeLimitBytes: string, rowLimit: int, sizeLimitBytes: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment-rules/enrichment-rules/v1/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List E2Ms
#
# GET /events2metrics/events2metrics/v2
# operationId: Events2MetricService_ListE2M
export def "events2metrics-events2metrics ListE2M" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<e2m: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events2metrics/events2metrics/v2")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an E2M
#
# PUT /events2metrics/events2metrics/v2
# operationId: Events2MetricService_ReplaceE2M
# --metricFields item shape: {aggregations: list, sourceField: string, targetBaseMetricName: string}
# --metricLabels item shape: {sourceField: string, targetLabel: string}
# --permutations shape: {hasExceededLimit: bool, limit: int}
# --spansQuery shape: {actionFilters?: list, applicationnameFilters?: list, lucene?: string, serviceFilters?: list, subsystemnameFilters?: list}
# --logsQuery shape: {alias?: string, applicationnameFilters?: list, lucene?: string, severityFilters?: list, subsystemnameFilters?: list}
export def "events2metrics-events2metrics ReplaceE2M" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createTime: string # e.g. 2022-06-30T12:30:00Z'
  --description: string # e.g. avg and max the latency of catalog service
  --id: string # e.g. d6a3658e-78d2-47d0-9b81-b2c551f01b09
  --isInternal: oneof<nothing, bool>
  --metricFields: list # item shape: {aggregations: list, sourceField: string, targetBaseMetricName: string}
  --metricLabels: list # item shape: {sourceField: string, targetLabel: string}
  --name: string # e.g. Service_catalog_latency
  --permutations: record # This data structure represents the limit of events2metrics permutations and if the limit was exceeded — shape: {hasExceededLimit: bool, limit: int}
  --spansQuery: record # This data structure represents a query for spans. — shape: {actionFilters?: list, applicationnameFilters?: list, lucene?: string, serviceFilters?: list, subsystemnameFilters?: list}
  --type: string@type-completer
  --updateTime: string # e.g. 2022-06-30T12:30:00Z'
  --logsQuery: record # This data structure represents a query for logs. — shape: {alias?: string, applicationnameFilters?: list, lucene?: string, severityFilters?: list, subsystemnameFilters?: list}
]: any -> record<e2m: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events2metrics/events2metrics/v2")
  let body = {createTime: $createTime, description: $description, id: $id, isInternal: $isInternal, metricFields: $metricFields, metricLabels: $metricLabels, name: $name, permutations: $permutations, spansQuery: $spansQuery, type: $type, updateTime: $updateTime, logsQuery: $logsQuery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new E2M
#
# POST /events2metrics/events2metrics/v2
# operationId: Events2MetricService_CreateE2M
# --metricFields item shape: {aggregations: list, sourceField: string, targetBaseMetricName: string}
# --metricLabels item shape: {sourceField: string, targetLabel: string}
# --spansQuery shape: {actionFilters?: list, applicationnameFilters?: list, lucene?: string, serviceFilters?: list, subsystemnameFilters?: list}
# --logsQuery shape: {alias?: string, applicationnameFilters?: list, lucene?: string, severityFilters?: list, subsystemnameFilters?: list}
export def "events2metrics-events2metrics CreateE2M" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # e.g. avg and max the latency of catalog service
  --metricFields: list # item shape: {aggregations: list, sourceField: string, targetBaseMetricName: string}
  --metricLabels: list # item shape: {sourceField: string, targetLabel: string}
  --name: string # e.g. Service catalog latency
  --permutationsLimit: int # format: int32, e.g. 30000
  --spansQuery: record # This data structure represents a query for spans. — shape: {actionFilters?: list, applicationnameFilters?: list, lucene?: string, serviceFilters?: list, subsystemnameFilters?: list}
  --type: string@type-completer
  --logsQuery: record # This data structure represents a query for logs. — shape: {alias?: string, applicationnameFilters?: list, lucene?: string, severityFilters?: list, subsystemnameFilters?: list}
]: any -> record<e2m: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events2metrics/events2metrics/v2")
  let body = {description: $description, metricFields: $metricFields, metricLabels: $metricLabels, name: $name, permutationsLimit: $permutationsLimit, spansQuery: $spansQuery, type: $type, logsQuery: $logsQuery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Atomic Batch Execute E2M
#
# POST /events2metrics/events2metrics/v2/batch
# operationId: Events2MetricService_AtomicBatchExecuteE2M
export def "events2metrics-events2metrics-batch AtomicBatchExecuteE2M" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list
]: any -> record<matchingResponses: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events2metrics/events2metrics/v2/batch")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List E2M Labels Cardinality
#
# GET /events2metrics/events2metrics/v2/labels:cardinality
# operationId: Events2MetricService_ListLabelsCardinality
export def "events2metrics-events2metrics-labels-cardinality ListLabelsCardinality" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --spans-query: record
  --logs-query: record
  --metric-labels: list
]: nothing -> record<permutations: table<day: string, permutations: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spans_query" $spans_query "multi") (serialize-qp "logs_query" $logs_query "multi") (serialize-qp "metric_labels" $metric_labels "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/events2metrics/events2metrics/v2/labels:cardinality" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get E2M Limits
#
# GET /events2metrics/events2metrics/v2/limits
# operationId: Events2MetricService_GetLimits
export def "events2metrics-events2metrics-limits GetLimits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<companyId: string, labelsLimit: int, metricsLimit: record<limit: int, used: int>, permutationsLimit: record<limit: int, used: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events2metrics/events2metrics/v2/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an E2M
#
# GET /events2metrics/events2metrics/v2/{id}
# operationId: Events2MetricService_GetE2M
export def "events2metrics-events2metrics GetE2M" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<e2m: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events2metrics/events2metrics/v2/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an E2M
#
# DELETE /events2metrics/events2metrics/v2/{id}
# operationId: Events2MetricService_DeleteE2M
export def "events2metrics-events2metrics DeleteE2M" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events2metrics/events2metrics/v2/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List incidents with filters
#
# POST /incidents/incidents/v1
# operationId: IncidentsService_ListIncidents
export def "incidents-incidents ListIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
  --pagination: record
  --order-bys: list
]: nothing -> record<incidents: table<assignments: list, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list, name: string, severity: string, state: string, status: string>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi") (serialize-qp "pagination" $pagination "multi") (serialize-qp "order_bys" $order_bys "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acknowledge incidents
#
# POST /incidents/incidents/v1/acknowledge
# operationId: IncidentsService_AcknowledgeIncidents
export def "incidents-incidents-acknowledge AcknowledgeIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-ids: list # e.g. [incident_id_1, incident_id_2]
]: nothing -> record<incidents: table<assignments: list, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_ids" $incident_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/acknowledge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incident aggregations
#
# GET /incidents/incidents/v1/aggregations
# operationId: IncidentsService_ListIncidentAggregations
export def "incidents-incidents-aggregations ListIncidentAggregations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
  --group-bys: list
  --pagination: record
]: nothing -> record<incidentAggs: table<aggAssignmentsCount: list, aggMetaLabelsCount: list, aggSeverityCount: list, aggStateCount: list, aggStatusCount: list, allValuesCount: int, firstCreatedAt: string, groupBysValue: list, lastClosedAt: string, lastStateUpdateTime: string, listIncidentsId: list>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi") (serialize-qp "group_bys" $group_bys "multi") (serialize-qp "pagination" $pagination "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/aggregations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multiple incidents by IDs
#
# GET /incidents/incidents/v1/batch
# operationId: IncidentsService_BatchGetIncident
export def "incidents-incidents-batch BatchGetIncident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: nothing -> record<incidents: record, notFoundIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign incidents to a user
#
# POST /incidents/incidents/v1/by-user
# operationId: IncidentsService_AssignIncidents
export def "incidents-incidents-by-user AssignIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-ids: list # e.g. [incident_id_1, incident_id_2]
  --assigned-to: record
]: nothing -> record<incidents: table<assignments: list, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_ids" $incident_ids "multi") (serialize-qp "assigned_to" $assigned_to "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/by-user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove incident user assignments
#
# DELETE /incidents/incidents/v1/by-user
# operationId: IncidentsService_UnassignIncidents
export def "incidents-incidents-by-user UnassignIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-ids: list # e.g. [incident_id_1, incident_id_2]
]: nothing -> record<incidents: table<assignments: list, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_ids" $incident_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/by-user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close incidents
#
# POST /incidents/incidents/v1/close
# operationId: IncidentsService_CloseIncidents
export def "incidents-incidents-close CloseIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-ids: list # e.g. [incident_id_1, incident_id_2]
]: nothing -> record<incidents: table<assignments: list, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_ids" $incident_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/close" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List incident events with filters
#
# GET /incidents/incidents/v1/events
# operationId: IncidentsService_ListIncidentEvents
export def "incidents-incidents-events ListIncidentEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
  --pagination: record
  --order-by: record
]: nothing -> record<items: table<cxEventKey: string, cxEventTimestamp: string, incidentEvent: any, incidentEventExtendedMetadata: record>, pagination: record<nextPageToken: string, totalSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi") (serialize-qp "pagination" $pagination "multi") (serialize-qp "order_by" $order_by "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get total count of incident events
#
# GET /incidents/incidents/v1/events/count
# operationId: IncidentsService_ListIncidentEventsTotalCount
export def "incidents-incidents-events-count ListIncidentEventsTotalCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
]: nothing -> record<count: string, reachedLimit: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/events/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available incident event filter values
#
# GET /incidents/incidents/v1/events/filter-values
# operationId: IncidentsService_ListIncidentEventsFilterValues
export def "incidents-incidents-events-filter-values ListIncidentEventsFilterValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
]: nothing -> record<filtersValues: record<assigneeWithCount: list<record>, contextualLabels: record, displayLabels: record, metaLabelsOp: string, metaLabelsWithCount: list<record>, severityWithCount: list<record>, stateWithCount: list<record>, statusWithCount: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/events/filter-values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incident by event ID
#
# GET /incidents/incidents/v1/events/{event_id}
# operationId: IncidentsService_GetIncidentByEventId
export def "incidents-incidents-events GetIncidentByEventId" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incident: record<assignments: list<record>, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list<any>, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list<record>, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/incidents/v1/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acknowledge incident by event id
#
# POST /incidents/incidents/v1/events/{event_id}/acknowledge
# operationId: IncidentsService_AcknowledgeIncidentByEventId
export def "incidents-incidents-events-acknowledge AcknowledgeIncidentByEventId" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incident: record<assignments: list<record>, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list<any>, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list<record>, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/incidents/v1/events/($event_id)/acknowledge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve incident by event id
#
# POST /incidents/incidents/v1/events/{event_id}/resolve
# operationId: IncidentsService_ResolveIncidentByEventId
export def "incidents-incidents-events-resolve ResolveIncidentByEventId" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incident: record<assignments: list<record>, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list<any>, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list<record>, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/incidents/v1/events/($event_id)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available filter values
#
# POST /incidents/incidents/v1/filter-values
# operationId: IncidentsService_GetFilterValues
export def "incidents-incidents-filter-values GetFilterValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record
]: nothing -> record<filtersValues: record<assigneeWithCount: list<record>, contextualLabels: record, displayLabels: record, metaLabelsOp: string, metaLabelsWithCount: list<record>, severityWithCount: list<record>, stateWithCount: list<record>, statusWithCount: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/filter-values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve incidents
#
# POST /incidents/incidents/v1/resolve
# operationId: IncidentsService_ResolveIncidents
export def "incidents-incidents-resolve ResolveIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-ids: list # e.g. [incident_id_1, incident_id_2]
]: nothing -> record<incidents: table<assignments: list, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_ids" $incident_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/incidents/v1/resolve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incident by ID
#
# GET /incidents/incidents/v1/{id}
# operationId: IncidentsService_GetIncident
export def "incidents-incidents GetIncident" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incident: record<assignments: list<record>, closedAt: string, contextualLabels: record, createdAt: string, description: string, displayLabels: record, duration: string, events: list<any>, id: string, isMuted: bool, lastStateUpdateKey: string, lastStateUpdateTime: string, metaLabels: list<record>, name: string, severity: string, state: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/incidents/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incident events
#
# GET /incidents/incidents/v1/{incident_id}/events
# operationId: IncidentsService_GetIncidentEvents
export def "incidents-incidents-events GetIncidentEvents" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incidentEvents: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/incidents/v1/($incident_id)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all contextual data integrations accessible
#
# GET /integrations/contextual-data/v1
# operationId: ContextualDataIntegrationService_GetContextualDataIntegrations
export def "integrations-contextual-data GetContextualDataIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-testing-integrations: oneof<nothing, bool>
]: nothing -> record<integrations: table<amountIntegrations: int, errors: list, integration: record, isNew: bool, upgradeAvailable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_testing_integrations" $include_testing_integrations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/contextual-data/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update contextual data integration
#
# PUT /integrations/contextual-data/v1
# operationId: ContextualDataIntegrationService_UpdateContextualDataIntegration
# --metadata shape: {integrationKey?: string, integrationParameters?: record, version?: string}
export def "integrations-contextual-data UpdateContextualDataIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integrationId: string
  --metadata: record # This data structure represents the metadata of an integration. — shape: {integrationKey?: string, integrationParameters?: record, version?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/contextual-data/v1")
  let body = {integrationId: $integrationId, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save contextual data integration
#
# POST /integrations/contextual-data/v1
# operationId: ContextualDataIntegrationService_SaveContextualDataIntegration
# --metadata shape: {integrationKey?: string, integrationParameters?: record, version?: string}
export def "integrations-contextual-data SaveContextualDataIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # This data structure represents the metadata of an integration. — shape: {integrationKey?: string, integrationParameters?: record, version?: string}
]: any -> record<integrationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/contextual-data/v1")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get contextual data integration definition
#
# GET /integrations/contextual-data/v1/definition/{id}
# operationId: ContextualDataIntegrationService_GetContextualDataIntegrationDefinition
export def "integrations-contextual-data-definition GetContextualDataIntegrationDefinition" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-testing-integrations: oneof<nothing, bool>
]: nothing -> record<integrationDefinition: record<featureFlag: string, integrationType: any, key: string, revisions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_testing_integrations" $include_testing_integrations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/contextual-data/v1/definition/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test contextual data integration
#
# POST /integrations/contextual-data/v1/test
# operationId: ContextualDataIntegrationService_TestContextualDataIntegration
# --integrationData shape: {integrationKey?: string, integrationParameters?: record, version?: string}
export def "integrations-contextual-data-test TestContextualDataIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integrationData: record # This data structure represents the metadata of an integration. — shape: {integrationKey?: string, integrationParameters?: record, version?: string}
  --integrationId: string
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/contextual-data/v1/test")
  let body = {integrationData: $integrationData, integrationId: $integrationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get contextual data integration details
#
# GET /integrations/contextual-data/v1/{id}
# operationId: ContextualDataIntegrationService_GetContextualDataIntegrationDetails
export def "integrations-contextual-data GetContextualDataIntegrationDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-testing-revisions: oneof<nothing, bool>
]: nothing -> record<integrationDetail: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_testing_revisions" $include_testing_revisions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/contextual-data/v1/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete contextual data integration
#
# DELETE /integrations/contextual-data/v1/{integration_id}
# operationId: ContextualDataIntegrationService_DeleteContextualDataIntegration
export def "integrations-contextual-data DeleteContextualDataIntegration" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/contextual-data/v1/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all extensions
#
# POST /integrations/extensions/v1/all
# operationId: ExtensionService_GetAllExtensions
# --filter shape: {integrations?: list}
export def "integrations-extensions-all GetAllExtensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # Filter by integration ids — shape: {integrations?: list}
  --includeHiddenExtensions: oneof<nothing, bool>
]: any -> record<extensions: table<darkModeImage: string, deprecation: record, id: string, image: string, integrations: list, isHidden: bool, keywords: list, name: string, revisions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/extensions/v1/all")
  let body = {filter: $filter, includeHiddenExtensions: $includeHiddenExtensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get deployed extensions
#
# GET /integrations/extensions/v1/deployed
# operationId: ExtensionDeploymentService_GetDeployedExtensions
export def "integrations-extensions-deployed GetDeployedExtensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deployedExtensions: table<applications: list, id: string, itemIds: list, subsystems: list, summary: record, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/extensions/v1/deployed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy extension
#
# PUT /integrations/extensions/v1/deployed
# operationId: ExtensionDeploymentService_DeployExtension
export def "integrations-extensions-deployed DeployExtension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --version: string
  --item-ids: list
  --applications: list
  --subsystems: list
  --extension-deployment: record
]: nothing -> record<extensionDeployment: record<applications: list<string>, id: string, itemIds: list<string>, subsystems: list<string>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "item_ids" $item_ids "multi") (serialize-qp "applications" $applications "multi") (serialize-qp "subsystems" $subsystems "multi") (serialize-qp "extension_deployment" $extension_deployment "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/extensions/v1/deployed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update extension
#
# POST /integrations/extensions/v1/deployed
# operationId: ExtensionDeploymentService_UpdateExtension
export def "integrations-extensions-deployed UpdateExtension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --version: string
  --item-ids: list
  --applications: list
  --subsystems: list
  --extension-deployment: record
]: nothing -> record<extensionDeployment: record<applications: list<string>, id: string, itemIds: list<string>, subsystems: list<string>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "item_ids" $item_ids "multi") (serialize-qp "applications" $applications "multi") (serialize-qp "subsystems" $subsystems "multi") (serialize-qp "extension_deployment" $extension_deployment "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/extensions/v1/deployed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revert deployment of extension
#
# DELETE /integrations/extensions/v1/deployed
# operationId: ExtensionDeploymentService_UndeployExtension
export def "integrations-extensions-deployed UndeployExtension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --keptExtensionItems: list
]: any -> record<extensionDeployment: record<applications: list<string>, id: string, itemIds: list<string>, subsystems: list<string>, version: string>, failedItems: table<itemId: string, reason: string, remoteId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/extensions/v1/deployed")
  let body = {id: $id, keptExtensionItems: $keptExtensionItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test extension revision
#
# POST /integrations/extensions/v1/testing
# operationId: ExtensionTestingService_TestExtensionRevision
# --extensionData shape: {binaries?: list, changelog?: list, darkModeImage?: string, deprecation?: record, description?: string, excerpt?: string, id?: string, image?: string, integrationDetails?: list, integrations?: list, isHidden?: bool, items?: list, keywords?: list, labels?: list, name?: string, version?: string}
export def "integrations-extensions-testing TestExtensionRevision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cleanupAfterTest: oneof<nothing, bool>
  --extensionData: record # Extension details for ingestion — shape: {binaries?: list, changelog?: list, darkModeImage?: string, deprecation?: record, description?: string, excerpt?: string, id?: string, image?: string, integrationDetails?: list, integrations?: list, isHidden?: bool, items?: list, keywords?: list, labels?: list, name?: string, version?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/extensions/v1/testing")
  let body = {cleanupAfterTest: $cleanupAfterTest, extensionData: $extensionData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cleanup testing extension
#
# DELETE /integrations/extensions/v1/testing
# operationId: ExtensionTestingService_CleanupTestingRevision
export def "integrations-extensions-testing CleanupTestingRevision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/extensions/v1/testing")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initialize testing revision
#
# POST /integrations/extensions/v1/testing/initialize
# operationId: ExtensionTestingService_InitializeTestingRevision
# --extensionData shape: {binaries?: list, changelog?: list, darkModeImage?: string, deprecation?: record, description?: string, excerpt?: string, id?: string, image?: string, integrationDetails?: list, integrations?: list, isHidden?: bool, items?: list, keywords?: list, labels?: list, name?: string, version?: string}
export def "integrations-extensions-testing-initialize InitializeTestingRevision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extensionData: record # Extension details for ingestion — shape: {binaries?: list, changelog?: list, darkModeImage?: string, deprecation?: record, description?: string, excerpt?: string, id?: string, image?: string, integrationDetails?: list, integrations?: list, isHidden?: bool, items?: list, keywords?: list, labels?: list, name?: string, version?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/extensions/v1/testing/initialize")
  let body = {extensionData: $extensionData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get extension by ID
#
# GET /integrations/extensions/v1/{id}
# operationId: ExtensionService_GetExtension
export def "integrations-extensions GetExtension" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-dashboard-binaries: oneof<nothing, bool>
  --include-testing-revision: oneof<nothing, bool>
]: nothing -> record<changelog: table<descriptionMd: string, version: string>, darkModeImage: string, deprecation: record<reason: string, replacementExtensions: list<string>>, id: string, image: string, integrations: list<string>, isHidden: bool, keywords: list<string>, name: string, permissionDeniedRevisions: table<binaries: list, description: string, excerpt: string, integrationDetails: list, isTesting: bool, items: list, labels: list, permissionDeniedItems: list, version: string>, revisions: table<binaries: list, description: string, excerpt: string, integrationDetails: list, isTesting: bool, items: list, labels: list, permissionDeniedItems: list, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_dashboard_binaries" $include_dashboard_binaries "scalar") (serialize-qp "include_testing_revision" $include_testing_revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/extensions/v1/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all integrations
#
# GET /integrations/integrations/v1
# operationId: IntegrationService_GetIntegrations
export def "integrations-integrations GetIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-testing-revision: oneof<nothing, bool>
]: nothing -> record<integrations: table<amountIntegrations: int, errors: list, integration: record, isNew: bool, upgradeAvailable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_testing_revision" $include_testing_revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/integrations/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get integration definition
#
# GET /integrations/integrations/v1/definition/{id}
# operationId: IntegrationService_GetIntegrationDefinition
export def "integrations-integrations-definition GetIntegrationDefinition" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-testing-revision: oneof<nothing, bool>
]: nothing -> record<integrationDefinition: record<featureFlag: string, integrationType: any, key: string, revisions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_testing_revision" $include_testing_revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/integrations/v1/definition/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deployed integration
#
# GET /integrations/integrations/v1/deployed/{integration_id}
# operationId: IntegrationService_GetDeployedIntegration
export def "integrations-integrations-deployed GetDeployedIntegration" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<integration: record<definitionKey: string, definitionVersion: string, id: string, integrationStatus: record<connectionStatus: string, details: record, messages: list>, parameters: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/integrations/v1/deployed/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete integration
#
# DELETE /integrations/integrations/v1/instance/{integration_id}
# operationId: IntegrationService_DeleteIntegration
export def "integrations-integrations-instance DeleteIntegration" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/integrations/v1/instance/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List managed integration keys
#
# GET /integrations/integrations/v1/managed
# operationId: IntegrationService_ListManagedIntegrationKeys
export def "integrations-integrations-managed ListManagedIntegrationKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<integrationKeys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/integrations/v1/managed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get managed integration status
#
# GET /integrations/integrations/v1/managed/{integration_id}
# operationId: IntegrationService_GetManagedIntegrationStatus
export def "integrations-integrations-managed GetManagedIntegrationStatus" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<integrationId: string, status: record<connectionStatus: string, details: record, messages: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/integrations/v1/managed/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update integration
#
# PUT /integrations/integrations/v1/metadata
# operationId: IntegrationService_UpdateIntegration
# --metadata shape: {integrationKey?: string, integrationParameters?: record, version?: string}
export def "integrations-integrations-metadata UpdateIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --metadata: record # This data structure represents the metadata of an integration. — shape: {integrationKey?: string, integrationParameters?: record, version?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/integrations/v1/metadata")
  let body = {id: $id, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save integration registration metadata
#
# POST /integrations/integrations/v1/metadata
# operationId: IntegrationService_SaveIntegration
# --metadata shape: {integrationKey?: string, integrationParameters?: record, version?: string}
export def "integrations-integrations-metadata SaveIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # This data structure represents the metadata of an integration. — shape: {integrationKey?: string, integrationParameters?: record, version?: string}
]: any -> record<integrationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/integrations/v1/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test integration
#
# POST /integrations/integrations/v1/metadata/test
# operationId: IntegrationService_TestIntegration
# --integrationData shape: {integrationKey?: string, integrationParameters?: record, version?: string}
export def "integrations-integrations-metadata-test TestIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integrationData: record # This data structure represents the metadata of an integration. — shape: {integrationKey?: string, integrationParameters?: record, version?: string}
  --integrationId: string
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/integrations/v1/metadata/test")
  let body = {integrationData: $integrationData, integrationId: $integrationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get RUM integration versions data
#
# GET /integrations/integrations/v1/rum/app-versions
# operationId: IntegrationService_GetRumApplicationVersionData
export def "integrations-integrations-rum-app-versions GetRumApplicationVersionData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application-name: string
]: nothing -> record<versionData: record<syncedAt: string, versions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "application_name" $application_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/integrations/v1/rum/app-versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger sync of RUM integration data
#
# POST /integrations/integrations/v1/rum/sync
# operationId: IntegrationService_SyncRumData
export def "integrations-integrations-rum-sync SyncRumData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool>
]: any -> record<syncExecuted: bool, syncedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/integrations/v1/rum/sync")
  let body = {force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get integration template
#
# GET /integrations/integrations/v1/template
# operationId: IntegrationService_GetTemplate
export def "integrations-integrations-template GetTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integration-id: string
  --common-arm-params: record
  --empty: record
]: nothing -> record<templateUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "integration_id" $integration_id "scalar") (serialize-qp "common_arm_params" $common_arm_params "multi") (serialize-qp "empty" $empty "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/integrations/v1/template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get integration details
#
# GET /integrations/integrations/v1/{id}
# operationId: IntegrationService_GetIntegrationDetails
export def "integrations-integrations GetIntegrationDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-testing-revision: oneof<nothing, bool>
]: nothing -> record<integrationDetail: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_testing_revision" $include_testing_revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/integrations/v1/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all outgoing webhooks
#
# GET /integrations/webhooks/v1
# operationId: OutgoingWebhooksService_ListAllOutgoingWebhooks
export def "integrations-webhooks ListAllOutgoingWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deployed: table<createdAt: string, externalId: int, id: string, name: string, type: string, updatedAt: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an outgoing webhook
#
# PUT /integrations/webhooks/v1
# operationId: OutgoingWebhooksService_UpdateOutgoingWebhook
export def "integrations-webhooks UpdateOutgoingWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: any
  --id: string # e.g. example_id
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1")
  let body = {data: $data, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an outgoing webhook
#
# POST /integrations/webhooks/v1
# operationId: OutgoingWebhooksService_CreateOutgoingWebhook
export def "integrations-webhooks CreateOutgoingWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: any
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List outbound webhooks summary
#
# GET /integrations/webhooks/v1/summary
# operationId: OutgoingWebhooksService_ListOutboundWebhooksSummary
export def "integrations-webhooks-summary ListOutboundWebhooksSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<outboundWebhookSummaries: table<createdAt: string, externalId: int, id: string, name: string, type: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test an outgoing webhook
#
# POST /integrations/webhooks/v1/test
# operationId: OutgoingWebhooksService_TestOutgoingWebhook
export def "integrations-webhooks-test TestOutgoingWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1/test")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test an existing outgoing webhook
#
# POST /integrations/webhooks/v1/test-existing
# operationId: OutgoingWebhooksService_TestExistingOutgoingWebhook
export def "integrations-webhooks-test-existing TestExistingOutgoingWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # e.g. example_id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1/test-existing")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get outgoing webhook types
#
# GET /integrations/webhooks/v1/types
# operationId: OutgoingWebhooksService_ListOutgoingWebhookTypes
export def "integrations-webhooks-types ListOutgoingWebhookTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhooks: table<count: int, label: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/webhooks/v1/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outgoing webhook type details
#
# GET /integrations/webhooks/v1/types/{type}
# operationId: OutgoingWebhooksService_GetOutgoingWebhookTypeDetails
export def "integrations-webhooks-types GetOutgoingWebhookTypeDetails" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<details: record<label: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/webhooks/v1/types/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outgoing webhook
#
# GET /integrations/webhooks/v1/{id}
# operationId: OutgoingWebhooksService_GetOutgoingWebhook
export def "integrations-webhooks GetOutgoingWebhook" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/webhooks/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an outgoing webhook
#
# DELETE /integrations/webhooks/v1/{id}
# operationId: OutgoingWebhooksService_DeleteOutgoingWebhook
export def "integrations-webhooks DeleteOutgoingWebhook" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/webhooks/v1/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List outgoing webhooks
#
# GET /integrations/webhooks/v1:listByType
# operationId: OutgoingWebhooksService_ListOutgoingWebhooks
export def "integrations-webhooks-v1-list-by-type ListOutgoingWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-1
]: nothing -> record<deployed: table<createdAt: string, externalId: int, id: string, name: string, updatedAt: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/webhooks/v1:listByType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get target
#
# GET /logs/data-setup/v2
# operationId: S3TargetService_GetTarget
export def "logs-data-setup GetTarget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<target: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logs/data-setup/v2")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set target
#
# POST /logs/data-setup/v2
# operationId: S3TargetService_SetTarget
# --s3 shape: {bucket: string, region?: string}
export def "logs-data-setup SetTarget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isActive: oneof<nothing, bool> # e.g. true
  --s3: record # This data structure represents an S3 target. — shape: {bucket: string, region?: string}
]: any -> record<target: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logs/data-setup/v2")
  let body = {isActive: $isActive, s3: $s3} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetTenantConfig
#
# GET /metrics/data-setup/v1
# operationId: MetricsConfiguratorPublicService_GetTenantConfig
export def "metrics-data-setup GetTenantConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tenantConfig: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/data-setup/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /metrics/data-setup/v1
# operationId: MetricsConfiguratorPublicService_Update
# --ibm shape: {crn?: string, endpoint?: string, serviceCrn?: string}
# --s3 shape: {bucket?: string, region?: string}
export def "metrics-data-setup Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ibm: record # This data structure is used to configure an IBM bucket. — shape: {crn?: string, endpoint?: string, serviceCrn?: string}
  --retentionDays: int # format: int64
  --s3: record # This data structure represents the S3 configuration for a tenant. — shape: {bucket?: string, region?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/data-setup/v1")
  let body = {ibm: $ibm, retentionDays: $retentionDays, s3: $s3} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ConfigureTenant
#
# POST /metrics/data-setup/v1
# operationId: MetricsConfiguratorPublicService_ConfigureTenant
# --retentionPolicy shape: {fiveMinutesResolution?: int, oneHourResolution?: int, rawResolution?: int}
# --s3 shape: {bucket?: string, region?: string}
# --ibm shape: {crn?: string, endpoint?: string, serviceCrn?: string}
export def "metrics-data-setup ConfigureTenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --retentionPolicy: record # This data structure is used to set the retention policy for a tenant. — shape: {fiveMinutesResolution?: int, oneHourResolution?: int, rawResolution?: int}
  --s3: record # This data structure represents the S3 configuration for a tenant. — shape: {bucket?: string, region?: string}
  --ibm: record # This data structure is used to configure an IBM bucket. — shape: {crn?: string, endpoint?: string, serviceCrn?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/data-setup/v1")
  let body = {retentionPolicy: $retentionPolicy, s3: $s3, ibm: $ibm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DisableArchive
#
# POST /metrics/data-setup/v1/disable
# operationId: MetricsConfiguratorPublicService_DisableArchive
export def "metrics-data-setup-disable DisableArchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/data-setup/v1/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# EnableArchive
#
# POST /metrics/data-setup/v1/enable
# operationId: MetricsConfiguratorPublicService_EnableArchive
export def "metrics-data-setup-enable EnableArchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/data-setup/v1/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ValidateBucket
#
# POST /metrics/data-setup/v1/validate
# operationId: MetricsConfiguratorPublicService_ValidateBucket
# --s3 shape: {bucket?: string, region?: string}
# --ibm shape: {crn?: string, endpoint?: string, serviceCrn?: string}
export def "metrics-data-setup-validate ValidateBucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --s3: record # This data structure represents the S3 configuration for a tenant. — shape: {bucket?: string, region?: string}
  --ibm: record # This data structure is used to configure an IBM bucket. — shape: {crn?: string, endpoint?: string, serviceCrn?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics/data-setup/v1/validate")
  let body = {s3: $s3, ibm: $ibm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace a Connector
#
# PUT /notifications/notification-center/v1/connector
# operationId: ConnectorsService_ReplaceConnector
# --connector shape: {configOverrides?: list, connectorConfig?: record, createTime?: string, description?: string, diagnostics?: record, id?: string, name?: string, teamId?: int, type?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", updateTime?: string}
export def "notifications-notification-center-connector ReplaceConnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector: record # A connector configuration for sending notifications — shape: {configOverrides?: list, connectorConfig?: record, createTime?: string, description?: string, diagnostics?: record, id?: string, name?: string, teamId?: int, type?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", updateTime?: string}
]: any -> record<connector: record<configOverrides: list<record>, connectorConfig: record<fields: list>, createTime: string, description: string, diagnostics: record<delivery: string>, id: string, name: string, teamId: int, type: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/connector")
  let body = {connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetConnectorSchema
#
# GET /notifications/notification-center/v1/connector-schema
# operationId: ConnectorSchemaService_GetConnectorSchema
export def "notifications-notification-center-connector-schema GetConnectorSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2
]: nothing -> record<connectorSchema: record<connectorConfigSchema: record<fields: list>, messageConfigSchemas: list<record>, supportedPayloadTypes: list<string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/connector-schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Connectors
#
# GET /notifications/notification-center/v1/connectors
# operationId: ConnectorsService_ListConnectors
export def "notifications-notification-center-connectors ListConnectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-type: string@connector-type-completer
  --supported-by-entity-type: string@supported-by-entity-type-completer
]: nothing -> record<connectors: table<configOverrides: list, connectorConfig: record, createTime: string, description: string, diagnostics: record, id: string, name: string, teamId: int, type: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_type" $connector_type "scalar") (serialize-qp "supported_by_entity_type" $supported_by_entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Connector
#
# POST /notifications/notification-center/v1/connectors
# operationId: ConnectorsService_CreateConnector
# --connector shape: {configOverrides?: list, connectorConfig?: record, createTime?: string, description?: string, diagnostics?: record, id?: string, name?: string, teamId?: int, type?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", updateTime?: string}
export def "notifications-notification-center-connectors CreateConnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector: record # A connector configuration for sending notifications — shape: {configOverrides?: list, connectorConfig?: record, createTime?: string, description?: string, diagnostics?: record, id?: string, name?: string, teamId?: int, type?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", updateTime?: string}
]: any -> record<connector: record<configOverrides: list<record>, connectorConfig: record<fields: list>, createTime: string, description: string, diagnostics: record<delivery: string>, id: string, name: string, teamId: int, type: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/connectors")
  let body = {connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Connector
#
# GET /notifications/notification-center/v1/connectors/{id}
# operationId: ConnectorsService_GetConnector
export def "notifications-notification-center-connectors GetConnector" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connector: record<configOverrides: list<record>, connectorConfig: record<fields: list>, createTime: string, description: string, diagnostics: record<delivery: string>, id: string, name: string, teamId: int, type: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/connectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Connector
#
# DELETE /notifications/notification-center/v1/connectors/{id}
# operationId: ConnectorsService_DeleteConnector
export def "notifications-notification-center-connectors DeleteConnector" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/connectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Get Connectors
#
# GET /notifications/notification-center/v1/connectors:batchGet
# operationId: ConnectorsService_BatchGetConnectors
export def "notifications-notification-center-connectors-batch-get BatchGetConnectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-ids: list # e.g. [connector-id-1, connector-id-2]
]: nothing -> record<connectors: record, notFoundIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_ids" $connector_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/connectors:batchGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Get Connectors Summaries
#
# GET /notifications/notification-center/v1/connectors:batchGetSummaries
# operationId: ConnectorsService_BatchGetConnectorSummaries
export def "notifications-notification-center-connectors-batch-get-summaries BatchGetConnectorSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-ids: list
]: nothing -> record<connectorSummaries: record, notFoundIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_ids" $connector_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/connectors:batchGetSummaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connector Type Summaries
#
# GET /notifications/notification-center/v1/connectors:getTypeSummaries
# operationId: ConnectorsService_GetConnectorTypeSummaries
export def "notifications-notification-center-connectors-get-type-summaries GetConnectorTypeSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --supported-by-entity-type: string@supported-by-entity-type-completer
]: nothing -> record<connectorTypeSummaries: table<count: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "supported_by_entity_type" $supported_by_entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/connectors:getTypeSummaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Connector Summaries
#
# GET /notifications/notification-center/v1/connectors:listSummaries
# operationId: ConnectorsService_ListConnectorSummaries
export def "notifications-notification-center-connectors-list-summaries ListConnectorSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-type: string@connector-type-completer
  --supported-by-entity-type: string@supported-by-entity-type-completer
]: nothing -> record<connectors: table<createTime: string, description: string, id: string, name: string, teamId: int, type: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_type" $connector_type "scalar") (serialize-qp "supported_by_entity_type" $supported_by_entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/connectors:listSummaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Entity Types
#
# GET /notifications/notification-center/v1/entity-types
# operationId: EntitiesService_ListEntityTypes
export def "notifications-notification-center-entity-types ListEntityTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entityTypes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/entity-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Entity Subtypes
#
# GET /notifications/notification-center/v1/entity-types/{entity_type}/entity-subtypes
# operationId: EntitiesService_ListEntitySubTypes
export def "notifications-notification-center-entity-types-entity-subtypes ListEntitySubTypes" [
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entitySubTypes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/entity-types/($entity_type)/entity-subtypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TestConnectorConfig
#
# POST /notifications/notification-center/v1/notifications/testing:testConnectorConfiguration
# operationId: TestingService_TestConnectorConfig
# --fields item shape: {fieldName?: string, value?: string}
export def "notifications-notification-center-notifications-testing-test-connector-configuration TestConnectorConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: string@entityType-completer
  --body-fields: list # item shape: {fieldName?: string, value?: string}
  --payloadType: string # e.g. default
  --type: string@type-completer-2
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testConnectorConfiguration")
  let body = {entityType: $entityType, fields: $body_fields, payloadType: $payloadType, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestDestination
#
# POST /notifications/notification-center/v1/notifications/testing:testDestination
# operationId: TestingService_TestDestination
# --connectorConfigFields item shape: {fieldName?: string, template?: string}
# --messageConfigFields item shape: {fieldName?: string, template?: string}
export def "notifications-notification-center-notifications-testing-test-destination TestDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectorConfigFields: list # item shape: {fieldName?: string, template?: string}
  --connectorId: string
  --entitySubType: string # e.g. logsImmediateResolved
  --entityType: string@entityType-completer
  --messageConfigFields: list # item shape: {fieldName?: string, template?: string}
  --payloadType: string # e.g. default
  --presetId: string
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testDestination")
  let body = {connectorConfigFields: $connectorConfigFields, connectorId: $connectorId, entitySubType: $entitySubType, entityType: $entityType, messageConfigFields: $messageConfigFields, payloadType: $payloadType, presetId: $presetId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestExistingConnector
#
# POST /notifications/notification-center/v1/notifications/testing:testExistingConnector
# operationId: TestingService_TestExistingConnector
export def "notifications-notification-center-notifications-testing-test-existing-connector TestExistingConnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectorId: string
  --payloadType: string # e.g. default
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testExistingConnector")
  let body = {connectorId: $connectorId, payloadType: $payloadType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestExistingPreset
#
# POST /notifications/notification-center/v1/notifications/testing:testExistingPreset
# operationId: TestingService_TestExistingPreset
export def "notifications-notification-center-notifications-testing-test-existing-preset TestExistingPreset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectorId: string
  --entitySubType: string # e.g. logsImmediateResolved
  --entityType: string@entityType-completer
  --presetId: string
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testExistingPreset")
  let body = {connectorId: $connectorId, entitySubType: $entitySubType, entityType: $entityType, presetId: $presetId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestPresetConfig
#
# POST /notifications/notification-center/v1/notifications/testing:testPresetConfiguration
# operationId: TestingService_TestPresetConfig
# --configOverrides item shape: {conditionType?: any, messageConfig?: record, payloadType?: string}
export def "notifications-notification-center-notifications-testing-test-preset-configuration TestPresetConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --configOverrides: list # item shape: {conditionType?: any, messageConfig?: record, payloadType?: string}
  --connectorId: string
  --entitySubType: string # e.g. metric
  --entityType: string@entityType-completer
  --parentPresetId: string
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testPresetConfiguration")
  let body = {configOverrides: $configOverrides, connectorId: $connectorId, entitySubType: $entitySubType, entityType: $entityType, parentPresetId: $parentPresetId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestRoutingConditionValid
#
# POST /notifications/notification-center/v1/notifications/testing:testRoutingConditionValid
# operationId: TestingService_TestRoutingConditionValid
export def "notifications-notification-center-notifications-testing-test-routing-condition-valid TestRoutingConditionValid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: string@entityType-completer
  --template: string # e.g. alertDef.priority == 'P1'
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testRoutingConditionValid")
  let body = {entityType: $entityType, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TestTemplateRender
#
# POST /notifications/notification-center/v1/notifications/testing:testTemplateRender
# operationId: TestingService_TestTemplateRender
export def "notifications-notification-center-notifications-testing-test-template-render TestTemplateRender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entitySubType: string # e.g. logsImmediateResolved
  --entityType: string@entityType-completer
  --template: string # e.g. {{ alertDef.name }}
]: any -> record<result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/notifications/testing:testTemplateRender")
  let body = {entitySubType: $entitySubType, entityType: $entityType, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace Custom Preset
#
# PUT /notifications/notification-center/v1/presets/custom
# operationId: PresetsService_ReplaceCustomPreset
# --preset shape: {configOverrides?: list, connectorType?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", createTime?: string, description?: string, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", id?: string, name?: string, parentId?: string, presetType?: "PRESET_TYPE_UNSPECIFIED"|"SYSTEM"|"CUSTOM", updateTime?: string}
export def "notifications-notification-center-presets-custom ReplaceCustomPreset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --preset: record # Set of preconfigured templates for notification content rendering — shape: {configOverrides?: list, connectorType?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", createTime?: string, description?: string, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", id?: string, name?: string, parentId?: string, presetType?: "PRESET_TYPE_UNSPECIFIED"|"SYSTEM"|"CUSTOM", updateTime?: string}
]: any -> record<preset: record<configOverrides: list<record>, connectorType: string, createTime: string, description: string, entityType: string, id: string, name: string, parentId: string, presetType: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/presets/custom")
  let body = {preset: $preset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Custom Preset
#
# POST /notifications/notification-center/v1/presets/custom
# operationId: PresetsService_CreateCustomPreset
# --preset shape: {configOverrides?: list, connectorType?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", createTime?: string, description?: string, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", id?: string, name?: string, parentId?: string, presetType?: "PRESET_TYPE_UNSPECIFIED"|"SYSTEM"|"CUSTOM", updateTime?: string}
export def "notifications-notification-center-presets-custom CreateCustomPreset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --preset: record # Set of preconfigured templates for notification content rendering — shape: {configOverrides?: list, connectorType?: "CONNECTOR_TYPE_UNSPECIFIED"|"SLACK"|"GENERIC_HTTPS"|"PAGERDUTY"|"IBM_EVENT_NOTIFICATIONS"|"SERVICE_NOW"|"EMAIL", createTime?: string, description?: string, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", id?: string, name?: string, parentId?: string, presetType?: "PRESET_TYPE_UNSPECIFIED"|"SYSTEM"|"CUSTOM", updateTime?: string}
]: any -> record<preset: record<configOverrides: list<record>, connectorType: string, createTime: string, description: string, entityType: string, id: string, name: string, parentId: string, presetType: string, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/presets/custom")
  let body = {preset: $preset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Preset
#
# DELETE /notifications/notification-center/v1/presets/custom/{id}
# operationId: PresetsService_DeleteCustomPreset
export def "notifications-notification-center-presets-custom DeleteCustomPreset" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/presets/custom/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Custom Preset As Default
#
# POST /notifications/notification-center/v1/presets/custom/{id}:defaultSet
# operationId: PresetsService_SetCustomPresetAsDefault
export def "notifications-notification-center-presets-custom SetCustomPresetAsDefault" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/presets/custom/($id):defaultSet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Preset
#
# GET /notifications/notification-center/v1/presets/{id}
# operationId: PresetsService_GetPreset
export def "notifications-notification-center-presets GetPreset" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<preset: record<configOverrides: list<record>, connectorType: string, createTime: string, description: string, entityType: string, id: string, name: string, parentId: string, presetType: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/presets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Preset As Default
#
# POST /notifications/notification-center/v1/presets/{id}:defaultSet
# operationId: PresetsService_SetPresetAsDefault
export def "notifications-notification-center-presets SetPresetAsDefault" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/presets/($id):defaultSet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Get Presets
#
# GET /notifications/notification-center/v1/presets:batchGet
# operationId: PresetsService_BatchGetPresets
export def "notifications-notification-center-presets-batch-get BatchGetPresets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --preset-ids: list
]: nothing -> record<notFoundIds: list<string>, presets: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preset_ids" $preset_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/presets:batchGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Default Preset Summary
#
# GET /notifications/notification-center/v1/presets:defaultSummaryGet
# operationId: PresetsService_GetDefaultPresetSummary
export def "notifications-notification-center-presets-default-summary-get GetDefaultPresetSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-type: string@connector-type-completer
  --entity-type: string@entity-type-completer
]: nothing -> record<presetSummary: record<connectorType: string, createTime: string, description: string, entityType: string, id: string, name: string, parentId: string, presetType: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_type" $connector_type "scalar") (serialize-qp "entity_type" $entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/presets:defaultSummaryGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Preset Summaries
#
# GET /notifications/notification-center/v1/presets:summariesList
# operationId: PresetsService_ListPresetSummaries
export def "notifications-notification-center-presets-summaries-list ListPresetSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-type: string@connector-type-completer
  --entity-type: string@entity-type-completer
]: nothing -> record<presetSummaries: table<connectorType: string, createTime: string, description: string, entityType: string, id: string, name: string, parentId: string, presetType: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_type" $connector_type "scalar") (serialize-qp "entity_type" $entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/presets:summariesList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get System Default Preset Summary
#
# GET /notifications/notification-center/v1/presets:systemDefaultSummaryGet
# operationId: PresetsService_GetSystemDefaultPresetSummary
export def "notifications-notification-center-presets-system-default-summary-get GetSystemDefaultPresetSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector-type: string@connector-type-completer
  --entity-type: string@entity-type-completer
]: nothing -> record<presetSummary: record<connectorType: string, createTime: string, description: string, entityType: string, id: string, name: string, parentId: string, presetType: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connector_type" $connector_type "scalar") (serialize-qp "entity_type" $entity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/presets:systemDefaultSummaryGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Global Routers
#
# GET /notifications/notification-center/v1/routers
# operationId: GlobalRoutersService_ListGlobalRouters
export def "notifications-notification-center-routers ListGlobalRouters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-type: string@entity-type-completer
  --source-entity-labels: record
]: nothing -> record<routers: table<createTime: string, description: string, entityLabelMatcher: record, entityLabels: record, entityType: string, fallback: list, id: string, name: string, routingLabels: record, rules: list, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "source_entity_labels" $source_entity_labels "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/routers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace Global Router
#
# PUT /notifications/notification-center/v1/routers
# operationId: GlobalRoutersService_ReplaceGlobalRouter
# --router shape: {createTime?: string, description?: string, entityLabelMatcher?: record, entityLabels?: record, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", fallback?: list, id?: string, name?: string, routingLabels?: record, rules?: list, updateTime?: string}
export def "notifications-notification-center-routers ReplaceGlobalRouter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --router: record # Defines a set of pre-configured routing rules for directing notifications — shape: {createTime?: string, description?: string, entityLabelMatcher?: record, entityLabels?: record, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", fallback?: list, id?: string, name?: string, routingLabels?: record, rules?: list, updateTime?: string}
]: any -> record<router: record<createTime: string, description: string, entityLabelMatcher: record, entityLabels: record, entityType: string, fallback: list<record>, id: string, name: string, routingLabels: record<environment: string, service: string, team: string>, rules: list<record>, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/routers")
  let body = {router: $router} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Global Router
#
# POST /notifications/notification-center/v1/routers
# operationId: GlobalRoutersService_CreateGlobalRouter
# --router shape: {createTime?: string, description?: string, entityLabelMatcher?: record, entityLabels?: record, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", fallback?: list, id?: string, name?: string, routingLabels?: record, rules?: list, updateTime?: string}
export def "notifications-notification-center-routers CreateGlobalRouter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --router: record # Defines a set of pre-configured routing rules for directing notifications — shape: {createTime?: string, description?: string, entityLabelMatcher?: record, entityLabels?: record, entityType?: "ENTITY_TYPE_UNSPECIFIED"|"ALERTS"|"TEST_NOTIFICATIONS"|"CASES", fallback?: list, id?: string, name?: string, routingLabels?: record, rules?: list, updateTime?: string}
]: any -> record<router: record<createTime: string, description: string, entityLabelMatcher: record, entityLabels: record, entityType: string, fallback: list<record>, id: string, name: string, routingLabels: record<environment: string, service: string, team: string>, rules: list<record>, updateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/notification-center/v1/routers")
  let body = {router: $router} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Global Router
#
# GET /notifications/notification-center/v1/routers/{id}
# operationId: GlobalRoutersService_GetGlobalRouter
export def "notifications-notification-center-routers GetGlobalRouter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<router: record<createTime: string, description: string, entityLabelMatcher: record, entityLabels: record, entityType: string, fallback: list<record>, id: string, name: string, routingLabels: record<environment: string, service: string, team: string>, rules: list<record>, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/routers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Global Router
#
# DELETE /notifications/notification-center/v1/routers/{id}
# operationId: GlobalRoutersService_DeleteGlobalRouter
export def "notifications-notification-center-routers DeleteGlobalRouter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/notification-center/v1/routers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Get Global Routers
#
# GET /notifications/notification-center/v1/routers:batchGetSummaries
# operationId: GlobalRoutersService_BatchGetGlobalRouters
export def "notifications-notification-center-routers-batch-get-summaries BatchGetGlobalRouters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --global-router-ids: list
]: nothing -> record<notFoundIds: list<string>, routers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "global_router_ids" $global_router_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/routers:batchGetSummaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ValidateEntityLabelMatcher
#
# POST /notifications/notification-center/v1/routers:validateEntityLabelMatcher
# operationId: GlobalRoutersService_ValidateEntityLabelMatcher
export def "notifications-notification-center-routers-validate-entity-label-matcher ValidateEntityLabelMatcher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-label-matcher: record
]: nothing -> record<result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_label_matcher" $entity_label_matcher "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/notification-center/v1/routers:validateEntityLabelMatcher" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Rule Groups
#
# GET /parsing-rules/rule-groups/v1
# operationId: RuleGroupsService_ListRuleGroups
export def "parsing-rules-rule-groups ListRuleGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ruleGroups: table<creator: string, description: string, enabled: bool, hidden: bool, id: string, name: string, order: int, ruleMatchers: list, ruleSubgroups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parsing-rules/rule-groups/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Rule Group
#
# POST /parsing-rules/rule-groups/v1
# operationId: RuleGroupsService_CreateRuleGroup
# --ruleSubgroups item shape: {enabled?: bool, order?: int, rules?: list}
# --teamId shape: {id?: int}
export def "parsing-rules-rule-groups CreateRuleGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creator: string
  --description: string
  --enabled: oneof<nothing, bool>
  --hidden: oneof<nothing, bool>
  --name: string
  --order: int # format: int64
  --ruleMatchers: list
  --ruleSubgroups: list # item shape: {enabled?: bool, order?: int, rules?: list}
  --teamId: record # shape: {id?: int}
]: any -> record<ruleGroup: record<creator: string, description: string, enabled: bool, hidden: bool, id: string, name: string, order: int, ruleMatchers: list<any>, ruleSubgroups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parsing-rules/rule-groups/v1")
  let body = {creator: $creator, description: $description, enabled: $enabled, hidden: $hidden, name: $name, order: $order, ruleMatchers: $ruleMatchers, ruleSubgroups: $ruleSubgroups, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Rule Group
#
# DELETE /parsing-rules/rule-groups/v1
# operationId: RuleGroupsService_BulkDeleteRuleGroup
export def "parsing-rules-rule-groups BulkDeleteRuleGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-ids: list
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_ids" $group_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/parsing-rules/rule-groups/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Usage Limits
#
# POST /parsing-rules/rule-groups/v1/limits
# operationId: RuleGroupsService_GetCompanyUsageLimits
export def "parsing-rules-rule-groups-limits GetCompanyUsageLimits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<companyId: string, limits: record<groups: int, parsingThemes: int, rules: int>, usage: record<groups: int, parsingThemes: int, rules: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parsing-rules/rule-groups/v1/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Rule Group Model Mapping
#
# POST /parsing-rules/rule-groups/v1/mapping
# operationId: RuleGroupsService_GetRuleGroupModelMapping
# --ruleSubgroups item shape: {enabled?: bool, order?: int, rules?: list}
export def "parsing-rules-rule-groups-mapping GetRuleGroupModelMapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creator: string
  --description: string
  --enabled: oneof<nothing, bool>
  --hidden: oneof<nothing, bool>
  --name: string
  --order: int # format: int64
  --ruleMatchers: list
  --ruleSubgroups: list # item shape: {enabled?: bool, order?: int, rules?: list}
]: any -> record<ruleDefinition: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parsing-rules/rule-groups/v1/mapping")
  let body = {creator: $creator, description: $description, enabled: $enabled, hidden: $hidden, name: $name, order: $order, ruleMatchers: $ruleMatchers, ruleSubgroups: $ruleSubgroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Rule Group
#
# GET /parsing-rules/rule-groups/v1/{group_id}
# operationId: RuleGroupsService_GetRuleGroup
export def "parsing-rules-rule-groups GetRuleGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ruleGroup: record<creator: string, description: string, enabled: bool, hidden: bool, id: string, name: string, order: int, ruleMatchers: list<any>, ruleSubgroups: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parsing-rules/rule-groups/v1/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Rule Group
#
# PUT /parsing-rules/rule-groups/v1/{group_id}
# operationId: RuleGroupsService_UpdateRuleGroup
# --ruleSubgroups item shape: {enabled?: bool, order?: int, rules?: list}
# --teamId shape: {id?: int}
export def "parsing-rules-rule-groups UpdateRuleGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creator: string
  --description: string
  --enabled: oneof<nothing, bool>
  --hidden: oneof<nothing, bool>
  --name: string
  --order: int # format: int64
  --ruleMatchers: list
  --ruleSubgroups: list # item shape: {enabled?: bool, order?: int, rules?: list}
  --teamId: record # shape: {id?: int}
]: any -> record<ruleGroup: record<creator: string, description: string, enabled: bool, hidden: bool, id: string, name: string, order: int, ruleMatchers: list<any>, ruleSubgroups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parsing-rules/rule-groups/v1/($group_id)")
  let body = {creator: $creator, description: $description, enabled: $enabled, hidden: $hidden, name: $name, order: $order, ruleMatchers: $ruleMatchers, ruleSubgroups: $ruleSubgroups, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Rule Group
#
# DELETE /parsing-rules/rule-groups/v1/{group_id}
# operationId: RuleGroupsService_DeleteRuleGroup
export def "parsing-rules-rule-groups DeleteRuleGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parsing-rules/rule-groups/v1/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quota allocation rule set
#
# GET /quota-rules/v1/quota-allocation-rule-set
# operationId: QuotaAllocationRuleSetService_GetQuotaAllocationRuleSet
export def "quota-rules-quota-allocation-rule-set GetQuotaAllocationRuleSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # e.g. 
]: nothing -> record<ruleSet: record<id: string, rules: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quota-rules/v1/quota-allocation-rule-set" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace quota allocation rule set
#
# PUT /quota-rules/v1/quota-allocation-rule-set
# operationId: QuotaAllocationRuleSetService_ReplaceQuotaAllocationRuleSet
# --ruleSet shape: {id?: string, rules: list}
export def "quota-rules-quota-allocation-rule-set ReplaceQuotaAllocationRuleSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleSet: record # Contains a collection of quota allocation rules for entity types — shape: {id?: string, rules: list}
]: any -> record<ruleSet: record<id: string, rules: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quota-rules/v1/quota-allocation-rule-set")
  let body = {ruleSet: $ruleSet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create quota allocation rule set
#
# POST /quota-rules/v1/quota-allocation-rule-set
# operationId: QuotaAllocationRuleSetService_CreateQuotaAllocationRuleSet
# --ruleSet shape: {id?: string, rules: list}
export def "quota-rules-quota-allocation-rule-set CreateQuotaAllocationRuleSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleSet: record # Contains a collection of quota allocation rules for entity types — shape: {id?: string, rules: list}
]: any -> record<ruleSet: record<id: string, rules: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quota-rules/v1/quota-allocation-rule-set")
  let body = {ruleSet: $ruleSet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete quota allocation rule set
#
# DELETE /quota-rules/v1/quota-allocation-rule-set
# operationId: QuotaAllocationRuleSetService_DeleteQuotaAllocationRuleSet
export def "quota-rules-quota-allocation-rule-set DeleteQuotaAllocationRuleSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quota-rules/v1/quota-allocation-rule-set")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an alert scheduler rule
#
# PUT /v1/alert-scheduler-rules
# operationId: AlertSchedulerRuleService_UpdateAlertSchedulerRule
# --alertSchedulerRule shape: {createdAt?: string, description?: string, enabled?: bool, filter?: any, id?: string, metaLabels?: list, name?: string, schedule?: any, uniqueIdentifier?: string, updatedAt?: string}
export def "alert-scheduler-rules UpdateAlertSchedulerRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alertSchedulerRule: record # shape: {createdAt?: string, description?: string, enabled?: bool, filter?: any, id?: string, metaLabels?: list, name?: string, schedule?: any, uniqueIdentifier?: string, updatedAt?: string}
]: any -> record<alertSchedulerRule: record<createdAt: string, description: string, enabled: bool, filter: any, id: string, metaLabels: list<record>, name: string, schedule: any, uniqueIdentifier: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alert-scheduler-rules")
  let body = {alertSchedulerRule: $alertSchedulerRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an alert scheduler rule
#
# POST /v1/alert-scheduler-rules
# operationId: AlertSchedulerRuleService_CreateAlertSchedulerRule
# --alertSchedulerRule shape: {createdAt?: string, description?: string, enabled?: bool, filter?: any, id?: string, metaLabels?: list, name?: string, schedule?: any, uniqueIdentifier?: string, updatedAt?: string}
export def "alert-scheduler-rules CreateAlertSchedulerRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alertSchedulerRule: record # shape: {createdAt?: string, description?: string, enabled?: bool, filter?: any, id?: string, metaLabels?: list, name?: string, schedule?: any, uniqueIdentifier?: string, updatedAt?: string}
]: any -> record<alertSchedulerRule: record<createdAt: string, description: string, enabled: bool, filter: any, id: string, metaLabels: list<record>, name: string, schedule: any, uniqueIdentifier: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alert-scheduler-rules")
  let body = {alertSchedulerRule: $alertSchedulerRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get multiple alert scheduler rules
#
# GET /v1/alert-scheduler-rules/bulk
# operationId: AlertSchedulerRuleService_GetBulkAlertSchedulerRule
export def "alert-scheduler-rules-bulk GetBulkAlertSchedulerRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active-timeframe: record
  --enabled: oneof<nothing, bool>
  --alert-scheduler-rules-ids: string
  --next-page-token: string # e.g. 
]: nothing -> record<alertSchedulerRules: table<alertSchedulerRule: record, nextActiveTimeframes: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active_timeframe" $active_timeframe "multi") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "alert_scheduler_rules_ids" $alert_scheduler_rules_ids "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/alert-scheduler-rules/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update multiple alert scheduler rules
#
# PUT /v1/alert-scheduler-rules/bulk
# operationId: AlertSchedulerRuleService_UpdateBulkAlertSchedulerRule
# --updateAlertSchedulerRuleRequests item shape: {alertSchedulerRule: record}
export def "alert-scheduler-rules-bulk UpdateBulkAlertSchedulerRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  updateAlertSchedulerRuleRequests: list # item shape: {alertSchedulerRule: record}
]: any -> record<updateSuppressionResponses: table<alertSchedulerRule: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alert-scheduler-rules/bulk")
  let body = {updateAlertSchedulerRuleRequests: $updateAlertSchedulerRuleRequests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create multiple alert scheduler rules
#
# POST /v1/alert-scheduler-rules/bulk
# operationId: AlertSchedulerRuleService_CreateBulkAlertSchedulerRule
# --createAlertSchedulerRuleRequests item shape: {alertSchedulerRule: record}
export def "alert-scheduler-rules-bulk CreateBulkAlertSchedulerRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  createAlertSchedulerRuleRequests: list # item shape: {alertSchedulerRule: record}
]: any -> record<createSuppressionResponses: table<alertSchedulerRule: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alert-scheduler-rules/bulk")
  let body = {createAlertSchedulerRuleRequests: $createAlertSchedulerRuleRequests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an alert scheduler rule
#
# GET /v1/alert-scheduler-rules/{alert_scheduler_rule_id}
# operationId: AlertSchedulerRuleService_GetAlertSchedulerRule
export def "alert-scheduler-rules GetAlertSchedulerRule" [
  alert_scheduler_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alertSchedulerRule: record<createdAt: string, description: string, enabled: bool, filter: any, id: string, metaLabels: list<record>, name: string, schedule: any, uniqueIdentifier: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alert-scheduler-rules/($alert_scheduler_rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an alert scheduler rule
#
# DELETE /v1/alert-scheduler-rules/{alert_scheduler_rule_id}
# operationId: AlertSchedulerRuleService_DeleteAlertSchedulerRule
export def "alert-scheduler-rules DeleteAlertSchedulerRule" [
  alert_scheduler_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alert-scheduler-rules/($alert_scheduler_rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a dashboard by URL slug
#
# GET /v1/dashboards/by-slug/{slug}
# operationId: DashboardsService_GetDashboardBySlug
export def "dashboards-by-slug GetDashboardBySlug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorId: string, authorName: string, createdAt: string, createdOriginType: string, dashboard: any, isLocked: bool, lockerAuthorId: string, lockerName: string, updatedAt: string, updatedOriginType: string, updaterAuthorId: string, updaterName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/by-slug/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace a dashboard
#
# PUT /v1/dashboards/dashboards
# operationId: DashboardsService_ReplaceDashboard
export def "dashboards-dashboards ReplaceDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dashboard: any
  --isLocked: oneof<nothing, bool>
  requestId: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards/dashboards")
  let body = {dashboard: $dashboard, isLocked: $isLocked, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new dashboard
#
# POST /v1/dashboards/dashboards
# operationId: DashboardsService_CreateDashboard
export def "dashboards-dashboards CreateDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dashboard: any
  --isLocked: oneof<nothing, bool>
  requestId: string
]: any -> record<dashboardId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards/dashboards")
  let body = {dashboard: $dashboard, isLocked: $isLocked, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a dashboard
#
# GET /v1/dashboards/dashboards/{dashboard_id}
# operationId: DashboardsService_GetDashboard
export def "dashboards-dashboards GetDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorId: string, authorName: string, createdAt: string, createdOriginType: string, dashboard: any, isLocked: bool, lockerAuthorId: string, lockerName: string, updatedAt: string, updatedOriginType: string, updaterAuthorId: string, updaterName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/dashboards/($dashboard_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a dashboard
#
# DELETE /v1/dashboards/dashboards/{dashboard_id}
# operationId: DashboardsService_DeleteDashboard
export def "dashboards-dashboards DeleteDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-id: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request_id" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dashboards/dashboards/($dashboard_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace the default dashboard
#
# PUT /v1/dashboards/dashboards/{dashboard_id}/default
# operationId: DashboardsService_ReplaceDefaultDashboard
export def "dashboards-dashboards-default ReplaceDefaultDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requestId: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/dashboards/($dashboard_id)/default")
  let body = {requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a dashboard to a folder
#
# POST /v1/dashboards/dashboards/{dashboard_id}/folder
# operationId: DashboardsService_AssignDashboardFolder
export def "dashboards-dashboards-folder AssignDashboardFolder" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folderId: string
  requestId: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/dashboards/($dashboard_id)/folder")
  let body = {folderId: $folderId, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add dashboard to favorites
#
# PATCH /v1/dashboards/dashboards/{dashboard_id}:pin
# operationId: DashboardsService_PinDashboard
export def "dashboards-dashboards PinDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requestId: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/dashboards/($dashboard_id):pin")
  let body = {requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove dashboard from favorites
#
# PATCH /v1/dashboards/dashboards/{dashboard_id}:unpin
# operationId: DashboardsService_UnpinDashboard
export def "dashboards-dashboards UnpinDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requestId: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/dashboards/($dashboard_id):unpin")
  let body = {requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Recording Rules
#
# GET /v1/rule-group-sets
# operationId: RuleGroupSets_List
export def "rule-group-sets List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sets: table<groups: list, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rule-group-sets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Recording Rules
#
# POST /v1/rule-group-sets
# operationId: RuleGroupSets_Create
# --groups item shape: {id?: string, interval?: int, limit?: string, name?: string, rules?: list, version?: int}
export def "rule-group-sets Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groups: list # item shape: {id?: string, interval?: int, limit?: string, name?: string, rules?: list, version?: int}
  --name: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rule-group-sets")
  let body = {groups: $groups, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Recording Rules
#
# GET /v1/rule-group-sets/{id}
# operationId: RuleGroupSets_Fetch
export def "rule-group-sets Fetch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<groups: table<id: string, interval: int, lastEvalAt: string, limit: string, name: string, rules: list, version: int>, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/rule-group-sets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Recording Rules
#
# PUT /v1/rule-group-sets/{id}
# operationId: RuleGroupSets_Update
# --groups item shape: {id?: string, interval?: int, limit?: string, name?: string, rules?: list, version?: int}
export def "rule-group-sets Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groups: list # item shape: {id?: string, interval?: int, limit?: string, name?: string, rules?: list, version?: int}
  --name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/rule-group-sets/($id)")
  let body = {groups: $groups, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Recording Rules
#
# DELETE /v1/rule-group-sets/{id}
# operationId: RuleGroupSets_Delete
export def "rule-group-sets Delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/rule-group-sets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Slos
#
# GET /v1/slo/slos
# operationId: SlosService_ListSlos
export def "slo-slos ListSlos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: record
]: nothing -> record<slos: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slo/slos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace Slo
#
# PUT /v1/slo/slos
# operationId: SlosService_ReplaceSlo
# --grouping shape: {labels?: list}
# --requestBasedMetricSli shape: {goodEvents: record, totalEvents: record}
# --revision shape: {revision?: int, updateTime?: string}
# --windowBasedMetricSli shape: {comparisonOperator: "COMPARISON_OPERATOR_UNSPECIFIED"|"COMPARISON_OPERATOR_GREATER_THAN"|"COMPARISON_OPERATOR_GREATER_THAN_OR_EQUALS"|"COMPARISON_OPERATOR_LESS_THAN"|"COMPARISON_OPERATOR_LESS_THAN_OR_EQUALS", missingDataStrategy?: "MISSING_DATA_STRATEGY_UNCOUNTED"|"MISSING_DATA_STRATEGY_GOOD"|"MISSING_DATA_STRATEGY_BAD", query: record, threshold: float, window: "WINDOW_SLO_WINDOW_UNSPECIFIED"|"WINDOW_SLO_WINDOW_1_MINUTE"|"WINDOW_SLO_WINDOW_5_MINUTES"}
export def "slo-slos ReplaceSlo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --silence-data-validations: oneof<nothing, bool>
  --createTime: string # format: date-time
  --creator: string # e.g. test@domain.com
  --description: string # e.g. A brief description of my SLO
  --grouping: record # Definition of the SLO grouping fields — shape: {labels?: list}
  --id: string # e.g. b11919d5-ef85-4bb1-8655-02640dbe94d9
  --labels: record
  --name: string # e.g. Example Slo Name
  --requestBasedMetricSli: record # Definition of a request-based SLI based on metrics — shape: {goodEvents: record, totalEvents: record}
  --revision: record # The revision of the slo, used to differentiate between different versions of the same SLO — shape: {revision?: int, updateTime?: string}
  --sloTimeFrame: string@sloTimeFrame-completer
  --targetThresholdPercentage: float # format: float, e.g. 99.999
  --type: string # e.g. request
  --updateTime: string # format: date-time
  --windowBasedMetricSli: record # Definition of a window-based SLI based on metrics — shape: {comparisonOperator: "COMPARISON_OPERATOR_UNSPECIFIED"|"COMPARISON_OPERATOR_GREATER_THAN"|"COMPARISON_OPERATOR_GREATER_THAN_OR_EQUALS"|"COMPARISON_OPERATOR_LESS_THAN"|"COMPARISON_OPERATOR_LESS_THAN_OR_EQUALS", missingDataStrategy?: "MISSING_DATA_STRATEGY_UNCOUNTED"|"MISSING_DATA_STRATEGY_GOOD"|"MISSING_DATA_STRATEGY_BAD", query: record, threshold: float, window: "WINDOW_SLO_WINDOW_UNSPECIFIED"|"WINDOW_SLO_WINDOW_1_MINUTE"|"WINDOW_SLO_WINDOW_5_MINUTES"}
]: any -> record<effectedSloAlertIds: list<string>, slo: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "silence_data_validations" $silence_data_validations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slo/slos" $qp)
  let body = {createTime: $createTime, creator: $creator, description: $description, grouping: $grouping, id: $id, labels: $labels, name: $name, requestBasedMetricSli: $requestBasedMetricSli, revision: $revision, sloTimeFrame: $sloTimeFrame, targetThresholdPercentage: $targetThresholdPercentage, type: $type, updateTime: $updateTime, windowBasedMetricSli: $windowBasedMetricSli} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Slo
#
# POST /v1/slo/slos
# operationId: SlosService_CreateSlo
# --grouping shape: {labels?: list}
# --requestBasedMetricSli shape: {goodEvents: record, totalEvents: record}
# --revision shape: {revision?: int, updateTime?: string}
# --windowBasedMetricSli shape: {comparisonOperator: "COMPARISON_OPERATOR_UNSPECIFIED"|"COMPARISON_OPERATOR_GREATER_THAN"|"COMPARISON_OPERATOR_GREATER_THAN_OR_EQUALS"|"COMPARISON_OPERATOR_LESS_THAN"|"COMPARISON_OPERATOR_LESS_THAN_OR_EQUALS", missingDataStrategy?: "MISSING_DATA_STRATEGY_UNCOUNTED"|"MISSING_DATA_STRATEGY_GOOD"|"MISSING_DATA_STRATEGY_BAD", query: record, threshold: float, window: "WINDOW_SLO_WINDOW_UNSPECIFIED"|"WINDOW_SLO_WINDOW_1_MINUTE"|"WINDOW_SLO_WINDOW_5_MINUTES"}
export def "slo-slos CreateSlo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --silence-data-validations: oneof<nothing, bool>
  --createTime: string # format: date-time
  --creator: string # e.g. test@domain.com
  --description: string # e.g. A brief description of my SLO
  --grouping: record # Definition of the SLO grouping fields — shape: {labels?: list}
  --id: string # e.g. b11919d5-ef85-4bb1-8655-02640dbe94d9
  --labels: record
  --name: string # e.g. Example Slo Name
  --requestBasedMetricSli: record # Definition of a request-based SLI based on metrics — shape: {goodEvents: record, totalEvents: record}
  --revision: record # The revision of the slo, used to differentiate between different versions of the same SLO — shape: {revision?: int, updateTime?: string}
  --sloTimeFrame: string@sloTimeFrame-completer
  --targetThresholdPercentage: float # format: float, e.g. 99.999
  --type: string # e.g. request
  --updateTime: string # format: date-time
  --windowBasedMetricSli: record # Definition of a window-based SLI based on metrics — shape: {comparisonOperator: "COMPARISON_OPERATOR_UNSPECIFIED"|"COMPARISON_OPERATOR_GREATER_THAN"|"COMPARISON_OPERATOR_GREATER_THAN_OR_EQUALS"|"COMPARISON_OPERATOR_LESS_THAN"|"COMPARISON_OPERATOR_LESS_THAN_OR_EQUALS", missingDataStrategy?: "MISSING_DATA_STRATEGY_UNCOUNTED"|"MISSING_DATA_STRATEGY_GOOD"|"MISSING_DATA_STRATEGY_BAD", query: record, threshold: float, window: "WINDOW_SLO_WINDOW_UNSPECIFIED"|"WINDOW_SLO_WINDOW_1_MINUTE"|"WINDOW_SLO_WINDOW_5_MINUTES"}
]: any -> record<slo: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "silence_data_validations" $silence_data_validations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slo/slos" $qp)
  let body = {createTime: $createTime, creator: $creator, description: $description, grouping: $grouping, id: $id, labels: $labels, name: $name, requestBasedMetricSli: $requestBasedMetricSli, revision: $revision, sloTimeFrame: $sloTimeFrame, targetThresholdPercentage: $targetThresholdPercentage, type: $type, updateTime: $updateTime, windowBasedMetricSli: $windowBasedMetricSli} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace Slo Pre-Validate Alerts
#
# POST /v1/slo/slos/validate
# operationId: SlosService_ValidateReplaceSloAlerts
# --grouping shape: {labels?: list}
# --revision shape: {revision?: int, updateTime?: string}
# --windowBasedMetricSli shape: {comparisonOperator: "COMPARISON_OPERATOR_UNSPECIFIED"|"COMPARISON_OPERATOR_GREATER_THAN"|"COMPARISON_OPERATOR_GREATER_THAN_OR_EQUALS"|"COMPARISON_OPERATOR_LESS_THAN"|"COMPARISON_OPERATOR_LESS_THAN_OR_EQUALS", missingDataStrategy?: "MISSING_DATA_STRATEGY_UNCOUNTED"|"MISSING_DATA_STRATEGY_GOOD"|"MISSING_DATA_STRATEGY_BAD", query: record, threshold: float, window: "WINDOW_SLO_WINDOW_UNSPECIFIED"|"WINDOW_SLO_WINDOW_1_MINUTE"|"WINDOW_SLO_WINDOW_5_MINUTES"}
# --requestBasedMetricSli shape: {goodEvents: record, totalEvents: record}
export def "slo-slos-validate ValidateReplaceSloAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createTime: string # format: date-time
  --creator: string # e.g. test@domain.com
  --description: string # e.g. A brief description of my SLO
  --grouping: record # Definition of the SLO grouping fields — shape: {labels?: list}
  --id: string # e.g. b11919d5-ef85-4bb1-8655-02640dbe94d9
  --labels: record
  --name: string # e.g. Example Slo Name
  --revision: record # The revision of the slo, used to differentiate between different versions of the same SLO — shape: {revision?: int, updateTime?: string}
  --sloTimeFrame: string@sloTimeFrame-completer
  --targetThresholdPercentage: float # format: float, e.g. 99.999
  --type: string # e.g. request
  --updateTime: string # format: date-time
  --windowBasedMetricSli: record # Definition of a window-based SLI based on metrics — shape: {comparisonOperator: "COMPARISON_OPERATOR_UNSPECIFIED"|"COMPARISON_OPERATOR_GREATER_THAN"|"COMPARISON_OPERATOR_GREATER_THAN_OR_EQUALS"|"COMPARISON_OPERATOR_LESS_THAN"|"COMPARISON_OPERATOR_LESS_THAN_OR_EQUALS", missingDataStrategy?: "MISSING_DATA_STRATEGY_UNCOUNTED"|"MISSING_DATA_STRATEGY_GOOD"|"MISSING_DATA_STRATEGY_BAD", query: record, threshold: float, window: "WINDOW_SLO_WINDOW_UNSPECIFIED"|"WINDOW_SLO_WINDOW_1_MINUTE"|"WINDOW_SLO_WINDOW_5_MINUTES"}
  --requestBasedMetricSli: record # Definition of a request-based SLI based on metrics — shape: {goodEvents: record, totalEvents: record}
]: any -> record<alertsValidationResult: table<alertVersionId: string, errorMessage: string, id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/slo/slos/validate")
  let body = {createTime: $createTime, creator: $creator, description: $description, grouping: $grouping, id: $id, labels: $labels, name: $name, revision: $revision, sloTimeFrame: $sloTimeFrame, targetThresholdPercentage: $targetThresholdPercentage, type: $type, updateTime: $updateTime, windowBasedMetricSli: $windowBasedMetricSli, requestBasedMetricSli: $requestBasedMetricSli} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Slo Zero State
#
# GET /v1/slo/slos/zeroState
# operationId: SlosService_GetZeroState
export def "slo-slos-zero-state GetZeroState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<zeroState: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/slo/slos/zeroState")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Slo
#
# GET /v1/slo/slos/{id}
# operationId: SlosService_GetSlo
export def "slo-slos GetSlo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<slo: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slo/slos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Slo
#
# DELETE /v1/slo/slos/{id}
# operationId: SlosService_DeleteSlo
export def "slo-slos DeleteSlo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<effectedSloAlertIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slo/slos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Execute Slo
#
# POST /v1/slo/slos:batchExecute
# operationId: SlosService_BatchExecuteSlo
export def "slo-slos-batch-execute BatchExecuteSlo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list
]: nothing -> record<matchingResponses: list<any>, status: record<details: record, message: string, statusCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requests" $requests "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slo/slos:batchExecute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Get Slo
#
# GET /v1/slo/slos:batchGet
# operationId: SlosService_BatchGetSlos
export def "slo-slos-batch-get BatchGetSlos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: nothing -> record<notFoundIds: list<string>, slos: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slo/slos:batchGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Group Scope
#
# GET /v1/teams/groups/{id}/scope
# operationId: TeamPermissionsMgmtService_GetTeamGroupScope
export def "teams-groups-scope GetTeamGroupScope" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scope: record<filters: record<applications: list, subsystems: list>, id: record<id: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/groups/($id)/scope")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Team Group Scope
#
# POST /v1/teams/groups/{id}/scope
# operationId: TeamPermissionsMgmtService_SetTeamGroupScope
# --scopeFilters shape: {applications?: list, subsystems?: list}
export def "teams-groups-scope SetTeamGroupScope" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scopeFilters: record # shape: {applications?: list, subsystems?: list}
]: any -> record<scopeId: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/groups/($id)/scope")
  let body = {scopeFilters: $scopeFilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Actions
#
# GET /v2/actions
# operationId: ActionsService_ListActions
export def "actions ListActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<actions: table<applicationNames: list, createdBy: string, id: string, isHidden: bool, isPrivate: bool, name: string, sourceType: string, subsystemNames: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace Action
#
# PUT /v2/actions
# operationId: ActionsService_ReplaceAction
# --action shape: {applicationNames?: list, createdBy?: string, id?: string, isHidden?: bool, isPrivate?: bool, name?: string, sourceType?: "SOURCE_TYPE_UNSPECIFIED"|"SOURCE_TYPE_LOG"|"SOURCE_TYPE_DATA_MAP", subsystemNames?: list, url?: string}
export def "actions ReplaceAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: record # shape: {applicationNames?: list, createdBy?: string, id?: string, isHidden?: bool, isPrivate?: bool, name?: string, sourceType?: "SOURCE_TYPE_UNSPECIFIED"|"SOURCE_TYPE_LOG"|"SOURCE_TYPE_DATA_MAP", subsystemNames?: list, url?: string}
]: any -> record<action: record<applicationNames: list<string>, createdBy: string, id: string, isHidden: bool, isPrivate: bool, name: string, sourceType: string, subsystemNames: list<string>, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actions")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Action
#
# POST /v2/actions
# operationId: ActionsService_CreateAction
export def "actions CreateAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationNames: list
  --isPrivate: oneof<nothing, bool>
  --name: string
  --sourceType: string@sourceType-completer-1
  --subsystemNames: list
  --body-url: string
]: any -> record<action: record<applicationNames: list<string>, createdBy: string, id: string, isHidden: bool, isPrivate: bool, name: string, sourceType: string, subsystemNames: list<string>, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actions")
  let body = {applicationNames: $applicationNames, isPrivate: $isPrivate, name: $name, sourceType: $sourceType, subsystemNames: $subsystemNames, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Atomic Batch Execute Actions
#
# POST /v2/actions/actions:atomicBatchExecute
# operationId: ActionsService_AtomicBatchExecuteActions
export def "actions-actions-atomic-batch-execute AtomicBatchExecuteActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list
]: any -> record<matchingResponses: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actions/actions:atomicBatchExecute")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Order Actions
#
# POST /v2/actions/actions:order
# operationId: ActionsService_OrderActions
export def "actions-actions-order OrderActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --privateActionsOrder: record
  --sharedActionsOrder: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actions/actions:order")
  let body = {privateActionsOrder: $privateActionsOrder, sharedActionsOrder: $sharedActionsOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Action
#
# GET /v2/actions/{id}
# operationId: ActionsService_GetAction
export def "actions GetAction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<applicationNames: list<string>, createdBy: string, id: string, isHidden: bool, isPrivate: bool, name: string, sourceType: string, subsystemNames: list<string>, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Action
#
# DELETE /v2/actions/{id}
# operationId: ActionsService_DeleteAction
export def "actions DeleteAction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alert events statistics
#
# GET /v3/alert-event-stats
# operationId: AlertEventService_GetAlertEventsStats
export def "alert-event-stats GetAlertEventsStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
  --order-bys: list
]: nothing -> record<eventsStats: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "order_bys" $order_bys "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/alert-event-stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alert event by ID
#
# GET /v3/alert-event/{id}
# operationId: AlertEventService_GetAlertEvent
export def "alert-event GetAlertEvent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-bys: list
  --pagination: record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_bys" $order_bys "multi") (serialize-qp "pagination" $pagination "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/alert-event/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
