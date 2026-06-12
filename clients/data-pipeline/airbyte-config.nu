# Auto-generated client for Airbyte Configuration API v1.0.0
# Source: https://api.apis.guru/v2/specs/airbyte.local/config/1.0.0/openapi.json
# Auth: --token flag or $env.AIRBYTE_CONFIGURATION_API_TOKEN

const BASE_URL = "http://airbyte.local"
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

def base-url-completer [] { ["http://airbyte.local" "http://localhost:8000/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def geography-completer [] { ["auto" "eu" "us"] }
def namespaceDefinition-completer [] { ["customformat" "destination" "source"] }
def nonBreakingChangesPreference-completer [] { ["disable" "ignore"] }
def scheduleType-completer [] { ["basic" "cron" "manual"] }
def status-completer [] { ["active" "deprecated" "inactive"] }
def logType-completer [] { ["scheduler" "server"] }
def notificationType-completer [] { ["customerio" "slack"] }
def operatorType-completer [] { ["dbt" "normalization" "webhook"] }
def defaultGeography-completer [] { ["auto" "eu" "us"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attempt-save-stats saveStats" } } | get name | first)
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

# For worker to set sync stats of a running attempt.
#
# POST /v1/attempt/save_stats
# operationId: saveStats
# --stats shape: {bytesEmitted?: int, estimatedBytes?: int, estimatedRecords?: int, recordsCommitted?: int, recordsEmitted?: int, stateMessagesEmitted?: int}
# --streamStats item shape: {stats: record, streamName: string, streamNamespace?: string}
export def "attempt-save-stats saveStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  attemptNumber: int # format: int32
  jobId: int # format: int64
  stats: record # shape: {bytesEmitted?: int, estimatedBytes?: int, estimatedRecords?: int, recordsCommitted?: int, recordsEmitted?: int, stateMessagesEmitted?: int}
  --streamStats: list # item shape: {stats: record, streamName: string, streamNamespace?: string}
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_stats")
  let body = {attemptNumber: $attemptNumber, jobId: $jobId, stats: $stats, streamStats: $streamStats} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# For worker to save the AttemptSyncConfig for an attempt.
#
# POST /v1/attempt/save_sync_config
# operationId: saveSyncConfig
# --syncConfig shape: {destinationConfiguration: any, sourceConfiguration: any, state?: record}
export def "attempt-save-sync-config saveSyncConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  attemptNumber: int # format: int32
  jobId: int # format: int64
  syncConfig: record # shape: {destinationConfiguration: any, sourceConfiguration: any, state?: record}
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_sync_config")
  let body = {attemptNumber: $attemptNumber, jobId: $jobId, syncConfig: $syncConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# For worker to register the workflow id in attempt.
#
# POST /v1/attempt/set_workflow_in_attempt
# operationId: setWorkflowInAttempt
export def "attempt-set-workflow-in-attempt setWorkflowInAttempt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  attemptNumber: int # format: int32
  jobId: int # format: int64
  --processingTaskQueue: string # default: 
  workflowId: string
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/set_workflow_in_attempt")
  let body = {attemptNumber: $attemptNumber, jobId: $jobId, processingTaskQueue: $processingTaskQueue, workflowId: $workflowId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a connection between a source and a destination
#
# POST /v1/connections/create
# operationId: createConnection
# --resourceRequirements shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --syncCatalog shape: {streams: list}
export def "connections-create createConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationId: string # format: uuid
  --geography: string@geography-completer
  --name: string # Optional name of the connection
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --notifySchemaChanges: oneof<nothing, bool>
  --operationIds: list
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --sourceCatalogId: string # format: uuid
  sourceId: string # format: uuid
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/create")
  let body = {destinationId: $destinationId, geography: $geography, name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, nonBreakingChangesPreference: $nonBreakingChangesPreference, notifySchemaChanges: $notifySchemaChanges, operationIds: $operationIds, prefix: $prefix, resourceRequirements: $resourceRequirements, schedule: $schedule, scheduleData: $scheduleData, scheduleType: $scheduleType, sourceCatalogId: $sourceCatalogId, sourceId: $sourceId, status: $status, syncCatalog: $syncCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/get")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list_all")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/reset")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search connections
#
# POST /v1/connections/search
# operationId: searchConnections
# --destination shape: {connectionConfiguration?: any, destinationDefinitionId?: string, destinationId?: string, destinationName?: string, name?: string, workspaceId?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --source shape: {connectionConfiguration?: any, name?: string, sourceDefinitionId?: string, sourceId?: string, sourceName?: string, workspaceId?: string}
export def "connections-search searchConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connectionId: string # format: uuid
  --destination: record # shape: {connectionConfiguration?: any, destinationDefinitionId?: string, destinationId?: string, destinationName?: string, name?: string, workspaceId?: string}
  --destinationId: string # format: uuid
  --name: string
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --body-source: record # shape: {connectionConfiguration?: any, name?: string, sourceDefinitionId?: string, sourceId?: string, sourceName?: string, workspaceId?: string}
  --sourceId: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
]: any -> record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/search")
  let body = {connectionId: $connectionId, destination: $destination, destinationId: $destinationId, name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, prefix: $prefix, schedule: $schedule, scheduleData: $scheduleData, scheduleType: $scheduleType, source: $body_source, sourceId: $sourceId, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/sync")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a connection
#
# POST /v1/connections/update
# operationId: updateConnection
# --resourceRequirements shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --syncCatalog shape: {streams: list}
export def "connections-update updateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --breakingChange: oneof<nothing, bool>
  connectionId: string # format: uuid
  --geography: string@geography-completer
  --name: string # Name that will be set to this connection
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --notifySchemaChanges: oneof<nothing, bool>
  --operationIds: list
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --sourceCatalogId: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/update")
  let body = {breakingChange: $breakingChange, connectionId: $connectionId, geography: $geography, name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, nonBreakingChangesPreference: $nonBreakingChangesPreference, notifySchemaChanges: $notifySchemaChanges, operationIds: $operationIds, prefix: $prefix, resourceRequirements: $resourceRequirements, schedule: $schedule, scheduleData: $scheduleData, scheduleType: $scheduleType, sourceCatalogId: $sourceCatalogId, status: $status, syncCatalog: $syncCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: any, destinationDefinitionId: string, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, supportedDestinationSyncModes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definition_specifications/get")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a custom destinationDefinition for the given workspace
#
# POST /v1/destination_definitions/create_custom
# operationId: createCustomDestinationDefinition
# --destinationDefinition shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
export def "destination-definitions-create-custom createCustomDestinationDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinition: record # shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/create_custom")
  let body = {destinationDefinition: $destinationDefinition, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get")
  let body = {destinationDefinitionId: $destinationDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get_for_workspace")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# grant a private, non-custom destinationDefinition to a given workspace
#
# POST /v1/destination_definitions/grant_definition
# operationId: grantDestinationDefinitionToWorkspace
export def "destination-definitions-grant-definition grantDestinationDefinitionToWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, supportsDbt: bool>, granted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/grant_definition")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_for_workspace")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<destinationDefinitions: table<destinationDefinition: record, granted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_private")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# revoke a grant to a private, non-custom destinationDefinition from a given workspace
#
# POST /v1/destination_definitions/revoke_definition
# operationId: revokeDestinationDefinitionFromWorkspace
export def "destination-definitions-revoke-definition revokeDestinationDefinitionFromWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/revoke_definition")
  let body = {destinationDefinitionId: $destinationDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  --dockerImageTag: string
  --resourceRequirements: record # actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/update")
  let body = {destinationDefinitionId: $destinationDefinitionId, dockerImageTag: $dockerImageTag, resourceRequirements: $resourceRequirements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  --destinationId: string # format: uuid
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --queryParams: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirectUrl: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  workspaceId: string # format: uuid
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/complete_oauth")
  let body = {destinationDefinitionId: $destinationDefinitionId, destinationId: $destinationId, oAuthInputConfiguration: $oAuthInputConfiguration, queryParams: $queryParams, redirectUrl: $redirectUrl, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationDefinitionId: string # format: uuid
  --destinationId: string # format: uuid
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  redirectUrl: string # The url to redirect to after getting the user consent
  workspaceId: string # format: uuid
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/get_consent_url")
  let body = {destinationDefinitionId: $destinationDefinitionId, destinationId: $destinationId, oAuthInputConfiguration: $oAuthInputConfiguration, redirectUrl: $redirectUrl, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationId: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/check_connection")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check connection for a proposed update to a destination
#
# POST /v1/destinations/check_connection_for_update
# operationId: checkConnectionToDestinationForUpdate
export def "destinations-check-connection-for-update checkConnectionToDestinationForUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destinationId: string # format: uuid
  name: string
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/check_connection_for_update")
  let body = {connectionConfiguration: $connectionConfiguration, destinationId: $destinationId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clone destination
#
# POST /v1/destinations/clone
# operationId: cloneDestination
# --destinationConfiguration shape: {connectionConfiguration?: any, name?: string}
export def "destinations-clone cloneDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationCloneId: string # format: uuid
  --destinationConfiguration: record # shape: {connectionConfiguration?: any, name?: string}
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/clone")
  let body = {destinationCloneId: $destinationCloneId, destinationConfiguration: $destinationConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a destination
#
# POST /v1/destinations/create
# operationId: createDestination
export def "destinations-create createDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destinationDefinitionId: string # format: uuid
  name: string
  workspaceId: string # format: uuid
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/create")
  let body = {connectionConfiguration: $connectionConfiguration, destinationDefinitionId: $destinationDefinitionId, name: $name, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationId: string # format: uuid
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/get")
  let body = {destinationId: $destinationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List configured destinations for a workspace
#
# POST /v1/destinations/list
# operationId: listDestinationsForWorkspace
export def "destinations-list listDestinationsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/list")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --connectionConfiguration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --destinationDefinitionId: string # format: uuid
  --destinationId: string # format: uuid
  --destinationName: string
  --name: string
  --workspaceId: string # format: uuid
]: any -> record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/search")
  let body = {connectionConfiguration: $connectionConfiguration, destinationDefinitionId: $destinationDefinitionId, destinationId: $destinationId, destinationName: $destinationName, name: $name, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a destination
#
# POST /v1/destinations/update
# operationId: updateDestination
export def "destinations-update updateDestination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destinationId: string # format: uuid
  name: string
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/update")
  let body = {connectionConfiguration: $connectionConfiguration, destinationId: $destinationId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/cancel")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<airbyteVersion: string, configId: string, configType: string, destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>, id: int, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>, status: string>, workflowState: record<running: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_debug_info")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/jobs/get_last_replication_job
#
# operationId: getLastReplicationJob
export def "jobs-get-last-replication-job post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_last_replication_job")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_light")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get normalization status to determine if we can bypass normalization phase
#
# POST /v1/jobs/get_normalization_status
# operationId: getAttemptNormalizationStatusesForJob
export def "jobs-get-normalization-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attemptNormalizationStatuses: table<attemptNumber: int, hasNormalizationFailed: bool, hasRecordsCommitted: bool, recordsCommitted: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_normalization_status")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  configId: string
  configTypes: list
  --includingJobId: int # format: int64
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
]: any -> record<jobs: table<attempts: list, job: record>, totalJobCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/list")
  let body = {configId: $configId, configTypes: $configTypes, includingJobId: $includingJobId, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get logs
#
# POST /v1/logs/get
# operationId: getLogs
export def "logs-get post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  logType: string@logType-completer # type/source of logs produced
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logs/get")
  let body = {logType: $logType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Try sending a notifications
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --customerioConfiguration: record
  notificationType: string@notificationType-completer
  --sendOnFailure: oneof<nothing, bool> # default: true
  --sendOnSuccess: oneof<nothing, bool> # default: false
  --slackConfiguration: record # shape: {webhook: string}
]: any -> record<message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/notifications/try")
  let body = {customerioConfiguration: $customerioConfiguration, notificationType: $notificationType, sendOnFailure: $sendOnFailure, sendOnSuccess: $sendOnSuccess, slackConfiguration: $slackConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/openapi")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if an operation to be created is valid
#
# POST /v1/operations/check
# operationId: checkOperation
# --dbt shape: {dbtArguments?: string, dockerImage?: string, gitRepoBranch?: string, gitRepoUrl: string}
# --normalization shape: {option?: "basic"}
# --webhook shape: {dbtCloud?: record, executionBody?: string, executionUrl?: string, webhookConfigId?: string, webhookType?: "dbtCloud"}
export def "operations-check checkOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbt: record # shape: {dbtArguments?: string, dockerImage?: string, gitRepoBranch?: string, gitRepoUrl: string}
  --normalization: record # shape: {option?: "basic"}
  operatorType: string@operatorType-completer
  --webhook: record # shape: {dbtCloud?: record, executionBody?: string, executionUrl?: string, webhookConfigId?: string, webhookType?: "dbtCloud"}
]: any -> record<message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/check")
  let body = {dbt: $dbt, normalization: $normalization, operatorType: $operatorType, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an operation to be applied as part of a connection pipeline
#
# POST /v1/operations/create
# operationId: createOperation
# --operatorConfiguration shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
export def "operations-create createOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  operatorConfiguration: record # shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
  workspaceId: string # format: uuid
]: any -> record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/create")
  let body = {name: $name, operatorConfiguration: $operatorConfiguration, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  operationId: string # format: uuid
]: any -> record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/get")
  let body = {operationId: $operationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/list")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an operation
#
# POST /v1/operations/update
# operationId: updateOperation
# --operatorConfiguration shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
export def "operations-update updateOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  operationId: string # format: uuid
  operatorConfiguration: record # shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
]: any -> record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/update")
  let body = {name: $name, operationId: $operationId, operatorConfiguration: $operatorConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destinationDefinitionId: string # format: uuid
  --destinationId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/destinations/check_connection")
  let body = {connectionConfiguration: $connectionConfiguration, destinationDefinitionId: $destinationDefinitionId, destinationId: $destinationId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  sourceDefinitionId: string # format: uuid
  --sourceId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/sources/check_connection")
  let body = {connectionConfiguration: $connectionConfiguration, sourceDefinitionId: $sourceDefinitionId, sourceId: $sourceId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  sourceDefinitionId: string # format: uuid
  --sourceId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/sources/discover_schema")
  let body = {connectionConfiguration: $connectionConfiguration, sourceDefinitionId: $sourceDefinitionId, sourceId: $sourceId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: record, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, sourceDefinitionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definition_specifications/get")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a custom sourceDefinition for the given workspace
#
# POST /v1/source_definitions/create_custom
# operationId: createCustomSourceDefinition
# --sourceDefinition shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
export def "source-definitions-create-custom createCustomSourceDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceDefinition: record # shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
  workspaceId: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/create_custom")
  let body = {sourceDefinition: $sourceDefinition, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceDefinitionId: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get")
  let body = {sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get_for_workspace")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# grant a private, non-custom sourceDefinition to a given workspace
#
# POST /v1/source_definitions/grant_definition
# operationId: grantSourceDefinitionToWorkspace
export def "source-definitions-grant-definition grantSourceDefinitionToWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<granted: bool, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, sourceDefinitionId: string, sourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/grant_definition")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_for_workspace")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<sourceDefinitions: table<granted: bool, sourceDefinition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_private")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# revoke a grant to a private, non-custom sourceDefinition from a given workspace
#
# POST /v1/source_definitions/revoke_definition
# operationId: revokeSourceDefinitionFromWorkspace
export def "source-definitions-revoke-definition revokeSourceDefinitionFromWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/revoke_definition")
  let body = {sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  dockerImageTag: string
  --resourceRequirements: record # actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
  sourceDefinitionId: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/update")
  let body = {dockerImageTag: $dockerImageTag, resourceRequirements: $resourceRequirements, sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --queryParams: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirectUrl: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  sourceDefinitionId: string # format: uuid
  --sourceId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/complete_oauth")
  let body = {oAuthInputConfiguration: $oAuthInputConfiguration, queryParams: $queryParams, redirectUrl: $redirectUrl, sourceDefinitionId: $sourceDefinitionId, sourceId: $sourceId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --oAuthInputConfiguration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  redirectUrl: string # The url to redirect to after getting the user consent
  sourceDefinitionId: string # format: uuid
  --sourceId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/get_consent_url")
  let body = {oAuthInputConfiguration: $oAuthInputConfiguration, redirectUrl: $redirectUrl, sourceDefinitionId: $sourceDefinitionId, sourceId: $sourceId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  params: record
  sourceDefinitionId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/oauth_params/create")
  let body = {params: $params, sourceDefinitionId: $sourceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceId: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/check_connection")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check connection for a proposed update to a source
#
# POST /v1/sources/check_connection_for_update
# operationId: checkConnectionToSourceForUpdate
export def "sources-check-connection-for-update checkConnectionToSourceForUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  sourceId: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/check_connection_for_update")
  let body = {connectionConfiguration: $connectionConfiguration, name: $name, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clone source
#
# POST /v1/sources/clone
# operationId: cloneSource
# --sourceConfiguration shape: {connectionConfiguration?: any, name?: string}
export def "sources-clone cloneSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceCloneId: string # format: uuid
  --sourceConfiguration: record # shape: {connectionConfiguration?: any, name?: string}
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/clone")
  let body = {sourceCloneId: $sourceCloneId, sourceConfiguration: $sourceConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a source
#
# POST /v1/sources/create
# operationId: createSource
export def "sources-create createSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  sourceDefinitionId: string # format: uuid
  workspaceId: string # format: uuid
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/create")
  let body = {connectionConfiguration: $connectionConfiguration, name: $name, sourceDefinitionId: $sourceDefinitionId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --connectionId: string # format: uuid
  --disable-cache: oneof<nothing, bool>
  --notifySchemaChange: oneof<nothing, bool>
  sourceId: string # format: uuid
]: any -> record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/discover_schema")
  let body = {connectionId: $connectionId, disable_cache: $disable_cache, notifySchemaChange: $notifySchemaChange, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceId: string # format: uuid
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/get")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List sources for workspace
#
# POST /v1/sources/list
# operationId: listSourcesForWorkspace
export def "sources-list listSourcesForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/list")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  sourceId: string # format: uuid
]: any -> record<catalog: record, updatedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/most_recent_source_actor_catalog")
  let body = {sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --connectionConfiguration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --name: string
  --sourceDefinitionId: string # format: uuid
  --sourceId: string # format: uuid
  --sourceName: string
  --workspaceId: string # format: uuid
]: any -> record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/search")
  let body = {connectionConfiguration: $connectionConfiguration, name: $name, sourceDefinitionId: $sourceDefinitionId, sourceId: $sourceId, sourceName: $sourceName, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a source
#
# POST /v1/sources/update
# operationId: updateSource
export def "sources-update updateSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionConfiguration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  sourceId: string # format: uuid
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/update")
  let body = {connectionConfiguration: $connectionConfiguration, name: $name, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Should only called from worker, to write result from discover activity back to DB.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  catalog: record # describes the available schema (catalog). — shape: {streams: list}
  --configurationHash: string
  --connectorVersion: string
  --sourceId: string # format: uuid
]: any -> record<catalogId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/write_discover_catalog_result")
  let body = {catalog: $catalog, configurationHash: $configurationHash, connectorVersion: $connectorVersion, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or update the state for a connection.
#
# POST /v1/state/create_or_update
# operationId: createOrUpdateState
# --connectionState shape: {connectionId: string, globalState?: record, state?: record, stateType: "global"|"stream"|"legacy"|"not_set", streamState?: list}
export def "state-create-or-update createOrUpdateState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
  connectionState: record # Contains the state for a connection. The stateType field identifies what type of state it is. Only the field corresponding to that type will be set, the rest will be null. If stateType=not_set, then none of the fields will be set. — shape: {connectionId: string, globalState?: record, state?: record, stateType: "global"|"stream"|"legacy"|"not_set", streamState?: list}
]: any -> record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/create_or_update")
  let body = {connectionId: $connectionId, connectionState: $connectionState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/get")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<destinationDefinitions: int, sourceDefinitions: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/check_updates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a connection
#
# POST /v1/web_backend/connections/create
# operationId: webBackendCreateConnection
# --operations item shape: {name: string, operatorConfiguration: record, workspaceId: string}
# --resourceRequirements shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --syncCatalog shape: {streams: list}
export def "web-backend-connections-create webBackendCreateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destinationId: string # format: uuid
  --geography: string@geography-completer
  --name: string # Optional name of the connection
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --operationIds: list
  --operations: list # item shape: {name: string, operatorConfiguration: record, workspaceId: string}
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --sourceCatalogId: string # format: uuid
  sourceId: string # format: uuid
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/create")
  let body = {destinationId: $destinationId, geography: $geography, name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, nonBreakingChangesPreference: $nonBreakingChangesPreference, operationIds: $operationIds, operations: $operations, prefix: $prefix, resourceRequirements: $resourceRequirements, schedule: $schedule, scheduleData: $scheduleData, scheduleType: $scheduleType, sourceCatalogId: $sourceCatalogId, sourceId: $sourceId, status: $status, syncCatalog: $syncCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
  --withRefreshedCatalog: oneof<nothing, bool>
]: any -> record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/get")
  let body = {connectionId: $connectionId, withRefreshedCatalog: $withRefreshedCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all non-deleted connections for a workspace.
#
# POST /v1/web_backend/connections/list
# operationId: webBackendListConnectionsForWorkspace
export def "web-backend-connections-list webBackendListConnectionsForWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinationId: list
  --sourceId: list
  workspaceId: string # format: uuid
]: any -> record<connections: table<connectionId: string, destination: record, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, scheduleData: record, scheduleType: string, schemaChange: string, source: record, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/list")
  let body = {destinationId: $destinationId, sourceId: $sourceId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a connection
#
# POST /v1/web_backend/connections/update
# operationId: webBackendUpdateConnection
# --operations item shape: {name: string, operationId?: string, operatorConfiguration: record, workspaceId: string}
# --resourceRequirements shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --syncCatalog shape: {streams: list}
export def "web-backend-connections-update webBackendUpdateConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
  --geography: string@geography-completer
  --name: string # Name that will be set to the connection
  --namespaceDefinition: string@namespaceDefinition-completer # Method used for computing final namespace in destination
  --namespaceFormat: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --nonBreakingChangesPreference: string@nonBreakingChangesPreference-completer
  --notifySchemaChanges: oneof<nothing, bool>
  --operations: list # item shape: {name: string, operationId?: string, operatorConfiguration: record, workspaceId: string}
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resourceRequirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --scheduleData: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --scheduleType: string@scheduleType-completer # determine how the schedule data should be interpreted
  --skipReset: oneof<nothing, bool>
  --sourceCatalogId: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --syncCatalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/update")
  let body = {connectionId: $connectionId, geography: $geography, name: $name, namespaceDefinition: $namespaceDefinition, namespaceFormat: $namespaceFormat, nonBreakingChangesPreference: $nonBreakingChangesPreference, notifySchemaChanges: $notifySchemaChanges, operations: $operations, prefix: $prefix, resourceRequirements: $resourceRequirements, schedule: $schedule, scheduleData: $scheduleData, scheduleType: $scheduleType, skipReset: $skipReset, sourceCatalogId: $sourceCatalogId, status: $status, syncCatalog: $syncCatalog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns available geographies can be selected to run data syncs in a particular geography. The 'auto' entry indicates that the sync will be automatically assigned to a geography according to the platform default behavior. Entries other than 'auto' are two-letter country codes that follow the ISO 3166-1 alpha-2 standard.
#
# POST /v1/web_backend/geographies/list
# operationId: webBackendListGeographies
export def "web-backend-geographies-list webBackendListGeographies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<geographies: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/geographies/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<hasConnections: bool, hasDestinations: bool, hasSources: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/workspace/state")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a workspace
#
# POST /v1/workspaces/create
# operationId: createWorkspace
# --notifications item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
# --webhookConfigs item shape: {authToken?: string, name?: string, validationUrl?: string}
export def "workspaces-create createWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymousDataCollection: oneof<nothing, bool>
  --defaultGeography: string@defaultGeography-completer
  --displaySetupWizard: oneof<nothing, bool>
  --email: string # format: email
  name: string
  --news: oneof<nothing, bool>
  --notifications: list # item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
  --securityUpdates: oneof<nothing, bool>
  --webhookConfigs: list # item shape: {authToken?: string, name?: string, validationUrl?: string}
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/create")
  let body = {anonymousDataCollection: $anonymousDataCollection, defaultGeography: $defaultGeography, displaySetupWizard: $displaySetupWizard, email: $email, name: $name, news: $news, notifications: $notifications, securityUpdates: $securityUpdates, webhookConfigs: $webhookConfigs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/delete")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  workspaceId: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get")
  let body = {workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  connectionId: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_connection_id")
  let body = {connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_slug")
  let body = {slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all workspaces registered in the current Airbyte deployment
#
# POST /v1/workspaces/list
# operationId: listWorkspaces
export def "workspaces-list listWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workspaces: table<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: list, securityUpdates: bool, slug: string, webhookConfigs: list, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update workspace state
#
# POST /v1/workspaces/update
# operationId: updateWorkspace
# --notifications item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
# --webhookConfigs item shape: {authToken?: string, name?: string, validationUrl?: string}
export def "workspaces-update updateWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymousDataCollection: oneof<nothing, bool>
  --defaultGeography: string@defaultGeography-completer
  --displaySetupWizard: oneof<nothing, bool>
  --email: string # format: email
  --initialSetupComplete: oneof<nothing, bool>
  --news: oneof<nothing, bool>
  --notifications: list # item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
  --securityUpdates: oneof<nothing, bool>
  --webhookConfigs: list # item shape: {authToken?: string, name?: string, validationUrl?: string}
  workspaceId: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update")
  let body = {anonymousDataCollection: $anonymousDataCollection, defaultGeography: $defaultGeography, displaySetupWizard: $displaySetupWizard, email: $email, initialSetupComplete: $initialSetupComplete, news: $news, notifications: $notifications, securityUpdates: $securityUpdates, webhookConfigs: $webhookConfigs, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  workspaceId: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update_name")
  let body = {name: $name, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
