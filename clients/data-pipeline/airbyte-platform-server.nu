# Auto-generated client for Airbyte Configuration API v1.0.0
# Source: https://raw.githubusercontent.com/airbytehq/airbyte-platform/main/airbyte-api/server-api/src/main/openapi/config.yaml
# Auth: --token flag or $env.AIRBYTE_CONFIGURATION_API_TOKEN

const BASE_URL = "https://cloud.airbyte.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AIRBYTE_CONFIGURATION_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://cloud.airbyte.com/api" "http://localhost:8000/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def timeWindow-completer [] { ["lastMonth" "lastSixMonths" "lastYear"] }
def notificationType-completer [] { ["customerio" "slack"] }
def notificationTrigger-completer [] { ["breaking_change_syncs_disabled" "breaking_change_warning" "connection_sync_queued" "connection_update" "connection_update_action_required" "sync_disabled" "sync_disabled_warning" "sync_failure" "sync_success"] }
def scopeType-completer [] { ["organization" "workspace"] }
def actorType-completer [] { ["destination" "source"] }
def sortKey-completer [] { ["actorDefinitionName_asc" "actorDefinitionName_desc" "actorName_asc" "actorName_desc" "lastSync_asc" "lastSync_desc"] }
def priority-completer [] { ["default" "high"] }
def namespaceDefinition-completer [] { ["customformat" "destination" "source"] }
def scheduleType-completer [] { ["basic" "cron" "manual"] }
def status-completer [] { ["active" "deprecated" "inactive" "locked"] }
def nonBreakingChangesPreference-completer [] { ["disable" "ignore" "propagate_columns" "propagate_fully"] }
def backfillPreference-completer [] { ["disabled" "enabled"] }
def refreshMode-completer [] { ["Merge" "Truncate"] }
def operatorType-completer [] { ["dbt" "normalization" "webhook"] }
def sortKey-completer-1 [] { ["connectionName_asc" "connectionName_desc" "destinationName_asc" "destinationName_desc" "lastSync_asc" "lastSync_desc" "sourceName_asc" "sourceName_desc"] }
def orderByField-completer [] { ["createdAt" "updatedAt"] }
def orderByMethod-completer [] { ["ASC" "DESC"] }
def status-completer-1 [] { ["disabled" "invited" "registered"] }
def permissionType-completer [] { ["instance_admin" "organization_admin" "organization_editor" "organization_member" "organization_reader" "organization_runner" "workspace_admin" "workspace_editor" "workspace_owner" "workspace_reader" "workspace_runner"] }
def secretPersistenceType-completer [] { ["aws" "azure" "google" "testing" "vault"] }
def scope-completer [] { ["organization" "workspace"] }
def secretStorageType-completer [] { ["aws_secrets_manager" "azure_key_vault" "google_secret_manager" "local_testing" "vault"] }
def jobType-completer [] { ["RESET" "SYNC"] }
def incompleteRunCause-completer [] { ["CANCELED" "FAILED"] }
def runState-completer [] { ["COMPLETE" "INCOMPLETE" "PENDING" "RATE_LIMITED" "RUNNING"] }
def flow-completer [] { ["payment_method" "portal" "setup"] }
def plan-completer [] { ["plus" "standard"] }
def paymentStatus-completer [] { ["disabled" "grace_period" "locked" "manual" "okay" "uninitialized"] }
def usageCategoryOverwrite-completer [] { ["free" "internal"] }
def rollout-strategy-completer [] { ["automated" "manual" "overridden"] }
def state-completer [] { ["canceled" "errored" "failed_rolled_back" "finalizing" "in_progress" "initialized" "paused" "succeeded" "workflow_started"] }
def state-completer-1 [] { ["canceled" "failed_rolled_back" "succeeded"] }
def plan-name-completer [] { ["CORE" "EMBEDDED_ANNUAL_COMMITMENT" "EMBEDDED_PAYG" "FLEX" "PARTNER" "POV" "PRO" "SME" "STANDARD" "STANDARD_TRIAL" "UNIFIED_TRIAL"] }
def status-completer-2 [] { ["active" "draft"] }
def defaultRole-completer [] { ["organization_admin" "organization_editor" "organization_member"] }
def grant-type-completer [] { ["client_credentials"] }
def jobType-completer-1 [] { ["clear" "refresh" "reset" "sync"] }
def clientType-completer [] { ["api" "webapp"] }
def namespaceDefinition-completer-1 [] { ["custom_format" "destination" "source"] }
def nonBreakingSchemaUpdatesBehavior-completer [] { ["disable_connection" "ignore" "propagate_columns" "propagate_fully"] }
def permissionType-completer-1 [] { ["organization_admin" "organization_editor" "organization_member" "organization_reader" "organization_runner" "workspace_admin" "workspace_editor" "workspace_reader" "workspace_runner"] }
def status-completer-3 [] { ["available" "configuring" "create_failed" "creating" "delete_failed" "deleted" "deleting" "pending_acceptance"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "workspaces-create createWorkspace" } } | get name | first)
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

# Creates a workspace
#
# POST /v1/workspaces/create
# operationId: createWorkspace
# --notifications item shape: {notificationType: "slack"|"customerio", sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration?: record, customerioConfiguration?: record}
# --notificationSettings shape: {sendOnSuccess?: record, sendOnFailure?: record, sendOnSyncDisabled?: record, sendOnSyncDisabledWarning?: record, sendOnConnectionUpdate?: record, sendOnConnectionUpdateActionRequired?: record, sendOnBreakingChangeWarning?: record, sendOnBreakingChangeSyncsDisabled?: record, sendOnConnectionSyncQueued?: record}
# --webhookConfigs item shape: {name?: string, authToken?: string, validationUrl?: string, customDbtHost?: string}
export def "workspaces-create createWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # format: email
  --anonymousDataCollection: string@bool-completer
  name: string
  --news: string@bool-completer
  --securityUpdates: string@bool-completer
  --notifications: list # item shape: {notificationType: "slack"|"customerio", sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration?: record, customerioConfiguration?: record}
  --notificationSettings: record # shape: {sendOnSuccess?: record, sendOnFailure?: record, sendOnSyncDisabled?: record, sendOnSyncDisabledWarning?: record, sendOnConnectionUpdate?: record, sendOnConnectionUpdateActionRequired?: record, sendOnBreakingChangeWarning?: record, sendOnBreakingChangeSyncsDisabled?: record, sendOnConnectionSyncQueued?: record}
  --displaySetupWizard: string@bool-completer
  --dataplaneGroupId: string # format: uuid
  --webhookConfigs: list # item shape: {name?: string, authToken?: string, validationUrl?: string, customDbtHost?: string}
  organizationId: string # format: uuid
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/create")
  let body = {email: $email, anonymousDataCollection: $anonymousDataCollection, name: $name, news: $news, securityUpdates: $securityUpdates, notifications: $notifications, notificationSettings: $notificationSettings, displaySetupWizard: $displaySetupWizard, dataplaneGroupId: $dataplaneGroupId, webhookConfigs: $webhookConfigs, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a workspace with an explicit workspace ID. This should be use in acceptance tests only.
#
# POST /v1/workspaces/create_if_not_exist
# operationId: createWorkspaceIfNotExist
# --notifications item shape: {notificationType: "slack"|"customerio", sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration?: record, customerioConfiguration?: record}
# --notificationSettings shape: {sendOnSuccess?: record, sendOnFailure?: record, sendOnSyncDisabled?: record, sendOnSyncDisabledWarning?: record, sendOnConnectionUpdate?: record, sendOnConnectionUpdateActionRequired?: record, sendOnBreakingChangeWarning?: record, sendOnBreakingChangeSyncsDisabled?: record, sendOnConnectionSyncQueued?: record}
# --webhookConfigs item shape: {name?: string, authToken?: string, validationUrl?: string, customDbtHost?: string}
export def "workspaces-create-if-not-exist createWorkspaceIfNotExist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # format: uuid
  --email: string # format: email
  --anonymousDataCollection: string@bool-completer
  name: string
  --news: string@bool-completer
  --securityUpdates: string@bool-completer
  --notifications: list # item shape: {notificationType: "slack"|"customerio", sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration?: record, customerioConfiguration?: record}
  --notificationSettings: record # shape: {sendOnSuccess?: record, sendOnFailure?: record, sendOnSyncDisabled?: record, sendOnSyncDisabledWarning?: record, sendOnConnectionUpdate?: record, sendOnConnectionUpdateActionRequired?: record, sendOnBreakingChangeWarning?: record, sendOnBreakingChangeSyncsDisabled?: record, sendOnConnectionSyncQueued?: record}
  --displaySetupWizard: string@bool-completer
  --dataplaneGroupId: string # format: uuid
  --webhookConfigs: list # item shape: {name?: string, authToken?: string, validationUrl?: string, customDbtHost?: string}
  organizationId: string # format: uuid
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/create_if_not_exist")
  let body = {id: $id, email: $email, anonymousDataCollection: $anonymousDataCollection, name: $name, news: $news, securityUpdates: $securityUpdates, notifications: $notifications, notificationSettings: $notificationSettings, displaySetupWizard: $displaySetupWizard, dataplaneGroupId: $dataplaneGroupId, webhookConfigs: $webhookConfigs, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a workspace
#
# POST /v1/workspaces/delete
# operationId: deleteWorkspace
export def "workspaces-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/delete")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspaces by given workspace IDs registered in the current Airbyte deployment. This function also supports pagination.
#
# POST /v1/workspaces/list_paginated
# operationId: listWorkspacesPaginated
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "workspaces-list-paginated listWorkspacesPaginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceIds: list
  --includeDeleted: string@bool-completer # default: false
  pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --nameContains: string
]: any -> record<workspaces: table<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: list, notificationSettings: record, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: list, organizationId: string, tombstone: bool, workspaceLimits: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/list_paginated")
  let body = {workspaceIds: $workspaceIds, includeDeleted: $includeDeleted, pagination: $pagination, nameContains: $nameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspaces under the given org id. This function also supports searching by keyword and pagination.
#
# POST /v1/workspaces/list_by_organization_id
# operationId: listWorkspacesInOrganization
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "workspaces-list-by-organization-id listWorkspacesInOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --nameContains: string
]: any -> record<workspaces: table<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: list, notificationSettings: record, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: list, organizationId: string, tombstone: bool, workspaceLimits: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/list_by_organization_id")
  let body = {organizationId: $organizationId, pagination: $pagination, nameContains: $nameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspaces by a given user id. The function also supports searching by keyword and pagination.
#
# POST /v1/workspaces/list_by_user_id
# operationId: listWorkspacesByUser
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "workspaces-list-by-user-id listWorkspacesByUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # format: uuid
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --nameContains: string
]: any -> record<workspaces: table<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: list, notificationSettings: record, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: list, organizationId: string, tombstone: bool, workspaceLimits: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/list_by_user_id")
  let body = {userId: $userId, pagination: $pagination, nameContains: $nameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calls the dbt Cloud `List Accounts` and `List jobs` APIs to get the list of available jobs for the dbt auth token associated with the requested workspace config.
#
# POST /v1/workspaces/get_available_dbt_jobs
# operationId: getAvailableDbtJobsForWorkspace
export def "workspaces-get-available-dbt-jobs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  dbtConfigId: string # The config id associated with the dbt Cloud config, references the webhookConfigId in the core API. (format: uuid)
]: any -> record<availableDbtJobs: table<accountId: int, jobId: int, jobName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_available_dbt_jobs")
  let body = {workspaceId: $workspaceId, dbtConfigId: $dbtConfigId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find workspace by ID
#
# POST /v1/workspaces/get
# operationId: getWorkspace
export def "workspaces-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find workspace by slug
#
# POST /v1/workspaces/get_by_slug
# operationId: getWorkspaceBySlug
export def "workspaces-get-by-slug post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_slug")
  let body = {slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find workspace by connection id
#
# POST /v1/workspaces/get_by_connection_id
# operationId: getWorkspaceByConnectionId
export def "workspaces-get-by-connection-id post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_connection_id")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find workspace by connection id including the tombstone ones
#
# POST /v1/workspaces/get_by_connection_id_with_tombstone
# operationId: getWorkspaceByConnectionIdWithTombstone
export def "workspaces-get-by-connection-id-with-tombstone post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_connection_id_with_tombstone")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a workspace's basic organization info that is accessible for all workspace members, regardless of organization membership.
#
# POST /v1/workspaces/get_organization_info
# operationId: getOrganizationInfo
export def "workspaces-get-organization-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<organizationId: string, organizationName: string, sso: bool, billing: record<subscriptionStatus: string, paymentStatus: string, accountType: string, gracePeriodEndsAt: int>, organizationPlanId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_organization_info")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace state
#
# POST /v1/workspaces/update
# operationId: updateWorkspace
# --notifications item shape: {notificationType: "slack"|"customerio", sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration?: record, customerioConfiguration?: record}
# --notificationSettings shape: {sendOnSuccess?: record, sendOnFailure?: record, sendOnSyncDisabled?: record, sendOnSyncDisabledWarning?: record, sendOnConnectionUpdate?: record, sendOnConnectionUpdateActionRequired?: record, sendOnBreakingChangeWarning?: record, sendOnBreakingChangeSyncsDisabled?: record, sendOnConnectionSyncQueued?: record}
# --notificationsConfig shape: {failure?: record, success?: record, connectionUpdate?: record, connectionUpdateActionRequired?: record, syncDisabled?: record, syncDisabledWarning?: record}
# --webhookConfigs item shape: {name?: string, authToken?: string, validationUrl?: string, customDbtHost?: string}
export def "workspaces-update updateWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --name: string
  --email: string # format: email
  --initialSetupComplete: string@bool-completer
  --displaySetupWizard: string@bool-completer
  --anonymousDataCollection: string@bool-completer
  --news: string@bool-completer
  --securityUpdates: string@bool-completer
  --notifications: list # item shape: {notificationType: "slack"|"customerio", sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration?: record, customerioConfiguration?: record}
  --notificationSettings: record # shape: {sendOnSuccess?: record, sendOnFailure?: record, sendOnSyncDisabled?: record, sendOnSyncDisabledWarning?: record, sendOnConnectionUpdate?: record, sendOnConnectionUpdateActionRequired?: record, sendOnBreakingChangeWarning?: record, sendOnBreakingChangeSyncsDisabled?: record, sendOnConnectionSyncQueued?: record}
  --notificationsConfig: record # Configures workspace notifications. — shape: {failure?: record, success?: record, connectionUpdate?: record, connectionUpdateActionRequired?: record, syncDisabled?: record, syncDisabledWarning?: record}
  --dataplaneGroupId: string # format: uuid
  --webhookConfigs: list # item shape: {name?: string, authToken?: string, validationUrl?: string, customDbtHost?: string}
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update")
  let body = {workspaceId: $workspaceId, name: $name, email: $email, initialSetupComplete: $initialSetupComplete, displaySetupWizard: $displaySetupWizard, anonymousDataCollection: $anonymousDataCollection, news: $news, securityUpdates: $securityUpdates, notifications: $notifications, notificationSettings: $notificationSettings, notificationsConfig: $notificationsConfig, dataplaneGroupId: $dataplaneGroupId, webhookConfigs: $webhookConfigs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace name
#
# POST /v1/workspaces/update_name
# operationId: updateWorkspaceName
export def "workspaces-update-name updateWorkspaceName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  name: string
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update_name")
  let body = {workspaceId: $workspaceId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace organization
#
# POST /v1/workspaces/update_organization
# operationId: updateWorkspaceOrganization
export def "workspaces-update-organization updateWorkspaceOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  organizationId: string # format: uuid
]: any -> record<workspaceId: string, customerId: string, email: string, name: string, slug: string, initialSetupComplete: bool, displaySetupWizard: bool, anonymousDataCollection: bool, news: bool, securityUpdates: bool, notifications: table<notificationType: string, sendOnSuccess: bool, sendOnFailure: bool, slackConfiguration: record, customerioConfiguration: record>, notificationSettings: record<sendOnSuccess: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnFailure: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnSyncDisabledWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdate: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionUpdateActionRequired: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeWarning: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnBreakingChangeSyncsDisabled: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>, sendOnConnectionSyncQueued: record<notificationType: list, slackConfiguration: record, customerioConfiguration: record>>, firstCompletedSync: bool, feedbackDone: bool, dataplaneGroupId: string, webhookConfigs: table<id: string, name: string, customDbtHost: string>, organizationId: string, tombstone: bool, workspaceLimits: record<sources: record<current: int, max: int>, destinations: record<current: int, max: int>, activeConnections: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update_organization")
  let body = {workspaceId: $workspaceId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get usage for a workspace
#
# POST /v1/workspaces/get_usage
# operationId: getWorkspaceUsage
export def "workspaces-get-usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  timeWindow: string@timeWindow-completer # default: lastMonth
]: any -> record<data: table<connection: record, source: record, sourceDefinition: record, destination: record, destinationDefinition: record, usage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_usage")
  let body = {workspaceId: $workspaceId, timeWindow: $timeWindow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Data Worker availability for a workspace
#
# POST /v1/workspaces/get_data_worker_availability
# operationId: getWorkspaceDataWorkerAvailability
export def "workspaces-get-data-worker-availability post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  organizationId: string # format: uuid
]: any -> record<workspaceId: string, organizationId: string, outOfDataWorkers: bool, enforcementEnabled: bool, currentDataWorkers: float, committedDataWorkers: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_data_worker_availability")
  let body = {workspaceId: $workspaceId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace feedback state
#
# POST /v1/workspaces/tag_feedback_status_as_done
# operationId: updateWorkspaceFeedback
export def "workspaces-tag-feedback-status-as-done updateWorkspaceFeedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/tag_feedback_status_as_done")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Try sending a notifications; to be deprecated
#
# POST /v1/notifications/try
# operationId: tryNotificationConfig
# --slackConfiguration shape: {webhook: string}
export def "notifications-try tryNotificationConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  notificationType: string@notificationType-completer
  --sendOnSuccess: string@bool-completer # default: false
  --sendOnFailure: string@bool-completer # default: true
  --slackConfiguration: record # shape: {webhook: string}
  --customerioConfiguration: record
]: any -> record<status: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/notifications/try")
  let body = {notificationType: $notificationType, sendOnSuccess: $sendOnSuccess, sendOnFailure: $sendOnFailure, slackConfiguration: $slackConfiguration, customerioConfiguration: $customerioConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Try sending a notifications to webhook
#
# POST /v1/notifications/try_webhook
# operationId: tryNotificationWebhookConfig
# --slackConfiguration shape: {webhook: string}
export def "notifications-try-webhook tryNotificationWebhookConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slackConfiguration: record # shape: {webhook: string}
  --notificationTrigger: string@notificationTrigger-completer
]: any -> record<status: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/notifications/try_webhook")
  let body = {slackConfiguration: $slackConfiguration, notificationTrigger: $notificationTrigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a sourceDefinition
#
# POST /v1/source_definitions/update
# operationId: updateSourceDefinition
# --resourceRequirements shape: {default?: record, jobSpecific?: list}
export def "source-definitions-update updateSourceDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  sourceDefinitionId: string # format: uuid
  dockerImageTag: string
  --resourceRequirements: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
  workspaceId: string # format: uuid
]: any -> record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/update")
  let body = {name: $name, sourceDefinitionId: $sourceDefinitionId, dockerImageTag: $dockerImageTag, resourceRequirements: $resourceRequirements, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the sourceDefinitions the current Airbyte deployment is configured to use
#
# POST /v1/source_definitions/list
# operationId: listSourceDefinitions
export def "source-definitions-list listSourceDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sourceDefinitions: table<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the latest sourceDefinitions Airbyte supports
#
# POST /v1/source_definitions/list_latest
# operationId: listLatestSourceDefinitions
export def "source-definitions-list-latest listLatestSourceDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sourceDefinitions: table<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get source
#
# POST /v1/source_definitions/get
# operationId: getSourceDefinition
export def "source-definitions-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
]: any -> record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get")
  let body = {sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a source definition
#
# POST /v1/source_definitions/delete
# operationId: deleteSourceDefinition
export def "source-definitions-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/delete")
  let body = {sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all private, non-custom sourceDefinitions, and for each indicate whether the given workspace has a grant for using the definition. Used by admins to view and modify a given workspace's grants.
#
# POST /v1/source_definitions/list_private
# operationId: listPrivateSourceDefinitions
export def "source-definitions-list-private listPrivateSourceDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<sourceDefinitions: table<sourceDefinition: record, granted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_private")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the sourceDefinitions the given workspace is configured to use
#
# POST /v1/source_definitions/list_for_workspace
# operationId: listSourceDefinitionsForWorkspace
export def "source-definitions-list-for-workspace listSourceDefinitionsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
  --filterByUsed: string@bool-completer # default: false
]: any -> record<sourceDefinitions: table<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_for_workspace")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone, filterByUsed: $filterByUsed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all enterprise source connector stubs from a specified GCS bucket.
#
# POST /v1/source_definitions/list_enterprise_source_stubs
# operationId: listEnterpriseSourceStubs
export def "source-definitions-list-enterprise-source-stubs listEnterpriseSourceStubs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enterpriseConnectorStubs: table<id: string, definitionId: string, name: string, url: string, icon: string, label: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_enterprise_source_stubs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all enterprise source connector stubs for a specified workspace.
#
# POST /v1/source_definitions/list_enterprise_stubs_for_workspace
# operationId: listEnterpriseSourceStubsForWorkspace
export def "source-definitions-list-enterprise-stubs-for-workspace listEnterpriseSourceStubsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<enterpriseConnectorStubs: table<id: string, definitionId: string, name: string, url: string, icon: string, label: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_enterprise_stubs_for_workspace")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a custom sourceDefinition for the given workspace or organization
#
# POST /v1/source_definitions/create_custom
# operationId: createCustomSourceDefinition
# --sourceDefinition shape: {name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon?: string, resourceRequirements?: record, connectorSpecification?: record}
export def "source-definitions-create-custom createCustomSourceDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # format: uuid
  --scopeId: string # format: uuid
  --scopeType: string@scopeType-completer
  sourceDefinition: record # shape: {name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon?: string, resourceRequirements?: record, connectorSpecification?: record}
]: any -> record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/create_custom")
  let body = {workspaceId: $workspaceId, scopeId: $scopeId, scopeType: $scopeType, sourceDefinition: $sourceDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a sourceDefinition that is configured for the given workspace
#
# POST /v1/source_definitions/get_for_workspace
# operationId: getSourceDefinitionForWorkspace
export def "source-definitions-get-for-workspace post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get_for_workspace")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a sourceDefinition that is configured for the given workspace or organization
#
# POST /v1/source_definitions/get_for_scope
# operationId: getSourceDefinitionForScope
export def "source-definitions-get-for-scope post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  scopeId: string # format: uuid
  scopeType: string@scopeType-completer
]: any -> record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get_for_scope")
  let body = {actorDefinitionId: $actorDefinitionId, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# grant a private, non-custom sourceDefinition to a given workspace or organization
#
# POST /v1/source_definitions/grant_definition
# operationId: grantSourceDefinition
export def "source-definitions-grant-definition grantSourceDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  scopeId: string # format: uuid
  scopeType: string@scopeType-completer
]: any -> record<sourceDefinition: record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record<default: record, jobSpecific: list>, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string>, granted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/grant_definition")
  let body = {actorDefinitionId: $actorDefinitionId, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# revoke a grant to a private, non-custom sourceDefinition from a given workspace or organization
#
# POST /v1/source_definitions/revoke_definition
# operationId: revokeSourceDefinition
export def "source-definitions-revoke-definition revokeSourceDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  scopeId: string # format: uuid
  scopeType: string@scopeType-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/revoke_definition")
  let body = {actorDefinitionId: $actorDefinitionId, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get actor definition version for a source.
#
# POST /v1/actor_definition_versions/get_for_source
# operationId: getActorDefinitionVersionForSourceId
export def "actor-definition-versions-get-for-source post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definition_versions/get_for_source")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specification for a SourceDefinition.
#
# POST /v1/source_definition_specifications/get
# operationId: getSourceDefinitionSpecification
export def "source-definition-specifications-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<sourceDefinitionId: string, documentationUrl: string, connectionSpecification: record, advancedAuth: record<authFlowType: string, predicateKey: list<string>, predicateValue: string, oauthConfigSpecification: record<oauthUserInputFromConnectorConfigSpecification: any, completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any>>, advancedAuthGlobalCredentialsAvailable: bool, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definition_specifications/get")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specification for a source.
#
# POST /v1/source_definition_specifications/get_for_source
# operationId: getSpecificationForSourceId
export def "source-definition-specifications-get-for-source post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> record<sourceDefinitionId: string, documentationUrl: string, connectionSpecification: record, advancedAuth: record<authFlowType: string, predicateKey: list<string>, predicateValue: string, oauthConfigSpecification: record<oauthUserInputFromConnectorConfigSpecification: any, completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any>>, advancedAuthGlobalCredentialsAvailable: bool, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definition_specifications/get_for_source")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve an actor definition version by version tag.
#
# POST /v1/actor_definition_versions/resolve
# operationId: resolveActorDefinitionVersionByTag
export def "actor-definition-versions-resolve resolveActorDefinitionVersionByTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  actorType: string@actorType-completer
  dockerImageTag: string
]: any -> record<versionId: string, dockerRepository: string, dockerImageTag: string, supportRefreshes: bool, supportFileTransfer: bool, supportDataActivation: bool, connectorIPCOptions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definition_versions/resolve")
  let body = {actorDefinitionId: $actorDefinitionId, actorType: $actorType, dockerImageTag: $dockerImageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the default actor definition version for the actor.
#
# POST /v1/actor_definition_versions/get_default
# operationId: getActorDefinitionVersionDefault
export def "actor-definition-versions-get-default post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
]: any -> record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definition_versions/get_default")
  let body = {actorDefinitionId: $actorDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an actor definition (source or destination) for the given workspace or organization
#
# POST /v1/actor_definitions/create
# operationId: createActorDefinition
# --actorDefinition shape: {name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon?: string, resourceRequirements?: record}
export def "actor-definitions-create createActorDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # format: uuid
  --scopeId: string # format: uuid
  --scopeType: string@scopeType-completer
  actorType: string@actorType-completer
  actorDefinition: record # shape: {name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon?: string, resourceRequirements?: record}
]: any -> record<requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definitions/create")
  let body = {workspaceId: $workspaceId, scopeId: $scopeId, scopeType: $scopeType, actorType: $actorType, actorDefinition: $actorDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an actor definition (source or destination)
#
# POST /v1/actor_definitions/update
# operationId: updateActorDefinition
# --resourceRequirements shape: {default?: record, jobSpecific?: list}
export def "actor-definitions-update updateActorDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # The ID of the actor definition to update (format: uuid)
  actorType: string@actorType-completer
  --name: string # Optional name update (mainly for custom connectors)
  dockerImageTag: string # The new docker image tag to update to
  --resourceRequirements: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
  workspaceId: string # format: uuid
]: any -> record<requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definitions/update")
  let body = {actorDefinitionId: $actorDefinitionId, actorType: $actorType, name: $name, dockerImageTag: $dockerImageTag, resourceRequirements: $resourceRequirements, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finishes processing an actor definition create or update operation
#
# POST /v1/actor_definitions/finish
# operationId: finishActorDefinitionUpdate
# --actorUpdateRequest shape: {actorType: "source"|"destination", actorDefinitionId?: string, imageName: string, imageTag: string}
# --metadata shape: {name?: string, icon?: string, documentationUrl?: string, resourceRequirements?: record}
export def "actor-definitions-finish finishActorDefinitionUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorUpdateRequest: record # shape: {actorType: "source"|"destination", actorDefinitionId?: string, imageName: string, imageTag: string}
  metadata: record # shape: {name?: string, icon?: string, documentationUrl?: string, resourceRequirements?: record}
  --commandId: string # The command ID from the spec command that was executed
  workspaceId: string # The workspace ID (format: uuid)
]: any -> record<actorDefinitionId: string, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record<name: string, namespace: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definitions/finish")
  let body = {actorUpdateRequest: $actorUpdateRequest, metadata: $metadata, commandId: $commandId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the result of an actor definition create or update operation
#
# POST /v1/actor_definitions/result
# operationId: getActorDefinitionResult
export def "actor-definitions-result post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  requestId: string # The request ID returned from the create or update operation
]: any -> record<status: string, actorDefinitionId: string, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record<name: string, namespace: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definitions/result")
  let body = {requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a declarative manifest to be used by the specified source definition
#
# POST /v1/declarative_source_definitions/create_manifest
# operationId: createDeclarativeSourceDefinitionManifest
# --declarativeManifest shape: {description: string, manifest: record, spec: record, version: int}
export def "declarative-source-definitions-create-manifest createDeclarativeSourceDefinitionManifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  sourceDefinitionId: string # format: uuid
  --setAsActiveManifest: string@bool-completer
  declarativeManifest: record # shape: {description: string, manifest: record, spec: record, version: int}
  --componentsFileContent: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/declarative_source_definitions/create_manifest")
  let body = {workspaceId: $workspaceId, sourceDefinitionId: $sourceDefinitionId, setAsActiveManifest: $setAsActiveManifest, declarativeManifest: $declarativeManifest, componentsFileContent: $componentsFileContent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the declarative manifest version for a source
#
# POST /v1/declarative_source_definitions/update_active_manifest
# operationId: updateDeclarativeManifestVersion
export def "declarative-source-definitions-update-active-manifest updateDeclarativeManifestVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  sourceDefinitionId: string # format: uuid
  version: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/declarative_source_definitions/update_active_manifest")
  let body = {workspaceId: $workspaceId, sourceDefinitionId: $sourceDefinitionId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all available declarative manifest versions of a declarative source definition
#
# POST /v1/declarative_source_definitions/list_manifests
# operationId: listDeclarativeManifests
export def "declarative-source-definitions-list-manifests listDeclarativeManifests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  sourceDefinitionId: string # format: uuid
]: any -> record<manifestVersions: table<version: int, isActive: bool, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/declarative_source_definitions/list_manifests")
  let body = {workspaceId: $workspaceId, sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new connector builder project
#
# POST /v1/connector_builder_projects/create
# operationId: createConnectorBuilderProject
# --builderProject shape: {name: string, draftManifest?: record, yamlManifest?: string, componentsFileContent?: string, baseActorDefinitionVersionId?: string, contributionPullRequestUrl?: string, contributionActorDefinitionId?: string}
export def "connector-builder-projects-create createConnectorBuilderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProject: record # shape: {name: string, draftManifest?: record, yamlManifest?: string, componentsFileContent?: string, baseActorDefinitionVersionId?: string, contributionPullRequestUrl?: string, contributionActorDefinitionId?: string}
]: any -> record<workspaceId: string, builderProjectId: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/create")
  let body = {workspaceId: $workspaceId, builderProject: $builderProject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Publish a connector to the workspace
#
# POST /v1/connector_builder_projects/publish
# operationId: publishConnectorBuilderProject
# --initialDeclarativeManifest shape: {description: string, manifest: record, spec: record, version: int}
export def "connector-builder-projects-publish publishConnectorBuilderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProjectId: string # format: uuid
  name: string
  initialDeclarativeManifest: record # shape: {description: string, manifest: record, spec: record, version: int}
  --componentsFileContent: string
]: any -> record<sourceDefinitionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/publish")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, name: $name, initialDeclarativeManifest: $initialDeclarativeManifest, componentsFileContent: $componentsFileContent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the base image for the declarative manifest
#
# POST /v1/connector_builder_projects/get_base_image
# operationId: getDeclarativeManifestBaseImage
export def "connector-builder-projects-get-base-image post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  manifest: record # Low code CDK manifest JSON object
]: any -> record<baseImage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/get_base_image")
  let body = {manifest: $manifest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update connector builder project
#
# POST /v1/connector_builder_projects/update
# operationId: updateConnectorBuilderProject
# --builderProject shape: {name: string, draftManifest?: record, yamlManifest?: string, componentsFileContent?: string, baseActorDefinitionVersionId?: string, contributionPullRequestUrl?: string, contributionActorDefinitionId?: string}
export def "connector-builder-projects-update updateConnectorBuilderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProjectId: string # format: uuid
  builderProject: record # shape: {name: string, draftManifest?: record, yamlManifest?: string, componentsFileContent?: string, baseActorDefinitionVersionId?: string, contributionPullRequestUrl?: string, contributionActorDefinitionId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/update")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, builderProject: $builderProject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes connector builder project
#
# POST /v1/connector_builder_projects/delete
# operationId: deleteConnectorBuilderProject
export def "connector-builder-projects-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProjectId: string # format: uuid
  --version: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/delete")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List connector builder projects for workspace
#
# POST /v1/connector_builder_projects/list
# operationId: listConnectorBuilderProjects
export def "connector-builder-projects-list listConnectorBuilderProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<projects: table<name: string, builderProjectId: string, sourceDefinitionId: string, activeDeclarativeManifestVersion: int, hasDraft: bool, updatedAt: int, baseActorDefinitionVersionInfo: record, contributionInfo: record, componentsFileContent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/list")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connector builder project with draft manifest
#
# POST /v1/connector_builder_projects/get_with_manifest
# operationId: getConnectorBuilderProject
export def "connector-builder-projects-get-with-manifest post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProjectId: string # format: uuid
  --version: int # format: int64
]: any -> record<builderProject: record<name: string, builderProjectId: string, sourceDefinitionId: string, activeDeclarativeManifestVersion: int, hasDraft: bool, updatedAt: int, baseActorDefinitionVersionInfo: record<name: string, dockerRepository: string, dockerImageTag: string, actorDefinitionId: string, icon: string, documentationUrl: string>, contributionInfo: record<pullRequestUrl: string, actorDefinitionId: string>, componentsFileContent: string>, declarativeManifest: record<manifest: record, isDraft: bool, version: int, description: string>, testingValues: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/get_with_manifest")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connector builder project by source definition ID
#
# POST /v1/connector_builder_projects/get_for_definition_id
# operationId: getConnectorBuilderProjectIdForDefinitionId
export def "connector-builder-projects-get-for-definition-id post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  workspaceId: string # format: uuid
]: any -> record<builderProjectId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/get_for_definition_id")
  let body = {actorDefinitionId: $actorDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit a set of testing values to persist for a connector builder project
#
# POST /v1/connector_builder_projects/update_testing_values
# operationId: updateConnectorBuilderProjectTestingValues
export def "connector-builder-projects-update-testing-values updateConnectorBuilderProjectTestingValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProjectId: string # format: uuid
  spec: record # The specification for what values are required to configure the sourceDefinition. (e.g. {user: {type: string}})
  testingValues: record # The config blob containing the user inputs for testing
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/update_testing_values")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, spec: $spec, testingValues: $testingValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reads the target stream of the connector builder project using the persisted testing values
#
# POST /v1/connector_builder_projects/read_stream
# operationId: readConnectorBuilderProjectStream
export def "connector-builder-projects-read-stream readConnectorBuilderProjectStream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  builderProjectId: string # format: uuid
  manifest: record # Low code CDK manifest JSON object
  streamName: string # Name of the stream to read
  --customComponentsCode: string # Custom components python code to use during source execution
  --formGeneratedManifest: string@bool-completer # Indicates if the manifest was auto-generated from the form-based Connector Builder UI (default: false)
  --recordLimit: int # Maximum number of records that will be returned to the client from connector builder test reads (default: 1000)
  --pageLimit: int # Maximum number of pages that will be returned to the client from connector builder test reads (default: 5)
  --sliceLimit: int # Maximum number of slices that will be returned to the client from connector builder test reads (default: 5)
  --state: list
]: any -> record<logs: table<message: string, level: string, internal_message: string, stacktrace: string>, slices: table<pages: list, slice_descriptor: record, state: list, auxiliary_requests: list>, test_read_limit_reached: bool, auxiliary_requests: table<description: string, request: record, response: record, title: string, type: string>, inferred_schema: record, inferred_datetime_formats: record, latest_config_update: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/read_stream")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, manifest: $manifest, streamName: $streamName, customComponentsCode: $customComponentsCode, formGeneratedManifest: $formGeneratedManifest, recordLimit: $recordLimit, pageLimit: $pageLimit, sliceLimit: $sliceLimit, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a JSON manifest, returns a JSON manifest with all dynamic streams and all of the $refs and $parameters resolved and flattened
#
# POST /v1/connector_builder_projects/full_resolve
# operationId: fullResolveManifestBuilderProject
export def "connector-builder-projects-full-resolve fullResolveManifestBuilderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # format: uuid
  --builderProjectId: string # format: uuid
  --streamLimit: int # Maximum number of generated streams that will be returned to the client from connector builder test reads (default: 5)
  manifest: record # Low code CDK manifest JSON object
]: any -> record<manifest: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/full_resolve")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, streamLimit: $streamLimit, manifest: $manifest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a JSON manifest, returns a JSON manifest with all of the $refs and $parameters resolved and flattened
#
# POST /v1/connector_builder_projects/resolve
# operationId: resolveManifestBuilderProject
export def "connector-builder-projects-resolve resolveManifestBuilderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # format: uuid
  --builderProjectId: string # format: uuid
  manifest: record # Low code CDK manifest JSON object
]: any -> record<manifest: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/resolve")
  let body = {workspaceId: $workspaceId, builderProjectId: $builderProjectId, manifest: $manifest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connector builder capabilities
#
# POST /v1/connector_builder_projects/capabilities
# operationId: getConnectorBuilderCapabilities
export def "connector-builder-projects-capabilities post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<customCodeExecution: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/capabilities")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new builder project that is a fork of an existing source definition
#
# POST /v1/connector_builder_projects/fork
# operationId: createForkedConnectorBuilderProject
export def "connector-builder-projects-fork createForkedConnectorBuilderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  baseActorDefinitionId: string # format: uuid
]: any -> record<workspaceId: string, builderProjectId: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/fork")
  let body = {workspaceId: $workspaceId, baseActorDefinitionId: $baseActorDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Checks if a connector being contributed already exists
#
# POST /v1/connector_builder_projects/contribute/check
# operationId: checkContribution
export def "connector-builder-projects-contribute-check checkContribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connector_image_name: string # The id of the connector being submitted for contribution
]: any -> record<connector_name: string, connector_description: string, github_url: string, connector_exists: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/contribute/check")
  let body = {connector_image_name: $connector_image_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generates a connector module and pushes it to Github as a PR
#
# POST /v1/connector_builder_projects/contribute/generate
# operationId: generateContribution
export def "connector-builder-projects-contribute-generate generateContribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the connector being contributed, e.g. Google Sheets
  connector_image_name: string # The name of the connector module, e.g. source-google-sheets
  connector_description: string # Brief description of the connector and the API it integrates
  github_token: string # Github Personal Access Token that should be used to create the PR
  manifest_yaml: string # The connector manifest in YAML form
  --custom-components: string # (Optional) The file contents for any custom python CDK components
  base_image: string # The base image to use for the connector
  contribution_description: string # Message describing the content of the contribution, including any changes to the connector
]: any -> record<pull_request_url: string, actor_definition_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/contribute/generate")
  let body = {name: $name, connector_image_name: $connector_image_name, connector_description: $connector_description, github_token: $github_token, manifest_yaml: $manifest_yaml, custom_components: $custom_components, base_image: $base_image, contribution_description: $contribution_description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assist server access point
#
# POST /v1/connector_builder_assist/process
# operationId: assistV1Process
export def "connector-builder-assist-process assistV1Process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_assist/process")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assist server warming access point
#
# POST /v1/connector_builder_assist/warm
# operationId: assistV1Warm
export def "connector-builder-assist-warm assistV1Warm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_assist/warm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the documentation for a connector
#
# POST /v1/connector_documentation/get
# operationId: getConnectorDocumentation
export def "connector-documentation-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorType: string@actorType-completer
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  workspaceId: string # format: uuid
  --actorId: string # A unique identifier for an actor. (format: uuid)
]: any -> record<doc: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_documentation/get")
  let body = {actorType: $actorType, actorDefinitionId: $actorDefinitionId, workspaceId: $workspaceId, actorId: $actorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a source
#
# POST /v1/sources/create
# operationId: createSource
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "sources-create createSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  workspaceId: string # format: uuid
  name: string
  --secretId: string # e.g. airbyte_oauth_workspace_0509f049-d671-48cb-8105-0a23d47e6db6_secret_e0d38206-034e-4d75-9d21-da5a99b02826_v1
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/create")
  let body = {sourceDefinitionId: $sourceDefinitionId, connectionConfiguration: $connectionConfiguration, workspaceId: $workspaceId, name: $name, secretId: $secretId, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a source
#
# POST /v1/sources/update
# operationId: updateSource
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "sources-update updateSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
  connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  --secretId: string # e.g. airbyte_oauth_workspace_0509f049-d671-48cb-8105-0a23d47e6db6_secret_e0d38206-034e-4d75-9d21-da5a99b02826_v1
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/update")
  let body = {sourceId: $sourceId, connectionConfiguration: $connectionConfiguration, name: $name, secretId: $secretId, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a source
#
# POST /v1/sources/partial_update
# operationId: partialUpdateSource
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "sources-partial-update partialUpdateSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
  --connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --name: string
  --secretId: string # e.g. airbyte_oauth_workspace_0509f049-d671-48cb-8105-0a23d47e6db6_secret_e0d38206-034e-4d75-9d21-da5a99b02826_v1
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/partial_update")
  let body = {sourceId: $sourceId, connectionConfiguration: $connectionConfiguration, name: $name, secretId: $secretId, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrade a source to the latest version
#
# POST /v1/sources/upgrade_version
# operationId: upgradeSourceVersion
export def "sources-upgrade-version upgradeSourceVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/upgrade_version")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List sources for workspace
#
# POST /v1/sources/list
# operationId: listSourcesForWorkspace
# --filters shape: {states?: list, searchTerm?: string}
export def "sources-list listSourcesForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --cursor: string # format: uuid
  --sortKey: string@sortKey-completer # Available sort keys for actor list pagination
  --filters: record # shape: {states?: list, searchTerm?: string}
  --pageSize: int # Number of actors to return in the list
]: any -> record<sources: table<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record, supportState: string, status: string, createdAt: int, resourceAllocation: record, numConnections: int, lastSync: int, connectionJobStatuses: record>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/list")
  let body = {workspaceId: $workspaceId, cursor: $cursor, sortKey: $sortKey, filters: $filters, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List sources for workspace
#
# POST /v1/sources/list_paginated
# operationId: listSourcesForWorkspacePaginated
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "sources-list-paginated listSourcesForWorkspacePaginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceIds: list
  --includeDeleted: string@bool-completer # default: false
  pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --nameContains: string
]: any -> record<sources: table<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record, supportState: string, status: string, createdAt: int, resourceAllocation: record, numConnections: int, lastSync: int, connectionJobStatuses: record>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/list_paginated")
  let body = {workspaceIds: $workspaceIds, includeDeleted: $includeDeleted, pagination: $pagination, nameContains: $nameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get source
#
# POST /v1/sources/get
# operationId: getSource
export def "sources-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/get")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get source with metadata
#
# POST /v1/sources/get_with_metadata
# operationId: getSourceWithMetadata
export def "sources-get-with-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
  --includeSecretCoordinates: string@bool-completer # If true, the response will include secret coordinates in the connection configuration. (default: false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/get_with_metadata")
  let body = {sourceId: $sourceId, includeSecretCoordinates: $includeSecretCoordinates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get most recent ActorCatalog for source
#
# POST /v1/sources/most_recent_source_actor_catalog
# operationId: getMostRecentSourceActorCatalog
export def "sources-most-recent-source-actor-catalog post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> record<updatedAt: int, catalog: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/most_recent_source_actor_catalog")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search sources
#
# POST /v1/sources/search
# operationId: searchSources
export def "sources-search searchSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceDefinitionId: string # format: uuid
  --sourceId: string # format: uuid
  --workspaceId: string # format: uuid
  --connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --name: string
  --sourceName: string
]: any -> record<sources: table<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record, supportState: string, status: string, createdAt: int, resourceAllocation: record, numConnections: int, lastSync: int, connectionJobStatuses: record>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/search")
  let body = {sourceDefinitionId: $sourceDefinitionId, sourceId: $sourceId, workspaceId: $workspaceId, connectionConfiguration: $connectionConfiguration, name: $name, sourceName: $sourceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a source
#
# POST /v1/sources/delete
# operationId: deleteSource
export def "sources-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/delete")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check connection to the source
#
# POST /v1/sources/check_connection
# operationId: checkConnectionToSource
export def "sources-check-connection checkConnectionToSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
]: any -> record<status: string, message: string, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/check_connection")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check connection for a proposed update to a source
#
# POST /v1/sources/check_connection_for_update
# operationId: checkConnectionToSourceForUpdate
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "sources-check-connection-for-update checkConnectionToSourceForUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
  connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  --secretId: string # e.g. airbyte_oauth_workspace_0509f049-d671-48cb-8105-0a23d47e6db6_secret_e0d38206-034e-4d75-9d21-da5a99b02826_v1
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<status: string, message: string, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/check_connection_for_update")
  let body = {sourceId: $sourceId, connectionConfiguration: $connectionConfiguration, name: $name, secretId: $secretId, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discover the schema catalog of the source
#
# POST /v1/sources/discover_schema
# operationId: discoverSchemaForSource
export def "sources-discover-schema discoverSchemaForSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceId: string # format: uuid
  --connectionId: string # format: uuid
  --disable-cache: string@bool-completer
  --priority: string@priority-completer
]: any -> record<catalog: record<streams: list<record>>, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>, catalogId: string, catalogDiff: record<transforms: list<record>>, breakingChange: bool, connectionStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/discover_schema")
  let body = {sourceId: $sourceId, connectionId: $connectionId, disable_cache: $disable_cache, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Auto propagate the change on a catalog to a catalog saved in the DB. It will fetch all the connections linked to a source id and apply the provided diff to their catalog.
#
# POST /v1/sources/apply_schema_changes
# operationId: applySchemaChangeForSource
# --catalog shape: {streams: list}
export def "sources-apply-schema-changes applySchemaChangeForSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  catalog: record # describes the available schema (catalog). — shape: {streams: list}
  catalogId: string # format: uuid
  sourceId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/apply_schema_changes")
  let body = {catalog: $catalog, catalogId: $catalogId, sourceId: $sourceId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Should only be called from job pods, to write result from discover activity back to DB.
#
# POST /v1/sources/write_discover_catalog_result
# operationId: writeDiscoverCatalogResult
# --catalog shape: {streams: list}
export def "sources-write-discover-catalog-result writeDiscoverCatalogResult" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  catalog: record # describes the available schema (catalog). — shape: {streams: list}
  --sourceId: string # format: uuid
  --connectorVersion: string
  --configurationHash: string
]: any -> record<catalogId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/write_discover_catalog_result")
  let body = {catalog: $catalog, sourceId: $sourceId, connectorVersion: $connectorVersion, configurationHash: $configurationHash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Should only be called from job pods, to write result from destination discover activity back to DB.
#
# POST /v1/destinations/write_discover_catalog_result
# operationId: writeDestinationDiscoverCatalogResult
# --catalog shape: {operations: list}
export def "destinations-write-discover-catalog-result writeDestinationDiscoverCatalogResult" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  catalog: record # shape: {operations: list}
  --destinationId: string # format: uuid
  --connectorVersion: string
  --configurationHash: string
]: any -> record<catalogId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/write_discover_catalog_result")
  let body = {catalog: $catalog, destinationId: $destinationId, connectorVersion: $connectorVersion, configurationHash: $configurationHash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update destinationDefinition
#
# POST /v1/destination_definitions/update
# operationId: updateDestinationDefinition
# --resourceRequirements shape: {default?: record, jobSpecific?: list}
export def "destination-definitions-update updateDestinationDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  destinationDefinitionId: string # format: uuid
  dockerImageTag: string
  --resourceRequirements: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/update")
  let body = {name: $name, destinationDefinitionId: $destinationDefinitionId, dockerImageTag: $dockerImageTag, resourceRequirements: $resourceRequirements, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the destinationDefinitions the current Airbyte deployment is configured to use
#
# POST /v1/destination_definitions/list
# operationId: listDestinationDefinitions
export def "destination-definitions-list listDestinationDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<destinationDefinitions: table<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the latest destinationDefinitions Airbyte supports
#
# POST /v1/destination_definitions/list_latest
# operationId: listLatestDestinationDefinitions
export def "destination-definitions-list-latest listLatestDestinationDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<destinationDefinitions: table<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get destinationDefinition
#
# POST /v1/destination_definitions/get
# operationId: getDestinationDefinition
export def "destination-definitions-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
]: any -> record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get")
  let body = {destinationDefinitionId: $destinationDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a destination definition
#
# POST /v1/destination_definitions/delete
# operationId: deleteDestinationDefinition
export def "destination-definitions-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/delete")
  let body = {destinationDefinitionId: $destinationDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all private, non-custom destinationDefinitions, and for each indicate whether the given workspace has a grant for using the definition. Used by admins to view and modify a given workspace's grants.
#
# POST /v1/destination_definitions/list_private
# operationId: listPrivateDestinationDefinitions
export def "destination-definitions-list-private listPrivateDestinationDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<destinationDefinitions: table<destinationDefinition: record, granted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_private")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the destinationDefinitions the given workspace is configured to use
#
# POST /v1/destination_definitions/list_for_workspace
# operationId: listDestinationDefinitionsForWorkspace
export def "destination-definitions-list-for-workspace listDestinationDefinitionsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
  --filterByUsed: string@bool-completer # default: false
]: any -> record<destinationDefinitions: table<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_for_workspace")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone, filterByUsed: $filterByUsed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all enterprise destination connector stubs for a specified workspace.
#
# POST /v1/destination_definitions/list_enterprise_stubs_for_workspace
# operationId: listEnterpriseDestinationStubsForWorkspace
export def "destination-definitions-list-enterprise-stubs-for-workspace listEnterpriseDestinationStubsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<enterpriseConnectorStubs: table<id: string, definitionId: string, name: string, url: string, icon: string, label: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_enterprise_stubs_for_workspace")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a custom destinationDefinition for the given workspace
#
# POST /v1/destination_definitions/create_custom
# operationId: createCustomDestinationDefinition
# --destinationDefinition shape: {name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon?: string, resourceRequirements?: record, connectorSpecification?: record}
export def "destination-definitions-create-custom createCustomDestinationDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # format: uuid
  destinationDefinition: record # shape: {name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon?: string, resourceRequirements?: record, connectorSpecification?: record}
  --scopeId: string # format: uuid
  --scopeType: string@scopeType-completer
]: any -> record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/create_custom")
  let body = {workspaceId: $workspaceId, destinationDefinition: $destinationDefinition, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a destinationDefinition that is configured for the given workspace
#
# POST /v1/destination_definitions/get_for_workspace
# operationId: getDestinationDefinitionForWorkspace
export def "destination-definitions-get-for-workspace post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get_for_workspace")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a destinationDefinition that is configured for the given scope
#
# POST /v1/destination_definitions/get_for_scope
# operationId: getDestinationDefinitionForScope
export def "destination-definitions-get-for-scope post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  scopeId: string # format: uuid
  scopeType: string@scopeType-completer
]: any -> record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get_for_scope")
  let body = {actorDefinitionId: $actorDefinitionId, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# grant a private, non-custom destinationDefinition to a given workspace or organization
#
# POST /v1/destination_definitions/grant_definition
# operationId: grantDestinationDefinition
export def "destination-definitions-grant-definition grantDestinationDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  scopeId: string # format: uuid
  scopeType: string@scopeType-completer
]: any -> record<destinationDefinition: record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record<default: record, jobSpecific: list>, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool>, granted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/grant_definition")
  let body = {actorDefinitionId: $actorDefinitionId, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# revoke a grant to a private, non-custom destinationDefinition from a given workspace or organization
#
# POST /v1/destination_definitions/revoke_definition
# operationId: revokeDestinationDefinition
export def "destination-definitions-revoke-definition revokeDestinationDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  scopeId: string # format: uuid
  scopeType: string@scopeType-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/revoke_definition")
  let body = {actorDefinitionId: $actorDefinitionId, scopeId: $scopeId, scopeType: $scopeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get actor definition version for a destination.
#
# POST /v1/actor_definition_versions/get_for_destination
# operationId: getActorDefinitionVersionForDestinationId
export def "actor-definition-versions-get-for-destination post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
]: any -> record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/actor_definition_versions/get_for_destination")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specification for a destinationDefinition
#
# POST /v1/destination_definition_specifications/get
# operationId: getDestinationDefinitionSpecification
export def "destination-definition-specifications-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitionId: string, documentationUrl: string, connectionSpecification: record, advancedAuth: record<authFlowType: string, predicateKey: list<string>, predicateValue: string, oauthConfigSpecification: record<oauthUserInputFromConnectorConfigSpecification: any, completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any>>, advancedAuthGlobalCredentialsAvailable: bool, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>, supportedDestinationSyncModes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definition_specifications/get")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specification for a destination
#
# POST /v1/destination_definition_specifications/get_for_destination
# operationId: getSpecificationForDestinationId
export def "destination-definition-specifications-get-for-destination post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
]: any -> record<destinationDefinitionId: string, documentationUrl: string, connectionSpecification: record, advancedAuth: record<authFlowType: string, predicateKey: list<string>, predicateValue: string, oauthConfigSpecification: record<oauthUserInputFromConnectorConfigSpecification: any, completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any>>, advancedAuthGlobalCredentialsAvailable: bool, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>, supportedDestinationSyncModes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definition_specifications/get_for_destination")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a destination
#
# POST /v1/destinations/create
# operationId: createDestination
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "destinations-create createDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  name: string
  destinationDefinitionId: string # format: uuid
  connectionConfiguration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/create")
  let body = {workspaceId: $workspaceId, name: $name, destinationDefinitionId: $destinationDefinitionId, connectionConfiguration: $connectionConfiguration, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a destination
#
# POST /v1/destinations/update
# operationId: updateDestination
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "destinations-update updateDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
  connectionConfiguration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  name: string
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/update")
  let body = {destinationId: $destinationId, connectionConfiguration: $connectionConfiguration, name: $name, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a destination partially
#
# POST /v1/destinations/partial_update
# operationId: partialUpdateDestination
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "destinations-partial-update partialUpdateDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationId: string # format: uuid
  --connectionConfiguration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --name: string
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/partial_update")
  let body = {destinationId: $destinationId, connectionConfiguration: $connectionConfiguration, name: $name, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrade a destination to the latest version
#
# POST /v1/destinations/upgrade_version
# operationId: upgradeDestinationVersion
export def "destinations-upgrade-version upgradeDestinationVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/upgrade_version")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List configured destinations for a workspace
#
# POST /v1/destinations/list
# operationId: listDestinationsForWorkspace
# --filters shape: {states?: list, searchTerm?: string}
export def "destinations-list listDestinationsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --cursor: string # format: uuid
  --sortKey: string@sortKey-completer # Available sort keys for actor list pagination
  --filters: record # shape: {states?: list, searchTerm?: string}
  --pageSize: int # Number of actors to return in the list
]: any -> record<destinations: table<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record, supportState: string, status: string, createdAt: int, resourceAllocation: record, numConnections: int, lastSync: int, connectionJobStatuses: record>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/list")
  let body = {workspaceId: $workspaceId, cursor: $cursor, sortKey: $sortKey, filters: $filters, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List configured destinations for a workspace. Pginated
#
# POST /v1/destinations/list_paginated
# operationId: listDestinationsForWorkspacesPaginated
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "destinations-list-paginated listDestinationsForWorkspacesPaginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceIds: list
  --includeDeleted: string@bool-completer # default: false
  pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --nameContains: string
]: any -> record<destinations: table<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record, supportState: string, status: string, createdAt: int, resourceAllocation: record, numConnections: int, lastSync: int, connectionJobStatuses: record>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/list_paginated")
  let body = {workspaceIds: $workspaceIds, includeDeleted: $includeDeleted, pagination: $pagination, nameContains: $nameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get configured destination
#
# POST /v1/destinations/get
# operationId: getDestination
export def "destinations-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
]: any -> record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list<record>, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>, numConnections: int, lastSync: int, connectionJobStatuses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/get")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discover the catalog for a destination
#
# POST /v1/destinations/discover_schema
# operationId: discoverCatalogForDestination
export def "destinations-discover-schema discoverCatalogForDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
  --disableCache: string@bool-completer
]: any -> record<catalog: record<operations: list<record>>, catalogId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/discover_schema")
  let body = {destinationId: $destinationId, disableCache: $disableCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the destination catalog for a connection
#
# POST /v1/destinations/get_catalog_for_connection
# operationId: getCatalogForConnection
export def "destinations-get-catalog-for-connection post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<catalog: record<operations: list<record>>, catalogId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/get_catalog_for_connection")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search destinations
#
# POST /v1/destinations/search
# operationId: searchDestinations
export def "destinations-search searchDestinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationDefinitionId: string # format: uuid
  --destinationId: string # format: uuid
  --workspaceId: string # format: uuid
  --connectionConfiguration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --name: string
  --destinationName: string
]: any -> record<destinations: table<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record, supportState: string, status: string, createdAt: int, resourceAllocation: record, numConnections: int, lastSync: int, connectionJobStatuses: record>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/search")
  let body = {destinationDefinitionId: $destinationDefinitionId, destinationId: $destinationId, workspaceId: $workspaceId, connectionConfiguration: $connectionConfiguration, name: $name, destinationName: $destinationName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check connection to the destination
#
# POST /v1/destinations/check_connection
# operationId: checkConnectionToDestination
export def "destinations-check-connection checkConnectionToDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
]: any -> record<status: string, message: string, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/check_connection")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check connection for a proposed update to a destination
#
# POST /v1/destinations/check_connection_for_update
# operationId: checkConnectionToDestinationForUpdate
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "destinations-check-connection-for-update checkConnectionToDestinationForUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
  connectionConfiguration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  name: string
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<status: string, message: string, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/check_connection_for_update")
  let body = {destinationId: $destinationId, connectionConfiguration: $connectionConfiguration, name: $name, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the destination
#
# POST /v1/destinations/delete
# operationId: deleteDestination
export def "destinations-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/delete")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a connection between a source and a destination
#
# POST /v1/connections/create
# operationId: createConnection
# --syncCatalog shape: {streams: list}
# --schedule shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --resourceRequirements shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
# --tags item shape: {tagId: string, workspaceId: string, name: string, color: string}
export def "connections-create createConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Optional name of the connection
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  sourceId: string # format: uuid
  destinationId: string # format: uuid
  --operationIds: list
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
  --schedule: record # if null, then no schedule is set. — shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. Locked means the connection is temporarily disabled due to external factors (e.g., payment issues). The schema field describes the elements of the schema that will be synced.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
  --sourceCatalogId: string # format: uuid
  --destinationCatalogId: string # format: uuid
  --dataplaneGroupId: string # format: uuid
  --notifySchemaChanges: string@bool-completer
  --notifySchemaChangesByEmail: string@bool-completer
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --backfillPreference: string@backfillPreference-completer
  --tags: list # item shape: {tagId: string, workspaceId: string, name: string, color: string}
  --onDemandEnabled: string@bool-completer # When enabled, this connection will use on-demand capacity if committed capacity is exhausted (default: false)
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list<string>, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/create")
  let body = {name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, sourceId: $sourceId, destinationId: $destinationId, operationIds: $operationIds, syncCatalog: $syncCatalog, schedule: $schedule, scheduleType: $scheduleType, scheduleData: $scheduleData, status: $status, resourceRequirements: $resourceRequirements, sourceCatalogId: $sourceCatalogId, destinationCatalogId: $destinationCatalogId, dataplaneGroupId: $dataplaneGroupId, notifySchemaChanges: $notifySchemaChanges, notifySchemaChangesByEmail: $notifySchemaChangesByEmail, nonBreakingChangesPreference: $nonBreakingChangesPreference, backfillPreference: $backfillPreference, tags: $tags, onDemandEnabled: $onDemandEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a connection
#
# POST /v1/connections/update
# operationId: updateConnection
# --syncCatalog shape: {streams: list}
# --schedule shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --resourceRequirements shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
# --tags item shape: {tagId: string, workspaceId: string, name: string, color: string}
export def "connections-update updateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --name: string # Name that will be set to this connection
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --operationIds: list # nullable
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
  --schedule: record # if null, then no schedule is set. — shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. Locked means the connection is temporarily disabled due to external factors (e.g., payment issues). The schema field describes the elements of the schema that will be synced.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
  --sourceCatalogId: string # format: uuid
  --destinationCatalogId: string # format: uuid
  --dataplaneGroupId: string # format: uuid
  --notifySchemaChanges: string@bool-completer
  --notifySchemaChangesByEmail: string@bool-completer
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --backfillPreference: string@backfillPreference-completer
  --breakingChange: string@bool-completer
  --tags: list # nullable — item shape: {tagId: string, workspaceId: string, name: string, color: string}
  --onDemandEnabled: string@bool-completer # When enabled, this connection will use on-demand capacity if committed capacity is exhausted
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list<string>, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/update")
  let body = {connectionId: $connectionId, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, name: $name, prefix: $prefix, operationIds: $operationIds, syncCatalog: $syncCatalog, schedule: $schedule, scheduleType: $scheduleType, scheduleData: $scheduleData, status: $status, resourceRequirements: $resourceRequirements, sourceCatalogId: $sourceCatalogId, destinationCatalogId: $destinationCatalogId, dataplaneGroupId: $dataplaneGroupId, notifySchemaChanges: $notifySchemaChanges, notifySchemaChangesByEmail: $notifySchemaChangesByEmail, nonBreakingChangesPreference: $nonBreakingChangesPreference, backfillPreference: $backfillPreference, breakingChange: $breakingChange, tags: $tags, onDemandEnabled: $onDemandEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a connection with reason
#
# POST /v1/connections/update_with_reason
# operationId: updateConnectionWithReason
# --connectionUpdate shape: {connectionId: string, namespaceDefinition?: "source"|"destination"|"customformat", namespaceFormat?: string, name?: string, prefix?: string, operationIds?: list, syncCatalog?: record, schedule?: record, scheduleType?: "manual"|"basic"|"cron", scheduleData?: record, status?: "active"|"inactive"|"deprecated"|"locked", resourceRequirements?: record, sourceCatalogId?: string, destinationCatalogId?: string, dataplaneGroupId?: string, notifySchemaChanges?: bool, notifySchemaChangesByEmail?: bool, nonBreakingChangesPreference?: "ignore"|"disable"|"propagate_columns"|"propagate_fully", backfillPreference?: "enabled"|"disabled", breakingChange?: bool, tags?: list, onDemandEnabled?: bool}
export def "connections-update-with-reason updateConnectionWithReason" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionUpdate: record # Used to apply a patch-style update to a connection, which means that null properties remain unchanged — shape: {connectionId: string, namespaceDefinition?: "source"|"destination"|"customformat", namespaceFormat?: string, name?: string, prefix?: string, operationIds?: list, syncCatalog?: record, schedule?: record, scheduleType?: "manual"|"basic"|"cron", scheduleData?: record, status?: "active"|"inactive"|"deprecated"|"locked", resourceRequirements?: record, sourceCatalogId?: string, destinationCatalogId?: string, dataplaneGroupId?: string, notifySchemaChanges?: bool, notifySchemaChangesByEmail?: bool, nonBreakingChangesPreference?: "ignore"|"disable"|"propagate_columns"|"propagate_fully", backfillPreference?: "enabled"|"disabled", breakingChange?: bool, tags?: list, onDemandEnabled?: bool}
  --updateReason: string
  --autoUpdate: string@bool-completer # default: false
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list<string>, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/update_with_reason")
  let body = {connectionUpdate: $connectionUpdate, updateReason: $updateReason, autoUpdate: $autoUpdate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all connections for a workspace.
#
# POST /v1/connections/list
# operationId: listConnectionsForWorkspace
export def "connections-list listConnectionsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<connections: table<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list, syncCatalog: record, schedule: record, scheduleType: string, scheduleData: record, status: string, statusReason: string, resourceRequirements: record, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: list, onDemandEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all connections for a workspace. Paginated.
#
# POST /v1/connections/list_paginated
# operationId: listConnectionsForWorkspacesPaginated
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "connections-list-paginated listConnectionsForWorkspacesPaginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceIds: list
  userId: string # format: uuid
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --includeDeleted: string@bool-completer # default: false
  --tagIds: list
]: any -> record<connections: table<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list, syncCatalog: record, schedule: record, scheduleType: string, scheduleData: record, status: string, statusReason: string, resourceRequirements: record, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: list, onDemandEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list_paginated")
  let body = {workspaceIds: $workspaceIds, userId: $userId, pagination: $pagination, includeDeleted: $includeDeleted, tagIds: $tagIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all connections for a workspace, including deleted connections.
#
# POST /v1/connections/list_all
# operationId: listAllConnectionsForWorkspace
export def "connections-list-all listAllConnectionsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<connections: table<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list, syncCatalog: record, schedule: record, scheduleType: string, scheduleData: record, status: string, statusReason: string, resourceRequirements: record, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: list, onDemandEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list_all")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of multiple connections
#
# POST /v1/connections/status
# operationId: getConnectionStatuses
export def "connections-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionIds: list
]: any -> table<connectionId: string, connectionSyncStatus: string, scheduleData: record<basicSchedule: record, cron: record>, lastSuccessfulSync: int, activeJob: record<id: int, configType: string, configId: string, enabledStreams: list, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record, refreshConfig: record, aggregatedStats: record, streamAggregatedStats: list>, lastSyncJobId: int, lastSyncAttemptNumber: int, lastSyncJobCreatedAt: int, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/status")
  let body = {connectionIds: $connectionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get progress information of the current sync of a connection
#
# POST /v1/connections/sync_progress
# operationId: getConnectionSyncProgress
export def "connections-sync-progress post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<connectionId: string, jobId: int, streams: table<streamName: string, streamNamespace: string, recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int, configType: string>, recordsEmitted: int, recordsCommitted: int, recordsRejected: int, bytesEmitted: int, bytesCommitted: int, syncStartedAt: int, configType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/sync_progress")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the uptime history of a connection
#
# POST /v1/connections/history/uptime
# operationId: getConnectionUptimeHistory
export def "connections-history-uptime post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  --numberOfJobs: int
]: any -> table<jobId: int, jobCreatedAt: int, jobUpdatedAt: int, streamStatuses: list<record>, configType: string, recordsEmitted: int, recordsCommitted: int, bytesEmitted: int, bytesCommitted: int, recordsRejected: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/history/uptime")
  let body = {connectionId: $connectionId, numberOfJobs: $numberOfJobs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the data history of a connection
#
# POST /v1/connections/history/data
# operationId: getConnectionDataHistory
export def "connections-history-data post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  numberOfJobs: int
]: any -> table<jobId: int, jobCreatedAt: int, jobUpdatedAt: int, streamStatuses: list<record>, configType: string, recordsEmitted: int, recordsCommitted: int, bytesEmitted: int, bytesCommitted: int, recordsRejected: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/history/data")
  let body = {connectionId: $connectionId, numberOfJobs: $numberOfJobs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the history of a connection
#
# POST /v1/connections/stream_history
# operationId: getConnectionStreamHistory
export def "connections-stream-history post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  timezone: string
]: any -> table<timestamp: int, streamName: string, streamNamespace: string, recordsCommitted: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/stream_history")
  let body = {connectionId: $connectionId, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single event (including details) in a connection by given event ID
#
# POST /v1/connections/events/get
# operationId: getConnectionEvent
export def "connections-events-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionEventId: string # format: UUID
  connectionId: string # format: uuid
]: any -> record<id: string, connectionId: string, eventType: string, summary: record, details: record, createdAt: int, user: record<id: string, email: string, name: string, isDeleted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/events/get")
  let body = {connectionEventId: $connectionEventId, connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List most recent events in a connection (optional filters may apply)
#
# POST /v1/connections/events/list
# operationId: listConnectionEvents
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "connections-events-list listConnectionEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  --eventTypes: list # filter events by event types (optional)
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --createdAtStart: string # The start datetime of a time range to filter by (format: date-time)
  --createdAtEnd: string # The end datetime of a time range to filter by (format: date-time)
]: any -> record<events: table<id: string, connectionId: string, eventType: string, summary: record, createdAt: int, user: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/events/list")
  let body = {connectionId: $connectionId, eventTypes: $eventTypes, pagination: $pagination, createdAtStart: $createdAtStart, createdAtEnd: $createdAtEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all events in a given time span in a minimal representation
#
# POST /v1/connections/events/list_minimal
# operationId: listConnectionEventsMinimal
export def "connections-events-list-minimal listConnectionEventsMinimal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  eventTypes: list # filter events by event types
  createdAtStart: string # The start datetime of a time range to filter by (format: date-time)
  createdAtEnd: string # The end datetime of a time range to filter by (format: date-time)
]: any -> record<events: table<eventId: string, connectionName: string, connectionId: string, createdAt: string, eventType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/events/list_minimal")
  let body = {workspaceId: $workspaceId, eventTypes: $eventTypes, createdAtStart: $createdAtStart, createdAtEnd: $createdAtEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Backfill events for a connection
#
# POST /v1/connections/events/backfill
# operationId: backfillConnectionEvents
export def "connections-events-backfill backfillConnectionEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  createdAtStart: string # The start datetime of a time range to backfill events (format: date-time)
  createdAtEnd: string # The end datetime of a time range to backfill events (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/events/backfill")
  let body = {connectionId: $connectionId, createdAtStart: $createdAtStart, createdAtEnd: $createdAtEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all connection events for a given job
#
# POST /v1/connections/events/list_for_job
# operationId: listConnectionEventsForJob
export def "connections-events-list-for-job listConnectionEventsForJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<events: table<id: string, connectionId: string, eventType: string, summary: record, createdAt: int, user: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/events/list_for_job")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a summary of the last completed job for each indicated stream in the connection.
#
# POST /v1/connections/last_job_per_stream
# operationId: getConnectionLastJobPerStream
export def "connections-last-job-per-stream post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> table<streamName: string, streamNamespace: string, jobId: int, configType: string, jobStatus: string, recordsCommitted: int, bytesCommitted: int, startedAt: int, endedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/last_job_per_stream")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection
#
# POST /v1/connections/get
# operationId: getConnection
export def "connections-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list<string>, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/get")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection for a given jobId
#
# POST /v1/connections/getForJob
# operationId: getConnectionForJob
export def "connections-get-for-job post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  jobId: int # format: int64
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list<string>, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/getForJob")
  let body = {connectionId: $connectionId, jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all connections that use the provided actor definition
#
# POST /v1/connections/list_by_actor_definition
# operationId: listConnectionsByActorDefinition
export def "connections-list-by-actor-definition listConnectionsByActorDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorDefinitionId: string # A unique identifier for an actor definition. (format: uuid)
  actorType: string@actorType-completer
]: any -> record<connections: table<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list, syncCatalog: record, schedule: record, scheduleType: string, scheduleData: record, status: string, statusReason: string, resourceRequirements: record, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: list, onDemandEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list_by_actor_definition")
  let body = {actorDefinitionId: $actorDefinitionId, actorType: $actorType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Auto propagate the change on a catalog to a catalog saved in the DB for the given connection.
#
# POST /v1/connections/apply_schema_changes
# operationId: applySchemaChangeForConnection
# --catalog shape: {streams: list}
export def "connections-apply-schema-changes applySchemaChangeForConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  catalog: record # describes the available schema (catalog). — shape: {streams: list}
  catalogId: string # format: uuid
  connectionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/apply_schema_changes")
  let body = {catalog: $catalog, catalogId: $catalogId, connectionId: $connectionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate the diff between stored catalog for the connection and catalog provided and postprocess as necessary
#
# POST /v1/connections/postprocess_discovered_catalog
# operationId: postprocessDiscoveredCatalogForConnection
export def "connections-postprocess-discovered-catalog postprocessDiscoveredCatalogForConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  catalogId: string # format: uuid
  connectionId: string # format: uuid
]: any -> record<appliedDiff: record<transforms: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/postprocess_discovered_catalog")
  let body = {catalogId: $catalogId, connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the domain ids for all objects related to a connection.
#
# POST /v1/connections/get_context
# operationId: getConnectionContext
export def "connections-get-context post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<connectionId: string, sourceId: string, destinationId: string, sourceDefinitionId: string, destinationDefinitionId: string, workspaceId: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/get_context")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch the current state for a connection.
#
# POST /v1/state/get
# operationId: getState
export def "state-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<stateType: string, connectionId: string, state: record, streamState: table<streamDescriptor: record, streamState: record>, globalState: record<shared_state: record, streamStates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/get")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update the state for a connection.
#
# POST /v1/state/create_or_update
# operationId: createOrUpdateState
# --connectionState shape: {stateType: "global"|"stream"|"legacy"|"not_set", connectionId: string, state?: record, streamState?: list, globalState?: record}
export def "state-create-or-update createOrUpdateState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  connectionState: record # Contains the state for a connection. The stateType field identifies what type of state it is. Only the field corresponding to that type will be set, the rest will be null. If stateType=not_set, then none of the fields will be set. — shape: {stateType: "global"|"stream"|"legacy"|"not_set", connectionId: string, state?: record, streamState?: list, globalState?: record}
]: any -> record<stateType: string, connectionId: string, state: record, streamState: table<streamDescriptor: record, streamState: record>, globalState: record<shared_state: record, streamStates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/create_or_update")
  let body = {connectionId: $connectionId, connectionState: $connectionState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update the state for a connection. Throws error if a sync is currently running when this is called.
#
# POST /v1/state/create_or_update_safe
# operationId: createOrUpdateStateSafe
# --connectionState shape: {stateType: "global"|"stream"|"legacy"|"not_set", connectionId: string, state?: record, streamState?: list, globalState?: record}
export def "state-create-or-update-safe createOrUpdateStateSafe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  connectionState: record # Contains the state for a connection. The stateType field identifies what type of state it is. Only the field corresponding to that type will be set, the rest will be null. If stateType=not_set, then none of the fields will be set. — shape: {stateType: "global"|"stream"|"legacy"|"not_set", connectionId: string, state?: record, streamState?: list, globalState?: record}
]: any -> record<stateType: string, connectionId: string, state: record, streamState: table<streamDescriptor: record, streamState: record>, globalState: record<shared_state: record, streamStates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/create_or_update_safe")
  let body = {connectionId: $connectionId, connectionState: $connectionState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search connections
#
# POST /v1/connections/search
# operationId: searchConnections
# --schedule shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --source shape: {sourceDefinitionId?: string, sourceId?: string, workspaceId?: string, connectionConfiguration?: record, name?: string, sourceName?: string}
# --destination shape: {destinationDefinitionId?: string, destinationId?: string, workspaceId?: string, connectionConfiguration?: record, name?: string, destinationName?: string}
export def "connections-search searchConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectionId: string # format: uuid
  --name: string
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --sourceId: string # format: uuid
  --destinationId: string # format: uuid
  --schedule: record # if null, then no schedule is set. — shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. Locked means the connection is temporarily disabled due to external factors (e.g., payment issues). The schema field describes the elements of the schema that will be synced.
  --body-source: record # shape: {sourceDefinitionId?: string, sourceId?: string, workspaceId?: string, connectionConfiguration?: record, name?: string, sourceName?: string}
  --destination: record # shape: {destinationDefinitionId?: string, destinationId?: string, workspaceId?: string, connectionConfiguration?: record, name?: string, destinationName?: string}
]: any -> record<connections: table<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, operationIds: list, syncCatalog: record, schedule: record, scheduleType: string, scheduleData: record, status: string, statusReason: string, resourceRequirements: record, sourceCatalogId: string, destinationCatalogId: string, breakingChange: bool, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, created_at: int, backfillPreference: string, workspaceId: string, dataplaneGroupId: string, tags: list, onDemandEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/search")
  let body = {connectionId: $connectionId, name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, sourceId: $sourceId, destinationId: $destinationId, schedule: $schedule, scheduleType: $scheduleType, scheduleData: $scheduleData, status: $status, source: $body_source, destination: $destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a connection
#
# POST /v1/connections/delete
# operationId: deleteConnection
export def "connections-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/delete")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger a manual sync of the connection
#
# POST /v1/connections/sync
# operationId: syncConnection
export def "connections-sync syncConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/sync")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the data for the connection. Deletes data generated by the connection in the destination. Resets any cursors back to initial state.
#
# POST /v1/connections/reset
# operationId: resetConnection
export def "connections-reset resetConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/reset")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear the data for the connection. Deletes data generated by the connection in the destination. Clear any cursors back to initial state.
#
# POST /v1/connections/clear
# operationId: clearConnection
export def "connections-clear clearConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/clear")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets connection to inactive if it has met any of the auto-disable conditions (i.e. it hits the max number of consecutive job failures or if it hits the max number of days with only failed jobs). Additionally, notifications will be sent if a connection is disabled or warned if it has reached halfway to disable limits. This endpoint is only able to inactivate connections with more than one non-cancelled job.
#
# POST /v1/connections/auto_disable
# operationId: autoDisableConnection
export def "connections-auto-disable autoDisableConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/auto_disable")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear the data for a specific stream in the connection. Deletes data generated by the stream in the destination. Clear any cursors back to initial state.
#
# POST /v1/connections/clear/stream
# operationId: clearConnectionStream
# --streams item shape: {streamName: string, streamNamespace?: string}
export def "connections-clear-stream clearConnectionStream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  streams: list # item shape: {streamName: string, streamNamespace?: string}
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/clear/stream")
  let body = {connectionId: $connectionId, streams: $streams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the data for a specific stream in the connection. Deletes data generated by the stream in the destination. Resets any cursors back to initial state.
#
# POST /v1/connections/reset/stream
# operationId: resetConnectionStream
# --streams item shape: {streamName: string, streamNamespace?: string}
export def "connections-reset-stream resetConnectionStream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  streams: list # item shape: {streamName: string, streamNamespace?: string}
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/reset/stream")
  let body = {connectionId: $connectionId, streams: $streams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# refresh the data for specific streams in the connection. If no stream is specify or the list of stream is empy, all the streams will be refreshed. Resets any cursors back to initial state.
#
# POST /v1/connections/refresh
# operationId: refreshConnectionStream
# --streams item shape: {streamName: string, streamNamespace?: string}
export def "connections-refresh refreshConnectionStream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  refreshMode: string@refreshMode-completer
  --streams: list # item shape: {streamName: string, streamNamespace?: string}
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/refresh")
  let body = {connectionId: $connectionId, refreshMode: $refreshMode, streams: $streams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if an operation to be created is valid
#
# POST /v1/operations/check
# operationId: checkOperation
# --webhook shape: {webhookConfigId?: string, webhookType?: "dbtCloud", dbtCloud?: record, executionUrl?: string, executionBody?: string}
export def "operations-check checkOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operatorType: string@operatorType-completer
  --webhook: record # shape: {webhookConfigId?: string, webhookType?: "dbtCloud", dbtCloud?: record, executionUrl?: string, executionBody?: string}
]: any -> record<status: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/check")
  let body = {operatorType: $operatorType, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an operation to be applied as part of a connection pipeline
#
# POST /v1/operations/create
# operationId: createOperation
# --operatorConfiguration shape: {operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
export def "operations-create createOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  name: string
  operatorConfiguration: record # shape: {operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
]: any -> record<workspaceId: string, operationId: string, name: string, operatorConfiguration: record<operatorType: string, webhook: record<webhookConfigId: string, webhookType: string, dbtCloud: record, executionUrl: string, executionBody: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/create")
  let body = {workspaceId: $workspaceId, name: $name, operatorConfiguration: $operatorConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an operation
#
# POST /v1/operations/update
# operationId: updateOperation
# --operatorConfiguration shape: {operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
export def "operations-update updateOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operationId: string # format: uuid
  name: string
  operatorConfiguration: record # shape: {operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
]: any -> record<workspaceId: string, operationId: string, name: string, operatorConfiguration: record<operatorType: string, webhook: record<webhookConfigId: string, webhookType: string, dbtCloud: record, executionUrl: string, executionBody: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/update")
  let body = {operationId: $operationId, name: $name, operatorConfiguration: $operatorConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all operations for a connection.
#
# POST /v1/operations/list
# operationId: listOperationsForConnection
export def "operations-list listOperationsForConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<operations: table<workspaceId: string, operationId: string, name: string, operatorConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/list")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns an operation
#
# POST /v1/operations/get
# operationId: getOperation
export def "operations-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operationId: string # format: uuid
]: any -> record<workspaceId: string, operationId: string, name: string, operatorConfiguration: record<operatorType: string, webhook: record<webhookConfigId: string, webhookType: string, dbtCloud: record, executionUrl: string, executionBody: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/get")
  let body = {operationId: $operationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an operation
#
# POST /v1/operations/delete
# operationId: deleteOperation
export def "operations-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/delete")
  let body = {operationId: $operationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run check connection for a given source configuration
#
# POST /v1/scheduler/sources/check_connection
# operationId: executeSourceCheckConnection
export def "scheduler-sources-check-connection executeSourceCheckConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceId: string # format: uuid
  sourceDefinitionId: string # format: uuid
  connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  workspaceId: string # format: uuid
]: any -> record<status: string, message: string, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/sources/check_connection")
  let body = {sourceId: $sourceId, sourceDefinitionId: $sourceDefinitionId, connectionConfiguration: $connectionConfiguration, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run discover schema for a given source a source configuration
#
# POST /v1/scheduler/sources/discover_schema
# operationId: executeSourceDiscoverSchema
export def "scheduler-sources-discover-schema executeSourceDiscoverSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceId: string # format: uuid
  sourceDefinitionId: string # format: uuid
  connectionConfiguration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  workspaceId: string # format: uuid
]: any -> record<catalog: record<streams: list<record>>, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>, catalogId: string, catalogDiff: record<transforms: list<record>>, breakingChange: bool, connectionStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/sources/discover_schema")
  let body = {sourceId: $sourceId, sourceDefinitionId: $sourceDefinitionId, connectionConfiguration: $connectionConfiguration, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run check connection for a given destination configuration
#
# POST /v1/scheduler/destinations/check_connection
# operationId: executeDestinationCheckConnection
export def "scheduler-destinations-check-connection executeDestinationCheckConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationId: string # format: uuid
  destinationDefinitionId: string # format: uuid
  connectionConfiguration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  workspaceId: string # format: uuid
]: any -> record<status: string, message: string, jobInfo: record<id: string, configType: string, configId: string, createdAt: int, endedAt: int, succeeded: bool, connectorConfigurationUpdated: bool, logType: string, logs: any, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/destinations/check_connection")
  let body = {destinationId: $destinationId, destinationDefinitionId: $destinationDefinitionId, connectionConfiguration: $connectionConfiguration, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets instancewide variables to be used for the oauth flow when creating this source. When set, these variables will be injected into a connector's configuration before any interaction with the connector image itself. This enables running oauth flows with consistent variables e.g: the company's Google Ads developer_token, client_id, and client_secret without the user having to know about these variables.
#
# POST /v1/source_oauths/oauth_params/create
# operationId: setInstancewideSourceOauthParams
export def "source-oauths-oauth-params-create setInstancewideSourceOauthParams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  params: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/oauth_params/create")
  let body = {sourceDefinitionId: $sourceDefinitionId, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a source connector definition ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/source_oauths/get_consent_url
# operationId: getSourceOAuthConsent
export def "source-oauths-get-consent-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
  redirectUrl: string # The url to redirect to after getting the user consent
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --sourceId: string # format: uuid
  --requestedScopes: list # Optional OAuth scopes to request, overriding the connector's default scopes. Only supported for connectors that define scopes as an array.
  --requestedOptionalScopes: list # Optional OAuth optional_scopes to request, overriding the connector's default optional_scopes. Only applied when requestedScopes is also provided.
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/get_consent_url")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId, redirectUrl: $redirectUrl, oAuthInputConfiguration: $oAuthInputConfiguration, sourceId: $sourceId, requestedScopes: $requestedScopes, requestedOptionalScopes: $requestedOptionalScopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a source connector definition ID, return the URL to the consent screen where to redirect the user to. This endpoint is specific for the embedded widget, and does not allow configuring the oAuthInputConfiguration for security purposes.
#
# POST /v1/source_oauths/get_embedded_consent_url
# operationId: getEmbeddedSourceOAuthConsent
export def "source-oauths-get-embedded-consent-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
  redirectUrl: string # The url to redirect to after getting the user consent
  --sourceId: string # format: uuid
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/get_embedded_consent_url")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId, redirectUrl: $redirectUrl, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a connector builder project ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/connector_builder_projects/get_oauth_consent_url
# operationId: getConnectorBuilderProjectOAuthConsent
export def "connector-builder-projects-get-oauth-consent-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  builderProjectId: string # format: uuid
  workspaceId: string # format: uuid
  redirectUrl: string # The url to redirect to after getting the user consent
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/get_oauth_consent_url")
  let body = {builderProjectId: $builderProjectId, workspaceId: $workspaceId, redirectUrl: $redirectUrl, oAuthInputConfiguration: $oAuthInputConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a source def ID generate an access/refresh token etc.
#
# POST /v1/source_oauths/complete_oauth
# operationId: completeSourceOAuth
export def "source-oauths-complete-oauth completeSourceOAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
  --redirectUrl: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  --queryParams: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --returnSecretCoordinate: string@bool-completer # If set to true, returns a secret coordinate which references the stored tokens. By default, returns raw tokens. (default: false)
  --sourceId: string # format: uuid
  --requestedScopes: list # Optional OAuth scopes to request, overriding the connector's default scopes. Only supported for connectors that define scopes as an array.
  --requestedOptionalScopes: list # Optional OAuth optional_scopes to request, overriding the connector's default optional_scopes. Only applied when requestedScopes is also provided.
]: any -> record<request_succeeded: bool, request_error: string, auth_payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/complete_oauth")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId, redirectUrl: $redirectUrl, queryParams: $queryParams, oAuthInputConfiguration: $oAuthInputConfiguration, returnSecretCoordinate: $returnSecretCoordinate, sourceId: $sourceId, requestedScopes: $requestedScopes, requestedOptionalScopes: $requestedOptionalScopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a builder project Id generate an access/refresh token etc.
#
# POST /v1/connector_builder_projects/complete_oauth
# operationId: completeConnectorBuilderProjectOauth
export def "connector-builder-projects-complete-oauth completeConnectorBuilderProjectOauth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  builderProjectId: string # format: uuid
  workspaceId: string # format: uuid
  --queryParams: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirectUrl: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
]: any -> record<request_succeeded: bool, request_error: string, auth_payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_builder_projects/complete_oauth")
  let body = {builderProjectId: $builderProjectId, workspaceId: $workspaceId, queryParams: $queryParams, redirectUrl: $redirectUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a source definition ID and workspace ID revoke access/refresh token etc.
#
# POST /v1/source_oauths/revoke
# operationId: revokeSourceOAuthTokens
export def "source-oauths-revoke revokeSourceOAuthTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  sourceId: string # format: uuid
  sourceDefinitionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/revoke")
  let body = {workspaceId: $workspaceId, sourceId: $sourceId, sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a source connector definition ID, return the default OAuth scopes.
#
# POST /v1/source_oauths/get_scopes
# operationId: getSourceOAuthScopes
export def "source-oauths-get-scopes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<scopes: table<scope: string>, optionalScopes: table<scope: string>, scopeJoinStrategy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/get_scopes")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a destination connector definition ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/destination_oauths/get_consent_url
# operationId: getDestinationOAuthConsent
export def "destination-oauths-get-consent-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
  redirectUrl: string # The url to redirect to after getting the user consent
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --destinationId: string # format: uuid
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/get_consent_url")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId, redirectUrl: $redirectUrl, oAuthInputConfiguration: $oAuthInputConfiguration, destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Given a destination def ID generate an access/refresh token etc.
#
# POST /v1/destination_oauths/complete_oauth
# operationId: completeDestinationOAuth
export def "destination-oauths-complete-oauth completeDestinationOAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
  --redirectUrl: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  --queryParams: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --destinationId: string # format: uuid
]: any -> record<request_succeeded: bool, request_error: string, auth_payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/complete_oauth")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId, redirectUrl: $redirectUrl, queryParams: $queryParams, oAuthInputConfiguration: $oAuthInputConfiguration, destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets instancewide variables to be used for the oauth flow when creating this destination. When set, these variables will be injected into a connector's configuration before any interaction with the connector image itself. This enables running oauth flows with consistent variables e.g: the company's Google Ads developer_token, client_id, and client_secret without the user having to know about these variables.
#
# POST /v1/destination_oauths/oauth_params/create
# operationId: setInstancewideDestinationOauthParams
export def "destination-oauths-oauth-params-create setInstancewideDestinationOauthParams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationDefinitionId: string # format: uuid
  params: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/oauth_params/create")
  let body = {destinationDefinitionId: $destinationDefinitionId, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a summary of source and destination definitions that could be updated.
#
# POST /v1/web_backend/check_updates
# operationId: webBackendCheckUpdates
export def "web-backend-check-updates webBackendCheckUpdates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<destinationDefinitions: int, sourceDefinitions: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/check_updates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validates a draft set of mappers against a connection's configured streams
#
# POST /v1/web_backend/mappers/validate
# operationId: webBackendValidateMappers
# --streamDescriptor shape: {name: string, namespace?: string}
# --mappers item shape: {id?: string, type: "hashing"|"field-renaming"|"row-filtering"|"encryption"|"field-filtering", mapperConfiguration: record}
export def "web-backend-mappers-validate webBackendValidateMappers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  streamDescriptor: record # shape: {name: string, namespace?: string}
  mappers: list # Mappers that should be applied to the stream before writing to the destination. — item shape: {id?: string, type: "hashing"|"field-renaming"|"row-filtering"|"encryption"|"field-filtering", mapperConfiguration: record}
]: any -> record<initialFields: table<name: string, isSelectedPrimaryKey: bool, isSelectedCursor: bool, type: string>, outputFields: table<name: string, isSelectedPrimaryKey: bool, isSelectedCursor: bool, type: string>, mappers: table<id: string, outputFields: list, inputFields: list, validationError: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/mappers/validate")
  let body = {connectionId: $connectionId, streamDescriptor: $streamDescriptor, mappers: $mappers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all non-deleted connections for a workspace.
#
# POST /v1/web_backend/connections/list
# operationId: webBackendListConnectionsForWorkspace
# --filters shape: {sourceDefinitionIds?: list, destinationDefinitionIds?: list, statuses?: list, states?: list, tagIds?: list, searchTerm?: string, onDemandEnabled?: bool}
export def "web-backend-connections-list webBackendListConnectionsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --sourceId: list
  --destinationId: list
  --cursor: string # format: uuid
  --sortKey: string@sortKey-completer-1 # Available sort keys for connection list pagination
  --filters: record # shape: {sourceDefinitionIds?: list, destinationDefinitionIds?: list, statuses?: list, states?: list, tagIds?: list, searchTerm?: string, onDemandEnabled?: bool}
  --pageSize: int # Number of connections to return in the list
]: any -> record<connections: table<connectionId: string, name: string, scheduleType: string, scheduleData: record, status: string, source: record, destination: record, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, isSyncing: bool, schemaChange: string, sourceActorDefinitionVersion: record, destinationActorDefinitionVersion: record, tags: list, onDemandEnabled: bool>, page_size: int, num_connections: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/list")
  let body = {workspaceId: $workspaceId, sourceId: $sourceId, destinationId: $destinationId, cursor: $cursor, sortKey: $sortKey, filters: $filters, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns aggregated connection status counts for a workspace.
#
# POST /v1/web_backend/connections/status_counts
# operationId: webBackendGetConnectionStatusCounts
export def "web-backend-connections-status-counts webBackendGetConnectionStatusCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<running: int, queued: int, healthy: int, failed: int, paused: int, notSynced: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/status_counts")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection
#
# POST /v1/web_backend/connections/get
# operationId: webBackendGetConnection
export def "web-backend-connections-get webBackendGetConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withRefreshedCatalog: string@bool-completer
  connectionId: string # format: uuid
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, operationIds: list<string>, source: record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record, jobSpecific: list>, numConnections: int, lastSync: int, connectionJobStatuses: record>, destination: record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record, jobSpecific: list>, numConnections: int, lastSync: int, connectionJobStatuses: record>, operations: table<workspaceId: string, operationId: string, name: string, operatorConfiguration: record>, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, isSyncing: bool, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, catalogId: string, destinationCatalogId: string, catalogDiff: record<transforms: list<record>>, dataplaneGroupId: string, schemaChange: string, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, createdAt: int, backfillPreference: string, sourceActorDefinitionVersion: record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record>, destinationActorDefinitionVersion: record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record>, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/get")
  let body = {withRefreshedCatalog: $withRefreshedCatalog, connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a connection
#
# POST /v1/web_backend/connections/create
# operationId: webBackendCreateConnection
# --syncCatalog shape: {streams: list}
# --schedule shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --resourceRequirements shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
# --operations item shape: {workspaceId: string, name: string, operatorConfiguration: record}
# --tags item shape: {tagId: string, workspaceId: string, name: string, color: string}
export def "web-backend-connections-create webBackendCreateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Optional name of the connection
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  sourceId: string # format: uuid
  destinationId: string # format: uuid
  --operationIds: list
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
  --schedule: record # if null, then no schedule is set. — shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. Locked means the connection is temporarily disabled due to external factors (e.g., payment issues). The schema field describes the elements of the schema that will be synced.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
  --operations: list # item shape: {workspaceId: string, name: string, operatorConfiguration: record}
  --sourceCatalogId: string # format: uuid
  --destinationCatalogId: string # format: uuid
  --dataplaneGroupId: string # format: uuid
  --notifySchemaChanges: string@bool-completer
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --backfillPreference: string@backfillPreference-completer
  --tags: list # item shape: {tagId: string, workspaceId: string, name: string, color: string}
  --onDemandEnabled: string@bool-completer # When enabled, this connection will use on-demand capacity if committed capacity is exhausted (default: false)
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, operationIds: list<string>, source: record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record, jobSpecific: list>, numConnections: int, lastSync: int, connectionJobStatuses: record>, destination: record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record, jobSpecific: list>, numConnections: int, lastSync: int, connectionJobStatuses: record>, operations: table<workspaceId: string, operationId: string, name: string, operatorConfiguration: record>, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, isSyncing: bool, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, catalogId: string, destinationCatalogId: string, catalogDiff: record<transforms: list<record>>, dataplaneGroupId: string, schemaChange: string, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, createdAt: int, backfillPreference: string, sourceActorDefinitionVersion: record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record>, destinationActorDefinitionVersion: record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record>, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/create")
  let body = {name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, sourceId: $sourceId, destinationId: $destinationId, operationIds: $operationIds, syncCatalog: $syncCatalog, schedule: $schedule, scheduleType: $scheduleType, scheduleData: $scheduleData, status: $status, resourceRequirements: $resourceRequirements, operations: $operations, sourceCatalogId: $sourceCatalogId, destinationCatalogId: $destinationCatalogId, dataplaneGroupId: $dataplaneGroupId, notifySchemaChanges: $notifySchemaChanges, nonBreakingChangesPreference: $nonBreakingChangesPreference, backfillPreference: $backfillPreference, tags: $tags, onDemandEnabled: $onDemandEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a connection
#
# POST /v1/web_backend/connections/update
# operationId: webBackendUpdateConnection
# --syncCatalog shape: {streams: list}
# --schedule shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --resourceRequirements shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
# --operations item shape: {operationId?: string, workspaceId: string, name: string, operatorConfiguration: record}
# --tags item shape: {tagId: string, workspaceId: string, name: string, color: string}
export def "web-backend-connections-update webBackendUpdateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name that will be set to the connection
  connectionId: string # format: uuid
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
  --schedule: record # if null, then no schedule is set. — shape: {units: int, timeUnit: "minutes"|"hours"|"days"|"weeks"|"months"}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. Locked means the connection is temporarily disabled due to external factors (e.g., payment issues). The schema field describes the elements of the schema that will be synced.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_request?: string, cpu_limit?: string, memory_request?: string, memory_limit?: string, ephemeral_storage_request?: string, ephemeral_storage_limit?: string}
  --skipReset: string@bool-completer
  --operations: list # nullable — item shape: {operationId?: string, workspaceId: string, name: string, operatorConfiguration: record}
  --sourceCatalogId: string # format: uuid
  --destinationCatalogId: string # format: uuid
  --dataplaneGroupId: string # format: uuid
  --notifySchemaChanges: string@bool-completer
  --notifySchemaChangesByEmail: string@bool-completer
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --backfillPreference: string@backfillPreference-completer
  --tags: list # nullable — item shape: {tagId: string, workspaceId: string, name: string, color: string}
  --onDemandEnabled: string@bool-completer # When enabled, this connection will use on-demand capacity if committed capacity is exhausted
]: any -> record<connectionId: string, name: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, sourceId: string, destinationId: string, syncCatalog: record<streams: list<record>>, schedule: record<units: int, timeUnit: string>, scheduleType: string, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, status: string, statusReason: string, operationIds: list<string>, source: record<sourceDefinitionId: string, sourceId: string, workspaceId: string, connectionConfiguration: record, name: string, sourceName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record, jobSpecific: list>, numConnections: int, lastSync: int, connectionJobStatuses: record>, destination: record<destinationDefinitionId: string, destinationId: string, workspaceId: string, connectionConfiguration: record, name: string, destinationName: string, icon: string, isVersionOverrideApplied: bool, isEntitled: bool, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, supportState: string, status: string, createdAt: int, resourceAllocation: record<default: record, jobSpecific: list>, numConnections: int, lastSync: int, connectionJobStatuses: record>, operations: table<workspaceId: string, operationId: string, name: string, operatorConfiguration: record>, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, isSyncing: bool, resourceRequirements: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, catalogId: string, destinationCatalogId: string, catalogDiff: record<transforms: list<record>>, dataplaneGroupId: string, schemaChange: string, notifySchemaChanges: bool, notifySchemaChangesByEmail: bool, nonBreakingChangesPreference: string, createdAt: int, backfillPreference: string, sourceActorDefinitionVersion: record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record>, destinationActorDefinitionVersion: record<dockerRepository: string, dockerImageTag: string, supportsRefreshes: bool, isVersionOverrideApplied: bool, supportLevel: string, supportState: string, breakingChanges: record<upcomingBreakingChanges: list, minUpgradeDeadline: string, deadlineAction: string>, lastPublished: string, cdkVersion: string, supportsFileTransfer: bool, supportsDataActivation: bool, connectorIPCOptions: record>, tags: table<tagId: string, workspaceId: string, name: string, color: string>, onDemandEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/update")
  let body = {name: $name, connectionId: $connectionId, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, syncCatalog: $syncCatalog, schedule: $schedule, scheduleType: $scheduleType, scheduleData: $scheduleData, status: $status, resourceRequirements: $resourceRequirements, skipReset: $skipReset, operations: $operations, sourceCatalogId: $sourceCatalogId, destinationCatalogId: $destinationCatalogId, dataplaneGroupId: $dataplaneGroupId, notifySchemaChanges: $notifySchemaChanges, notifySchemaChangesByEmail: $notifySchemaChangesByEmail, nonBreakingChangesPreference: $nonBreakingChangesPreference, backfillPreference: $backfillPreference, tags: $tags, onDemandEnabled: $onDemandEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a human-readable description of a CronTrigger expression
#
# POST /v1/web_backend/describe_cron_expression
# operationId: webBackendDescribeCronExpression
export def "web-backend-describe-cron-expression webBackendDescribeCronExpression" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cronExpression: string
]: any -> record<cronExpression: string, description: string, nextExecutions: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/describe_cron_expression")
  let body = {cronExpression: $cronExpression} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch the current state type for a connection.
#
# POST /v1/web_backend/state/get_type
# operationId: getStateType
export def "web-backend-state-get-type post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/state/get_type")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the current state of a workspace
#
# POST /v1/web_backend/workspace/state
# operationId: webBackendGetWorkspaceState
export def "web-backend-workspace-state webBackendGetWorkspaceState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
]: any -> record<hasConnections: bool, hasSources: bool, hasDestinations: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/workspace/state")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch webapp configuration
#
# GET /v1/web_backend/config
# operationId: getWebappConfig
export def "web-backend-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, edition: string, datadogApplicationId: string, datadogClientToken: string, datadogSite: string, datadogService: string, datadogEnv: string, hockeystackApiKey: string, keycloakBaseUrl: string, launchdarklyKey: string, osanoKey: string, segmentToken: string, sonarApiUrl: string, coralAgentsApiUrl: string, zendeskKey: string, fullstoryGuidesOrgId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new job for a given connection. If a job is already running for the connection, it will be stopped and a new job will be created.
#
# POST /v1/jobs/create
# operationId: createJob
export def "jobs-create createJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  --isScheduled: string@bool-completer
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/create")
  let body = {connectionId: $connectionId, isScheduled: $isScheduled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For worker to mark an attempt as successful.
#
# POST /v1/jobs/job_success_with_attempt_number
# operationId: jobSuccessWithAttemptNumber
export def "jobs-job-success-with-attempt-number jobSuccessWithAttemptNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
  connectionId: string # format: uuid
  standardSyncOutput: record
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/job_success_with_attempt_number")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber, connectionId: $connectionId, standardSyncOutput: $standardSyncOutput} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns recent jobs for a connection. Jobs are returned in descending order by createdAt.
#
# POST /v1/jobs/list
# operationId: listJobsFor
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "jobs-list listJobsFor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  configTypes: list
  --configId: string
  --includingJobId: int # format: int64
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --statuses: list # The Job statuses you want to filter by
  --createdAtStart: string # The start datetime to filter by (format: date-time)
  --createdAtEnd: string # The end datetime to filter by (format: date-time)
  --updatedAtStart: string # The start datetime to filter by (format: date-time)
  --updatedAtEnd: string # The end datetime to filter by (format: date-time)
  --orderByField: string@orderByField-completer # The field to order by
  --orderByMethod: string@orderByMethod-completer # The order by method
]: any -> record<jobs: table<job: record, attempts: list>, totalJobCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/list")
  let body = {configTypes: $configTypes, configId: $configId, includingJobId: $includingJobId, pagination: $pagination, statuses: $statuses, createdAtStart: $createdAtStart, createdAtEnd: $createdAtEnd, updatedAtStart: $updatedAtStart, updatedAtEnd: $updatedAtEnd, orderByField: $orderByField, orderByMethod: $orderByMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns recent jobs for a connection. Jobs are returned in descending order by createdAt.
#
# POST /v1/jobs/list_for_workspaces
# operationId: listJobsForWorkspaces
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "jobs-list-for-workspaces listJobsForWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  configTypes: list
  --configId: string
  --workspaceIds: list
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --statuses: list # The Job statuses you want to filter by
  --createdAtStart: string # The start datetime to filter by (format: date-time)
  --createdAtEnd: string # The end datetime to filter by (format: date-time)
  --updatedAtStart: string # The start datetime to filter by (format: date-time)
  --updatedAtEnd: string # The end datetime to filter by (format: date-time)
  --orderByField: string@orderByField-completer # The field to order by
  --orderByMethod: string@orderByMethod-completer # The order by method
]: any -> record<jobs: table<job: record, attempts: list>, totalJobCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/list_for_workspaces")
  let body = {configTypes: $configTypes, configId: $configId, workspaceIds: $workspaceIds, pagination: $pagination, statuses: $statuses, createdAtStart: $createdAtStart, createdAtEnd: $createdAtEnd, updatedAtStart: $updatedAtStart, updatedAtEnd: $updatedAtEnd, orderByField: $orderByField, orderByMethod: $orderByMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about a job
#
# POST /v1/jobs/get
# operationId: getJobInfo
export def "jobs-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the latest job not including the cancel jobs.
#
# POST /v1/jobs/get_last_replication_job
# operationId: getLastReplicationJob
export def "jobs-get-last-replication-job post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_last_replication_job")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the latest job including the cancel jobs. This is used for scheduling in order to make sure that we don't immediately start a new job after a cancel.
#
# POST /v1/jobs/get_last_replication_job_with_cancel
# operationId: getLastReplicationJobWithCancel
export def "jobs-get-last-replication-job-with-cancel post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_last_replication_job_with_cancel")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about a job excluding logs
#
# POST /v1/jobs/get_without_logs
# operationId: getJobInfoWithoutLogs
export def "jobs-get-without-logs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_without_logs")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about a job excluding attempt info and logs
#
# POST /v1/jobs/get_light
# operationId: getJobInfoLight
export def "jobs-get-light post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_light")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancels a job
#
# POST /v1/jobs/cancel
# operationId: cancelJob
export def "jobs-cancel cancelJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<job: record<id: int, configType: string, configId: string, enabledStreams: list<record>, createdAt: int, updatedAt: int, startedAt: int, status: string, resetConfig: record<streamsToReset: list>, refreshConfig: record<streamsToRefresh: list>, aggregatedStats: record<recordsEmitted: int, bytesEmitted: int, recordsCommitted: int, bytesCommitted: int, recordsRejected: int>, streamAggregatedStats: list<record>>, attempts: table<attempt: record, logType: string, logs: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/cancel")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all information needed to debug this job
#
# POST /v1/jobs/get_debug_info
# operationId: getJobDebugInfo
export def "jobs-get-debug-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<job: record<id: int, configType: string, configId: string, status: string, airbyteVersion: string, sourceDefinition: record<sourceDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, sourceType: string, resourceRequirements: record, maxSecondsBetweenMessages: int, lastPublished: string, cdkVersion: string, metrics: record, language: string>, destinationDefinition: record<destinationDefinitionId: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string, icon: string, protocolVersion: string, custom: bool, enterprise: bool, supportLevel: string, releaseStage: string, releaseDate: string, resourceRequirements: record, lastPublished: string, cdkVersion: string, metrics: record, language: string, supportsDataActivation: bool>>, attempts: table<attempt: record, logType: string, logs: any>, workflowState: record<running: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_debug_info")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the job input in order to be able to start a synchronization.
#
# POST /v1/jobs/get_input
# operationId: getJobInput
export def "jobs-get-input post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_input")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fails all non-terminal jobs for a connection
#
# POST /v1/jobs/fail_non_terminal
# operationId: failNonTerminalJobs
export def "jobs-fail-non-terminal failNonTerminalJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/fail_non_terminal")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For worker to report when a job starts.
#
# POST /v1/jobs/reportJobStart
# operationId: reportJobStart
export def "jobs-report-job-start reportJobStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  connectionId: string # format: uuid
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/reportJobStart")
  let body = {jobId: $jobId, connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set a job status to QUEUED when waiting for Data Worker capacity.
#
# POST /v1/jobs/setJobQueued
# operationId: setJobQueued
export def "jobs-set-job-queued setJobQueued" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/setJobQueued")
  let body = {jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a job that is still queued while waiting for capacity.
#
# POST /v1/jobs/cancelQueuedJob
# operationId: cancelQueuedJob
export def "jobs-cancel-queued-job cancelQueuedJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/cancelQueuedJob")
  let body = {jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check and reserve Data Worker capacity for a queued job.
#
# POST /v1/jobs/checkDataWorkerCapacity
# operationId: checkDataWorkerCapacity
export def "jobs-check-data-worker-capacity checkDataWorkerCapacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  connectionId: string # format: uuid
  organizationId: string # format: uuid
]: any -> record<capacityAvailable: bool, useOnDemandCapacity: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/checkDataWorkerCapacity")
  let body = {jobId: $jobId, connectionId: $connectionId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a webhook config for a job.
#
# POST /v1/jobs/getWebhookConfig
# operationId: getWebhookConfig
export def "jobs-get-webhook-config post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
]: any -> record<value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/getWebhookConfig")
  let body = {jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Marks a job as failed
#
# POST /v1/jobs/job_failure
# operationId: jobFailure
export def "jobs-job-failure jobFailure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
  connectionId: string # format: uuid
  reason: string # Reason of the failure
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/job_failure")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber, connectionId: $connectionId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes all stream reset records for the specified job
#
# POST /v1/jobs/delete_stream_reset_records
# operationId: deleteStreamResetRecordsForJob
export def "jobs-delete-stream-reset-records post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  jobId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/delete_stream_reset_records")
  let body = {connectionId: $connectionId, jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a LLM generated description of the result of a given job
#
# POST /v1/jobs/explain
# operationId: explainJob
export def "jobs-explain explainJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<jobId: int, explanation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/explain")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# evaluate if a job is an outlier
#
# POST /v1/jobs/evaluate_outlier
# operationId: evaluateOutlier
export def "jobs-evaluate-outlier evaluateOutlier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/evaluate_outlier")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# finalizes a job
#
# POST /v1/jobs/finalize
# operationId: finalizeJob
export def "jobs-finalize finalizeJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/finalize")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Airbyte user by internal user ID
#
# POST /v1/users/get
# operationId: getUser
export def "users-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # Internal Airbyte user ID (format: uuid)
]: any -> record<name: string, userId: string, defaultWorkspaceId: string, status: string, companyName: string, email: string, news: bool, metadata: record, agenticEnabledAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/get")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Airbyte user by auth id
#
# POST /v1/users/get_by_auth_id
# operationId: getUserByAuthId
export def "users-get-by-auth-id post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  authUserId: string
  --isAgenticUser: string@bool-completer # Indicates whether this user should have agentic features enabled.  Behavior: - New user + true: User created with agenticEnabledAt timestamp - New user + false/omitted: User created as non-agentic (agenticEnabledAt = null) - Existing agentic user + any value: Timestamp preserved (immutable, cannot downgrade) - Existing non-agentic user + true: User upgraded, agenticEnabledAt set to current time - Existing non-agentic user + false/omitted: Remains non-agentic  Note: agenticEnabledAt is one-way - once set, it cannot be unset. Users can be upgraded from non-agentic to agentic, but not downgraded.
]: any -> record<name: string, userId: string, defaultWorkspaceId: string, status: string, companyName: string, email: string, news: bool, metadata: record, agenticEnabledAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/get_by_auth_id")
  let body = {authUserId: $authUserId, isAgenticUser: $isAgenticUser} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Airbyte user by email
#
# POST /v1/users/get_by_email
# operationId: getUserByEmail
export def "users-get-by-email post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string
]: any -> record<name: string, userId: string, defaultWorkspaceId: string, status: string, companyName: string, email: string, news: bool, metadata: record, agenticEnabledAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/get_by_email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Airbyte user by auth id. If not existed, will create a user.
#
# POST /v1/users/get_or_create_by_auth_id
# operationId: getOrCreateUserByAuthId
export def "users-get-or-create-by-auth-id post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  authUserId: string
  --isAgenticUser: string@bool-completer # Indicates whether this user should have agentic features enabled.  Behavior: - New user + true: User created with agenticEnabledAt timestamp - New user + false/omitted: User created as non-agentic (agenticEnabledAt = null) - Existing agentic user + any value: Timestamp preserved (immutable, cannot downgrade) - Existing non-agentic user + true: User upgraded, agenticEnabledAt set to current time - Existing non-agentic user + false/omitted: Remains non-agentic  Note: agenticEnabledAt is one-way - once set, it cannot be unset. Users can be upgraded from non-agentic to agentic, but not downgraded.
]: any -> record<userRead: record<name: string, userId: string, defaultWorkspaceId: string, status: string, companyName: string, email: string, news: bool, metadata: record, agenticEnabledAt: string>, authUserId: string, authProvider: string, newUserCreated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/get_or_create_by_auth_id")
  let body = {authUserId: $authUserId, isAgenticUser: $isAgenticUser} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user state
#
# POST /v1/users/update
# operationId: updateUser
export def "users-update updateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Caption name for the user
  userId: string # Internal Airbyte user ID (format: uuid)
  --defaultWorkspaceId: string # format: uuid
  --status: string@status-completer-1 # user status
  --companyName: string
  --news: string@bool-completer
  --metadata: record # UI metadata used in frontend
]: any -> record<name: string, userId: string, defaultWorkspaceId: string, status: string, companyName: string, email: string, news: bool, metadata: record, agenticEnabledAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/update")
  let body = {name: $name, userId: $userId, defaultWorkspaceId: $defaultWorkspaceId, status: $status, companyName: $companyName, news: $news, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a user
#
# POST /v1/users/delete
# operationId: deleteUser
export def "users-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # Internal Airbyte user ID (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/delete")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List user access info for a particular workspace.
#
# POST /v1/users/list_access_info_by_workspace_id
# operationId: listAccessInfoByWorkspaceId
export def "users-list-access-info-by-workspace-id listAccessInfoByWorkspaceId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> record<usersWithAccess: table<userId: string, userEmail: string, userName: string, workspaceId: string, workspacePermission: record, organizationPermission: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/list_access_info_by_workspace_id")
  let body = {workspaceId: $workspaceId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all users with permissions of the given org
#
# POST /v1/users/list_by_organization_id
# operationId: listUsersInOrganization
export def "users-list-by-organization-id listUsersInOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<users: table<name: string, userId: string, email: string, permissionId: string, permissionType: string, organizationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/list_by_organization_id")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all users with instance admin permissions. Only instance admin has permission to call this.
#
# POST /v1/users/list_instance_admin
# operationId: listInstanceAdminUsers
export def "users-list-instance-admin listInstanceAdminUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<users: table<name: string, userId: string, email: string, permissionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/list_instance_admin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a permission resource
#
# POST /v1/permissions/create
# operationId: createPermission
export def "permissions-create createPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissionId: string # This is a temporary and optional field just for dual write purpose during the data migration. (format: uuid)
  permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
  userId: string # Internal Airbyte user ID (format: uuid)
  --workspaceId: string # format: uuid
  --organizationId: string # format: uuid
]: any -> record<permissionId: string, permissionType: string, userId: string, workspaceId: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/create")
  let body = {permissionId: $permissionId, permissionType: $permissionType, userId: $userId, workspaceId: $workspaceId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find a permission by ID
#
# POST /v1/permissions/get
# operationId: getPermission
export def "permissions-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionId: string # format: uuid
]: any -> record<permissionId: string, permissionType: string, userId: string, workspaceId: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/get")
  let body = {permissionId: $permissionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check permissions for user
#
# POST /v1/permissions/check
# operationId: checkPermissions
export def "permissions-check checkPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
  userId: string # Internal Airbyte user ID (format: uuid)
  --workspaceId: string # format: uuid
  --organizationId: string # format: uuid
]: any -> record<status: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/check")
  let body = {permissionType: $permissionType, userId: $userId, workspaceId: $workspaceId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check permissions for user across workspaces
#
# POST /v1/permissions/check_multiple_workspaces
# operationId: checkPermissionsAcrossMultipleWorkspaces
export def "permissions-check-multiple-workspaces checkPermissionsAcrossMultipleWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
  userId: string # Internal Airbyte user ID (format: uuid)
  --workspaceIds: list
]: any -> record<status: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/check_multiple_workspaces")
  let body = {permissionType: $permissionType, userId: $userId, workspaceIds: $workspaceIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a permission resource
#
# POST /v1/permissions/update
# operationId: updatePermission
export def "permissions-update updatePermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionId: string # format: uuid
  --permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/update")
  let body = {permissionId: $permissionId, permissionType: $permissionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get secrets persistence config
#
# POST /v1/secrets_persistence_config/get
# operationId: getSecretsPersistenceConfig
export def "secrets-persistence-config-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopeType: string@scopeType-completer
  scopeId: string # format: uuid
]: any -> record<secretPersistenceType: string, configuration: record, scopeType: string, scopeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secrets_persistence_config/get")
  let body = {scopeType: $scopeType, scopeId: $scopeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update secrets persistence config
#
# POST /v1/secrets_persistence_config/create_or_update
# operationId: createOrUpdateSecretsPersistenceConfig
export def "secrets-persistence-config-create-or-update createOrUpdateSecretsPersistenceConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  secretPersistenceType: string@secretPersistenceType-completer
  configuration: record
  scope: string@scope-completer
  scopeId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secrets_persistence_config/create_or_update")
  let body = {secretPersistenceType: $secretPersistenceType, configuration: $configuration, scope: $scope, scopeId: $scopeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create secret storage
#
# POST /v1/secret_storage/create
# operationId: createSecretStorage
export def "secret-storage-create createSecretStorage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  descriptor: string
  secretStorageType: string@secretStorageType-completer
  scopeType: string@scopeType-completer
  scopeId: string # format: uuid
  --config: record
  --isConfiguredFromEnvironment: string@bool-completer
]: any -> record<id: string, secretStorageType: string, isConfiguredFromEnvironment: bool, scopeType: string, scopeId: string, config: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secret_storage/create")
  let body = {descriptor: $descriptor, secretStorageType: $secretStorageType, scopeType: $scopeType, scopeId: $scopeId, config: $config, isConfiguredFromEnvironment: $isConfiguredFromEnvironment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all secret storages for a given scope
#
# POST /v1/secret_storage/list
# operationId: listSecretStorage
export def "secret-storage-list listSecretStorage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopeType: string@scopeType-completer
  scopeId: string # format: uuid
]: any -> record<secretStorages: table<id: string, secretStorageType: string, isConfiguredFromEnvironment: bool, scopeType: string, scopeId: string, config: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secret_storage/list")
  let body = {scopeType: $scopeType, scopeId: $scopeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete secret storage by its id
#
# POST /v1/secret_storage/delete
# operationId: deleteSecretStorage
export def "secret-storage-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  secretStorageId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secret_storage/delete")
  let body = {secretStorageId: $secretStorageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get secret storage by its id
#
# POST /v1/secret_storage/get
# operationId: getSecretStorage
export def "secret-storage-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  secretStorageId: string # format: uuid
]: any -> record<id: string, secretStorageType: string, isConfiguredFromEnvironment: bool, scopeType: string, scopeId: string, config: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secret_storage/get")
  let body = {secretStorageId: $secretStorageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate from one secret storage to another
#
# POST /v1/secret_storage/migrate
# operationId: migrateSecretStorage
export def "secret-storage-migrate migrateSecretStorage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fromSecretStorageId: string # format: uuid
  toSecretStorageId: string # format: uuid
  scopeType: string@scopeType-completer
  scopeId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/secret_storage/migrate")
  let body = {fromSecretStorageId: $fromSecretStorageId, toSecretStorageId: $toSecretStorageId, scopeType: $scopeType, scopeId: $scopeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a permission resource
#
# POST /v1/permissions/delete
# operationId: deletePermission
export def "permissions-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/delete")
  let body = {permissionId: $permissionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes all workspace-level permissions for a particular user and workspace
#
# POST /v1/permissions/delete_user_from_workspace
# operationId: deleteUserFromWorkspace
export def "permissions-delete-user-from-workspace post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # Internal Airbyte user ID (format: uuid)
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/delete_user_from_workspace")
  let body = {userId: $userId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List permissions a user has access to
#
# POST /v1/permissions/list_by_user
# operationId: listPermissionsByUser
export def "permissions-list-by-user listPermissionsByUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # Internal Airbyte user ID (format: uuid)
]: any -> record<permissions: table<permissionId: string, permissionType: string, userId: string, workspaceId: string, organizationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/permissions/list_by_user")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Health Check
#
# GET /v1/health
# operationId: getHealthCheck
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the openapi specification
#
# GET /v1/openapi
# operationId: getOpenApiSpec
export def "openapi get" [
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
  let full_url = (build-url $base "/v1/openapi")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# For worker to create a new attempt number.
#
# POST /v1/attempt/create_new_attempt_number
# operationId: createNewAttemptNumber
export def "attempt-create-new-attempt-number createNewAttemptNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
]: any -> record<attemptNumber: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/create_new_attempt_number")
  let body = {jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save stream level attempt information
#
# POST /v1/attempt/save_stream_metadata
# operationId: saveStreamMetadata
# --streamMetadata item shape: {streamName: string, streamNamespace?: string, wasBackfilled: bool, wasResumed: bool}
export def "attempt-save-stream-metadata saveStreamMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
  --streamMetadata: list # item shape: {streamName: string, streamNamespace?: string, wasBackfilled: bool, wasResumed: bool}
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_stream_metadata")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber, streamMetadata: $streamMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For worker to set sync stats of a running attempt.
#
# POST /v1/attempt/save_stats
# operationId: saveStats
# --stats shape: {recordsEmitted?: int, bytesEmitted?: int, stateMessagesEmitted?: int, bytesCommitted?: int, recordsCommitted?: int, recordsRejected?: int, estimatedRecords?: int, estimatedBytes?: int, additionalStats?: record}
# --streamStats item shape: {streamName: string, streamNamespace?: string, stats: record}
export def "attempt-save-stats saveStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
  stats: record # shape: {recordsEmitted?: int, bytesEmitted?: int, stateMessagesEmitted?: int, bytesCommitted?: int, recordsCommitted?: int, recordsRejected?: int, estimatedRecords?: int, estimatedBytes?: int, additionalStats?: record}
  --streamStats: list # item shape: {streamName: string, streamNamespace?: string, stats: record}
  --connectionId: string # format: uuid
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_stats")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber, stats: $stats, streamStats: $streamStats, connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For worker to save the AttemptSyncConfig for an attempt.
#
# POST /v1/attempt/save_sync_config
# operationId: saveSyncConfig
# --syncConfig shape: {sourceConfiguration: record, destinationConfiguration: record, state?: record}
export def "attempt-save-sync-config saveSyncConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
  syncConfig: record # shape: {sourceConfiguration: record, destinationConfiguration: record, state?: record}
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_sync_config")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber, syncConfig: $syncConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fails an attempt with a failure summary and if provided a sync output.
#
# POST /v1/attempt/fail
# operationId: failAttempt
export def "attempt-fail failAttempt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
  --failureSummary: record # Attempt failure summary serialized as a raw object
  --standardSyncOutput: record # Sync output serialized as a raw object
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/fail")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber, failureSummary: $failureSummary, standardSyncOutput: $standardSyncOutput} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For retrieving combined stats for a single attempt
#
# POST /v1/attempt/get_combined_stats
# operationId: getAttemptCombinedStats
export def "attempt-get-combined-stats post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
]: any -> record<recordsEmitted: int, bytesEmitted: int, stateMessagesEmitted: int, bytesCommitted: int, recordsCommitted: int, recordsRejected: int, estimatedRecords: int, estimatedBytes: int, additionalStats: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/get_combined_stats")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves an attempt with logs for a job and attempt number.
#
# POST /v1/attempt/get_for_job
# operationId: getAttemptForJob
export def "attempt-get-for-job post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobId: int # format: int64
  attemptNumber: int # format: int32
]: any -> record<attempt: record<id: int, status: string, createdAt: int, updatedAt: int, endedAt: int, bytesSynced: int, recordsSynced: int, totalStats: record<recordsEmitted: int, bytesEmitted: int, stateMessagesEmitted: int, bytesCommitted: int, recordsCommitted: int, recordsRejected: int, estimatedRecords: int, estimatedBytes: int, additionalStats: record>, streamStats: list<record>, failureSummary: record<failures: list, partialSuccess: bool>>, logType: string, logs: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/get_for_job")
  let body = {jobId: $jobId, attemptNumber: $attemptNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of stream statuses filtered by parameters (with AND semantics).
#
# POST /v1/stream_statuses/list
# operationId: getStreamStatuses
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "stream-statuses-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attemptNumber: int # format: int32
  --connectionId: string # format: uuid
  --jobId: int # format: int64
  --jobType: string@jobType-completer
  pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --streamName: string
  --streamNamespace: string
  workspaceId: string # format: uuid
]: any -> record<streamStatuses: table<attemptNumber: int, connectionId: string, id: string, jobId: int, incompleteRunCause: string, jobType: string, runState: string, streamName: string, streamNamespace: string, transitionedAt: int, workspaceId: string, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/stream_statuses/list")
  let body = {attemptNumber: $attemptNumber, connectionId: $connectionId, jobId: $jobId, jobType: $jobType, pagination: $pagination, streamName: $streamName, streamNamespace: $streamNamespace, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of the latest stream status for each stream and run state for a connection.
#
# POST /v1/stream_statuses/latest_per_run_state
# operationId: getStreamStatusesByRunState
export def "stream-statuses-latest-per-run-state post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
]: any -> record<streamStatuses: table<attemptNumber: int, connectionId: string, id: string, jobId: int, incompleteRunCause: string, jobType: string, runState: string, streamName: string, streamNamespace: string, transitionedAt: int, workspaceId: string, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/stream_statuses/latest_per_run_state")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a stream status.
#
# POST /v1/stream_statuses/create
# operationId: createStreamStatus
# --metadata shape: {quotaReset?: int}
export def "stream-statuses-create createStreamStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attemptNumber: int # format: int32
  connectionId: string # format: uuid
  jobId: int # format: int64
  --incompleteRunCause: string@incompleteRunCause-completer # Values:   * `FAILED` - A failure has occurred   * `CANCELED` - The run has been canceled
  jobType: string@jobType-completer
  runState: string@runState-completer # Values:   * `PENDING` - The stream operation has been selected to run   * `RUNNING` - The stream operation is running   * `COMPLETE` - The stream operation ran successfully to completion   * `INCOMPLETE` - The stream operation has terminated in an incomplete state.   See StreamStatusIncompleteRunCause for more details.   * `RATE_LIMITED` - The stream is rate limited because the source has run out of API quota.
  streamName: string
  --streamNamespace: string
  transitionedAt: int # format: int64
  workspaceId: string # format: uuid
  --metadata: record # shape: {quotaReset?: int}
]: any -> record<attemptNumber: int, connectionId: string, id: string, jobId: int, incompleteRunCause: string, jobType: string, runState: string, streamName: string, streamNamespace: string, transitionedAt: int, workspaceId: string, metadata: record<quotaReset: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/stream_statuses/create")
  let body = {attemptNumber: $attemptNumber, connectionId: $connectionId, jobId: $jobId, incompleteRunCause: $incompleteRunCause, jobType: $jobType, runState: $runState, streamName: $streamName, streamNamespace: $streamNamespace, transitionedAt: $transitionedAt, workspaceId: $workspaceId, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a stream status.
#
# POST /v1/stream_statuses/update
# operationId: updateStreamStatus
# --metadata shape: {quotaReset?: int}
export def "stream-statuses-update updateStreamStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attemptNumber: int # format: int32
  connectionId: string # format: uuid
  jobId: int # format: int64
  --incompleteRunCause: string@incompleteRunCause-completer # Values:   * `FAILED` - A failure has occurred   * `CANCELED` - The run has been canceled
  jobType: string@jobType-completer
  runState: string@runState-completer # Values:   * `PENDING` - The stream operation has been selected to run   * `RUNNING` - The stream operation is running   * `COMPLETE` - The stream operation ran successfully to completion   * `INCOMPLETE` - The stream operation has terminated in an incomplete state.   See StreamStatusIncompleteRunCause for more details.   * `RATE_LIMITED` - The stream is rate limited because the source has run out of API quota.
  streamName: string
  --streamNamespace: string
  transitionedAt: int # format: int64
  workspaceId: string # format: uuid
  --metadata: record # shape: {quotaReset?: int}
  id: string # format: uuid
]: any -> record<attemptNumber: int, connectionId: string, id: string, jobId: int, incompleteRunCause: string, jobType: string, runState: string, streamName: string, streamNamespace: string, transitionedAt: int, workspaceId: string, metadata: record<quotaReset: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/stream_statuses/update")
  let body = {attemptNumber: $attemptNumber, connectionId: $connectionId, jobId: $jobId, incompleteRunCause: $incompleteRunCause, jobType: $jobType, runState: $runState, streamName: $streamName, streamNamespace: $streamNamespace, transitionedAt: $transitionedAt, workspaceId: $workspaceId, metadata: $metadata, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get instance configuration
#
# GET /v1/instance_configuration
# operationId: getInstanceConfiguration
export def "instance-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<edition: string, version: string, licenseStatus: string, licenseExpirationDate: int, auth: record<mode: string, clientId: string, defaultRealm: string, authorizationServerUrl: string, audience: string, extraScopes: string>, airbyteUrl: string, initialSetupComplete: bool, defaultUserId: string, defaultOrganizationId: string, defaultOrganizationEmail: string, defaultWorkspaceId: string, trackingStrategy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/instance_configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Setup an instance with user and organization information.
#
# POST /v1/instance_configuration/setup
# operationId: setupInstanceConfiguration
export def "instance-configuration-setup setupInstanceConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string
  --anonymousDataCollection: string@bool-completer
  --initialSetupComplete: string@bool-completer
  --displaySetupWizard: string@bool-completer
  --userName: string # Optional name of the user to create. Defaults to 'Default User' if not specified.
  --organizationName: string # Optional name of the organization to create. Defaults to 'Default Organization' if not specified.
]: any -> record<edition: string, version: string, licenseStatus: string, licenseExpirationDate: int, auth: record<mode: string, clientId: string, defaultRealm: string, authorizationServerUrl: string, audience: string, extraScopes: string>, airbyteUrl: string, initialSetupComplete: bool, defaultUserId: string, defaultOrganizationId: string, defaultOrganizationEmail: string, defaultWorkspaceId: string, trackingStrategy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/instance_configuration/setup")
  let body = {email: $email, anonymousDataCollection: $anonymousDataCollection, initialSetupComplete: $initialSetupComplete, displaySetupWizard: $displaySetupWizard, userName: $userName, organizationName: $organizationName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch license limits and usage
#
# GET /v1/instance_configuration/license/info
# operationId: licenseInfo
export def "instance-configuration-license-info licenseInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<edition: string, licenseStatus: string, maxNodes: int, maxEditors: int, usedNodes: int, usedEditors: int, expirationDate: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/instance_configuration/license/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a retry state for a job.
#
# POST /v1/jobs/retry_states/create_or_update
# operationId: createOrUpdate
export def "jobs-retry-states-create-or-update createOrUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # format: uuid
  connectionId: string # format: uuid
  jobId: int # format: int64
  successiveCompleteFailures: int
  totalCompleteFailures: int
  successivePartialFailures: int
  totalPartialFailures: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/retry_states/create_or_update")
  let body = {id: $id, connectionId: $connectionId, jobId: $jobId, successiveCompleteFailures: $successiveCompleteFailures, totalCompleteFailures: $totalCompleteFailures, successivePartialFailures: $successivePartialFailures, totalPartialFailures: $totalPartialFailures} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a retry state.
#
# POST /v1/jobs/retry_states/get
# operationId: get
export def "jobs-retry-states-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # format: int64
]: any -> record<id: string, connectionId: string, jobId: int, successiveCompleteFailures: int, totalCompleteFailures: int, successivePartialFailures: int, totalPartialFailures: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/retry_states/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns whether the job preceding the specified job succeeded
#
# POST /v1/jobs/did_previous_job_succeed
# operationId: didPreviousJobSucceed
export def "jobs-did-previous-job-succeed didPreviousJobSucceed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: uuid
  jobId: int # format: int64
]: any -> record<value: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/did_previous_job_succeed")
  let body = {connectionId: $connectionId, jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Persists the cancellation of a job and kicks off any post processing (e.g notifications).
#
# POST /v1/jobs/persist_cancellation
# operationId: persistJobCancellation
export def "jobs-persist-cancellation persistJobCancellation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attemptFailureSummary: record # Attempt failure summary serialized as a raw object
  attemptNumber: int # format: int32
  connectionId: string # format: uuid
  jobId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/persist_cancellation")
  let body = {attemptFailureSummary: $attemptFailureSummary, attemptNumber: $attemptNumber, connectionId: $connectionId, jobId: $jobId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a link to the customer portal
#
# POST /v1/billing/customer_portal
# operationId: getCustomerPortalLink
export def "billing-customer-portal post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  returnUrl: string
  --flow: string@flow-completer # default: portal
  --plan: string@plan-completer # Requested self-serve plan when initiating setup checkout. Defaults to standard for backwards compatibility. (default: standard)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/customer_portal")
  let body = {organizationId: $organizationId, returnUrl: $returnUrl, flow: $flow, plan: $plan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Backfill usage
#
# POST /v1/billing/backfill_usage
# operationId: backfillUsage
export def "billing-backfill-usage backfillUsage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  jobIds: list
  backfillId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/backfill_usage")
  let body = {jobIds: $jobIds, backfillId: $backfillId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Handle an external billing event (ie a webhook from an external payment provider service)
#
# POST /v1/billing/handle_webhook
# operationId: handleWebhook
export def "billing-handle-webhook handleWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/handle_webhook")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of past invoices of the customer
#
# POST /v1/billing/list_invoices
# operationId: listPastInvoices
export def "billing-list-invoices listPastInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<invoices: table<id: string, number: string, total: int, currency: string, invoiceDate: int, status: string, pdfUrl: string, invoiceUrl: string>, hasMore: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/list_invoices")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a summary of payment information for a specific organization
#
# POST /v1/billing/payment_information
# operationId: getPaymentInformation
export def "billing-payment-information post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<customer: record<email: string, customerAddress: record<country: string, state: string, city: string, postalCode: string, line1: string, line2: string>, shippingAddress: record<country: string, state: string, city: string, postalCode: string, line1: string, line2: string>, defaultPaymentMethod: record<type: string, cardBrand: string, cardLastDigits: string, cardExpireMonth: int, cardExpireYear: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/payment_information")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the current information about the organization's subscription
#
# POST /v1/billing/subscription_info
# operationId: getSubscriptionInfo
export def "billing-subscription-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<name: string, selfServeSubscription: bool, cancellationDate: string, balanceHidden: bool, upcomingInvoice: record<currency: string, amount: string, dueDate: string>, credits: record<balance: float, blocks: list<record>>, entitlementPlan: record<planEnum: string, planId: string, planName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/subscription_info")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the current trial status of an organization
#
# POST /v1/billing/trial_status
# operationId: getOrganizationTrialStatus
export def "billing-trial-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<trialStatus: string, trialEndsAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/trial_status")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule canceling the subscription of an organization
#
# POST /v1/billing/cancel_subscription
# operationId: cancelSubscription
export def "billing-cancel-subscription cancelSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<subscriptionEndsAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/cancel_subscription")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unschedule a scheduled cancelation of the subscription of an organization
#
# POST /v1/billing/unschedule_cancel_subscription
# operationId: unscheduleCancelSubscription
export def "billing-unschedule-cancel-subscription unscheduleCancelSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/billing/unschedule_cancel_subscription")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable connections in workspaces that are delinquent in payment
#
# POST /v1/billing/disable_delinquent_workspaces
# operationId: disableDelinquentWorkspaces
export def "billing-disable-delinquent-workspaces disableDelinquentWorkspaces" [
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
  let full_url = (build-url $base "/v1/billing/disable_delinquent_workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an organization payment config
#
# GET /v1/organization_payment_config/{organizationId}
# operationId: getOrganizationPaymentConfig
export def "organization-payment-config get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationId: string, paymentStatus: string, subscriptionStatus: string, paymentProviderId: string, gracePeriodEndAt: string, usageCategoryOverwrite: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organization_payment_config/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update an organization payment config
#
# POST /v1/organization_payment_config
# operationId: updateOrganizationPaymentConfig
export def "organization-payment-config updateOrganizationPaymentConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  paymentStatus: string@paymentStatus-completer
  --paymentProviderId: string
  --usageCategoryOverwrite: string@usageCategoryOverwrite-completer
  --gracePeriodEndAt: string # format: date-time
  --newGracePeriodReason: string
]: any -> record<organizationId: string, paymentStatus: string, subscriptionStatus: string, paymentProviderId: string, gracePeriodEndAt: string, usageCategoryOverwrite: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organization_payment_config")
  let body = {organizationId: $organizationId, paymentStatus: $paymentStatus, paymentProviderId: $paymentProviderId, usageCategoryOverwrite: $usageCategoryOverwrite, gracePeriodEndAt: $gracePeriodEndAt, newGracePeriodReason: $newGracePeriodReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# End a grace period for an organization
#
# POST /v1/organization_payment_config/{organizationId}/end_grace_period
# operationId: endGracePeriod
export def "organization-payment-config-end-grace-period endGracePeriod" [
  organizationId: string
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
  let full_url = (build-url $base $"/v1/organization_payment_config/($organizationId)/end_grace_period")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an organization info
#
# POST /v1/organizations/get
# operationId: getOrganization
export def "organizations-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<organizationId: string, organizationName: string, email: string, ssoRealm: string, isAgentic: bool, organizationLimits: record<users: record<current: int, max: int>, workspaces: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/get")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an organization
#
# POST /v1/organizations/create
# operationId: createOrganization
export def "organizations-create createOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # format: uuid
  organizationName: string
  --email: string
  --isAgentic: string@bool-completer # default: false
]: any -> record<organizationId: string, organizationName: string, email: string, ssoRealm: string, isAgentic: bool, organizationLimits: record<users: record<current: int, max: int>, workspaces: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/create")
  let body = {userId: $userId, organizationName: $organizationName, email: $email, isAgentic: $isAgentic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an organization info
#
# POST /v1/organizations/update
# operationId: updateOrganization
export def "organizations-update updateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  --organizationName: string
  --email: string
]: any -> record<organizationId: string, organizationName: string, email: string, ssoRealm: string, isAgentic: bool, organizationLimits: record<users: record<current: int, max: int>, workspaces: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/update")
  let body = {organizationId: $organizationId, organizationName: $organizationName, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set whether an organization is agentic
#
# POST /v1/organizations/agentic_status
# operationId: setOrganizationAgenticStatus
export def "organizations-agentic-status setOrganizationAgenticStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  --isAgentic: string@bool-completer
]: any -> record<organizationId: string, organizationName: string, email: string, ssoRealm: string, isAgentic: bool, organizationLimits: record<users: record<current: int, max: int>, workspaces: record<current: int, max: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/agentic_status")
  let body = {organizationId: $organizationId, isAgentic: $isAgentic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# POST /v1/organizations/delete
# operationId: deleteOrganization
export def "organizations-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/delete")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List organizations by a given user id. The function also supports searching by keyword and pagination.
#
# POST /v1/organizations/list_by_user_id
# operationId: listOrganizationsByUser
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "organizations-list-by-user-id listOrganizationsByUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # format: uuid
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
  --nameContains: string
]: any -> record<organizations: table<organizationId: string, organizationName: string, email: string, ssoRealm: string, isAgentic: bool, organizationLimits: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/list_by_user_id")
  let body = {userId: $userId, pagination: $pagination, nameContains: $nameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get usage for an organization
#
# POST /v1/organizations/get_usage
# operationId: getOrganizationUsage
export def "organizations-get-usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  timeWindow: string@timeWindow-completer # default: lastMonth
]: any -> record<data: table<workspace: record, usage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/get_usage")
  let body = {organizationId: $organizationId, timeWindow: $timeWindow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get data worker usage for an organization
#
# POST /v1/organizations/get_data_worker_usage
# operationId: getOrganizationDataWorkerUsage
export def "organizations-get-data-worker-usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  startDate: string # format: date
  endDate: string # format: date
]: any -> record<organizationId: string, committedDataWorkers: int, regions: table<id: string, name: string, workspaces: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/get_data_worker_usage")
  let body = {organizationId: $organizationId, startDate: $startDate, endDate: $endDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a paginated list of organizations with an optional filter, containing a summary of various org data
#
# POST /v1/organizations/list_summaries
# operationId: listOrganizationSummaries
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "organizations-list-summaries listOrganizationSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # Internal Airbyte user ID (format: uuid)
  nameContains: string
  pagination: record # shape: {pageSize?: int, rowOffset?: int}
]: any -> record<organizationSummaries: table<organization: record, workspaces: list, memberCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/list_summaries")
  let body = {userId: $userId, nameContains: $nameContains, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an organization's basic organization info that is accessible for all organization members.
#
# POST /v1/organizations/get_organization_info
# operationId: getOrgInfo
export def "organizations-get-organization-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<organizationId: string, organizationName: string, sso: bool, billing: record<subscriptionStatus: string, paymentStatus: string, accountType: string, gracePeriodEndsAt: int>, organizationPlanId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/get_organization_info")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all pending domain verifications
#
# POST /v1/domain_verifications/list_pending
# operationId: listPendingDomainVerifications
export def "domain-verifications-list-pending listPendingDomainVerifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domainVerifications: table<id: string, organizationId: string, domain: string, verificationMethod: string, status: string, dnsRecordName: string, dnsRecordValue: string, attempts: int, expiresAt: int, verifiedAt: int, lastCheckedAt: int, createdAt: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain_verifications/list_pending")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check domain verification
#
# POST /v1/domain_verifications/check
# operationId: checkDomainVerification
export def "domain-verifications-check checkDomainVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domainVerificationId: string # format: uuid
]: any -> record<id: string, organizationId: string, domain: string, verificationMethod: string, status: string, dnsRecordName: string, dnsRecordValue: string, attempts: int, expiresAt: int, verifiedAt: int, lastCheckedAt: int, createdAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain_verifications/check")
  let body = {domainVerificationId: $domainVerificationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Provides the Airbyte deployment metadata.
#
# POST /v1/deployment/metadata
# operationId: getDeploymentMetadata
export def "deployment-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, mode: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deployment/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all Applications for a User.
#
# POST /v1/applications/list
# operationId: listApplications
export def "applications-list listApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applications: table<id: string, name: string, clientId: string, clientSecret: string, createdAt: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/applications/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an Application.
#
# POST /v1/applications/delete
# operationId: deleteApplication
export def "applications-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicationId: string # format: uuid
  --includeTombstone: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/applications/delete")
  let body = {applicationId: $applicationId, includeTombstone: $includeTombstone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new Application.
#
# POST /v1/applications/create
# operationId: createApplication
export def "applications-create createApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<id: string, name: string, clientId: string, clientSecret: string, createdAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/applications/create")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Grant an Access Token for an Application.
#
# POST /v1/applications/token
# operationId: applicationTokenRequest
export def "applications-token applicationTokenRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string
  client_secret: string
]: any -> record<access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/applications/token")
  let body = {client_id: $client_id, client_secret: $client_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all scoped configurations with a given key
#
# POST /v1/scoped_configuration/list
# operationId: getScopedConfigurationsList
export def "scoped-configuration-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config-key: string # Key of the configuration to filter by
  --origin-type: string # Type of origin to filter by
]: any -> record<scopedConfigurations: table<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped_configuration/list")
  let body = {config_key: $config_key, origin_type: $origin_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get related configurations for a given scope
#
# POST /v1/scoped_configuration/get_context
# operationId: getScopedConfigurationContext
export def "scoped-configuration-get-context post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config_key: string
  --resource-id: string # format: UUID
  --resource-type: string
  scope_id: string # format: UUID
  scope_type: string
]: any -> record<activeConfiguration: record<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>, ancestorConfigurations: table<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>, descendantConfigurations: table<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped_configuration/get_context")
  let body = {config_key: $config_key, resource_id: $resource_id, resource_type: $resource_type, scope_id: $scope_id, scope_type: $scope_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new scoped configuration
#
# POST /v1/scoped_configuration/create
# operationId: createScopedConfiguration
export def "scoped-configuration-create createScopedConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string
  --description: string
  --reference-url: string
  config_key: string
  --resource-id: string
  --resource-type: string
  scope_id: string
  scope_type: string
  origin: string
  origin_type: string
  --expires-at: string # format: date
]: any -> record<data: record<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped_configuration/create")
  let body = {value: $value, description: $description, reference_url: $reference_url, config_key: $config_key, resource_id: $resource_id, resource_type: $resource_type, scope_id: $scope_id, scope_type: $scope_type, origin: $origin, origin_type: $origin_type, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a scoped configuration by ID
#
# POST /v1/scoped_configuration/get
# operationId: getScopedConfigurationById
export def "scoped-configuration-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopedConfigurationId: string # format: uuid
]: any -> record<data: record<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped_configuration/get")
  let body = {scopedConfigurationId: $scopedConfigurationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a scoped configuration by ID
#
# POST /v1/scoped_configuration/update
# operationId: updateScopedConfiguration
# --data shape: {value: string, description?: string, reference_url?: string, config_key: string, resource_id?: string, resource_type?: string, scope_id: string, scope_type: string, origin: string, origin_type: string, expires_at?: string}
export def "scoped-configuration-update updateScopedConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopedConfigurationId: string # format: uuid
  data: record # shape: {value: string, description?: string, reference_url?: string, config_key: string, resource_id?: string, resource_type?: string, scope_id: string, scope_type: string, origin: string, origin_type: string, expires_at?: string}
]: any -> record<data: record<id: string, value: string, value_name: string, description: string, reference_url: string, config_key: string, resource_id: string, resource_name: string, resource_type: string, scope_id: string, scope_type: string, scope_name: string, origin: string, origin_type: string, origin_name: string, created_at: string, updated_at: string, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped_configuration/update")
  let body = {scopedConfigurationId: $scopedConfigurationId, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a scoped configuration by ID
#
# POST /v1/scoped_configuration/delete
# operationId: deleteScopedConfiguration
export def "scoped-configuration-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopedConfigurationId: string # format: uuid
]: any -> record<scopedConfigurationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scoped_configuration/delete")
  let body = {scopedConfigurationId: $scopedConfigurationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all connector rollouts matching the provided actor definition ID & docker image version
#
# POST /v1/connector_rollout/list
# operationId: getConnectorRolloutsList
export def "connector-rollout-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --docker-repository: string
  docker_image_tag: string
  actor_definition_id: string # format: uuid
]: any -> record<connectorRollouts: table<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/list")
  let body = {docker_repository: $docker_repository, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all connector rollouts matching the provided actor definition ID
#
# POST /v1/connector_rollout/list_by_actor_definition_id
# operationId: getConnectorRolloutsListByActorDefinitionId
export def "connector-rollout-list-by-actor-definition-id post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actor_definition_id: string # format: uuid
]: any -> record<connectorRollouts: table<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/list_by_actor_definition_id")
  let body = {actor_definition_id: $actor_definition_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all connector rollouts
#
# POST /v1/connector_rollout/list_all
# operationId: getConnectorRolloutsListAll
export def "connector-rollout-list-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connectorRollouts: table<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record, actor_syncs: record, tier: string, tag: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/list_all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a connector rollout by actor definition ID and version
#
# POST /v1/connector_rollout/get
# operationId: getConnectorRolloutById
export def "connector-rollout-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # format: uuid
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of actors pinned to a release candidate, and information about their syncs
#
# POST /v1/connector_rollout/get_actor_sync_info
# operationId: getConnectorRolloutActorSyncInfo
export def "connector-rollout-get-actor-sync-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # format: uuid
]: any -> record<data: record<actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, syncs: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/get_actor_sync_info")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a connector rollout by ID. This will update the state of the rollout from INITIALIZED to WORKFLOW_STARTED, and add the Temporal run ID of the workflow to the rollout entry.
#
# POST /v1/connector_rollout/start
# operationId: startConnectorRollout
export def "connector-rollout-start startConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # format: uuid
  workflow_run_id: string
  rollout_strategy: string@rollout-strategy-completer
  --updated-by: string # format: uuid
  --migrate-pins: string@bool-completer # default: true
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/start")
  let body = {id: $id, workflow_run_id: $workflow_run_id, rollout_strategy: $rollout_strategy, updated_by: $updated_by, migrate_pins: $migrate_pins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Roll out a release candidate. This will pin the actors to the release candidate version ID.
#
# POST /v1/connector_rollout/rollout
# operationId: doConnectorRollout
export def "connector-rollout-rollout doConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # format: uuid
  --actor-ids: list
  --target-percentage: int # format: int32
  rollout_strategy: string@rollout-strategy-completer
  --updated-by: string # format: uuid
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/rollout")
  let body = {id: $id, actor_ids: $actor_ids, target_percentage: $target_percentage, rollout_strategy: $rollout_strategy, updated_by: $updated_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update rollout state
#
# POST /v1/connector_rollout/update_state
# operationId: updateConnectorRolloutState
export def "connector-rollout-update-state updateConnectorRolloutState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # format: uuid
  --docker-repository: string
  --docker-image-tag: string
  --actor-definition-id: string # format: uuid
  state: string@state-completer
  --error-msg: string
  --failed-reason: string
  --paused-reason: string
  --updated-by: string # format: uuid
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/update_state")
  let body = {id: $id, docker_repository: $docker_repository, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id, state: $state, error_msg: $error_msg, failed_reason: $failed_reason, paused_reason: $paused_reason, updated_by: $updated_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finalize a connector rollout by ID. This will unpin all actors that have been pinned to the release candidate version.
#
# POST /v1/connector_rollout/finalize
# operationId: finalizeConnectorRollout
export def "connector-rollout-finalize finalizeConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # format: uuid
  state: string@state-completer-1
  --error-msg: string
  --failed-reason: string
  rollout_strategy: string@rollout-strategy-completer
  --updated-by: string # format: uuid
  --retain-pins-on-cancellation: string@bool-completer # default: true
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/finalize")
  let body = {id: $id, state: $state, error_msg: $error_msg, failed_reason: $failed_reason, rollout_strategy: $rollout_strategy, updated_by: $updated_by, retain_pins_on_cancellation: $retain_pins_on_cancellation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually start a connector rollout workflow. This will update the state of the rollout from INITIALIZED to WORKFLOW_STARTED, and add the Temporal run ID of the workflow to the rollout entry.
#
# POST /v1/connector_rollout/manual_start
# operationId: manualStartConnectorRollout
# --filters shape: {tierFilter?: record, jobBypassFilter?: record}
export def "connector-rollout-manual-start manualStartConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  docker_repository: string
  docker_image_tag: string
  actor_definition_id: string # format: uuid
  updated_by: string # format: uuid
  rollout_strategy: string@rollout-strategy-completer
  --initial-rollout-pct: int # format: int32
  --final-target-rollout-pct: int # format: int32
  --migrate-pins: string@bool-completer # default: true
  --filters: record # shape: {tierFilter?: record, jobBypassFilter?: record}
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/manual_start")
  let body = {docker_repository: $docker_repository, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id, updated_by: $updated_by, rollout_strategy: $rollout_strategy, initial_rollout_pct: $initial_rollout_pct, final_target_rollout_pct: $final_target_rollout_pct, migrate_pins: $migrate_pins, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually roll out a release candidate. This will pin the actors to the release candidate version ID.
#
# POST /v1/connector_rollout/manual_rollout
# operationId: manualDoConnectorRollout
# --filters shape: {tierFilter?: record, jobBypassFilter?: record}
export def "connector-rollout-manual-rollout manualDoConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  docker_repository: string
  docker_image_tag: string
  actor_definition_id: string # format: uuid
  id: string # format: uuid
  updated_by: string # format: uuid
  --actor-ids: list
  --target-percentage: int # format: int32
  --migrate-pins: string@bool-completer # default: true
  --filters: record # shape: {tierFilter?: record, jobBypassFilter?: record}
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/manual_rollout")
  let body = {docker_repository: $docker_repository, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id, id: $id, updated_by: $updated_by, actor_ids: $actor_ids, target_percentage: $target_percentage, migrate_pins: $migrate_pins, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually finalize a connector rollout by ID. This will unpin all actors that have been pinned to the release candidate version.
#
# POST /v1/connector_rollout/manual_finalize
# operationId: manualFinalizeConnectorRollout
export def "connector-rollout-manual-finalize manualFinalizeConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  docker_repository: string
  docker_image_tag: string
  actor_definition_id: string # format: uuid
  id: string # format: uuid
  updated_by: string # format: uuid
  state: string@state-completer-1
  --error-msg: string
  --failed-reason: string
  --retain-pins-on-cancellation: string@bool-completer # default: true
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/manual_finalize")
  let body = {docker_repository: $docker_repository, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id, id: $id, updated_by: $updated_by, state: $state, error_msg: $error_msg, failed_reason: $failed_reason, retain_pins_on_cancellation: $retain_pins_on_cancellation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update rollout state to paused
#
# POST /v1/connector_rollout/manual_pause
# operationId: manualPauseConnectorRollout
export def "connector-rollout-manual-pause manualPauseConnectorRollout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # format: uuid
  --docker-repository: string
  --docker-image-tag: string
  --actor-definition-id: string # format: uuid
  state: string@state-completer
  --error-msg: string
  --failed-reason: string
  --paused-reason: string
  --updated-by: string # format: uuid
]: any -> record<data: record<docker_repository: string, docker_image_tag: string, id: string, workflow_run_id: string, actor_definition_id: string, release_candidate_version_id: string, initial_version_id: string, state: string, initial_rollout_pct: int, current_target_rollout_pct: int, final_target_rollout_pct: int, has_breaking_changes: bool, max_step_wait_time_mins: int, updated_by: string, created_at: string, updated_at: string, completed_at: string, expires_at: string, error_msg: string, failed_reason: string, paused_reason: string, rollout_strategy: string, actor_selection_info: record<num_actors: int, num_actors_eligible_or_already_pinned: int, num_pinned_to_connector_rollout: int>, actor_syncs: record, tier: string, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connector_rollout/manual_pause")
  let body = {id: $id, docker_repository: $docker_repository, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id, state: $state, error_msg: $error_msg, failed_reason: $failed_reason, paused_reason: $paused_reason, updated_by: $updated_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Determine whether the organization is entitled to the specified resource
#
# POST /v1/entitlements/is_entitled
# operationId: checkEntitlement
export def "entitlements-is-entitled checkEntitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # format: uuid
  feature_id: string
]: any -> record<feature_id: string, is_entitled: bool, access_denied_reason: string, feature_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/entitlements/is_entitled")
  let body = {organization_id: $organization_id, feature_id: $feature_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of entitlements for the organization
#
# POST /v1/entitlements/get_entitlements
# operationId: getEntitlements
export def "entitlements-get-entitlements post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # format: uuid
]: any -> record<entitlements: table<feature_id: string, is_entitled: bool, access_denied_reason: string, feature_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/entitlements/get_entitlements")
  let body = {organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of all available entitlement plans
#
# POST /v1/entitlements/list_plans
# operationId: listAllEntitlementPlans
export def "entitlements-list-plans listAllEntitlementPlans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<plans: table<plan_id: string, plan_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/entitlements/list_plans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization's entitlement plan
#
# POST /v1/entitlements/update_plan
# operationId: updateOrganizationEntitlementPlan
export def "entitlements-update-plan updateOrganizationEntitlementPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # format: uuid
  plan_name: string@plan-name-completer
]: any -> record<organization_id: string, plan_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/entitlements/update_plan")
  let body = {organization_id: $organization_id, plan_name: $plan_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a user invitation
#
# POST /v1/user_invitations/create
# operationId: createUserInvitation
export def "user-invitations-create createUserInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invitedEmail: string # format: email
  permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
  scopeType: string@scopeType-completer
  scopeId: string # format: uuid
]: any -> record<inviteCode: string, directlyAdded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user_invitations/create")
  let body = {invitedEmail: $invitedEmail, permissionType: $permissionType, scopeType: $scopeType, scopeId: $scopeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user invitation by its unique code (not primary key ID)
#
# GET /v1/user_invitations/by_code/{inviteCode}
# operationId: getUserInvitation
export def "user-invitations-by-code get" [
  inviteCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, inviteCode: string, inviterUserId: string, invitedEmail: string, scopeId: string, scopeType: string, permissionType: string, status: string, createdAt: int, updatedAt: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/user_invitations/by_code/($inviteCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending invitations
#
# POST /v1/user_invitations/list_pending
# operationId: listPendingInvitations
export def "user-invitations-list-pending listPendingInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopeType: string@scopeType-completer
  scopeId: string # format: uuid
]: any -> table<id: string, inviteCode: string, inviterUserId: string, invitedEmail: string, scopeId: string, scopeType: string, permissionType: string, status: string, createdAt: int, updatedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user_invitations/list_pending")
  let body = {scopeType: $scopeType, scopeId: $scopeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accept a user invitation
#
# POST /v1/user_invitations/accept
# operationId: acceptUserInvitation
export def "user-invitations-accept acceptUserInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inviteCode: string
]: any -> record<id: string, inviteCode: string, inviterUserId: string, invitedEmail: string, scopeId: string, scopeType: string, permissionType: string, status: string, createdAt: int, updatedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user_invitations/accept")
  let body = {inviteCode: $inviteCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Decline a user invitation
#
# POST /v1/user_invitations/decline
# operationId: declineUserInvitation
export def "user-invitations-decline declineUserInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inviteCode: string
]: any -> record<id: string, inviteCode: string, inviterUserId: string, invitedEmail: string, scopeId: string, scopeType: string, permissionType: string, status: string, createdAt: int, updatedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user_invitations/decline")
  let body = {inviteCode: $inviteCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a user invitation
#
# POST /v1/user_invitations/cancel
# operationId: cancelUserInvitation
export def "user-invitations-cancel cancelUserInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inviteCode: string
]: any -> record<id: string, inviteCode: string, inviterUserId: string, invitedEmail: string, scopeId: string, scopeType: string, permissionType: string, status: string, createdAt: int, updatedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user_invitations/cancel")
  let body = {inviteCode: $inviteCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tags in a workspace
#
# POST /v1/tags/list
# operationId: listTags
export def "tags-list listTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
]: any -> table<tagId: string, workspaceId: string, name: string, color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags/list")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a tag
#
# POST /v1/tags/update
# operationId: updateTag
export def "tags-update updateTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tagId: string # format: uuid
  workspaceId: string # format: uuid
  name: string
  color: string
]: any -> record<tagId: string, workspaceId: string, name: string, color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags/update")
  let body = {tagId: $tagId, workspaceId: $workspaceId, name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag
#
# POST /v1/tags/delete
# operationId: deleteTag
export def "tags-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tagId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<tagId: string, workspaceId: string, name: string, color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags/delete")
  let body = {tagId: $tagId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a tag
#
# POST /v1/tags/create
# operationId: createTag
export def "tags-create createTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  name: string
  color: string
]: any -> record<tagId: string, workspaceId: string, name: string, color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tags/create")
  let body = {workspaceId: $workspaceId, name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a diagnostic report
#
# POST /v1/diagnostic_tool/generate_report
# operationId: generateDiagnosticReport
export def "diagnostic-tool-generate-report generateDiagnosticReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/diagnostic_tool/generate_report")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Signal that an operation is terminal
#
# POST /v1/signal
# operationId: signal
export def "signal signal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workflowType: string
  workflowId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/signal")
  let body = {workflowType: $workflowType, workflowId: $workflowId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compute the diff between two catalogs
#
# POST /v1/catalogs/diff
# operationId: diffCatalogs
export def "catalogs-diff diffCatalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  current_catalog_id: string # The ID of the current catalog (format: uuid)
  new_catalog_id: string # The ID of the new catalog (format: uuid)
  --connection-id: string # Optional connection ID for additional workspace validation and breaking change detection based on configured streams (format: uuid)
  --persist-changes: string@bool-completer # If true, persist the catalog changes to the connection (requires connection_id and WORKSPACE_EDITOR role). Updates breakingChange flag and status (set to INACTIVE if breaking change detected or if nonBreakingChangesPreference is DISABLE and there are any changes). Does not update sourceCatalogId or syncCatalog. (default: false)
]: any -> record<catalog_diff: record<transforms: list<record>>, schema_change: string, merged_catalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/catalogs/diff")
  let body = {current_catalog_id: $current_catalog_id, new_catalog_id: $new_catalog_id, connection_id: $connection_id, persist_changes: $persist_changes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a Check command for a Connector
#
# POST /v1/commands/run/check
# operationId: runCheckCommand
export def "commands-run-check runCheckCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # a command id which acts as an idempotency key.
  --workspace-id: string # format: uuid
  --actor-id: string # format: uuid
  --actor-definition-id: string # format: uuid
  --config: record
  --job-id: string # internal usage
  --attempt-number: int # format: int32
  --priority: string # internal usage
  --signal-input: string # internal usage
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/run/check")
  let body = {id: $id, workspace_id: $workspace_id, actor_id: $actor_id, actor_definition_id: $actor_definition_id, config: $config, job_id: $job_id, attempt_number: $attempt_number, priority: $priority, signal_input: $signal_input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a Discover command for a Connector
#
# POST /v1/commands/run/discover
# operationId: runDiscoverCommand
export def "commands-run-discover runDiscoverCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # a command id which acts as an idempotency key.
  actor_id: string # format: uuid
  --jobId: string # internal usage
  --attemptNumber: int # format: int32
  --priority: string # internal usage
  --signal-input: string # internal usage
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/run/discover")
  let body = {id: $id, actor_id: $actor_id, jobId: $jobId, attemptNumber: $attemptNumber, priority: $priority, signal_input: $signal_input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a Replicate command for a Connection
#
# POST /v1/commands/run/replicate
# operationId: runReplicateCommand
# --applied_catalog_diff shape: {transforms: list}
export def "commands-run-replicate runReplicateCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # a command id which acts as an idempotency key.
  connection_id: string # format: uuid
  job_id: string # internal usage
  attempt_number: int # format: int32
  --applied-catalog-diff: record # Describes the difference between two Airbyte catalogs. — shape: {transforms: list}
  --signal-input: string # internal usage
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/run/replicate")
  let body = {id: $id, connection_id: $connection_id, job_id: $job_id, attempt_number: $attempt_number, applied_catalog_diff: $applied_catalog_diff, signal_input: $signal_input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a Spec command for a Connector
#
# POST /v1/commands/run/spec
# operationId: runSpecCommand
export def "commands-run-spec runSpecCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # a command id which acts as an idempotency key.
  workspace_id: string # format: uuid
  --docker-image: string # the docker image (without tag) for a custom connector
  docker_image_tag: string # the docker image tag
  --actor-definition-id: string # the actor definition id for a registered connector (format: uuid)
  --signal-input: string # internal usage
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/run/spec")
  let body = {id: $id, workspace_id: $workspace_id, docker_image: $docker_image, docker_image_tag: $docker_image_tag, actor_definition_id: $actor_definition_id, signal_input: $signal_input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of a check command
#
# POST /v1/commands/output/check
# operationId: getCheckCommandOutput
export def "commands-output-check post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
  --with-logs: string@bool-completer # default: false
]: any -> record<id: string, status: string, connectorConfigurationUpdated: bool, message: string, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record<name: string, namespace: string>>, logs: record<logType: string, logEvents: record<events: list, version: string>, logLines: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/output/check")
  let body = {id: $id, with_logs: $with_logs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of a discover command
#
# POST /v1/commands/output/discover
# operationId: getDiscoverCommandOutput
export def "commands-output-discover post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
  --with-logs: string@bool-completer # default: false
]: any -> record<id: string, status: string, catalog: record<streams: list<record>>, catalogId: string, destinationCatalog: record<operations: list<record>>, catalogDiff: record<transforms: list<record>>, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record<name: string, namespace: string>>, logs: record<logType: string, logEvents: record<events: list, version: string>, logLines: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/output/discover")
  let body = {id: $id, with_logs: $with_logs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of a replicate command
#
# POST /v1/commands/output/replicate
# operationId: getReplicateCommandOutput
export def "commands-output-replicate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
]: any -> record<id: string, attempt_summary: record, failures: table<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record>, catalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/output/replicate")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the output of a spec command
#
# POST /v1/commands/output/spec
# operationId: getSpecCommandOutput
export def "commands-output-spec post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
  --with-logs: string@bool-completer # default: false
]: any -> record<id: string, status: string, spec: record, failureReason: record<failureOrigin: string, failureType: string, externalMessage: string, internalMessage: string, stacktrace: string, retryable: bool, timestamp: int, fromTraceMessage: bool, streamDescriptor: record<name: string, namespace: string>>, logs: record<logType: string, logEvents: record<events: list, version: string>, logLines: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/output/spec")
  let body = {id: $id, with_logs: $with_logs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of command
#
# POST /v1/commands/status
# operationId: getCommandStatus
export def "commands-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
]: any -> record<id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/status")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the a command record
#
# POST /v1/commands/get
# operationId: getCommand
export def "commands-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
]: any -> record<id: string, workload_id: string, command_type: string, command_input: string, workspace_id: string, organization_id: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of command
#
# POST /v1/commands/cancel
# operationId: cancelCommand
export def "commands-cancel cancelCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/commands/cancel")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Write the output of a workload
#
# POST /v1/workload_output/write
# operationId: writeWorkloadOutput
export def "workload-output-write writeWorkloadOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workloadId: string
  output: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workload_output/write")
  let body = {workloadId: $workloadId, output: $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a dataplane group
#
# POST /v1/dataplane_group/create
# operationId: createDataplaneGroup
export def "dataplane-group-create createDataplaneGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # format: UUID
  name: string
  --enabled: string@bool-completer
]: any -> record<name: string, dataplane_group_id: string, organization_id: string, enabled: bool, created_at: string, updated_at: string, dataplanes: table<name: string, dataplane_id: string, dataplane_group_id: string, enabled: bool, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplane_group/create")
  let body = {organization_id: $organization_id, name: $name, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a dataplane group
#
# POST /v1/dataplane_group/update
# operationId: updateDataplaneGroup
export def "dataplane-group-update updateDataplaneGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dataplane_group_id: string # format: uuid
  --name: string
  --enabled: string@bool-completer
]: any -> record<name: string, dataplane_group_id: string, organization_id: string, enabled: bool, created_at: string, updated_at: string, dataplanes: table<name: string, dataplane_id: string, dataplane_group_id: string, enabled: bool, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplane_group/update")
  let body = {dataplane_group_id: $dataplane_group_id, name: $name, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dataplane group
#
# POST /v1/dataplane_group/delete
# operationId: deleteDataplaneGroup
export def "dataplane-group-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dataplane_group_id: string # format: uuid
]: any -> record<name: string, dataplane_group_id: string, organization_id: string, enabled: bool, created_at: string, updated_at: string, dataplanes: table<name: string, dataplane_id: string, dataplane_group_id: string, enabled: bool, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplane_group/delete")
  let body = {dataplane_group_id: $dataplane_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List dataplane groups for the organization
#
# POST /v1/dataplane_group/list
# operationId: listDataplaneGroups
export def "dataplane-group-list listDataplaneGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # format: uuid
]: any -> record<dataplaneGroups: table<name: string, dataplane_group_id: string, organization_id: string, enabled: bool, created_at: string, updated_at: string, dataplanes: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplane_group/list")
  let body = {organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a dataplane
#
# POST /v1/dataplanes/create
# operationId: createDataplane
export def "dataplanes-create createDataplane" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dataplane_group_id: string # format: UUID
  name: string
  --enabled: string@bool-completer
  --instanceScope: string@bool-completer # default: false
]: any -> record<dataplane_id: string, region_id: string, client_id: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/create")
  let body = {dataplane_group_id: $dataplane_group_id, name: $name, enabled: $enabled, instanceScope: $instanceScope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a dataplane
#
# POST /v1/dataplanes/update
# operationId: updateDataplane
export def "dataplanes-update updateDataplane" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dataplane_id: string # format: uuid
  --name: string
  --enabled: string@bool-completer
]: any -> record<name: string, dataplane_id: string, dataplane_group_id: string, enabled: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/update")
  let body = {dataplane_id: $dataplane_id, name: $name, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dataplane
#
# POST /v1/dataplanes/delete
# operationId: deleteDataplane
export def "dataplanes-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dataplane_id: string # format: uuid
]: any -> record<name: string, dataplane_id: string, dataplane_group_id: string, enabled: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/delete")
  let body = {dataplane_id: $dataplane_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List dataplanes for the dataplane group
#
# POST /v1/dataplanes/list
# operationId: listDataplanes
export def "dataplanes-list listDataplanes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dataplane_group_id: string # format: uuid
]: any -> record<dataplanes: table<name: string, dataplane_id: string, dataplane_group_id: string, enabled: bool, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/list")
  let body = {dataplane_group_id: $dataplane_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a token for dataplane requests
#
# POST /v1/dataplanes/token
# operationId: getDataplaneToken
export def "dataplanes-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string
  client_secret: string
]: any -> record<access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/token")
  let body = {client_id: $client_id, client_secret: $client_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For a dataplane to signal it is still alive
#
# POST /v1/dataplanes/heartbeat
# operationId: heartbeatDataplane
export def "dataplanes-heartbeat heartbeatDataplane" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Airbyte-Version: string # Airbyte application version
  client_id: string
]: any -> record<dataplane_name: string, dataplane_id: string, dataplane_enabled: bool, dataplane_group_name: string, dataplane_group_id: string, organization_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/heartbeat")
  let body = {client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Airbyte-Version": $X_Airbyte_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get health status for dataplanes
#
# POST /v1/dataplanes/health
# operationId: listDataplaneHealth
export def "dataplanes-health listDataplaneHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<dataplanes: table<dataplane_id: string, dataplane_name: string, dataplane_group_id: string, organization_id: string, status: string, last_heartbeat_timestamp: int, recent_heartbeats: list, control_plane_version: string, dataplane_version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/health")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns information needed for dataplane startup and initialization (groups, queues, AuthN identify, etc.)
#
# POST /v1/dataplanes/initialize
# operationId: initializeDataplane
export def "dataplanes-initialize initializeDataplane" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Airbyte-Version: string # Airbyte application version
  client_id: string
]: any -> record<dataplane_name: string, dataplane_id: string, dataplane_enabled: bool, dataplane_group_name: string, dataplane_group_id: string, organization_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataplanes/initialize")
  let body = {client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Airbyte-Version": $X_Airbyte_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the sso config for an organization
#
# POST /v1/sso_config/get
# operationId: getSsoConfig
export def "sso-config-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<organizationId: string, companyIdentifier: string, clientId: string, clientSecret: string, emailDomains: list<string>, status: string, defaultRole: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sso_config/get")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Onboard a cloud customer to SSO
#
# POST /v1/sso_config/create
# operationId: createSsoConfig
export def "sso-config-create createSsoConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  companyIdentifier: string # Used to name the keycloak realm
  clientId: string
  clientSecret: string
  discoveryUrl: string # format: url
  --emailDomain: string
  status: string@status-completer-2
  --defaultRole: string@defaultRole-completer # Default organization role granted to users provisioned by an SSO configuration. If omitted, defaults to organization_member.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sso_config/create")
  let body = {organizationId: $organizationId, companyIdentifier: $companyIdentifier, clientId: $clientId, clientSecret: $clientSecret, discoveryUrl: $discoveryUrl, emailDomain: $emailDomain, status: $status, defaultRole: $defaultRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an SSO config
#
# POST /v1/sso_config/delete
# operationId: deleteSsoConfig
export def "sso-config-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  companyIdentifier: string # Matches the keycloak realm to be removed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sso_config/delete")
  let body = {organizationId: $organizationId, companyIdentifier: $companyIdentifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a client id and client secret for an SSO IDP
#
# POST /v1/sso_config/update_credentials
# operationId: updateSsoCredentials
export def "sso-config-update-credentials updateSsoCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  clientId: string
  clientSecret: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sso_config/update_credentials")
  let body = {organizationId: $organizationId, clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate a draft SSO config
#
# POST /v1/sso_config/activate
# operationId: activateSsoConfig
export def "sso-config-activate activateSsoConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  --emailDomain: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sso_config/activate")
  let body = {organizationId: $organizationId, emailDomain: $emailDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate an access token against an organization's SSO realm
#
# POST /v1/sso_config/validate_token
# operationId: validateSsoToken
export def "sso-config-validate-token validateSsoToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  accessToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sso_config/validate_token")
  let body = {organizationId: $organizationId, accessToken: $accessToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Root path, currently returns a redirect to the documentation
#
# GET /public
# operationId: getDocumentation
export def "public get" [
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
  let full_url = (build-url $base "/public")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Health Check
#
# GET /public/v1/health
# operationId: publicGetHealthCheck
export def "public-health publicGetHealthCheck" [
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
  let full_url = (build-url $base "/public/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Applications
#
# GET /public/v1/applications
# operationId: publicListApplications
export def "public-applications publicListApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applications: table<id: string, name: string, clientId: string, clientSecret: string, createdAt: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/applications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Application
#
# POST /public/v1/applications
# operationId: publicCreateApplication
export def "public-applications publicCreateApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<id: string, name: string, clientId: string, clientSecret: string, createdAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/applications")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Application detail
#
# GET /public/v1/applications/{applicationId}
# operationId: publicGetApplication
export def "public-applications publicGetApplication" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, clientId: string, clientSecret: string, createdAt: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/applications/($applicationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an Application
#
# DELETE /public/v1/applications/{applicationId}
# operationId: publicDeleteApplication
export def "public-applications publicDeleteApplication" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, clientId: string, clientSecret: string, createdAt: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/applications/($applicationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Access Token
#
# POST /public/v1/applications/token
# operationId: publicGetAccessToken
export def "public-applications-token publicGetAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string
  client_secret: string
  --grant-type: any@grant-type-completer
]: any -> record<access_token: string, token_type: any, expires_in: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/applications/token")
  let body = {client_id: $client_id, client_secret: $client_secret, grant-type: $grant_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Jobs by sync type
#
# GET /public/v1/jobs
# operationId: listJobs
export def "public-jobs listJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectionId: string # Filter the Jobs by connectionId. (format: UUID)
  --limit: int # Set the limit on the number of Jobs returned. The default is 20 Jobs. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning Jobs. The default is 0. (format: int32, default: 0)
  --jobType: string # Filter the Jobs by jobType.
  --workspaceIds: list # The UUIDs of the workspaces you wish to list jobs for. Empty list will retrieve all allowed workspaces.
  --status: string # The Job status you want to filter by
  --createdAtStart: string # The start date to filter by (format: date-time, e.g. 2023-06-22T16:15:00Z)
  --createdAtEnd: string # The end date to filter by (format: date-time, e.g. 2023-06-22T16:15:00Z)
  --updatedAtStart: string # The start date to filter by (format: date-time, e.g. 2023-06-22T16:15:00Z)
  --updatedAtEnd: string # The end date to filter by (format: date-time, e.g. 2023-06-22T16:15:00Z)
  --orderBy: string # The field and method to use for ordering (e.g. updatedAt|DESC)
]: nothing -> record<previous: string, next: string, data: table<jobId: int, status: string, jobType: string, startTime: string, connectionId: string, lastUpdatedAt: string, duration: string, bytesSynced: int, rowsSynced: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connectionId" $connectionId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "jobType" $jobType "scalar") (serialize-qp "workspaceIds" $workspaceIds "multi") (serialize-qp "status" $status "scalar") (serialize-qp "createdAtStart" $createdAtStart "scalar") (serialize-qp "createdAtEnd" $createdAtEnd "scalar") (serialize-qp "updatedAtStart" $updatedAtStart "scalar") (serialize-qp "updatedAtEnd" $updatedAtEnd "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a sync or reset job of a connection
#
# POST /public/v1/jobs
# operationId: publicCreateJob
export def "public-jobs publicCreateJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  connectionId: string # format: UUID
  jobType: string@jobType-completer-1 # Enum that describes the different types of jobs that the platform runs. When not specified, all job types are returned.
]: any -> record<jobId: int, status: string, jobType: string, startTime: string, connectionId: string, lastUpdatedAt: string, duration: string, bytesSynced: int, rowsSynced: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/jobs")
  let body = {connectionId: $connectionId, jobType: $jobType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Job status and details
#
# GET /public/v1/jobs/{jobId}
# operationId: getJob
export def "public-jobs get" [
  jobId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobId: int, status: string, jobType: string, startTime: string, connectionId: string, lastUpdatedAt: string, duration: string, bytesSynced: int, rowsSynced: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a running Job
#
# DELETE /public/v1/jobs/{jobId}
# operationId: publicCancelJob
export def "public-jobs publicCancelJob" [
  jobId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobId: int, status: string, jobType: string, startTime: string, connectionId: string, lastUpdatedAt: string, duration: string, bytesSynced: int, rowsSynced: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List regions
#
# GET /public/v1/regions
# operationId: publicListRegions
export def "public-regions publicListRegions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: string # The UUID of the organization to list regions for (format: uuid)
]: nothing -> record<data: table<regionId: string, name: string, organizationId: string, enabled: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a region
#
# POST /public/v1/regions
# operationId: publicCreateRegion
export def "public-regions publicCreateRegion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  organizationId: string # format: uuid
  --enabled: string@bool-completer
]: any -> record<regionId: string, name: string, organizationId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/regions")
  let body = {name: $name, organizationId: $organizationId, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a region
#
# GET /public/v1/regions/{regionId}
# operationId: publicGetRegion
export def "public-regions publicGetRegion" [
  regionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<regionId: string, name: string, organizationId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/regions/($regionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a region
#
# PATCH /public/v1/regions/{regionId}
# operationId: publicUpdateRegion
export def "public-regions publicUpdateRegion" [
  regionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --enabled: string@bool-completer
]: any -> record<regionId: string, name: string, organizationId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/regions/($regionId)")
  let body = {name: $name, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a region
#
# DELETE /public/v1/regions/{regionId}
# operationId: publicDeleteRegion
export def "public-regions publicDeleteRegion" [
  regionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<regionId: string, name: string, organizationId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/regions/($regionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List dataplanes
#
# GET /public/v1/dataplanes
# operationId: publicListDataplanes
export def "public-dataplanes publicListDataplanes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --regionIds: list # The UUIDs of the regions to filter by. If provided, only dataplanes belonging to these regions will be returned. Empty list will retrieve all dataplanes accessible to the current user.
]: nothing -> record<data: table<dataplaneId: string, name: string, regionId: string, enabled: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "regionIds" $regionIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/dataplanes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dataplane
#
# POST /public/v1/dataplanes
# operationId: publicCreateDataplane
export def "public-dataplanes publicCreateDataplane" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  regionId: string # format: uuid
  name: string
  --enabled: string@bool-completer
]: any -> record<dataplaneId: string, regionId: string, clientId: string, clientSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/dataplanes")
  let body = {regionId: $regionId, name: $name, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a dataplane
#
# GET /public/v1/dataplanes/{dataplaneId}
# operationId: publicGetDataplane
export def "public-dataplanes publicGetDataplane" [
  dataplaneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dataplaneId: string, name: string, regionId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/dataplanes/($dataplaneId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dataplane
#
# PATCH /public/v1/dataplanes/{dataplaneId}
# operationId: publicUpdateDataplane
export def "public-dataplanes publicUpdateDataplane" [
  dataplaneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --enabled: string@bool-completer
]: any -> record<dataplaneId: string, name: string, regionId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/dataplanes/($dataplaneId)")
  let body = {name: $name, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dataplane
#
# DELETE /public/v1/dataplanes/{dataplaneId}
# operationId: publicDeleteDataplane
export def "public-dataplanes publicDeleteDataplane" [
  dataplaneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dataplaneId: string, name: string, regionId: string, enabled: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/dataplanes/($dataplaneId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List connector definitions
#
# GET /public/v1/connector_definitions
# operationId: listConnectorDefinitions
export def "public-connector-definitions listConnectorDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # The type of connector definition to list
  --workspaceId: string # The UUID of the workspace you wish to list connector definitions for. One of this or organizationId must be populated. (format: uuid, e.g. df08f6b0-b364-4cc1-9b3f-96f5d2fccfb2)
]: nothing -> record<data: table<id: string, name: string, connectorDefinitionType: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "workspaceId" $workspaceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/connector_definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List declarative source definitions.
#
# GET /public/v1/workspaces/{workspaceId}/definitions/declarative_sources
# operationId: publicListDeclarativeSourceDefinitions
export def "public-workspaces-definitions-declarative-sources publicListDeclarativeSourceDefinitions" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<previous: string, next: string, data: table<id: string, name: string, manifest: record, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/declarative_sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a declarative source definition.
#
# POST /public/v1/workspaces/{workspaceId}/definitions/declarative_sources
# operationId: publicCreateDeclarativeSourceDefinition
export def "public-workspaces-definitions-declarative-sources publicCreateDeclarativeSourceDefinition" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  manifest: record # Low code CDK manifest JSON object
]: any -> record<id: string, name: string, manifest: record, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/declarative_sources")
  let body = {name: $name, manifest: $manifest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get declarative source definition details.
#
# GET /public/v1/workspaces/{workspaceId}/definitions/declarative_sources/{definitionId}
# operationId: publicGetDeclarativeSourceDefinition
export def "public-workspaces-definitions-declarative-sources publicGetDeclarativeSourceDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, manifest: record, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/declarative_sources/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update declarative source definition details.
#
# PUT /public/v1/workspaces/{workspaceId}/definitions/declarative_sources/{definitionId}
# operationId: publicUpdateDeclarativeSourceDefinition
export def "public-workspaces-definitions-declarative-sources publicUpdateDeclarativeSourceDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  manifest: record # Low code CDK manifest JSON object
]: any -> record<id: string, name: string, manifest: record, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/declarative_sources/($definitionId)")
  let body = {manifest: $manifest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a declarative source definition.
#
# DELETE /public/v1/workspaces/{workspaceId}/definitions/declarative_sources/{definitionId}
# operationId: publicDeleteDeclarativeSourceDefinition
export def "public-workspaces-definitions-declarative-sources publicDeleteDeclarativeSourceDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, manifest: record, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/declarative_sources/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List source definitions.
#
# GET /public/v1/workspaces/{workspaceId}/definitions/sources
# operationId: publicListSourceDefinitions
export def "public-workspaces-definitions-sources publicListSourceDefinitions" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<previous: string, next: string, data: table<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a source definition.
#
# POST /public/v1/workspaces/{workspaceId}/definitions/sources
# operationId: publicCreateSourceDefinition
export def "public-workspaces-definitions-sources publicCreateSourceDefinition" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  dockerRepository: string
  dockerImageTag: string
  --documentationUrl: string # format: uri
]: any -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/sources")
  let body = {name: $name, dockerRepository: $dockerRepository, dockerImageTag: $dockerImageTag, documentationUrl: $documentationUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get source definition details.
#
# GET /public/v1/workspaces/{workspaceId}/definitions/sources/{definitionId}
# operationId: publicGetSourceDefinition
export def "public-workspaces-definitions-sources publicGetSourceDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/sources/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update source definition details.
#
# PUT /public/v1/workspaces/{workspaceId}/definitions/sources/{definitionId}
# operationId: publicUpdateSourceDefinition
export def "public-workspaces-definitions-sources publicUpdateSourceDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  dockerImageTag: string
]: any -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/sources/($definitionId)")
  let body = {name: $name, dockerImageTag: $dockerImageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a source definition.
#
# DELETE /public/v1/workspaces/{workspaceId}/definitions/sources/{definitionId}
# operationId: publicDeleteSourceDefinition
export def "public-workspaces-definitions-sources publicDeleteSourceDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/sources/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List destination definitions.
#
# GET /public/v1/workspaces/{workspaceId}/definitions/destinations
# operationId: publicListDestinationDefinitions
export def "public-workspaces-definitions-destinations publicListDestinationDefinitions" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<previous: string, next: string, data: table<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/destinations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a destination definition.
#
# POST /public/v1/workspaces/{workspaceId}/definitions/destinations
# operationId: publicCreateDestinationDefinition
export def "public-workspaces-definitions-destinations publicCreateDestinationDefinition" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  dockerRepository: string
  dockerImageTag: string
  --documentationUrl: string # format: uri
]: any -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/destinations")
  let body = {name: $name, dockerRepository: $dockerRepository, dockerImageTag: $dockerImageTag, documentationUrl: $documentationUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get destination definition details.
#
# GET /public/v1/workspaces/{workspaceId}/definitions/destinations/{definitionId}
# operationId: publicGetDestinationDefinition
export def "public-workspaces-definitions-destinations publicGetDestinationDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/destinations/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update destination definition details.
#
# PUT /public/v1/workspaces/{workspaceId}/definitions/destinations/{definitionId}
# operationId: publicUpdateDestinationDefinition
export def "public-workspaces-definitions-destinations publicUpdateDestinationDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  dockerImageTag: string
]: any -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/destinations/($definitionId)")
  let body = {name: $name, dockerImageTag: $dockerImageTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a destination definition.
#
# DELETE /public/v1/workspaces/{workspaceId}/definitions/destinations/{definitionId}
# operationId: publicDeleteDestinationDefinition
export def "public-workspaces-definitions-destinations publicDeleteDestinationDefinition" [
  workspaceId: string
  definitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, dockerRepository: string, dockerImageTag: string, documentationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/definitions/destinations/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sources
#
# GET /public/v1/sources
# operationId: listSources
export def "public-sources listSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceIds: list # The UUIDs of the workspaces you wish to list sources for. Empty list will retrieve all allowed workspaces. (e.g. df08f6b0-b364-4cc1-9b3f-96f5d2fccfb2,b0796797-de23-4fc7-a5e2-7e131314718c)
  --includeDeleted: string@bool-completer # Include deleted sources in the returned results. (default: false)
  --limit: int # Set the limit on the number of sources returned. The default is 20. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning sources. The default is 0 (format: int32, default: 0)
]: nothing -> record<previous: string, next: string, data: table<sourceId: string, name: string, sourceType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceIds" $workspaceIds "multi") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a source
#
# POST /public/v1/sources
# operationId: publicCreateSource
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "public-sources publicCreateSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the source e.g. dev-mysql-instance.
  --definitionId: string # The UUID of the connector definition. One of configuration.sourceType or definitionId must be provided. (format: uuid)
  workspaceId: string # format: uuid
  configuration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --secretId: string # Optional secretID obtained through the  OAuth redirect flow.
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<sourceId: string, name: string, sourceType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/sources")
  let body = {name: $name, definitionId: $definitionId, workspaceId: $workspaceId, configuration: $configuration, secretId: $secretId, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Source details
#
# GET /public/v1/sources/{sourceId}
# operationId: publicGetSource
export def "public-sources publicGetSource" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeSecretCoordinates: string@bool-completer # Rather than return *** for secret properties include the secret coordinate information
]: nothing -> record<sourceId: string, name: string, sourceType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeSecretCoordinates" $includeSecretCoordinates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/sources/($sourceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Source
#
# PATCH /public/v1/sources/{sourceId}
# operationId: patchSource
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "public-sources patch" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. My source
  --workspaceId: string # format: uuid
  --configuration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --secretId: string # Optional secretID obtained through the  OAuth redirect flow.
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<sourceId: string, name: string, sourceType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/sources/($sourceId)")
  let body = {name: $name, workspaceId: $workspaceId, configuration: $configuration, secretId: $secretId, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Source and fully overwrite it
#
# PUT /public/v1/sources/{sourceId}
# operationId: putSource
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "public-sources put" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  configuration: record # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<sourceId: string, name: string, sourceType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/sources/($sourceId)")
  let body = {name: $name, configuration: $configuration, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Source
#
# DELETE /public/v1/sources/{sourceId}
# operationId: publicDeleteSource
export def "public-sources publicDeleteSource" [
  sourceId: string
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
  let full_url = (build-url $base $"/public/v1/sources/($sourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List destinations
#
# GET /public/v1/destinations
# operationId: listDestinations
export def "public-destinations listDestinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceIds: list # The UUIDs of the workspaces you wish to list destinations for. Empty list will retrieve all allowed workspaces.
  --includeDeleted: string@bool-completer # Include deleted destinations in the returned results. (default: false)
  --limit: int # Set the limit on the number of destinations returned. The default is 20. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning destinations. The default is 0 (format: int32, default: 0)
]: nothing -> record<previous: string, next: string, data: table<destinationId: string, name: string, destinationType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceIds" $workspaceIds "multi") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/destinations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a destination
#
# POST /public/v1/destinations
# operationId: publicCreateDestination
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "public-destinations publicCreateDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the destination e.g. dev-mysql-instance.
  --definitionId: string # The UUID of the connector definition. One of configuration.destinationType or definitionId must be provided. (format: uuid)
  workspaceId: string # format: uuid
  configuration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationId: string, name: string, destinationType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/destinations")
  let body = {name: $name, definitionId: $definitionId, workspaceId: $workspaceId, configuration: $configuration, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Destination details
#
# GET /public/v1/destinations/{destinationId}
# operationId: publicGetDestination
export def "public-destinations publicGetDestination" [
  destinationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeSecretCoordinates: string@bool-completer # Rather than return *** for secret properties include the secret coordinate information
]: nothing -> record<destinationId: string, name: string, destinationType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeSecretCoordinates" $includeSecretCoordinates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/destinations/($destinationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Destination
#
# DELETE /public/v1/destinations/{destinationId}
# operationId: publicDeleteDestination
export def "public-destinations publicDeleteDestination" [
  destinationId: string
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
  let full_url = (build-url $base $"/public/v1/destinations/($destinationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Destination
#
# PATCH /public/v1/destinations/{destinationId}
# operationId: patchDestination
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "public-destinations patch" [
  destinationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --configuration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationId: string, name: string, destinationType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/destinations/($destinationId)")
  let body = {name: $name, configuration: $configuration, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Destination and fully overwrite it
#
# PUT /public/v1/destinations/{destinationId}
# operationId: putDestination
# --resourceAllocation shape: {default?: record, jobSpecific?: list}
export def "public-destinations put" [
  destinationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  configuration: record # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --resourceAllocation: record # actor or actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationId: string, name: string, destinationType: string, definitionId: string, workspaceId: string, configuration: record, createdAt: int, resourceAllocation: record<default: record<cpu_request: string, cpu_limit: string, memory_request: string, memory_limit: string, ephemeral_storage_request: string, ephemeral_storage_limit: string>, jobSpecific: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/destinations/($destinationId)")
  let body = {name: $name, configuration: $configuration, resourceAllocation: $resourceAllocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Receive OAuth callbacks
#
# GET /public/v1/oauth/callback
# operationId: oauthCallback
export def "public-oauth-callback oauthCallback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --queryParams: record # Query parameters. Should contain state and code.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryParams" $queryParams "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/oauth/callback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate OAuth for a source
#
# POST /public/v1/sources/initiateOAuth
# operationId: initiateOAuth
export def "public-sources-initiate-o-auth initiateOAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the source to authenticate to. Deprecated - use sourceType instead.
  --sourceType: string # The name of the source to authenticate to
  redirectUrl: string # Redirect target after OAuth callback. In `api` mode, callback includes `secret_id`, `state`, `workspace_id`, and `definition_id`. In `webapp` mode, callback forwards all provider callback query params.
  --clientType: string@clientType-completer # OAuth callback mode. `api` is default when omitted. `webapp` forwards provider callback query params and does not create a secret during callback.
  workspaceId: string # The workspace to create the secret and eventually the full source. (format: uuid)
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --requestedScopes: list # Optional OAuth scopes to request, overriding the connector's default scopes. Only supported for connectors that define scopes as an array.
  --requestedOptionalScopes: list # Optional OAuth optional_scopes to request, overriding the connector's default optional_scopes. Only applied when requestedScopes is also provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/sources/initiateOAuth")
  let body = {name: $name, sourceType: $sourceType, redirectUrl: $redirectUrl, clientType: $clientType, workspaceId: $workspaceId, oAuthInputConfiguration: $oAuthInputConfiguration, requestedScopes: $requestedScopes, requestedOptionalScopes: $requestedOptionalScopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a connection
#
# POST /public/v1/connections
# operationId: publicCreateConnection
# --configurations shape: {streams?: list}
# --schedule shape: {scheduleType: "manual"|"cron", cronExpression?: string}
# --tags item shape: {tagId: string, workspaceId: string, name: string, color: string}
@deprecated --flag dataResidency
export def "public-connections publicCreateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Optional name of the connection
  sourceId: string # format: uuid
  destinationId: string # format: uuid
  --configurations: record # A list of configured stream options for a connection. — shape: {streams?: list}
  --schedule: record # schedule for when the the connection should run, per the schedule type — shape: {scheduleType: "manual"|"cron", cronExpression?: string}
  --dataResidency: string # DEPRECATED
  --namespaceDefinition: string@namespaceDefinition-completer-1 # Define the location where the data will be stored in the destination (default: destination)
  --namespaceFormat: string # Used when namespaceDefinition is 'custom_format'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination (ex. “airbyte_” causes “projects” => “airbyte_projects”). (default: )
  --nonBreakingSchemaUpdatesBehavior: string@nonBreakingSchemaUpdatesBehavior-completer # Set how Airbyte handles syncs when it detects a non-breaking schema change in the source (default: ignore)
  --status: string@status-completer
  --tags: list # item shape: {tagId: string, workspaceId: string, name: string, color: string}
]: any -> record<connectionId: string, name: string, sourceId: string, destinationId: string, workspaceId: string, status: string, schedule: record<scheduleType: string, cronExpression: string, basicTiming: string>, nonBreakingSchemaUpdatesBehavior: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, configurations: record<streams: list<record>>, createdAt: int, tags: table<tagId: string, workspaceId: string, name: string, color: string>, statusReason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/connections")
  let body = {name: $name, sourceId: $sourceId, destinationId: $destinationId, configurations: $configurations, schedule: $schedule, dataResidency: $dataResidency, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, nonBreakingSchemaUpdatesBehavior: $nonBreakingSchemaUpdatesBehavior, status: $status, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List connections
#
# GET /public/v1/connections
# operationId: listConnections
export def "public-connections listConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceIds: list # The UUIDs of the workspaces you wish to list connections for. Empty list will retrieve all allowed workspaces.
  --tagIds: list # The UUIDs of the tags you wish to list connections for. Empty list will retrieve all connections.
  --includeDeleted: string@bool-completer # Include deleted connections in the returned results. (default: false)
  --limit: int # Set the limit on the number of Connections returned. The default is 20. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning Connections. The default is 0 (format: int32, default: 0)
]: nothing -> record<previous: string, next: string, data: table<connectionId: string, name: string, sourceId: string, destinationId: string, workspaceId: string, status: string, schedule: record, nonBreakingSchemaUpdatesBehavior: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, configurations: record, createdAt: int, tags: list, statusReason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceIds" $workspaceIds "multi") (serialize-qp "tagIds" $tagIds "multi") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connection details
#
# GET /public/v1/connections/{connectionId}
# operationId: publicGetConnection
export def "public-connections publicGetConnection" [
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connectionId: string, name: string, sourceId: string, destinationId: string, workspaceId: string, status: string, schedule: record<scheduleType: string, cronExpression: string, basicTiming: string>, nonBreakingSchemaUpdatesBehavior: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, configurations: record<streams: list<record>>, createdAt: int, tags: table<tagId: string, workspaceId: string, name: string, color: string>, statusReason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/connections/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Connection details
#
# PATCH /public/v1/connections/{connectionId}
# operationId: patchConnection
# --configurations shape: {streams?: list}
# --schedule shape: {scheduleType: "manual"|"cron", cronExpression?: string}
# --tags item shape: {tagId: string, workspaceId: string, name: string, color: string}
@deprecated --flag dataResidency
export def "public-connections patch" [
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Optional name of the connection
  --configurations: record # A list of configured stream options for a connection. — shape: {streams?: list}
  --schedule: record # schedule for when the the connection should run, per the schedule type — shape: {scheduleType: "manual"|"cron", cronExpression?: string}
  --dataResidency: string # DEPRECATED
  --namespaceDefinition: string@namespaceDefinition-completer-1 # Define the location where the data will be stored in the destination
  --namespaceFormat: string # Used when namespaceDefinition is 'custom_format'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination (ex. “airbyte_” causes “projects” => “airbyte_projects”).
  --nonBreakingSchemaUpdatesBehavior: string@nonBreakingSchemaUpdatesBehavior-completer # Set how Airbyte handles syncs when it detects a non-breaking schema change in the source
  --status: string@status-completer
  --tags: list # item shape: {tagId: string, workspaceId: string, name: string, color: string}
]: any -> record<connectionId: string, name: string, sourceId: string, destinationId: string, workspaceId: string, status: string, schedule: record<scheduleType: string, cronExpression: string, basicTiming: string>, nonBreakingSchemaUpdatesBehavior: string, namespaceDefinition: string, namespaceFormat: string, prefix: string, configurations: record<streams: list<record>>, createdAt: int, tags: table<tagId: string, workspaceId: string, name: string, color: string>, statusReason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/connections/($connectionId)")
  let body = {name: $name, configurations: $configurations, schedule: $schedule, dataResidency: $dataResidency, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, nonBreakingSchemaUpdatesBehavior: $nonBreakingSchemaUpdatesBehavior, status: $status, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Connection
#
# DELETE /public/v1/connections/{connectionId}
# operationId: publicDeleteConnection
export def "public-connections publicDeleteConnection" [
  connectionId: string
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
  let full_url = (build-url $base $"/public/v1/connections/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stream properties
#
# GET /public/v1/streams
# operationId: getStreamProperties
export def "public-streams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceId: string # ID of the source (format: UUID)
  --destinationId: string # ID of the destination (format: UUID)
  --ignoreCache: string@bool-completer # If true pull the latest schema from the source, else pull from cache (default false) (default: false)
]: nothing -> table<streamName: string, syncModes: list<any>, streamnamespace: string, defaultCursorField: list<string>, sourceDefinedCursorField: bool, sourceDefinedPrimaryKey: list<list>, propertyFields: list<list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "destinationId" $destinationId "scalar") (serialize-qp "ignoreCache" $ignoreCache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspaces
#
# GET /public/v1/workspaces
# operationId: publicListWorkspaces
export def "public-workspaces publicListWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceIds: list # The UUIDs of the workspaces you wish to fetch. Empty list will retrieve all allowed workspaces.
  --includeDeleted: string@bool-completer # Include deleted workspaces in the returned results. (default: false)
  --limit: int # Set the limit on the number of workspaces returned. The default is 20. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning workspaces. The default is 0 (format: int32, default: 0)
]: nothing -> record<previous: string, next: string, data: table<workspaceId: string, name: string, dataResidency: string, notifications: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceIds" $workspaceIds "multi") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workspace
#
# POST /public/v1/workspaces
# operationId: publicCreateWorkspace
# --notifications shape: {failure?: record, success?: record, connectionUpdate?: record, connectionUpdateActionRequired?: record, syncDisabled?: record, syncDisabledWarning?: record}
export def "public-workspaces publicCreateWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the workspace
  --organizationId: string # ID of organization to add workspace to. (format: uuid)
  --notifications: record # Configures workspace notifications. — shape: {failure?: record, success?: record, connectionUpdate?: record, connectionUpdateActionRequired?: record, syncDisabled?: record, syncDisabledWarning?: record}
  --regionId: string # format: uuid
]: any -> record<workspaceId: string, name: string, dataResidency: string, notifications: record<failure: record<email: record, webhook: record>, success: record<email: record, webhook: record>, connectionUpdate: record<email: record, webhook: record>, connectionUpdateActionRequired: record<email: record, webhook: record>, syncDisabled: record<email: record, webhook: record>, syncDisabledWarning: record<email: record, webhook: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/workspaces")
  let body = {name: $name, organizationId: $organizationId, notifications: $notifications, regionId: $regionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Workspace details
#
# GET /public/v1/workspaces/{workspaceId}
# operationId: publicGetWorkspace
export def "public-workspaces publicGetWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<workspaceId: string, name: string, dataResidency: string, notifications: record<failure: record<email: record, webhook: record>, success: record<email: record, webhook: record>, connectionUpdate: record<email: record, webhook: record>, connectionUpdateActionRequired: record<email: record, webhook: record>, syncDisabled: record<email: record, webhook: record>, syncDisabledWarning: record<email: record, webhook: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workspace
#
# PATCH /public/v1/workspaces/{workspaceId}
# operationId: publicUpdateWorkspace
# --notifications shape: {failure?: record, success?: record, connectionUpdate?: record, connectionUpdateActionRequired?: record, syncDisabled?: record, syncDisabledWarning?: record}
export def "public-workspaces publicUpdateWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the workspace
  --notifications: record # Configures workspace notifications. — shape: {failure?: record, success?: record, connectionUpdate?: record, connectionUpdateActionRequired?: record, syncDisabled?: record, syncDisabledWarning?: record}
  --regionId: string # format: uuid
]: any -> record<workspaceId: string, name: string, dataResidency: string, notifications: record<failure: record<email: record, webhook: record>, success: record<email: record, webhook: record>, connectionUpdate: record<email: record, webhook: record>, connectionUpdateActionRequired: record<email: record, webhook: record>, syncDisabled: record<email: record, webhook: record>, syncDisabledWarning: record<email: record, webhook: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)")
  let body = {name: $name, notifications: $notifications, regionId: $regionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Workspace
#
# DELETE /public/v1/workspaces/{workspaceId}
# operationId: publicDeleteWorkspace
export def "public-workspaces publicDeleteWorkspace" [
  workspaceId: string
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
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create OAuth override credentials for a workspace and source type.
#
# PUT /public/v1/workspaces/{workspaceId}/oauthCredentials
# operationId: createOrUpdateWorkspaceOAuthCredentials
export def "public-workspaces-oauth-credentials createOrUpdateWorkspaceOAuthCredentials" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorType: any@actorType-completer # Whether you're setting this override for a source or destination
  name: string # The name of the source i.e. google-ads
  configuration: record # The configuration for this source/destination based on the OAuth section of the relevant specification. (e.g. {credentials: {client_id: 871d9b60-11d1-44cb-8c92-c246d53bf87e, client_secret: shhhhhh}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspaceId)/oauthCredentials")
  let body = {actorType: $actorType, name: $name, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Permission details
#
# GET /public/v1/permissions/{permissionId}
# operationId: publicGetPermission
export def "public-permissions publicGetPermission" [
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<permissionId: string, permissionType: string, userId: string, workspaceId: string, organizationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/permissions/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a permission
#
# PATCH /public/v1/permissions/{permissionId}
# operationId: publicUpdatePermission
export def "public-permissions publicUpdatePermission" [
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
]: any -> record<permissionId: string, permissionType: string, userId: string, workspaceId: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/permissions/($permissionId)")
  let body = {permissionType: $permissionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Permission
#
# DELETE /public/v1/permissions/{permissionId}
# operationId: publicDeletePermission
export def "public-permissions publicDeletePermission" [
  permissionId: string
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
  let full_url = (build-url $base $"/public/v1/permissions/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Permissions by user id
#
# GET /public/v1/permissions
# operationId: publicListPermissionsByUserId
export def "public-permissions publicListPermissionsByUserId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # User Id in permission. (format: UUID)
  --organizationId: string # This is required if you want to read someone else's permissions, and you should have organization admin or a higher role. (format: UUID)
]: nothing -> record<data: table<permissionId: string, permissionType: string, userId: string, scopeId: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a permission
#
# POST /public/v1/permissions
# operationId: publicCreatePermission
export def "public-permissions publicCreatePermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionType: string@permissionType-completer-1 # Subset of `PermissionType` (removing `instance_admin`), could be used in public-api.
  userId: string # Internal Airbyte user ID (format: uuid)
  --workspaceId: string # format: uuid
  --organizationId: string # format: uuid
]: any -> record<permissionId: string, permissionType: string, userId: string, workspaceId: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/permissions")
  let body = {permissionType: $permissionType, userId: $userId, workspaceId: $workspaceId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all organizations for a user
#
# GET /public/v1/organizations
# operationId: publicListOrganizationsForUser
export def "public-organizations publicListOrganizationsForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<organizationId: string, organizationName: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create OAuth override credentials for an organization and source type.
#
# PUT /public/v1/organizations/{organizationId}/oauthCredentials
# operationId: createOrUpdateOrganizationOAuthCredentials
export def "public-organizations-oauth-credentials createOrUpdateOrganizationOAuthCredentials" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actorType: any@actorType-completer # Whether you're setting this override for a source or destination
  name: string # The name of the source i.e. google-ads
  configuration: record # The configuration for this source/destination based on the OAuth section of the relevant specification. (e.g. {credentials: {client_id: 871d9b60-11d1-44cb-8c92-c246d53bf87e, client_secret: shhhhhh}})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/organizations/($organizationId)/oauthCredentials")
  let body = {actorType: $actorType, name: $name, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete OAuth override credentials for an organization and source/destination type.
#
# DELETE /public/v1/organizations/{organizationId}/oauthCredentials/{actorType}/{name}
# operationId: deleteOrganizationOAuthCredentials
export def "public-organizations-oauth-credentials delete" [
  organizationId: string
  actorType: string
  name: string
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
  let full_url = (build-url $base $"/public/v1/organizations/($organizationId)/oauthCredentials/($actorType)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users within an organization
#
# GET /public/v1/users
# operationId: publicListUsersWithinAnOrganization
export def "public-users publicListUsersWithinAnOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: string # format: UUID
  --ids: list # List of user IDs to filter by
  --emails: list # List of user emails to filter by
]: nothing -> record<data: table<name: string, id: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "ids" $ids "multi") (serialize-qp "emails" $emails "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups
#
# GET /public/v1/groups
# operationId: publicListGroups
export def "public-groups publicListGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: string # Filter groups by organization ID (format: uuid)
  --limit: int # Set the limit on the number of Groups returned. The default is 20 Groups. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning Groups. The default is 0. (format: int32, default: 0)
]: nothing -> record<data: table<groupId: string, name: string, description: string, organizationId: string, memberCount: int>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create group
#
# POST /public/v1/groups
# operationId: publicCreateGroup
export def "public-groups publicCreateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the group
  --description: string # Optional description of the group (nullable)
  organizationId: string # The ID of the organization the group belongs to (format: uuid)
]: any -> record<groupId: string, name: string, description: string, organizationId: string, memberCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/groups")
  let body = {name: $name, description: $description, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get group details
#
# GET /public/v1/groups/{groupId}
# operationId: publicGetGroup
export def "public-groups publicGetGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<groupId: string, name: string, description: string, organizationId: string, memberCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update group
#
# PATCH /public/v1/groups/{groupId}
# operationId: publicUpdateGroup
export def "public-groups publicUpdateGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The updated name of the group
  --description: string # The updated description of the group (nullable)
]: any -> record<groupId: string, name: string, description: string, organizationId: string, memberCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/groups/($groupId)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete group
#
# DELETE /public/v1/groups/{groupId}
# operationId: publicDeleteGroup
export def "public-groups publicDeleteGroup" [
  groupId: string
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
  let full_url = (build-url $base $"/public/v1/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List group members
#
# GET /public/v1/groups/{groupId}/members
# operationId: publicListGroupMembers
export def "public-groups-members publicListGroupMembers" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Set the limit on the number of members returned. The default is 20. (format: int32, default: 20)
  --offset: int # Set the offset to start at when returning members. The default is 0. (format: int32, default: 0)
]: nothing -> record<data: table<memberId: string, groupId: string, userId: string, userEmail: string, userName: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/groups/($groupId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add member to group
#
# POST /public/v1/groups/{groupId}/members
# operationId: publicAddGroupMember
export def "public-groups-members publicAddGroupMember" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: string # The ID of the user to add to the group (format: uuid)
]: any -> record<memberId: string, groupId: string, userId: string, userEmail: string, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/groups/($groupId)/members")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove member from group
#
# DELETE /public/v1/groups/{groupId}/members/{userId}
# operationId: publicRemoveGroupMember
export def "public-groups-members publicRemoveGroupMember" [
  groupId: string
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
  let full_url = (build-url $base $"/public/v1/groups/($groupId)/members/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List group permissions
#
# GET /public/v1/groups/{groupId}/permissions
# operationId: publicListGroupPermissions
export def "public-groups-permissions publicListGroupPermissions" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<permissionId: string, groupId: string, permissionType: string, workspaceId: string, organizationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/groups/($groupId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create group permission
#
# POST /public/v1/groups/{groupId}/permissions
# operationId: publicCreateGroupPermission
export def "public-groups-permissions publicCreateGroupPermission" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionType: string@permissionType-completer # Describes what actions/endpoints the permission entitles to
  --workspaceId: string # Required for workspace-scoped permissions (nullable, format: uuid)
  --organizationId: string # Required for organization-scoped permissions (nullable, format: uuid)
]: any -> record<permissionId: string, groupId: string, permissionType: string, workspaceId: string, organizationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/groups/($groupId)/permissions")
  let body = {permissionType: $permissionType, workspaceId: $workspaceId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete group permission
#
# DELETE /public/v1/groups/{groupId}/permissions/{permissionId}
# operationId: publicDeleteGroupPermission
export def "public-groups-permissions publicDeleteGroupPermission" [
  groupId: string
  permissionId: string
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
  let full_url = (build-url $base $"/public/v1/groups/($groupId)/permissions/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all tags
#
# GET /public/v1/tags
# operationId: publicListTags
export def "public-tags publicListTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceIds: list
]: nothing -> record<data: table<tagId: string, name: string, color: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceIds" $workspaceIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tag
#
# POST /public/v1/tags
# operationId: publicCreateTag
export def "public-tags publicCreateTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  color: string
  workspaceId: string # format: uuid
]: any -> record<tagId: string, name: string, color: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/tags")
  let body = {name: $name, color: $color, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a tag
#
# GET /public/v1/tags/{tagId}
# operationId: publicGetTag
export def "public-tags publicGetTag" [
  tagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tagId: string, name: string, color: string, workspaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/tags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag
#
# DELETE /public/v1/tags/{tagId}
# operationId: publicDeleteTag
export def "public-tags publicDeleteTag" [
  tagId: string
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
  let full_url = (build-url $base $"/public/v1/tags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tag
#
# PATCH /public/v1/tags/{tagId}
# operationId: publicUpdateTag
export def "public-tags publicUpdateTag" [
  tagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  color: string
]: any -> record<tagId: string, name: string, color: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/tags/($tagId)")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a widget token for Airbyte Embedded
#
# POST /public/v1/embedded/widget_token
# operationId: getEmbeddedWidget
export def "public-embedded-widget-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  allowedOrigin: string
  externalUserId: string
  organizationId: string # format: uuid
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/embedded/widget_token")
  let body = {allowedOrigin: $allowedOrigin, externalUserId: $externalUserId, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a scoped token for Airbyte Embedded
#
# POST /public/v1/embedded/scoped_token
# operationId: generateEmbeddedScopedToken
export def "public-embedded-scoped-token generateEmbeddedScopedToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/embedded/scoped_token")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List organizations that a user has access to that have embedded enabled.
#
# GET /public/v1/embedded/organizations
# operationId: listEmbeddedOrganizationsByUser
export def "public-embedded-organizations listEmbeddedOrganizationsByUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizations: table<organizationId: string, organizationName: string, permission: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/embedded/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an access token for a service account.
#
# POST /v1/service_accounts/token
# operationId: getServiceAccountToken
export def "service-accounts-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  service_account_id: string # format: uuid
  secret: string
]: any -> record<access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/service_accounts/token")
  let body = {service_account_id: $service_account_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single orchestration by id
#
# POST /v1/orchestrations/get
# operationId: getOrchestration
export def "orchestrations-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  orchestrationId: string # format: uuid
]: any -> record<orchestrationId: string, versionId: string, workspaceId: string, name: string, tasks: table<taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: string, taskDefinitionId: string, dependsOn: list, createdAt: int>, createdAt: int, updatedAt: int, tombstone: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orchestrations/get")
  let body = {workspaceId: $workspaceId, orchestrationId: $orchestrationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all orchestrations for a workspace.
#
# POST /v1/orchestrations/list
# operationId: listOrchestrationsForWorkspace
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "orchestrations-list listOrchestrationsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  pagination: record # shape: {pageSize?: int, rowOffset?: int}
]: any -> record<orchestrations: table<orchestrationId: string, versionId: string, workspaceId: string, name: string, tasks: list, createdAt: int, updatedAt: int, tombstone: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orchestrations/list")
  let body = {workspaceId: $workspaceId, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an orchestration
#
# POST /v1/orchestrations/create
# operationId: createOrchestration
# --tasks item shape: {taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: "sync", taskDefinitionId: string, dependsOn: list, createdAt: int}
export def "orchestrations-create createOrchestration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  name: string
  tasks: list # item shape: {taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: "sync", taskDefinitionId: string, dependsOn: list, createdAt: int}
]: any -> record<orchestrationId: string, versionId: string, workspaceId: string, name: string, tasks: table<taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: string, taskDefinitionId: string, dependsOn: list, createdAt: int>, createdAt: int, updatedAt: int, tombstone: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orchestrations/create")
  let body = {workspaceId: $workspaceId, name: $name, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an orchestration
#
# POST /v1/orchestrations/delete
# operationId: deleteOrchestration
export def "orchestrations-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  orchestrationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orchestrations/delete")
  let body = {workspaceId: $workspaceId, orchestrationId: $orchestrationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an orchestration
#
# POST /v1/orchestrations/update
# operationId: updateOrchestration
# --tasks item shape: {taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: "sync", taskDefinitionId: string, dependsOn: list, createdAt: int}
export def "orchestrations-update updateOrchestration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  orchestrationId: string # format: uuid
  name: string
  tasks: list # item shape: {taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: "sync", taskDefinitionId: string, dependsOn: list, createdAt: int}
]: any -> record<orchestrationId: string, versionId: string, workspaceId: string, name: string, tasks: table<taskId: string, orchestrationId: string, orchestrationVersion: string, orchestrationTaskType: string, taskDefinitionId: string, dependsOn: list, createdAt: int>, createdAt: int, updatedAt: int, tombstone: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orchestrations/update")
  let body = {workspaceId: $workspaceId, orchestrationId: $orchestrationId, name: $name, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start an orchestration
#
# POST /v1/orchestrations/run
# operationId: runOrchestration
export def "orchestrations-run runOrchestration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  orchestrationId: string # format: uuid
]: any -> record<orchestrationRunId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/orchestrations/run")
  let body = {workspaceId: $workspaceId, orchestrationId: $orchestrationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new domain verification request for given org
#
# POST /v1/domain_verifications/create
# operationId: createDomainVerification
export def "domain-verifications-create createDomainVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
  domain: string
]: any -> record<id: string, organizationId: string, domain: string, verificationMethod: string, status: string, dnsRecordName: string, dnsRecordValue: string, attempts: int, expiresAt: int, verifiedAt: int, lastCheckedAt: int, createdAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain_verifications/create")
  let body = {organizationId: $organizationId, domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all domain verifications for an organization
#
# POST /v1/domain_verifications/list
# operationId: listDomainVerifications
export def "domain-verifications-list listDomainVerifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # format: uuid
]: any -> record<domainVerifications: table<id: string, organizationId: string, domain: string, verificationMethod: string, status: string, dnsRecordName: string, dnsRecordValue: string, attempts: int, expiresAt: int, verifiedAt: int, lastCheckedAt: int, createdAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain_verifications/list")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a domain verification
#
# POST /v1/domain_verifications/delete
# operationId: deleteDomainVerification
export def "domain-verifications-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domainVerificationId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain_verifications/delete")
  let body = {domainVerificationId: $domainVerificationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset a failed or expired domain verification
#
# POST /v1/domain_verifications/reset
# operationId: resetDomainVerification
export def "domain-verifications-reset resetDomainVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domainVerificationId: string # format: uuid
]: any -> record<id: string, organizationId: string, domain: string, verificationMethod: string, status: string, dnsRecordName: string, dnsRecordValue: string, attempts: int, expiresAt: int, verifiedAt: int, lastCheckedAt: int, createdAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domain_verifications/reset")
  let body = {domainVerificationId: $domainVerificationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a private link for a workspace
#
# POST /v1/private_link/create
# operationId: createPrivateLink
export def "private-link-create createPrivateLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
  name: string
  serviceConfig: any # Variant config selected by the `type` field (endpoint or storage).
]: any -> record<id: string, workspaceId: string, dataplaneGroupId: string, name: string, status: string, serviceConfig: any, endpointId: string, dnsName: string, scopedConfigurationId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/private_link/create")
  let body = {workspaceId: $workspaceId, name: $name, serviceConfig: $serviceConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List private links for a workspace
#
# POST /v1/private_link/list
# operationId: listPrivateLinksForWorkspace
export def "private-link-list listPrivateLinksForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceId: string # format: uuid
]: any -> record<privateLinks: table<id: string, workspaceId: string, dataplaneGroupId: string, name: string, status: string, serviceConfig: any, endpointId: string, dnsName: string, scopedConfigurationId: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/private_link/list")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a private link
#
# POST /v1/private_link/delete
# operationId: deletePrivateLink
export def "private-link-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  privateLinkId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/private_link/delete")
  let body = {privateLinkId: $privateLinkId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a private link by id (internal — admin only)
#
# POST /v1/private_link/get
# operationId: getPrivateLink
export def "private-link-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  privateLinkId: string # format: uuid
]: any -> record<id: string, workspaceId: string, dataplaneGroupId: string, name: string, status: string, serviceConfig: any, endpointId: string, dnsName: string, scopedConfigurationId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/private_link/get")
  let body = {privateLinkId: $privateLinkId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a private link (internal — admin only)
#
# POST /v1/private_link/update
# operationId: updatePrivateLink
export def "private-link-update updatePrivateLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  privateLinkId: string # format: uuid
  --status: string@status-completer-3
  --endpointId: string
  --dnsName: string
  --scopedConfigurationId: string # format: uuid
  --clearScopedConfigurationId: string@bool-completer
]: any -> record<id: string, workspaceId: string, dataplaneGroupId: string, name: string, status: string, serviceConfig: any, endpointId: string, dnsName: string, scopedConfigurationId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/private_link/update")
  let body = {privateLinkId: $privateLinkId, status: $status, endpointId: $endpointId, dnsName: $dnsName, scopedConfigurationId: $scopedConfigurationId, clearScopedConfigurationId: $clearScopedConfigurationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
