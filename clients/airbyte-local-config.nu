# Auto-generated client for Airbyte Configuration API v1.0.0
# Source: https://api.apis.guru/v2/specs/airbyte.local/config/1.0.0/openapi.json
# Auth: --token flag or $env.AIRBYTE_CONFIGURATION_API_TOKEN

const BASE_URL = "http://airbyte.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AIRBYTE_CONFIGURATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://airbyte.local" "http://localhost:8000/api"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def geography-completer [] { ["auto" "eu" "us"] }
def namespace-definition-completer [] { ["customformat" "destination" "source"] }
def non-breaking-changes-preference-completer [] { ["disable" "ignore"] }
def schedule-type-completer [] { ["basic" "cron" "manual"] }
def status-completer [] { ["active" "deprecated" "inactive"] }
def log-type-completer [] { ["scheduler" "server"] }
def notification-type-completer [] { ["customerio" "slack"] }
def operator-type-completer [] { ["dbt" "normalization" "webhook"] }
def default-geography-completer [] { ["auto" "eu" "us"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attempt-save-stats stats" } } | get name | first)
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
export def "attempt-save-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attempt_number: int # format: int32
  job_id: int # format: int64
  stats: record # shape: {bytesEmitted?: int, estimatedBytes?: int, estimatedRecords?: int, recordsCommitted?: int, recordsEmitted?: int, stateMessagesEmitted?: int}
  --stream-stats: list # item shape: {stats: record, streamName: string, streamNamespace?: string}
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_stats" $auth.query)
  let req_body = {"attemptNumber": $attempt_number, "jobId": $job_id, "stats": $stats, "streamStats": $stream_stats} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# For worker to save the AttemptSyncConfig for an attempt.
#
# POST /v1/attempt/save_sync_config
# operationId: saveSyncConfig
# --syncConfig shape: {destinationConfiguration: any, sourceConfiguration: any, state?: record}
export def "attempt-save-sync-config sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attempt_number: int # format: int32
  job_id: int # format: int64
  sync_config: record # shape: {destinationConfiguration: any, sourceConfiguration: any, state?: record}
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/save_sync_config" $auth.query)
  let req_body = {"attemptNumber": $attempt_number, "jobId": $job_id, "syncConfig": $sync_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# For worker to register the workflow id in attempt.
#
# POST /v1/attempt/set_workflow_in_attempt
# operationId: setWorkflowInAttempt
export def "attempt-set-workflow-in-attempt update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attempt_number: int # format: int32
  job_id: int # format: int64
  --processing-task-queue: string # default: 
  workflow_id: string
]: any -> record<succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/attempt/set_workflow_in_attempt" $auth.query)
  let req_body = {"attemptNumber": $attempt_number, "jobId": $job_id, "processingTaskQueue": $processing_task_queue, "workflowId": $workflow_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create a connection between a source and a destination
#
# POST /v1/connections/create
# operationId: createConnection
# --resourceRequirements shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --syncCatalog shape: {streams: list}
export def "connections-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Optional name of the connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --notify-schema-changes: oneof<nothing, bool>
  --operation-ids: list<string>
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source-catalog-id: string # format: uuid
  source_id: string # format: uuid
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/create" $auth.query)
  let req_body = {"destinationId": $destination_id, "geography": $geography, "name": $name, "namespaceDefinition": $namespace_definition, "namespaceFormat": $namespace_format, "nonBreakingChangesPreference": $non_breaking_changes_preference, "notifySchemaChanges": $notify_schema_changes, "operationIds": $operation_ids, "prefix": $prefix, "resourceRequirements": $resource_requirements, "schedule": $schedule, "scheduleData": $schedule_data, "scheduleType": $schedule_type, "sourceCatalogId": $source_catalog_id, "sourceId": $source_id, "status": $status, "syncCatalog": $sync_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a connection
#
# POST /v1/connections/delete
# operationId: deleteConnection
export def "connections-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/delete" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a connection
#
# POST /v1/connections/get
# operationId: getConnection
export def "connections-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/get" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all connections for a workspace.
#
# POST /v1/connections/list
# operationId: listConnectionsForWorkspace
export def "connections-list list-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all connections for a workspace, including deleted connections.
#
# POST /v1/connections/list_all
# operationId: listAllConnectionsForWorkspace
export def "connections-list-all list-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/list_all" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Reset the data for the connection. Deletes data generated by the connection in the destination. Resets any cursors back to initial state.
#
# POST /v1/connections/reset
# operationId: resetConnection
export def "connections-reset reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/reset" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Search connections
#
# POST /v1/connections/search
# operationId: searchConnections
# --destination shape: {connectionConfiguration?: any, destinationDefinitionId?: string, destinationId?: string, destinationName?: string, name?: string, workspaceId?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --source shape: {connectionConfiguration?: any, name?: string, sourceDefinitionId?: string, sourceId?: string, sourceName?: string, workspaceId?: string}
export def "connections-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # format: uuid
  --destination: record # shape: {connectionConfiguration?: any, destinationDefinitionId?: string, destinationId?: string, destinationName?: string, name?: string, workspaceId?: string}
  --destination-id: string # format: uuid
  --name: string
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --body-source: record # shape: {connectionConfiguration?: any, name?: string, sourceDefinitionId?: string, sourceId?: string, sourceName?: string, workspaceId?: string}
  --source-id: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
]: any -> record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/search" $auth.query)
  let req_body = {"connectionId": $connection_id, "destination": $destination, "destinationId": $destination_id, "name": $name, "namespaceDefinition": $namespace_definition, "namespaceFormat": $namespace_format, "prefix": $prefix, "schedule": $schedule, "scheduleData": $schedule_data, "scheduleType": $schedule_type, "source": $body_source, "sourceId": $source_id, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Trigger a manual sync of the connection
#
# POST /v1/connections/sync
# operationId: syncConnection
export def "connections-sync sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/sync" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a connection
#
# POST /v1/connections/update
# operationId: updateConnection
# --resourceRequirements shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
# --schedule shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
# --scheduleData shape: {basicSchedule?: record, cron?: record}
# --syncCatalog shape: {streams: list}
export def "connections-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --breaking-change: oneof<nothing, bool>
  connection_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Name that will be set to this connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --notify-schema-changes: oneof<nothing, bool>
  --operation-ids: list<string>
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source-catalog-id: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/update" $auth.query)
  let req_body = {"breakingChange": $breaking_change, "connectionId": $connection_id, "geography": $geography, "name": $name, "namespaceDefinition": $namespace_definition, "namespaceFormat": $namespace_format, "nonBreakingChangesPreference": $non_breaking_changes_preference, "notifySchemaChanges": $notify_schema_changes, "operationIds": $operation_ids, "prefix": $prefix, "resourceRequirements": $resource_requirements, "schedule": $schedule, "scheduleData": $schedule_data, "scheduleType": $schedule_type, "sourceCatalogId": $source_catalog_id, "status": $status, "syncCatalog": $sync_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get specification for a destinationDefinition
#
# POST /v1/destination_definition_specifications/get
# operationId: getDestinationDefinitionSpecification
export def "destination-definition-specifications-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: any, destinationDefinitionId: string, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, supportedDestinationSyncModes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definition_specifications/get" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a custom destinationDefinition for the given workspace
#
# POST /v1/destination_definitions/create_custom
# operationId: createCustomDestinationDefinition
# --destinationDefinition shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
export def "destination-definitions-create-custom create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition: record # shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
  workspace_id: string # format: uuid
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/create_custom" $auth.query)
  let req_body = {"destinationDefinition": $destination_definition, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a destination definition
#
# POST /v1/destination_definitions/delete
# operationId: deleteDestinationDefinition
export def "destination-definitions-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/delete" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get destinationDefinition
#
# POST /v1/destination_definitions/get
# operationId: getDestinationDefinition
export def "destination-definitions-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a destinationDefinition that is configured for the given workspace
#
# POST /v1/destination_definitions/get_for_workspace
# operationId: getDestinationDefinitionForWorkspace
export def "destination-definitions-get-for-workspace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/get_for_workspace" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# grant a private, non-custom destinationDefinition to a given workspace
#
# POST /v1/destination_definitions/grant_definition
# operationId: grantDestinationDefinitionToWorkspace
export def "destination-definitions-grant-definition create-to-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, supportsDbt: bool>, granted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/grant_definition" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all the destinationDefinitions the current Airbyte deployment is configured to use
#
# POST /v1/destination_definitions/list
# operationId: listDestinationDefinitions
export def "destination-definitions-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List all the destinationDefinitions the given workspace is configured to use
#
# POST /v1/destination_definitions/list_for_workspace
# operationId: listDestinationDefinitionsForWorkspace
export def "destination-definitions-list-for-workspace list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_for_workspace" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the latest destinationDefinitions Airbyte supports
#
# POST /v1/destination_definitions/list_latest
# operationId: listLatestDestinationDefinitions
export def "destination-definitions-list-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_latest" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List all private, non-custom destinationDefinitions, and for each indicate whether the given workspace has a grant for using the definition. Used by admins to view and modify a given workspace's grants.
#
# POST /v1/destination_definitions/list_private
# operationId: listPrivateDestinationDefinitions
export def "destination-definitions-list-private list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<destinationDefinitions: table<destinationDefinition: record, granted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/list_private" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# revoke a grant to a private, non-custom destinationDefinition from a given workspace
#
# POST /v1/destination_definitions/revoke_definition
# operationId: revokeDestinationDefinitionFromWorkspace
export def "destination-definitions-revoke-definition delete-from-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/revoke_definition" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update destinationDefinition
#
# POST /v1/destination_definitions/update
# operationId: updateDestinationDefinition
# --resourceRequirements shape: {default?: record, jobSpecific?: list}
export def "destination-definitions-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  --docker-image-tag: string
  --resource-requirements: record # actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_definitions/update" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "dockerImageTag": $docker_image_tag, "resourceRequirements": $resource_requirements} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Given a destination def ID generate an access/refresh token etc.
#
# POST /v1/destination_oauths/complete_oauth
# operationId: completeDestinationOAuth
export def "destination-oauths-complete-oauth complete-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  --destination-id: string # format: uuid
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --query-params: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirect-url: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  workspace_id: string # format: uuid
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/complete_oauth" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "destinationId": $destination_id, "oAuthInputConfiguration": $o_auth_input_configuration, "queryParams": $query_params, "redirectUrl": $redirect_url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Given a destination connector definition ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/destination_oauths/get_consent_url
# operationId: getDestinationOAuthConsent
export def "destination-oauths-get-consent-url get-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  --destination-id: string # format: uuid
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  redirect_url: string # The url to redirect to after getting the user consent
  workspace_id: string # format: uuid
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/get_consent_url" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "destinationId": $destination_id, "oAuthInputConfiguration": $o_auth_input_configuration, "redirectUrl": $redirect_url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sets instancewide variables to be used for the oauth flow when creating this destination. When set, these variables will be injected into a connector's configuration before any interaction with the connector image itself. This enables running oauth flows with consistent variables e.g: the company's Google Ads developer_token, client_id, and client_secret without the user having to know about these variables.
#
# POST /v1/destination_oauths/oauth_params/create
# operationId: setInstancewideDestinationOauthParams
export def "destination-oauths-oauth-params-create update-instancewide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  params: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destination_oauths/oauth_params/create" $auth.query)
  let req_body = {"destinationDefinitionId": $destination_definition_id, "params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Check connection to the destination
#
# POST /v1/destinations/check_connection
# operationId: checkConnectionToDestination
export def "destinations-check-connection check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/check_connection" $auth.query)
  let req_body = {"destinationId": $destination_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Check connection for a proposed update to a destination
#
# POST /v1/destinations/check_connection_for_update
# operationId: checkConnectionToDestinationForUpdate
export def "destinations-check-connection-for-update check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_id: string # format: uuid
  name: string
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/check_connection_for_update" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "destinationId": $destination_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Clone destination
#
# POST /v1/destinations/clone
# operationId: cloneDestination
# --destinationConfiguration shape: {connectionConfiguration?: any, name?: string}
export def "destinations-clone clone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_clone_id: string # format: uuid
  --destination-configuration: record # shape: {connectionConfiguration?: any, name?: string}
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/clone" $auth.query)
  let req_body = {"destinationCloneId": $destination_clone_id, "destinationConfiguration": $destination_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create a destination
#
# POST /v1/destinations/create
# operationId: createDestination
export def "destinations-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_definition_id: string # format: uuid
  name: string
  workspace_id: string # format: uuid
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/create" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "destinationDefinitionId": $destination_definition_id, "name": $name, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete the destination
#
# POST /v1/destinations/delete
# operationId: deleteDestination
export def "destinations-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/delete" $auth.query)
  let req_body = {"destinationId": $destination_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get configured destination
#
# POST /v1/destinations/get
# operationId: getDestination
export def "destinations-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/get" $auth.query)
  let req_body = {"destinationId": $destination_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List configured destinations for a workspace
#
# POST /v1/destinations/list
# operationId: listDestinationsForWorkspace
export def "destinations-list list-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/list" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Search destinations
#
# POST /v1/destinations/search
# operationId: searchDestinations
export def "destinations-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --destination-definition-id: string # format: uuid
  --destination-id: string # format: uuid
  --destination-name: string
  --name: string
  --workspace-id: string # format: uuid
]: any -> record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/search" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "destinationDefinitionId": $destination_definition_id, "destinationId": $destination_id, "destinationName": $destination_name, "name": $name, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a destination
#
# POST /v1/destinations/update
# operationId: updateDestination
export def "destinations-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_id: string # format: uuid
  name: string
]: any -> record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/destinations/update" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "destinationId": $destination_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Health Check
#
# GET /v1/health
# operationId: getHealthCheck
export def "health get-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cancels a job
#
# POST /v1/jobs/cancel
# operationId: cancelJob
export def "jobs-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/cancel" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get information about a job
#
# POST /v1/jobs/get
# operationId: getJobInfo
export def "jobs-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets all information needed to debug this job
#
# POST /v1/jobs/get_debug_info
# operationId: getJobDebugInfo
export def "jobs-get-debug-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attempts: table<attempt: record, logs: record>, job: record<airbyteVersion: string, configId: string, configType: string, destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>, id: int, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>, status: string>, workflowState: record<running: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_debug_info" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /v1/jobs/get_last_replication_job
#
# operationId: getLastReplicationJob
export def "jobs-get-last-replication-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_last_replication_job" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get information about a job excluding attempt info and logs
#
# POST /v1/jobs/get_light
# operationId: getJobInfoLight
export def "jobs-get-light get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_light" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get normalization status to determine if we can bypass normalization phase
#
# POST /v1/jobs/get_normalization_status
# operationId: getAttemptNormalizationStatusesForJob
export def "jobs-get-normalization-status get-attempt-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> record<attemptNormalizationStatuses: table<attemptNumber: int, hasNormalizationFailed: bool, hasRecordsCommitted: bool, recordsCommitted: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/get_normalization_status" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns recent jobs for a connection. Jobs are returned in descending order by createdAt.
#
# POST /v1/jobs/list
# operationId: listJobsFor
# --pagination shape: {pageSize?: int, rowOffset?: int}
export def "jobs-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config_id: string
  config_types: list<string>
  --including-job-id: int # format: int64
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
]: any -> record<jobs: table<attempts: list, job: record>, totalJobCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jobs/list" $auth.query)
  let req_body = {"configId": $config_id, "configTypes": $config_types, "includingJobId": $including_job_id, "pagination": $pagination} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get logs
#
# POST /v1/logs/get
# operationId: getLogs
export def "logs-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  log_type: string@log-type-completer # type/source of logs produced
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logs/get" $auth.query)
  let req_body = {"logType": $log_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Try sending a notifications
#
# POST /v1/notifications/try
# operationId: tryNotificationConfig
# --slackConfiguration shape: {webhook: string}
export def "notifications-try create-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customerio-configuration: record
  notification_type: string@notification-type-completer
  --send-on-failure: oneof<nothing, bool> # default: true
  --send-on-success: oneof<nothing, bool> # default: false
  --slack-configuration: record # shape: {webhook: string}
]: any -> record<message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/notifications/try" $auth.query)
  let req_body = {"customerioConfiguration": $customerio_configuration, "notificationType": $notification_type, "sendOnFailure": $send_on_failure, "sendOnSuccess": $send_on_success, "slackConfiguration": $slack_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the openapi specification
#
# GET /v1/openapi
# operationId: getOpenApiSpec
export def "openapi get-open-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/openapi" $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check if an operation to be created is valid
#
# POST /v1/operations/check
# operationId: checkOperation
# --dbt shape: {dbtArguments?: string, dockerImage?: string, gitRepoBranch?: string, gitRepoUrl: string}
# --normalization shape: {option?: "basic"}
# --webhook shape: {dbtCloud?: record, executionBody?: string, executionUrl?: string, webhookConfigId?: string, webhookType?: "dbtCloud"}
export def "operations-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbt: record # shape: {dbtArguments?: string, dockerImage?: string, gitRepoBranch?: string, gitRepoUrl: string}
  --normalization: record # shape: {option?: "basic"}
  operator_type: string@operator-type-completer
  --webhook: record # shape: {dbtCloud?: record, executionBody?: string, executionUrl?: string, webhookConfigId?: string, webhookType?: "dbtCloud"}
]: any -> record<message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/check" $auth.query)
  let req_body = {"dbt": $dbt, "normalization": $normalization, "operatorType": $operator_type, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create an operation to be applied as part of a connection pipeline
#
# POST /v1/operations/create
# operationId: createOperation
# --operatorConfiguration shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
export def "operations-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  operator_configuration: record # shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
  workspace_id: string # format: uuid
]: any -> record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/create" $auth.query)
  let req_body = {"name": $name, "operatorConfiguration": $operator_configuration, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an operation
#
# POST /v1/operations/delete
# operationId: deleteOperation
export def "operations-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  operation_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/delete" $auth.query)
  let req_body = {"operationId": $operation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns an operation
#
# POST /v1/operations/get
# operationId: getOperation
export def "operations-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  operation_id: string # format: uuid
]: any -> record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/get" $auth.query)
  let req_body = {"operationId": $operation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all operations for a connection.
#
# POST /v1/operations/list
# operationId: listOperationsForConnection
export def "operations-list list-for-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/list" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update an operation
#
# POST /v1/operations/update
# operationId: updateOperation
# --operatorConfiguration shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
export def "operations-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  operation_id: string # format: uuid
  operator_configuration: record # shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
]: any -> record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/operations/update" $auth.query)
  let req_body = {"name": $name, "operationId": $operation_id, "operatorConfiguration": $operator_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Run check connection for a given destination configuration
#
# POST /v1/scheduler/destinations/check_connection
# operationId: executeDestinationCheckConnection
export def "scheduler-destinations-check-connection check-execute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_definition_id: string # format: uuid
  --destination-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/destinations/check_connection" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "destinationDefinitionId": $destination_definition_id, "destinationId": $destination_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Run check connection for a given source configuration
#
# POST /v1/scheduler/sources/check_connection
# operationId: executeSourceCheckConnection
export def "scheduler-sources-check-connection check-execute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/sources/check_connection" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "sourceDefinitionId": $source_definition_id, "sourceId": $source_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Run discover schema for a given source a source configuration
#
# POST /v1/scheduler/sources/discover_schema
# operationId: executeSourceDiscoverSchema
export def "scheduler-sources-discover-schema create-execute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduler/sources/discover_schema" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "sourceDefinitionId": $source_definition_id, "sourceId": $source_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get specification for a SourceDefinition.
#
# POST /v1/source_definition_specifications/get
# operationId: getSourceDefinitionSpecification
export def "source-definition-specifications-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: record, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, sourceDefinitionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definition_specifications/get" $auth.query)
  let req_body = {"sourceDefinitionId": $source_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a custom sourceDefinition for the given workspace
#
# POST /v1/source_definitions/create_custom
# operationId: createCustomSourceDefinition
# --sourceDefinition shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
export def "source-definitions-create-custom create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition: record # shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
  workspace_id: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/create_custom" $auth.query)
  let req_body = {"sourceDefinition": $source_definition, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a source definition
#
# POST /v1/source_definitions/delete
# operationId: deleteSourceDefinition
export def "source-definitions-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/delete" $auth.query)
  let req_body = {"sourceDefinitionId": $source_definition_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get source
#
# POST /v1/source_definitions/get
# operationId: getSourceDefinition
export def "source-definitions-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get" $auth.query)
  let req_body = {"sourceDefinitionId": $source_definition_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a sourceDefinition that is configured for the given workspace
#
# POST /v1/source_definitions/get_for_workspace
# operationId: getSourceDefinitionForWorkspace
export def "source-definitions-get-for-workspace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/get_for_workspace" $auth.query)
  let req_body = {"sourceDefinitionId": $source_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# grant a private, non-custom sourceDefinition to a given workspace
#
# POST /v1/source_definitions/grant_definition
# operationId: grantSourceDefinitionToWorkspace
export def "source-definitions-grant-definition create-to-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<granted: bool, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, sourceDefinitionId: string, sourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/grant_definition" $auth.query)
  let req_body = {"sourceDefinitionId": $source_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all the sourceDefinitions the current Airbyte deployment is configured to use
#
# POST /v1/source_definitions/list
# operationId: listSourceDefinitions
export def "source-definitions-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List all the sourceDefinitions the given workspace is configured to use
#
# POST /v1/source_definitions/list_for_workspace
# operationId: listSourceDefinitionsForWorkspace
export def "source-definitions-list-for-workspace list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_for_workspace" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the latest sourceDefinitions Airbyte supports
#
# POST /v1/source_definitions/list_latest
# operationId: listLatestSourceDefinitions
export def "source-definitions-list-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_latest" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List all private, non-custom sourceDefinitions, and for each indicate whether the given workspace has a grant for using the definition. Used by admins to view and modify a given workspace's grants.
#
# POST /v1/source_definitions/list_private
# operationId: listPrivateSourceDefinitions
export def "source-definitions-list-private list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<sourceDefinitions: table<granted: bool, sourceDefinition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/list_private" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# revoke a grant to a private, non-custom sourceDefinition from a given workspace
#
# POST /v1/source_definitions/revoke_definition
# operationId: revokeSourceDefinitionFromWorkspace
export def "source-definitions-revoke-definition delete-from-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/revoke_definition" $auth.query)
  let req_body = {"sourceDefinitionId": $source_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update a sourceDefinition
#
# POST /v1/source_definitions/update
# operationId: updateSourceDefinition
# --resourceRequirements shape: {default?: record, jobSpecific?: list}
export def "source-definitions-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  docker_image_tag: string
  --resource-requirements: record # actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
  source_definition_id: string # format: uuid
]: any -> record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_definitions/update" $auth.query)
  let req_body = {"dockerImageTag": $docker_image_tag, "resourceRequirements": $resource_requirements, "sourceDefinitionId": $source_definition_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Given a source def ID generate an access/refresh token etc.
#
# POST /v1/source_oauths/complete_oauth
# operationId: completeSourceOAuth
export def "source-oauths-complete-oauth complete-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --query-params: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirect-url: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/complete_oauth" $auth.query)
  let req_body = {"oAuthInputConfiguration": $o_auth_input_configuration, "queryParams": $query_params, "redirectUrl": $redirect_url, "sourceDefinitionId": $source_definition_id, "sourceId": $source_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Given a source connector definition ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/source_oauths/get_consent_url
# operationId: getSourceOAuthConsent
export def "source-oauths-get-consent-url get-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  redirect_url: string # The url to redirect to after getting the user consent
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<consentUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/get_consent_url" $auth.query)
  let req_body = {"oAuthInputConfiguration": $o_auth_input_configuration, "redirectUrl": $redirect_url, "sourceDefinitionId": $source_definition_id, "sourceId": $source_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sets instancewide variables to be used for the oauth flow when creating this source. When set, these variables will be injected into a connector's configuration before any interaction with the connector image itself. This enables running oauth flows with consistent variables e.g: the company's Google Ads developer_token, client_id, and client_secret without the user having to know about these variables.
#
# POST /v1/source_oauths/oauth_params/create
# operationId: setInstancewideSourceOauthParams
export def "source-oauths-oauth-params-create update-instancewide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  params: record
  source_definition_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source_oauths/oauth_params/create" $auth.query)
  let req_body = {"params": $params, "sourceDefinitionId": $source_definition_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Check connection to the source
#
# POST /v1/sources/check_connection
# operationId: checkConnectionToSource
export def "sources-check-connection check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/check_connection" $auth.query)
  let req_body = {"sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Check connection for a proposed update to a source
#
# POST /v1/sources/check_connection_for_update
# operationId: checkConnectionToSourceForUpdate
export def "sources-check-connection-for-update check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  source_id: string # format: uuid
]: any -> record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/check_connection_for_update" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "name": $name, "sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Clone source
#
# POST /v1/sources/clone
# operationId: cloneSource
# --sourceConfiguration shape: {connectionConfiguration?: any, name?: string}
export def "sources-clone clone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_clone_id: string # format: uuid
  --source-configuration: record # shape: {connectionConfiguration?: any, name?: string}
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/clone" $auth.query)
  let req_body = {"sourceCloneId": $source_clone_id, "sourceConfiguration": $source_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create a source
#
# POST /v1/sources/create
# operationId: createSource
export def "sources-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/create" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "name": $name, "sourceDefinitionId": $source_definition_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a source
#
# POST /v1/sources/delete
# operationId: deleteSource
export def "sources-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/delete" $auth.query)
  let req_body = {"sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Discover the schema catalog of the source
#
# POST /v1/sources/discover_schema
# operationId: discoverSchemaForSource
export def "sources-discover-schema create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # format: uuid
  --disable-cache: oneof<nothing, bool>
  --notify-schema-change: oneof<nothing, bool>
  source_id: string # format: uuid
]: any -> record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/discover_schema" $auth.query)
  let req_body = {"connectionId": $connection_id, "disable_cache": $disable_cache, "notifySchemaChange": $notify_schema_change, "sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get source
#
# POST /v1/sources/get
# operationId: getSource
export def "sources-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/get" $auth.query)
  let req_body = {"sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List sources for workspace
#
# POST /v1/sources/list
# operationId: listSourcesForWorkspace
export def "sources-list list-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/list" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get most recent ActorCatalog for source
#
# POST /v1/sources/most_recent_source_actor_catalog
# operationId: getMostRecentSourceActorCatalog
export def "sources-most-recent-source-actor-catalog get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> record<catalog: record, updatedAt: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/most_recent_source_actor_catalog" $auth.query)
  let req_body = {"sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Search sources
#
# POST /v1/sources/search
# operationId: searchSources
export def "sources-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --name: string
  --source-definition-id: string # format: uuid
  --source-id: string # format: uuid
  --source-name: string
  --workspace-id: string # format: uuid
]: any -> record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/search" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "name": $name, "sourceDefinitionId": $source_definition_id, "sourceId": $source_id, "sourceName": $source_name, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a source
#
# POST /v1/sources/update
# operationId: updateSource
export def "sources-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  source_id: string # format: uuid
]: any -> record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/update" $auth.query)
  let req_body = {"connectionConfiguration": $connection_configuration, "name": $name, "sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Should only called from worker, to write result from discover activity back to DB.
#
# POST /v1/sources/write_discover_catalog_result
# operationId: writeDiscoverCatalogResult
# --catalog shape: {streams: list}
export def "sources-write-discover-catalog-result create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  catalog: record # describes the available schema (catalog). — shape: {streams: list}
  --configuration-hash: string
  --connector-version: string
  --source-id: string # format: uuid
]: any -> record<catalogId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/write_discover_catalog_result" $auth.query)
  let req_body = {"catalog": $catalog, "configurationHash": $configuration_hash, "connectorVersion": $connector_version, "sourceId": $source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create or update the state for a connection.
#
# POST /v1/state/create_or_update
# operationId: createOrUpdateState
# --connectionState shape: {connectionId: string, globalState?: record, state?: record, stateType: "global"|"stream"|"legacy"|"not_set", streamState?: list}
export def "state-create-or-update create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  connection_state: record # Contains the state for a connection. The stateType field identifies what type of state it is. Only the field corresponding to that type will be set, the rest will be null. If stateType=not_set, then none of the fields will be set. — shape: {connectionId: string, globalState?: record, state?: record, stateType: "global"|"stream"|"legacy"|"not_set", streamState?: list}
]: any -> record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/create_or_update" $auth.query)
  let req_body = {"connectionId": $connection_id, "connectionState": $connection_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Fetch the current state for a connection.
#
# POST /v1/state/get
# operationId: getState
export def "state-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/state/get" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a summary of source and destination definitions that could be updated.
#
# POST /v1/web_backend/check_updates
# operationId: webBackendCheckUpdates
export def "web-backend-check-updates check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<destinationDefinitions: int, sourceDefinitions: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/check_updates" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
export def "web-backend-connections-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Optional name of the connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --operation-ids: list<string>
  --operations: list # item shape: {name: string, operatorConfiguration: record, workspaceId: string}
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source-catalog-id: string # format: uuid
  source_id: string # format: uuid
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/create" $auth.query)
  let req_body = {"destinationId": $destination_id, "geography": $geography, "name": $name, "namespaceDefinition": $namespace_definition, "namespaceFormat": $namespace_format, "nonBreakingChangesPreference": $non_breaking_changes_preference, "operationIds": $operation_ids, "operations": $operations, "prefix": $prefix, "resourceRequirements": $resource_requirements, "schedule": $schedule, "scheduleData": $schedule_data, "scheduleType": $schedule_type, "sourceCatalogId": $source_catalog_id, "sourceId": $source_id, "status": $status, "syncCatalog": $sync_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a connection
#
# POST /v1/web_backend/connections/get
# operationId: webBackendGetConnection
export def "web-backend-connections-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  --with-refreshed-catalog: oneof<nothing, bool>
]: any -> record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/get" $auth.query)
  let req_body = {"connectionId": $connection_id, "withRefreshedCatalog": $with_refreshed_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all non-deleted connections for a workspace.
#
# POST /v1/web_backend/connections/list
# operationId: webBackendListConnectionsForWorkspace
export def "web-backend-connections-list list-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-id: list<string>
  --source-id: list<string>
  workspace_id: string # format: uuid
]: any -> record<connections: table<connectionId: string, destination: record, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, scheduleData: record, scheduleType: string, schemaChange: string, source: record, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/list" $auth.query)
  let req_body = {"destinationId": $destination_id, "sourceId": $source_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
export def "web-backend-connections-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Name that will be set to the connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --notify-schema-changes: oneof<nothing, bool>
  --operations: list # item shape: {name: string, operationId?: string, operatorConfiguration: record, workspaceId: string}
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --skip-reset: oneof<nothing, bool>
  --source-catalog-id: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/connections/update" $auth.query)
  let req_body = {"connectionId": $connection_id, "geography": $geography, "name": $name, "namespaceDefinition": $namespace_definition, "namespaceFormat": $namespace_format, "nonBreakingChangesPreference": $non_breaking_changes_preference, "notifySchemaChanges": $notify_schema_changes, "operations": $operations, "prefix": $prefix, "resourceRequirements": $resource_requirements, "schedule": $schedule, "scheduleData": $schedule_data, "scheduleType": $schedule_type, "skipReset": $skip_reset, "sourceCatalogId": $source_catalog_id, "status": $status, "syncCatalog": $sync_catalog} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns available geographies can be selected to run data syncs in a particular geography. The 'auto' entry indicates that the sync will be automatically assigned to a geography according to the platform default behavior. Entries other than 'auto' are two-letter country codes that follow the ISO 3166-1 alpha-2 standard.
#
# POST /v1/web_backend/geographies/list
# operationId: webBackendListGeographies
export def "web-backend-geographies-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<geographies: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/geographies/list" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Fetch the current state type for a connection.
#
# POST /v1/web_backend/state/get_type
# operationId: getStateType
export def "web-backend-state-get-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/state/get_type" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the current state of a workspace
#
# POST /v1/web_backend/workspace/state
# operationId: webBackendGetWorkspaceState
export def "web-backend-workspace-state get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<hasConnections: bool, hasDestinations: bool, hasSources: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/web_backend/workspace/state" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a workspace
#
# POST /v1/workspaces/create
# operationId: createWorkspace
# --notifications item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
# --webhookConfigs item shape: {authToken?: string, name?: string, validationUrl?: string}
export def "workspaces-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymous-data-collection: oneof<nothing, bool>
  --default-geography: string@default-geography-completer
  --display-setup-wizard: oneof<nothing, bool>
  --email: string # format: email
  name: string
  --news: oneof<nothing, bool>
  --notifications: list # item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
  --security-updates: oneof<nothing, bool>
  --webhook-configs: list # item shape: {authToken?: string, name?: string, validationUrl?: string}
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/create" $auth.query)
  let req_body = {"anonymousDataCollection": $anonymous_data_collection, "defaultGeography": $default_geography, "displaySetupWizard": $display_setup_wizard, "email": $email, "name": $name, "news": $news, "notifications": $notifications, "securityUpdates": $security_updates, "webhookConfigs": $webhook_configs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a workspace
#
# POST /v1/workspaces/delete
# operationId: deleteWorkspace
export def "workspaces-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/delete" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Find workspace by ID
#
# POST /v1/workspaces/get
# operationId: getWorkspace
export def "workspaces-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Find workspace by connection id
#
# POST /v1/workspaces/get_by_connection_id
# operationId: getWorkspaceByConnectionId
export def "workspaces-get-by-connection-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_connection_id" $auth.query)
  let req_body = {"connectionId": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Find workspace by slug
#
# POST /v1/workspaces/get_by_slug
# operationId: getWorkspaceBySlug
export def "workspaces-get-by-slug get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/get_by_slug" $auth.query)
  let req_body = {"slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all workspaces registered in the current Airbyte deployment
#
# POST /v1/workspaces/list
# operationId: listWorkspaces
export def "workspaces-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workspaces: table<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: list, securityUpdates: bool, slug: string, webhookConfigs: list, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/list" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Update workspace feedback state
#
# POST /v1/workspaces/tag_feedback_status_as_done
# operationId: updateWorkspaceFeedback
export def "workspaces-tag-feedback-status-as-done update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/tag_feedback_status_as_done" $auth.query)
  let req_body = {"workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update workspace state
#
# POST /v1/workspaces/update
# operationId: updateWorkspace
# --notifications item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
# --webhookConfigs item shape: {authToken?: string, name?: string, validationUrl?: string}
export def "workspaces-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymous-data-collection: oneof<nothing, bool>
  --default-geography: string@default-geography-completer
  --display-setup-wizard: oneof<nothing, bool>
  --email: string # format: email
  --initial-setup-complete: oneof<nothing, bool>
  --news: oneof<nothing, bool>
  --notifications: list # item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
  --security-updates: oneof<nothing, bool>
  --webhook-configs: list # item shape: {authToken?: string, name?: string, validationUrl?: string}
  workspace_id: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update" $auth.query)
  let req_body = {"anonymousDataCollection": $anonymous_data_collection, "defaultGeography": $default_geography, "displaySetupWizard": $display_setup_wizard, "email": $email, "initialSetupComplete": $initial_setup_complete, "news": $news, "notifications": $notifications, "securityUpdates": $security_updates, "webhookConfigs": $webhook_configs, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update workspace name
#
# POST /v1/workspaces/update_name
# operationId: updateWorkspaceName
export def "workspaces-update-name update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  workspace_id: string # format: uuid
]: any -> record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces/update_name" $auth.query)
  let req_body = {"name": $name, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
