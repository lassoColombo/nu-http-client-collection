# Auto-generated client for Kibana Serverless APIs v
# Source: https://raw.githubusercontent.com/elastic/kibana/main/oas_docs/output/kibana.serverless.yaml
# Auth: --token flag or $env.KIBANA_SERVERLESS_APIS_TOKEN

const BASE_URL = "https://<KIBANA_URL>"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KIBANA_SERVERLESS_APIS_TOKEN | default "" }
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

def base-url-completer [] { ["https://<KIBANA_URL>"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def visibility-completer [] { ["private" "public" "shared"] }
def sort-field-completer [] { ["round_count" "total_tokens" "updated_at"] }
def sort-order-completer [] { ["asc" "desc"] }
def execution-mode-completer [] { ["local" "task_manager"] }
def action-completer [] { ["regenerate"] }
def type-completer [] { ["esql" "index_search" "mcp" "workflow"] }
def notify-when-completer [] { ["" "onActionGroupChange" "onActiveAlert" "onThrottleInterval"] }
def mode-completer [] { ["build" "execute"] }
def default-search-operator-completer [] { ["AND" "OR"] }
def initiator-completer [] { ["system" "user"] }
def sort-field-completer-1 [] { ["createdAt" "start"] }
def elastic-api-version-completer [] { ["2023-10-31"] }
def id-field-completer [] { ["entity.id" "host.name" "service.name" "user.name"] }
def refresh-completer [] { ["wait_for"] }
def sort-field-completer-2 [] { ["@timestamp" "criticality_level" "id_field" "id_value"] }
def sort-direction-completer [] { ["asc" "desc"] }
def sort-field-completer-3 [] { ["@timestamp"] }
def subAction-completer [] { ["invokeAI" "invokeStream"] }
def action-completer-1 [] { ["delete"] }
def sort-field-completer-4 [] { ["createdAt" "created_at" "enabled" "execution_summary.last_execution.date" "execution_summary.last_execution.metrics.execution_gap_duration_s" "execution_summary.last_execution.metrics.total_indexing_duration_ms" "execution_summary.last_execution.metrics.total_search_duration_ms" "execution_summary.last_execution.status" "name" "riskScore" "risk_score" "severity" "updatedAt" "updated_at"] }
def type-completer-1 [] { ["simple"] }
def agentTypes-completer [] { ["crowdstrike" "endpoint" "microsoft_defender_endpoint" "sentinel_one"] }
def agent-type-completer [] { ["crowdstrike" "endpoint" "microsoft_defender_endpoint" "sentinel_one"] }
def sortField-completer [] { ["enrolled_at" "host_status" "last_checkin" "metadata.Endpoint.policy.applied.name" "metadata.Endpoint.policy.applied.status" "metadata.agent.version" "metadata.host.hostname" "metadata.host.ip" "metadata.host.os.name"] }
def sortDirection-completer [] { ["asc" "desc"] }
def sortField-completer-1 [] { ["createdAt" "createdBy" "fileSize" "name" "updatedAt" "updatedBy"] }
def fileType-completer [] { ["archive" "script"] }
def namespace-type-completer [] { ["agnostic" "single"] }
def type-completer-2 [] { ["detection" "endpoint" "endpoint_blocklists" "endpoint_events" "endpoint_host_isolation_exceptions" "endpoint_trusted_apps" "endpoint_trusted_devices" "rule_default"] }
def include-expired-exceptions-completer [] { ["false" "true"] }
def sortOrder-completer [] { ["asc" "desc"] }
def format-completer [] { ["legacy" "simplified"] }
def groupBy-completer [] { ["collector.group" "config.name"] }
def accountType-completer [] { ["organization-account" "single-account"] }
def cloudProvider-completer [] { ["aws" "azure" "gcp"] }
def type-completer-3 [] { ["logs" "metrics" "profiling" "synthetics" "traces"] }
def accept-completer [] { ["application/gzip; application/zip" "application/json"] }
def action-completer-2 [] { ["accept" "decline" "pending"] }
def dataStreamType-completer [] { ["logs" "metrics" "profiling" "synthetics" "traces"] }
def format-completer-1 [] { ["json" "yaml" "yml"] }
def preset-completer [] { ["balanced" "custom" "latency" "scale" "throughput"] }
def type-completer-4 [] { ["elasticsearch" "kafka" "logstash" "remote_elasticsearch"] }
def auth-type-completer [] { ["kerberos" "none" "ssl" "user_pass"] }
def compression-completer [] { ["gzip" "lz4" "none" "snappy"] }
def connection-type-completer [] { ["encryption" "plaintext"] }
def partition-completer [] { ["hash" "random" "round_robin"] }
def required-acks-completer [] { ["-1" "0" "1"] }
def type-completer-5 [] { ["elasticsearch"] }
def type-completer-6 [] { ["binary" "boolean" "byte" "date" "date_nanos" "date_range" "double" "double_range" "float" "float_range" "geo_point" "geo_shape" "half_float" "integer" "integer_range" "ip" "ip_range" "keyword" "long" "long_range" "shape" "short" "text"] }
def refresh-completer-1 [] { ["false" "true" "wait_for"] }
def associatedFilter-completer [] { ["all" "document_and_saved_object" "document_only" "orphan" "saved_object_only"] }
def schedule-type-completer [] { ["interval" "rrule"] }
def sort-field-completer-5 [] { ["allowed" "anonymized" "created_at" "field" "updated_at"] }
def category-completer [] { ["assistant" "insights"] }
def sort-field-completer-6 [] { ["created_at" "title" "updated_at"] }
def sort-field-completer-7 [] { ["created_at" "is_default" "title" "updated_at"] }
def sort-field-completer-8 [] { ["created_at" "is_default" "name" "updated_at"] }
def purpose-completer [] { ["any" "copySavedObjectsIntoSpace" "shareSavedObjectsIntoSpace"] }
def status-completer [] { ["disabled" "enabled"] }
def searchMode-completer [] { ["hybrid" "keyword" "semantic"] }
def status-completer-1 [] { ["active" "draft" "immutable"] }
def timelineType-completer [] { ["default" "template"] }
def isImmutable-completer [] { ["false" "true"] }
def only-user-favorite-completer [] { ["false" "true"] }
def timeline-type-completer [] { ["default" "template"] }
def sort-field-completer-9 [] { ["created" "description" "title" "updated"] }
def managed-completer [] { ["all" "managed" "unmanaged"] }
def collapse-completer [] { ["concurrencyGroupKey" "executedBy" "status" "triggeredBy"] }
def sortField-completer-2 [] { ["createdAt" "finishedAt"] }
def sortBy-completer [] { ["error_budget_consumed" "error_budget_remaining" "sli_value" "status"] }
def budgetingMethod-completer [] { ["occurrences" "timeslices"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions-connector-types get-actions-connector-types" } } | get name | first)
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

# Get connector types
#
# GET /api/actions/connector_types
# operationId: get-actions-connector-types
export def "actions-connector-types get-actions-connector-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feature-id: string # A filter to limit the retrieved connector types to those that support a specific feature (such as alerting or cases).
]: nothing -> table<allow_multiple_system_actions: bool, description: string, enabled: bool, enabled_in_config: bool, enabled_in_license: bool, id: string, is_deprecated: bool, is_experimental: bool, is_system_action_type: bool, minimum_license_required: string, name: string, source: string, sub_feature: string, supported_feature_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature_id" $feature_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/actions/connector_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Handle OAuth callback
#
# GET /api/actions/connector/_oauth_callback
# operationId: get-actions-connector-oauth-callback
export def "actions-connector-oauth-callback get-actions-connector-oauth-callback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # The authorization code returned by the OAuth provider.
  --state: string # The state parameter for CSRF protection.
  --qp-error: string # Error code if the authorization failed.
  --error-description: string # Human-readable error description.
  --session-state: string # Session state from the OAuth provider (e.g., Microsoft).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "error" $qp_error "scalar") (serialize-qp "error_description" $error_description "scalar") (serialize-qp "session_state" $session_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/actions/connector/_oauth_callback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Spaces method and path for this operation:**  <div><span class="operation-verb get">get</span>&nbsp;<span class="operation-path">/s/{space_id}/api/actions/connector/_oauth_callback_script</span></div>  Refer to [Spaces](https://www.elastic.co/docs/deploy-manage/manage-spaces) for more information.  Returns the OAuth callback script
#
# GET /api/actions/connector/_oauth_callback_script
# operationId: get-actions-connector-oauth-callback-script
export def "actions-connector-oauth-callback-script get-actions-connector-oauth-callback-script" [
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
  let full_url = (build-url $base "/api/actions/connector/_oauth_callback_script")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a connector
#
# DELETE /api/actions/connector/{id}
# operationId: delete-actions-connector-id
export def "actions-connector delete-actions-connector-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/actions/connector/($id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get connector information
#
# GET /api/actions/connector/{id}
# operationId: get-actions-connector-id
export def "actions-connector get-actions-connector-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, config: record, connector_type_id: string, id: string, is_connector_type_deprecated: bool, is_deprecated: bool, is_missing_secrets: bool, is_preconfigured: bool, is_system_action: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/actions/connector/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a connector
#
# POST /api/actions/connector/{id}
# operationId: post-actions-connector-id
export def "actions-connector post-actions-connector-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  connector_type_id: string # The type of connector.
  name: string # The display name for the connector.
  --config: any # The connector configuration details. (default: {})
  --secrets: any # default: {}
]: any -> record<auth_mode: string, config: record, connector_type_id: string, id: string, is_connector_type_deprecated: bool, is_deprecated: bool, is_missing_secrets: bool, is_preconfigured: bool, is_system_action: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/actions/connector/($id)")
  let body = {connector_type_id: $connector_type_id, name: $name, config: $config, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a connector
#
# PUT /api/actions/connector/{id}
# operationId: put-actions-connector-id
export def "actions-connector put-actions-connector-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  name: string # The display name for the connector.
  --config: any # The connector configuration details. (default: {})
  --secrets: any # default: {}
]: any -> record<auth_mode: string, config: record, connector_type_id: string, id: string, is_connector_type_deprecated: bool, is_deprecated: bool, is_missing_secrets: bool, is_preconfigured: bool, is_system_action: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/actions/connector/($id)")
  let body = {name: $name, config: $config, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a connector
#
# POST /api/actions/connector/{id}/_execute
# operationId: post-actions-connector-id-execute
export def "actions-connector-execute post-actions-connector-id-execute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  params: any
]: any -> record<auth_mode: string, config: record, connector_type_id: string, id: string, is_connector_type_deprecated: bool, is_deprecated: bool, is_missing_secrets: bool, is_preconfigured: bool, is_system_action: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/actions/connector/($id)/_execute")
  let body = {params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all connectors
#
# GET /api/actions/connectors
# operationId: get-actions-connectors
export def "actions-connectors get-actions-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<auth_mode: string, config: record, connector_type_id: string, id: string, is_connector_type_deprecated: bool, is_deprecated: bool, is_missing_secrets: bool, is_preconfigured: bool, is_system_action: bool, name: string, referenced_by_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/actions/connectors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send A2A task
#
# POST /api/agent_builder/a2a/{agentId}
# operationId: post-agent-builder-a2a-agentid
export def "agent-builder-a2a post-agent-builder-a2a-agentid" [
  agentId: string
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
  let full_url = (build-url $base $"/api/agent_builder/a2a/($agentId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get A2A agent card
#
# GET /api/agent_builder/a2a/{agentId}.json
# operationId: get-agent-builder-a2a-agentid.json
export def "agent-builder-a2a get-agent-builder-a2a-agentidjson" [
  agentId: string
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
  let full_url = (build-url $base $"/api/agent_builder/a2a/($agentId).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List agents
#
# GET /api/agent_builder/agents
# operationId: get-agent-builder-agents
export def "agent-builder-agents get-agent-builder-agents" [
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
  let full_url = (build-url $base "/api/agent_builder/agents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an agent
#
# POST /api/agent_builder/agents
# operationId: post-agent-builder-agents
# --configuration shape: {connector_ids?: list, enable_elastic_capabilities?: bool, instructions?: string, plugin_ids?: list, skill_ids?: list, tools: list, workflow_ids?: list}
export def "agent-builder-agents post-agent-builder-agents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --avatar-color: string # Optional hex color code for the agent avatar.
  --avatar-symbol: string # Optional symbol/initials for the agent avatar.
  configuration: record # Configuration settings for the agent. — shape: {connector_ids?: list, enable_elastic_capabilities?: bool, instructions?: string, plugin_ids?: list, skill_ids?: list, tools: list, workflow_ids?: list}
  description: string # Description of what the agent does.
  id: string # Unique identifier for the agent.
  --labels: list # Optional labels for categorizing and organizing agents.
  name: string # Display name for the agent.
  --visibility: string@visibility-completer # **Technical Preview; added in 9.4.0.** Optional visibility setting: `public` (any privileged user can read/write), `shared` (any privileged user can read, only owner can write), `private` (only owner can read/write).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/agents")
  let body = {avatar_color: $avatar_color, avatar_symbol: $avatar_symbol, configuration: $configuration, description: $description, id: $id, labels: $labels, name: $name, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent consumption data
#
# POST /api/agent_builder/agents/{agent_id}/consumption
# operationId: post-agent-builder-agents-agent-id-consumption
export def "agent-builder-agents-consumption post-agent-builder-agents-agent-id-consumption" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --has-warnings: oneof<nothing, bool> # Filter to conversations with or without high-token warnings.
  --search: string # Free-text search filter on conversation title.
  --search-after: list # Cursor for pagination. Pass the search_after value from the previous response.
  --size: float # Number of results per page. (default: 25)
  --sort-field: string@sort-field-completer # Field to sort results by. (default: updated_at)
  --sort-order: string@sort-order-completer # Sort direction. (default: desc)
  --usernames: list # Filter results to conversations by these usernames.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/agents/($agent_id)/consumption")
  let body = {has_warnings: $has_warnings, search: $search, search_after: $search_after, size: $size, sort_field: $sort_field, sort_order: $sort_order, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an agent
#
# DELETE /api/agent_builder/agents/{id}
# operationId: delete-agent-builder-agents-id
export def "agent-builder-agents delete-agent-builder-agents-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/agents/($id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an agent by ID
#
# GET /api/agent_builder/agents/{id}
# operationId: get-agent-builder-agents-id
export def "agent-builder-agents get-agent-builder-agents-id" [
  id: string
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
  let full_url = (build-url $base $"/api/agent_builder/agents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent
#
# PUT /api/agent_builder/agents/{id}
# operationId: put-agent-builder-agents-id
# --configuration shape: {connector_ids?: list, enable_elastic_capabilities?: bool, instructions?: string, plugin_ids?: list, skill_ids?: list, tools?: list, workflow_ids?: list}
export def "agent-builder-agents put-agent-builder-agents-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --avatar-color: string # Updated hex color code for the agent avatar.
  --avatar-symbol: string # Updated symbol/initials for the agent avatar.
  --configuration: record # Updated configuration settings for the agent. — shape: {connector_ids?: list, enable_elastic_capabilities?: bool, instructions?: string, plugin_ids?: list, skill_ids?: list, tools?: list, workflow_ids?: list}
  --description: string # Updated description of what the agent does.
  --labels: list # Updated labels for categorizing and organizing agents.
  --name: string # Updated display name for the agent.
  --visibility: string@visibility-completer # **Technical Preview; added in 9.4.0.** Updated visibility setting: `public` (any privileged user can read/write), `shared` (any privileged user can read, only owner can write), `private` (only owner can read/write).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/agents/($id)")
  let body = {avatar_color: $avatar_color, avatar_symbol: $avatar_symbol, configuration: $configuration, description: $description, labels: $labels, name: $name, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an agent's access control list
#
# GET /api/agent_builder/agents/{id}/acl
# operationId: get-agent-builder-agents-id-acl
export def "agent-builder-agents-acl get-agent-builder-agents-id-acl" [
  id: string
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
  let full_url = (build-url $base $"/api/agent_builder/agents/($id)/acl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent's access control list
#
# PUT /api/agent_builder/agents/{id}/acl
# operationId: put-agent-builder-agents-id-acl
# --entries item shape: {name: string, role: "user"|"editor"|"manager", type: "user"}
export def "agent-builder-agents-acl put-agent-builder-agents-id-acl" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  entries: list # Access control entries to apply to the agent. Each entry has a `type` (currently only `user` is supported; role-based grants are planned for a future release), a `name` (the principal username), and a `role`. Submitting this field replaces the existing ACL entirely; submit an empty array to clear all grants. — item shape: {name: string, role: "user"|"editor"|"manager", type: "user"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/agents/($id)/acl")
  let body = {entries: $entries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List conversations
#
# GET /api/agent_builder/conversations
# operationId: get-agent-builder-conversations
export def "agent-builder-conversations get-agent-builder-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # Optional agent ID to filter conversations by a specific agent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/agent_builder/conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete conversation by ID
#
# DELETE /api/agent_builder/conversations/{conversation_id}
# operationId: delete-agent-builder-conversations-conversation-id
export def "agent-builder-conversations delete-agent-builder-conversations-conversation-id" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation by ID
#
# GET /api/agent_builder/conversations/{conversation_id}
# operationId: get-agent-builder-conversations-conversation-id
export def "agent-builder-conversations get-agent-builder-conversations-conversation-id" [
  conversation_id: string
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
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List conversation attachments
#
# GET /api/agent_builder/conversations/{conversation_id}/attachments
# operationId: get-agent-builder-conversations-conversation-id-attachments
export def "agent-builder-conversations-attachments get-agent-builder-conversations-conversation-id-attachments" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deleted: oneof<nothing, bool> # Whether to include deleted attachments in the list.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_deleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create conversation attachment
#
# POST /api/agent_builder/conversations/{conversation_id}/attachments
# operationId: post-agent-builder-conversations-conversation-id-attachments
export def "agent-builder-conversations-attachments post-agent-builder-conversations-conversation-id-attachments" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --data: any # The attachment data/content. Required unless origin is provided. (nullable)
  --description: string # Human-readable description of the attachment.
  --hidden: oneof<nothing, bool> # Whether the attachment should be hidden from the user.
  --id: string # Optional custom ID for the attachment.
  --origin: string # Origin string (for example, saved object ID) for by-reference attachments. When provided without data, the content is resolved once at creation time.
  type: string # The type of the attachment (e.g., text, esql, visualization).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments")
  let body = {data: $data, description: $description, hidden: $hidden, id: $id, origin: $origin, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete conversation attachment
#
# DELETE /api/agent_builder/conversations/{conversation_id}/attachments/{attachment_id}
# operationId: delete-agent-builder-conversations-conversation-id-attachments-attachment-id
export def "agent-builder-conversations-attachments delete-agent-builder-conversations-conversation-id-attachments-attachment-id" [
  conversation_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permanent: oneof<nothing, bool> # If true, permanently removes the attachment (only for unreferenced attachments).
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permanent" $permanent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments/($attachment_id)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename attachment
#
# PATCH /api/agent_builder/conversations/{conversation_id}/attachments/{attachment_id}
# operationId: patch-agent-builder-conversations-conversation-id-attachments-attachment-id
export def "agent-builder-conversations-attachments patch-agent-builder-conversations-conversation-id-attachments-attachment-id" [
  conversation_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  description: string # The new description/name for the attachment.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments/($attachment_id)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update conversation attachment
#
# PUT /api/agent_builder/conversations/{conversation_id}/attachments/{attachment_id}
# operationId: put-agent-builder-conversations-conversation-id-attachments-attachment-id
export def "agent-builder-conversations-attachments put-agent-builder-conversations-conversation-id-attachments-attachment-id" [
  conversation_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --data: any # The new attachment data/content. (nullable)
  --description: string # Optional new description for the attachment.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments/($attachment_id)")
  let body = {data: $data, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore deleted attachment
#
# POST /api/agent_builder/conversations/{conversation_id}/attachments/{attachment_id}/_restore
# operationId: post-agent-builder-conversations-conversation-id-attachments-attachment-id-restore
export def "agent-builder-conversations-attachments-restore post-agent-builder-conversations-conversation-id-attachments-attachment-id-restore" [
  conversation_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments/($attachment_id)/_restore")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update attachment origin
#
# PUT /api/agent_builder/conversations/{conversation_id}/attachments/{attachment_id}/origin
# operationId: put-agent-builder-conversations-conversation-id-attachments-attachment-id-origin
export def "agent-builder-conversations-attachments-origin put-agent-builder-conversations-conversation-id-attachments-attachment-id-origin" [
  conversation_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  origin: string # The origin string (e.g., saved object ID for visualizations and dashboards).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments/($attachment_id)/origin")
  let body = {origin: $origin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check attachment staleness
#
# GET /api/agent_builder/conversations/{conversation_id}/attachments/stale
# operationId: get-agent-builder-conversations-conversation-id-attachments-stale
export def "agent-builder-conversations-attachments-stale get-agent-builder-conversations-conversation-id-attachments-stale" [
  conversation_id: string
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
  let full_url = (build-url $base $"/api/agent_builder/conversations/($conversation_id)/attachments/stale")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send chat message
#
# POST /api/agent_builder/converse
# operationId: post-agent-builder-converse
# --attachments item shape: {data?: record, description?: string, group_id?: string, hidden?: bool, id?: string, origin?: string, type: string}
# --browser_api_tools item shape: {description: string, id: string, schema: any}
# --capabilities shape: {visualizations?: bool}
# --configuration_overrides shape: {instructions?: string, tools?: list}
export def "agent-builder-converse post-agent-builder-converse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --execution-mode: string@execution-mode-completer # **Experimental; added in 9.4.0.** define how to execute the agent (local execution or via task_manager)
  --action: string@action-completer # The action to perform. "regenerate" re-executes the last round with the original input. Requires conversation_id.
  --agent-id: string # The ID of the agent to chat with. Defaults to the default Elastic AI agent. (default: elastic-ai-agent)
  --attachments: list # **Technical Preview; added in 9.3.0.** Optional attachments to send with the message. — item shape: {data?: record, description?: string, group_id?: string, hidden?: bool, id?: string, origin?: string, type: string}
  --browser-api-tools: list # Optional browser API tools to be registered as LLM tools with browser.* namespace. These tools execute on the client side. — item shape: {description: string, id: string, schema: any}
  --capabilities: record # Controls agent capabilities during conversation. Currently supports visualization rendering for tabular tool results. — shape: {visualizations?: bool}
  --configuration-overrides: record # Runtime configuration overrides. These override the stored agent configuration for this execution only. — shape: {instructions?: string, tools?: list}
  --connector-id: string # Optional connector ID for the agent to use for model routing. Mutually exclusive with `inference_id`; omit or use only one. (nullable)
  --conversation-id: string # Optional existing conversation ID to continue a previous conversation.
  --inference-id: string # Optional inference endpoint ID for model routing (public alias for the same internal identifier as `connector_id`). Mutually exclusive with `connector_id`. (nullable)
  --input: string # The user input message to send to the agent.
  --prompts: record # Use this field to respond to a confirmation or authorization prompt. Send an `allow` boolean to answer a confirmation prompt, or an `authorized` boolean to answer an authorization prompt.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/converse")
  let body = {_execution_mode: $execution_mode, action: $action, agent_id: $agent_id, attachments: $attachments, browser_api_tools: $browser_api_tools, capabilities: $capabilities, configuration_overrides: $configuration_overrides, connector_id: $connector_id, conversation_id: $conversation_id, inference_id: $inference_id, input: $input, prompts: $prompts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send chat message (streaming)
#
# POST /api/agent_builder/converse/async
# operationId: post-agent-builder-converse-async
# --attachments item shape: {data?: record, description?: string, group_id?: string, hidden?: bool, id?: string, origin?: string, type: string}
# --browser_api_tools item shape: {description: string, id: string, schema: any}
# --capabilities shape: {visualizations?: bool}
# --configuration_overrides shape: {instructions?: string, tools?: list}
export def "agent-builder-converse-async post-agent-builder-converse-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --execution-mode: string@execution-mode-completer # **Experimental; added in 9.4.0.** define how to execute the agent (local execution or via task_manager)
  --action: string@action-completer # The action to perform. "regenerate" re-executes the last round with the original input. Requires conversation_id.
  --agent-id: string # The ID of the agent to chat with. Defaults to the default Elastic AI agent. (default: elastic-ai-agent)
  --attachments: list # **Technical Preview; added in 9.3.0.** Optional attachments to send with the message. — item shape: {data?: record, description?: string, group_id?: string, hidden?: bool, id?: string, origin?: string, type: string}
  --browser-api-tools: list # Optional browser API tools to be registered as LLM tools with browser.* namespace. These tools execute on the client side. — item shape: {description: string, id: string, schema: any}
  --capabilities: record # Controls agent capabilities during conversation. Currently supports visualization rendering for tabular tool results. — shape: {visualizations?: bool}
  --configuration-overrides: record # Runtime configuration overrides. These override the stored agent configuration for this execution only. — shape: {instructions?: string, tools?: list}
  --connector-id: string # Optional connector ID for the agent to use for model routing. Mutually exclusive with `inference_id`; omit or use only one. (nullable)
  --conversation-id: string # Optional existing conversation ID to continue a previous conversation.
  --inference-id: string # Optional inference endpoint ID for model routing (public alias for the same internal identifier as `connector_id`). Mutually exclusive with `connector_id`. (nullable)
  --input: string # The user input message to send to the agent.
  --prompts: record # Use this field to respond to a confirmation or authorization prompt. Send an `allow` boolean to answer a confirmation prompt, or an `authorized` boolean to answer an authorization prompt.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/converse/async")
  let body = {_execution_mode: $execution_mode, action: $action, agent_id: $agent_id, attachments: $attachments, browser_api_tools: $browser_api_tools, capabilities: $capabilities, configuration_overrides: $configuration_overrides, connector_id: $connector_id, conversation_id: $conversation_id, inference_id: $inference_id, input: $input, prompts: $prompts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# MCP server
#
# POST /api/agent_builder/mcp
# operationId: post-agent-builder-mcp
export def "agent-builder-mcp post-agent-builder-mcp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Comma-separated list of namespaces to filter tools. Only tools matching the specified namespaces will be returned.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/agent_builder/mcp" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List plugins
#
# GET /api/agent_builder/plugins
# operationId: get-agent-builder-plugins
export def "agent-builder-plugins get-agent-builder-plugins" [
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
  let full_url = (build-url $base "/api/agent_builder/plugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a plugin
#
# DELETE /api/agent_builder/plugins/{pluginId}
# operationId: delete-agent-builder-plugins-pluginid
export def "agent-builder-plugins delete-agent-builder-plugins-pluginid" [
  pluginId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If true, removes the plugin skills from agents that use them and then deletes the plugin. If false and any agent uses the plugin skills, the request returns 409 Conflict with the list of agents. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/agent_builder/plugins/($pluginId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a plugin by id
#
# GET /api/agent_builder/plugins/{pluginId}
# operationId: get-agent-builder-plugins-pluginid
export def "agent-builder-plugins get-agent-builder-plugins-pluginid" [
  pluginId: string
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
  let full_url = (build-url $base $"/api/agent_builder/plugins/($pluginId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install a plugin
#
# POST /api/agent_builder/plugins/install
# operationId: post-agent-builder-plugins-install
export def "agent-builder-plugins-install post-agent-builder-plugins-install" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --plugin-name: string # Optional name override for the plugin. Defaults to the manifest name.
  --body-url: string # URL to install the plugin from (GitHub URL or direct zip URL).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/plugins/install")
  let body = {plugin_name: $plugin_name, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List skills
#
# GET /api/agent_builder/skills
# operationId: get-agent-builder-skills
export def "agent-builder-skills get-agent-builder-skills" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-plugins: oneof<nothing, bool> # Set to true to include skills from plugins. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_plugins" $include_plugins "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/agent_builder/skills" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a skill
#
# POST /api/agent_builder/skills
# operationId: post-agent-builder-skills
# --referenced_content item shape: {content: string, name: string, relativePath: string}
export def "agent-builder-skills post-agent-builder-skills" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  content: string # Skill instructions content (markdown).
  description: string # Description of what the skill does.
  id: string # Unique identifier for the skill.
  name: string # Human-readable name for the skill.
  --referenced-content: list # item shape: {content: string, name: string, relativePath: string}
  --tool-ids: list # Tool IDs from the tool registry that this skill references. (default: [])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/skills")
  let body = {content: $content, description: $description, id: $id, name: $name, referenced_content: $referenced_content, tool_ids: $tool_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a skill
#
# DELETE /api/agent_builder/skills/{skillId}
# operationId: delete-agent-builder-skills-skillid
export def "agent-builder-skills delete-agent-builder-skills-skillid" [
  skillId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If true, removes the skill from agents that use it and then deletes it. If false and any agent uses the skill, the request returns 409 Conflict with the list of agents. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/agent_builder/skills/($skillId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a skill by id
#
# GET /api/agent_builder/skills/{skillId}
# operationId: get-agent-builder-skills-skillid
export def "agent-builder-skills get-agent-builder-skills-skillid" [
  skillId: string
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
  let full_url = (build-url $base $"/api/agent_builder/skills/($skillId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a skill
#
# PUT /api/agent_builder/skills/{skillId}
# operationId: put-agent-builder-skills-skillid
# --referenced_content item shape: {content: string, name: string, relativePath: string}
export def "agent-builder-skills put-agent-builder-skills-skillid" [
  skillId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --content: string # Updated skill instructions content.
  --description: string # Updated description.
  --name: string # Updated name for the skill.
  --referenced-content: list # item shape: {content: string, name: string, relativePath: string}
  --tool-ids: list # Updated tool IDs from the tool registry.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/skills/($skillId)")
  let body = {content: $content, description: $description, name: $name, referenced_content: $referenced_content, tool_ids: $tool_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tools
#
# GET /api/agent_builder/tools
# operationId: get-agent-builder-tools
export def "agent-builder-tools get-agent-builder-tools" [
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
  let full_url = (build-url $base "/api/agent_builder/tools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tool
#
# POST /api/agent_builder/tools
# operationId: post-agent-builder-tools
export def "agent-builder-tools post-agent-builder-tools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  configuration: record # Tool-specific configuration parameters. See examples for details.
  --description: string # Description of what the tool does. (default: )
  id: string # Unique identifier for the tool.
  --tags: list # Optional tags for categorizing and organizing tools. (default: [])
  type: string@type-completer # The type of tool to create (e.g., esql, index_search).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/tools")
  let body = {configuration: $configuration, description: $description, id: $id, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a tool
#
# POST /api/agent_builder/tools/_execute
# operationId: post-agent-builder-tools-execute
export def "agent-builder-tools-execute post-agent-builder-tools-execute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --connector-id: string # Optional connector ID for tools that require external integrations.
  tool_id: string # The ID of the tool to execute.
  tool_params: record # Parameters to pass to the tool execution. See examples for details
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_builder/tools/_execute")
  let body = {connector_id: $connector_id, tool_id: $tool_id, tool_params: $tool_params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tool
#
# DELETE /api/agent_builder/tools/{toolId}
# operationId: delete-agent-builder-tools-toolid
export def "agent-builder-tools delete-agent-builder-tools-toolid" [
  toolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If true, removes the tool from agents that use it and then deletes it. If false and any agent uses the tool, the request returns 409 Conflict with the list of agents. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/agent_builder/tools/($toolId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a tool by id
#
# GET /api/agent_builder/tools/{toolId}
# operationId: get-agent-builder-tools-toolid
export def "agent-builder-tools get-agent-builder-tools-toolid" [
  toolId: string
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
  let full_url = (build-url $base $"/api/agent_builder/tools/($toolId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tool
#
# PUT /api/agent_builder/tools/{toolId}
# operationId: put-agent-builder-tools-toolid
export def "agent-builder-tools put-agent-builder-tools-toolid" [
  toolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --configuration: record # Updated tool-specific configuration parameters. See examples for details.
  --description: string # Updated description of what the tool does.
  --tags: list # Updated tags for categorizing and organizing tools.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_builder/tools/($toolId)")
  let body = {configuration: $configuration, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a rule
#
# DELETE /api/alerting/rule/{id}
# operationId: delete-alerting-rule-id
export def "alerting-rule delete-alerting-rule-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rule details
#
# GET /api/alerting/rule/{id}
# operationId: get-alerting-rule-id
export def "alerting-rule get-alerting-rule-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<actions: table<alerts_filter: record, connector_type_id: string, frequency: record, group: string, id: string, params: record, use_alert_data_for_template: bool, uuid: string>, alert_delay: record<active: float>, api_key_created_by_user: bool, api_key_owner: string, artifacts: record<dashboards: list<record>, investigation_guide: record<blob: string>>, consumer: string, created_at: string, created_by: string, enabled: bool, execution_status: record<error: record<message: string, reason: string>, last_duration: float, last_execution_date: string, status: string, warning: record<message: string, reason: string>>, flapping: record<enabled: bool, look_back_window: float, status_change_threshold: float>, id: string, last_run: record<alerts_count: record<active: float, ignored: float, new: float, recovered: float>, outcome: string, outcome_msg: list<string>, outcome_order: float, warning: string>, mapped_params: record, mute_all: bool, muted_alert_ids: list<string>, name: string, next_run: string, notify_when: string, params: record, revision: float, rule_type_id: string, running: bool, schedule: record<interval: string>, scheduled_task_id: string, tags: list<string>, throttle: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a rule
#
# POST /api/alerting/rule/{id}
# operationId: post-alerting-rule-id
# --actions item shape: {alerts_filter?: record, frequency?: record, group?: string, id: string, params?: record, use_alert_data_for_template?: bool, uuid?: string}
# --alert_delay shape: {active: float}
# --artifacts shape: {dashboards?: list, investigation_guide?: record}
# --schedule shape: {interval: string}
export def "alerting-rule post-alerting-rule-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --actions: list # default: [] — item shape: {alerts_filter?: record, frequency?: record, group?: string, id: string, params?: record, use_alert_data_for_template?: bool, uuid?: string}
  --alert-delay: record # Indicates that an alert occurs only when the specified number of consecutive runs met the rule conditions. — shape: {active: float}
  --artifacts: record # shape: {dashboards?: list, investigation_guide?: record}
  --consumer: string # The name of the application or feature that owns the rule. For example: `alerts`, `apm`, `discover`, `infrastructure`, `logs`, `metrics`, `ml`, `monitoring`, `securitySolution`, `siem`, `stackAlerts`, or `uptime`.
  --enabled: oneof<nothing, bool> # Indicates whether you want the rule to run on an interval basis after it is created. (default: true)
  --flapping: any # nullable
  --name: string # The name of the rule. While this name does not have to be unique, a distinctive name can help you identify a rule.
  --notify-when: string@notify-when-completer # Indicates how frequently rule actions are triggered. Valid values include: `onActionGroupChange`: Actions run when the alert status changes; `onActiveAlert`: Actions run when the alert becomes active and at each check interval while the rule conditions are met; `onThrottleInterval`: Actions run when the alert becomes active and at the interval specified in the throttle property while the rule conditions are met. You cannot specify `notify_when` at both the rule and action level. The recommended approach is to set it for each action individually. If you set `notify_when` at the rule level and then edit the rule, it will automatically be converted to action-specific values. (nullable)
  --params: record # The parameters for the rule. (default: {})
  --rule-type-id: string # The rule type identifier.
  --schedule: record # The check interval, which specifies how frequently the rule conditions are checked. — shape: {interval: string}
  --tags: list # The tags for the rule. (default: [])
  --throttle: string # Use the `throttle` property in the action `frequency` object instead. The throttle interval, which defines how frequently rule actions are triggered. You cannot specify the throttle interval at both the rule and action level. If you set the throttle interval at the rule level and then edit the rule, it will automatically be converted to action-specific values. (nullable)
]: any -> record<actions: table<alerts_filter: record, connector_type_id: string, frequency: record, group: string, id: string, params: record, use_alert_data_for_template: bool, uuid: string>, alert_delay: record<active: float>, api_key_created_by_user: bool, api_key_owner: string, artifacts: record<dashboards: list<record>, investigation_guide: record<blob: string>>, consumer: string, created_at: string, created_by: string, enabled: bool, execution_status: record<error: record<message: string, reason: string>, last_duration: float, last_execution_date: string, status: string, warning: record<message: string, reason: string>>, flapping: record<enabled: bool, look_back_window: float, status_change_threshold: float>, id: string, last_run: record<alerts_count: record<active: float, ignored: float, new: float, recovered: float>, outcome: string, outcome_msg: list<string>, outcome_order: float, warning: string>, mapped_params: record, mute_all: bool, muted_alert_ids: list<string>, name: string, next_run: string, notify_when: string, params: record, revision: float, rule_type_id: string, running: bool, schedule: record<interval: string>, scheduled_task_id: string, tags: list<string>, throttle: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)")
  let body = {actions: $actions, alert_delay: $alert_delay, artifacts: $artifacts, consumer: $consumer, enabled: $enabled, flapping: $flapping, name: $name, notify_when: $notify_when, params: $params, rule_type_id: $rule_type_id, schedule: $schedule, tags: $tags, throttle: $throttle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a rule
#
# PUT /api/alerting/rule/{id}
# operationId: put-alerting-rule-id
# --actions item shape: {alerts_filter?: record, frequency?: record, group?: string, id: string, params?: record, use_alert_data_for_template?: bool, uuid?: string}
# --alert_delay shape: {active: float}
# --artifacts shape: {dashboards?: list, investigation_guide?: record}
# --schedule shape: {interval: string}
export def "alerting-rule put-alerting-rule-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --actions: list # default: [] — item shape: {alerts_filter?: record, frequency?: record, group?: string, id: string, params?: record, use_alert_data_for_template?: bool, uuid?: string}
  --alert-delay: record # Indicates that an alert occurs only when the specified number of consecutive runs met the rule conditions. — shape: {active: float}
  --artifacts: record # shape: {dashboards?: list, investigation_guide?: record}
  --flapping: any # nullable
  name: string # The name of the rule. While this name does not have to be unique, a distinctive name can help you identify a rule.
  --notify-when: string@notify-when-completer # Indicates how frequently rule actions are triggered. Valid values include: `onActionGroupChange`: Actions run when the alert status changes; `onActiveAlert`: Actions run when the alert becomes active and at each check interval while the rule conditions are met; `onThrottleInterval`: Actions run when the alert becomes active and at the interval specified in the throttle property while the rule conditions are met. You cannot specify `notify_when` at both the rule and action level. The recommended approach is to set it for each action individually. If you set `notify_when` at the rule level and then edit the rule, it will automatically be converted to action-specific values. (nullable)
  --params: record # The parameters for the rule. (default: {})
  schedule: record # shape: {interval: string}
  --tags: list # default: []
  --throttle: string # Use the `throttle` property in the action `frequency` object instead. The throttle interval, which defines how frequently rule actions are triggered. You cannot specify the throttle interval at both the rule and action level. If you set the throttle interval at the rule level and then edit the rule, it will automatically be converted to action-specific values. (nullable)
]: any -> record<actions: table<alerts_filter: record, connector_type_id: string, frequency: record, group: string, id: string, params: record, use_alert_data_for_template: bool, uuid: string>, alert_delay: record<active: float>, api_key_created_by_user: bool, api_key_owner: string, artifacts: record<dashboards: list<record>, investigation_guide: record<blob: string>>, consumer: string, created_at: string, created_by: string, enabled: bool, execution_status: record<error: record<message: string, reason: string>, last_duration: float, last_execution_date: string, status: string, warning: record<message: string, reason: string>>, flapping: record<enabled: bool, look_back_window: float, status_change_threshold: float>, id: string, last_run: record<alerts_count: record<active: float, ignored: float, new: float, recovered: float>, outcome: string, outcome_msg: list<string>, outcome_order: float, warning: string>, mapped_params: record, mute_all: bool, muted_alert_ids: list<string>, name: string, next_run: string, notify_when: string, params: record, revision: float, rule_type_id: string, running: bool, schedule: record<interval: string>, scheduled_task_id: string, tags: list<string>, throttle: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)")
  let body = {actions: $actions, alert_delay: $alert_delay, artifacts: $artifacts, flapping: $flapping, name: $name, notify_when: $notify_when, params: $params, schedule: $schedule, tags: $tags, throttle: $throttle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable a rule
#
# POST /api/alerting/rule/{id}/_disable
# operationId: post-alerting-rule-id-disable
export def "alerting-rule-disable post-alerting-rule-id-disable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --untrack: oneof<nothing, bool> # Defines whether this rule's alerts should be untracked.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)/_disable")
  let body = {untrack: $untrack} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable a rule
#
# POST /api/alerting/rule/{id}/_enable
# operationId: post-alerting-rule-id-enable
export def "alerting-rule-enable post-alerting-rule-id-enable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)/_enable")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mute all alerts
#
# POST /api/alerting/rule/{id}/_mute_all
# operationId: post-alerting-rule-id-mute-all
export def "alerting-rule-mute-all post-alerting-rule-id-mute-all" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)/_mute_all")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmute all alerts
#
# POST /api/alerting/rule/{id}/_unmute_all
# operationId: post-alerting-rule-id-unmute-all
export def "alerting-rule-unmute-all post-alerting-rule-id-unmute-all" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)/_unmute_all")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the API key for a rule
#
# POST /api/alerting/rule/{id}/_update_api_key
# operationId: post-alerting-rule-id-update-api-key
export def "alerting-rule-update-api-key post-alerting-rule-id-update-api-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)/_update_api_key")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Elasticsearch query for a rule
#
# GET /api/alerting/rule/{id}/query_inspector
# operationId: get-alerting-rule-id-query-inspector
export def "alerting-rule-query-inspector get-alerting-rule-id-query-inspector" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mode: string@mode-completer # The inspection mode. Use "build" to return only the query, or "execute" to run the query and include the response. (default: build)
  --alert-id: string # The alert document ID. When provided, the query inspector uses the evaluation time range from the alert instead of the current time.
]: nothing -> record<queries: table<index: string, label: string, request: record, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "alert_id" $alert_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/alerting/rule/($id)/query_inspector" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a snooze for the rule
#
# POST /api/alerting/rule/{id}/snooze_schedule
# operationId: post-alerting-rule-id-snooze-schedule
# --schedule shape: {custom?: record}
export def "alerting-rule-snooze-schedule post-alerting-rule-id-snooze-schedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  schedule: record # shape: {custom?: record}
]: any -> record<body: record<schedule: record<custom: record, id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($id)/snooze_schedule")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mute an alert
#
# POST /api/alerting/rule/{rule_id}/alert/{alert_id}/_mute
# operationId: post-alerting-rule-rule-id-alert-alert-id-mute
export def "alerting-rule-alert-mute post-alerting-rule-rule-id-alert-alert-id-mute" [
  rule_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validate-alerts-existence: oneof<nothing, bool> # Whether to validate the existence of the alert.
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate_alerts_existence" $validate_alerts_existence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/alerting/rule/($rule_id)/alert/($alert_id)/_mute" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmute an alert
#
# POST /api/alerting/rule/{rule_id}/alert/{alert_id}/_unmute
# operationId: post-alerting-rule-rule-id-alert-alert-id-unmute
export def "alerting-rule-alert-unmute post-alerting-rule-rule-id-alert-alert-id-unmute" [
  rule_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($rule_id)/alert/($alert_id)/_unmute")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a snooze schedule for a rule
#
# DELETE /api/alerting/rule/{ruleId}/snooze_schedule/{scheduleId}
# operationId: delete-alerting-rule-ruleid-snooze-schedule-scheduleid
export def "alerting-rule-snooze-schedule delete-alerting-rule-ruleid-snooze-schedule-scheduleid" [
  ruleId: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rule/($ruleId)/snooze_schedule/($scheduleId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about rules
#
# GET /api/alerting/rules/_find
# operationId: get-alerting-rules-find
export def "alerting-rules-find get-alerting-rules-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: float # The number of rules to return per page. (default: 10)
  --page: float # The page number to return. (default: 1)
  --search: string # An Elasticsearch simple_query_string query that filters the objects in the response.
  --default-search-operator: string@default-search-operator-completer # The default operator to use for the simple_query_string. (default: OR)
  --search-fields: list # The fields to perform the simple_query_string parsed query against.
  --sort-field: string # Determines which field is used to sort the results. The field must exist in the `attributes` key of the response.
  --sort-order: string@sort-order-completer # Determines the sort order.
  --has-reference: record # Filters the rules that have a relation with the reference objects with a specific type and identifier. (nullable)
  --qp-fields: list # The fields to return in the `attributes` key of the response.
  --filter: string # A KQL string that you filter with an attribute from your saved object. It should look like `savedObjectType.attributes.title: "myTitle"`. However, if you used a direct attribute of a saved object, such as `updatedAt`, you must define your filter, for example, `savedObjectType.updatedAt > 2018-12-22`.
  --filter-consumers: list
]: nothing -> record<data: table<actions: list, alert_delay: record, api_key_created_by_user: bool, api_key_owner: string, artifacts: record, consumer: string, created_at: string, created_by: string, enabled: bool, execution_status: record, flapping: record, id: string, last_run: record, mapped_params: record, mute_all: bool, muted_alert_ids: list, name: string, next_run: string, notify_when: string, params: record, revision: float, rule_type_id: string, running: bool, schedule: record, scheduled_task_id: string, tags: list, throttle: string, updated_at: string, updated_by: string>, page: float, per_page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "default_search_operator" $default_search_operator "scalar") (serialize-qp "search_fields" $search_fields "multi") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "has_reference" $has_reference "multi") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_consumers" $filter_consumers "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alerting/rules/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find backfills for rules
#
# POST /api/alerting/rules/backfill/_find
# operationId: post-alerting-rules-backfill-find
export def "alerting-rules-backfill-find post-alerting-rules-backfill-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end: string # The end date for filtering backfills.
  --page: float # The page number to return. (default: 1)
  --per-page: float # The number of backfills to return per page. (default: 10)
  --rule-ids: string # A comma-separated list of rule identifiers.
  --initiator: string@initiator-completer # The initiator of the backfill, either `user` for manual backfills or `system` for automatic gap fills.
  --start: string # The start date for filtering backfills.
  --sort-field: string@sort-field-completer-1 # The field to sort backfills by.
  --sort-order: string@sort-order-completer # The sort order.
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<data: table<created_at: string, duration: string, enabled: bool, end: string, id: string, initiator: string, initiator_id: string, rule: record, schedule: list, space_id: string, start: string, status: string>, page: float, per_page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "end" $end "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "rule_ids" $rule_ids "scalar") (serialize-qp "initiator" $initiator "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alerting/rules/backfill/_find" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a backfill for rules
#
# POST /api/alerting/rules/backfill/_schedule
# operationId: post-alerting-rules-backfill-schedule
export def "alerting-rules-backfill-schedule post-alerting-rules-backfill-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/alerting/rules/backfill/_schedule")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a backfill by ID
#
# DELETE /api/alerting/rules/backfill/{id}
# operationId: delete-alerting-rules-backfill-id
export def "alerting-rules-backfill delete-alerting-rules-backfill-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rules/backfill/($id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a backfill by ID
#
# GET /api/alerting/rules/backfill/{id}
# operationId: get-alerting-rules-backfill-id
export def "alerting-rules-backfill get-alerting-rules-backfill-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, duration: string, enabled: bool, end: string, id: string, initiator: string, initiator_id: string, rule: record<api_key_created_by_user: bool, api_key_owner: string, consumer: string, created_at: string, created_by: string, enabled: bool, id: string, name: string, params: record, revision: float, rule_type_id: string, schedule: record<interval: string>, tags: list<string>, updated_at: string, updated_by: string>, schedule: table<interval: string, run_at: string, status: string>, space_id: string, start: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alerting/rules/backfill/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an APM agent key
#
# POST /api/apm/agent_keys
# operationId: createAgentKey
export def "apm-agent-keys createAgentKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  name: string # The name of the APM agent key.
  privileges: list # The APM agent key privileges. It can take one or more of the following values: * `event:write`, which is required for ingesting APM agent events. * `config_agent:read`, which is required for APM agents to read agent configuration remotely.
]: any -> record<agentKey: record<api_key: string, encoded: string, expiration: int, id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/apm/agent_keys")
  let body = {name: $name, privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"elastic-api-version": $elastic_api_version, "kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save APM server schema
#
# POST /api/apm/fleet/apm_server_schema
# DEPRECATED
# operationId: saveApmServerSchema
@deprecated
export def "apm-fleet-apm-server-schema saveApmServerSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --schema: record # Schema object (e.g. {foo: bar})
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/apm/fleet/apm_server_schema")
  let body = {schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"elastic-api-version": $elastic_api_version, "kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a service annotation
#
# POST /api/apm/services/{serviceName}/annotation
# operationId: createAnnotation
# --service shape: {environment?: string, version: string}
export def "apm-services-annotation createAnnotation" [
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  timestamp: string # The date and time of the annotation. It must be in ISO 8601 format.
  --message: string # The message displayed in the annotation. It defaults to `service.version`.
  service: record # The service that identifies the configuration to create or update. — shape: {environment?: string, version: string}
  --tags: list # Tags are used by the Applications UI to distinguish APM annotations from other annotations. Tags may have additional functionality in future releases. It defaults to `[apm]`. While you can add additional tags, you cannot remove the `apm` tag.
]: any -> record<_id: string, _index: string, _source: record<_timestamp: string, annotation: record<title: string, type: string>, event: record<created: string>, message: string, service: record<environment: string, name: string, version: string>, tags: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/apm/services/($serviceName)/annotation")
  let body = {@timestamp: $timestamp, message: $message, service: $service, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"elastic-api-version": $elastic_api_version, "kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for annotations
#
# GET /api/apm/services/{serviceName}/annotation/search
# operationId: getAnnotation
export def "apm-services-annotation-search get" [
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: string # The environment to filter annotations by
  --start: string # The start date for the search (format: date-time, e.g. 2024-01-01T00:00:00.000Z)
  --end: string # The end date for the search (format: date-time, e.g. 2024-01-31T23:59:59.999Z)
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
]: nothing -> record<annotations: table<_timestamp: float, id: string, text: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/apm/services/($serviceName)/annotation/search" $qp)
  let extra_headers = {"elastic-api-version": $elastic_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete agent configuration
#
# DELETE /api/apm/settings/agent-configuration
# operationId: deleteAgentConfiguration
# --service shape: {environment?: string, name?: string}
export def "apm-settings-agent-configuration delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  service: record # Service — shape: {environment?: string, name?: string}
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/apm/settings/agent-configuration")
  let body = {service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"elastic-api-version": $elastic_api_version, "kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of agent configurations
#
# GET /api/apm/settings/agent-configuration
# operationId: getAgentConfigurations
export def "apm-settings-agent-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
]: nothing -> record<configurations: table<_timestamp: float, agent_name: string, applied_by_agent: bool, etag: string, service: record, settings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/apm/settings/agent-configuration")
  let extra_headers = {"elastic-api-version": $elastic_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update agent configuration
#
# PUT /api/apm/settings/agent-configuration
# operationId: createUpdateAgentConfiguration
# --service shape: {environment?: string, name?: string}
export def "apm-settings-agent-configuration createUpdateAgentConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: oneof<nothing, bool> # If the config exists ?overwrite=true is required
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --agent-name: string # The agent name is used by the UI to determine which settings to display.
  service: record # Service — shape: {environment?: string, name?: string}
  settings: record # Agent configuration settings
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overwrite" $overwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/apm/settings/agent-configuration" $qp)
  let body = {agent_name: $agent_name, service: $service, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"elastic-api-version": $elastic_api_version, "kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent name for service
#
# GET /api/apm/settings/agent-configuration/agent_name
# operationId: getAgentNameForService
export def "apm-settings-agent-configuration-agent-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --serviceName: string # The name of the service (e.g. node)
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
]: nothing -> record<agentName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceName" $serviceName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/apm/settings/agent-configuration/agent_name" $qp)
  let extra_headers = {"elastic-api-version": $elastic_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environments for service
#
# GET /api/apm/settings/agent-configuration/environments
# operationId: getEnvironmentsForService
export def "apm-settings-agent-configuration-environments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --serviceName: string # The name of the service. If omitted, environments across all services are returned. (e.g. opbeans-node)
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
]: nothing -> record<environments: table<alreadyConfigured: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceName" $serviceName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/apm/settings/agent-configuration/environments" $qp)
  let extra_headers = {"elastic-api-version": $elastic_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup single agent configuration
#
# POST /api/apm/settings/agent-configuration/search
# DEPRECATED
# operationId: searchSingleConfiguration
# --service shape: {environment?: string, name?: string}
@deprecated
export def "apm-settings-agent-configuration-search searchSingleConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body-error: string # If provided, the agent configuration will be marked as error and `applied_by_agent` will be set to `false`. This is useful for cases where the agent configuration was not applied successfully.
  --etag: string # If etags match then `applied_by_agent` field will be set to `true` (e.g. 0bc3b5ebf18fba8163fe4c96f491e3767a358f85)
  --mark-as-applied-by-agent: oneof<nothing, bool> # `markAsAppliedByAgent=true` means "force setting it to true regardless of etag". This is needed for Jaeger agent that doesn't have etags
  service: record # Service — shape: {environment?: string, name?: string}
]: any -> record<_id: string, _index: string, _score: float, _source: record<_timestamp: float, agent_name: string, applied_by_agent: bool, etag: string, service: record<environment: string, name: string>, settings: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/apm/settings/agent-configuration/search")
  let body = {error: $body_error, etag: $etag, mark_as_applied_by_agent: $mark_as_applied_by_agent, service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"elastic-api-version": $elastic_api_version, "kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get single agent configuration
#
# GET /api/apm/settings/agent-configuration/view
# operationId: getSingleAgentConfiguration
export def "apm-settings-agent-configuration-view get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Service name (e.g. node)
  --environment: string # Service environment (e.g. prod)
  --elastic-api-version: string@elastic-api-version-completer # The version of the API to use
]: nothing -> record<id: string, _timestamp: float, agent_name: string, applied_by_agent: bool, etag: string, service: record<environment: string, name: string>, settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/apm/settings/agent-configuration/view" $qp)
  let extra_headers = {"elastic-api-version": $elastic_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an asset criticality record
#
# DELETE /api/asset_criticality
# operationId: DeleteAssetCriticalityRecord
export def "asset-criticality DeleteAssetCriticalityRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id-value: string # The ID value of the asset. (e.g. my_host)
  --id-field: string@id-field-completer # The field representing the ID. (e.g. host.name)
  --refresh: string@refresh-completer # If 'wait_for' the request will wait for the index refresh.
]: nothing -> record<deleted: bool, record: record<asset: record<criticality: string>, entity: record<asset: record, id: string>, host: record<asset: record, name: string>, service: record<asset: record, name: string>, user: record<asset: record, name: string>, _timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id_value" $id_value "scalar") (serialize-qp "id_field" $id_field "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/asset_criticality" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an asset criticality record
#
# GET /api/asset_criticality
# operationId: GetAssetCriticalityRecord
export def "asset-criticality GetAssetCriticalityRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id-value: string # The ID value of the asset. (e.g. my_host)
  --id-field: string@id-field-completer # The field representing the ID. (e.g. host.name)
]: nothing -> record<asset: record<criticality: string>, entity: record<asset: record<criticality: string>, id: string>, host: record<asset: record<criticality: string>, name: string>, service: record<asset: record<criticality: string>, name: string>, user: record<asset: record<criticality: string>, name: string>, _timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id_value" $id_value "scalar") (serialize-qp "id_field" $id_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/asset_criticality" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert an asset criticality record
#
# POST /api/asset_criticality
# operationId: CreateAssetCriticalityRecord
export def "asset-criticality CreateAssetCriticalityRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refresh: string@refresh-completer # If 'wait_for' the request will wait for the index refresh.
]: any -> record<asset: record<criticality: string>, entity: record<asset: record<criticality: string>, id: string>, host: record<asset: record<criticality: string>, name: string>, service: record<asset: record<criticality: string>, name: string>, user: record<asset: record<criticality: string>, name: string>, _timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/asset_criticality")
  let body = {refresh: $refresh} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk upsert asset criticality records
#
# POST /api/asset_criticality/bulk
# operationId: BulkUpsertAssetCriticalityRecords
# --records item shape: {id_field: "host.name"|"user.name"|"service.name"|"entity.id", id_value: string, criticality_level: "low_impact"|"medium_impact"|"high_impact"|"extreme_impact"|"unassigned"}
export def "asset-criticality-bulk BulkUpsertAssetCriticalityRecords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # item shape: {id_field: "host.name"|"user.name"|"service.name"|"entity.id", id_value: string, criticality_level: "low_impact"|"medium_impact"|"high_impact"|"extreme_impact"|"unassigned"}
]: any -> record<errors: table<index: int, message: string>, stats: record<failed: int, successful: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/asset_criticality/bulk")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List asset criticality records
#
# GET /api/asset_criticality/list
# operationId: FindAssetCriticalityRecords
export def "asset-criticality-list FindAssetCriticalityRecords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-field: string@sort-field-completer-2 # The field to sort by.
  --sort-direction: string@sort-direction-completer # The order to sort by.
  --page: int # The page number to return.
  --per-page: int # The number of records to return per page.
  --kuery: string # The kuery to filter by.
]: nothing -> record<page: int, per_page: int, records: table<asset: record, entity: record, host: record, service: record, user: record, _timestamp: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "kuery" $kuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/asset_criticality/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update Attack discoveries
#
# POST /api/attack_discovery/_bulk
# operationId: PostAttackDiscoveryBulk
# --update shape: {enable_field_rendering?: bool, ids: list, kibana_alert_workflow_status?: "open"|"acknowledged"|"closed", visibility?: "not_shared"|"shared", with_replacements?: bool}
export def "attack-discovery-bulk PostAttackDiscoveryBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  update: record # Configuration object containing all parameters for the bulk update operation — shape: {enable_field_rendering?: bool, ids: list, kibana_alert_workflow_status?: "open"|"acknowledged"|"closed", visibility?: "not_shared"|"shared", with_replacements?: bool}
]: any -> record<data: table<alert_ids: list, alert_rule_uuid: string, alert_start: string, alert_updated_at: string, alert_updated_by_user_id: string, alert_updated_by_user_name: string, alert_workflow_status: string, alert_workflow_status_updated_at: string, assignees: list, connector_id: string, connector_name: string, details_markdown: string, entity_summary_markdown: string, generation_uuid: string, id: string, index: string, mitre_attack_tactics: list, replacements: record, risk_score: int, summary_markdown: string, tags: list, timestamp: string, title: string, user_id: string, user_name: string, users: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/attack_discovery/_bulk")
  let body = {update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Attack discoveries that match the search criteria
#
# GET /api/attack_discovery/_find
# operationId: AttackDiscoveryFind
export def "attack-discovery-find AttackDiscoveryFind" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alert-ids: list # Filter results to Attack discoveries that include any of the provided alert IDs
  --connector-names: list # Filter results to Attack discoveries created by any of the provided human readable connector names. Note that values must match the human readable `connector_name` property of an Attack discovery, e.g. "GPT-5 Chat", which are distinct from `connector_id` values used to generate Attack discoveries.
  --enable-field-rendering: oneof<nothing, bool> # Enables a markdown syntax used to render pivot fields, for example `{{ user.name james }}`. When disabled, the same example would be rendered as `james`. This is primarily used for Attack Discovery views within Kibana. Defaults to `false`. (default: false, e.g. false)
  --end: string # End of the time range for the search. Accepts absolute timestamps (ISO 8601) or relative date math (e.g. "now", "now-24h"). (e.g. now)
  --ids: list # Filter results to the Attack discoveries with the specified IDs
  --include-unique-alert-ids: oneof<nothing, bool> # If `true`, the response will include `unique_alert_ids` and `unique_alert_ids_count` aggregated across the matched Attack discoveries (e.g. false)
  --page: int # Page number to return (used for pagination). Defaults to 1. (default: 1, e.g. 1)
  --per-page: int # Number of Attack discoveries to return per page (used for pagination). Defaults to 10. (default: 10, e.g. 10)
  --search: string # Free-text search query applied to relevant text fields of Attack discoveries (title, description, tags, etc.) (e.g. )
  --shared: oneof<nothing, bool> # Whether to filter by shared visibility. If omitted, both shared and privately visible Attack discoveries are returned. Use `true` to return only shared discoveries, `false` to return only those visible to the current user. Mutually exclusive with `include_all_authors`.
  --include-all-authors: oneof<nothing, bool> # If `true`, the response will include all attack discoveries matching other criteria regardless of who created them. Mutually exclusive with `shared`.
  --scheduled: oneof<nothing, bool> # Whether to filter by scheduled or ad-hoc attack discoveries. If omitted, both types of attack discoveries are returned. Use `true` to return only scheduled discoveries or `false` to return only ad-hoc discoveries.
  --sort-field: string@sort-field-completer-3 # Field used to sort results. See `AttackDiscoveryFindSortField` for allowed values. (e.g. @timestamp)
  --sort-order: string@sort-order-completer # Sort order direction `asc` for ascending or `desc` for descending. Defaults to `desc`. (e.g. asc)
  --start: string # Start of the time range for the search. Accepts absolute timestamps (ISO 8601) or relative date math (e.g. "now-7d"). (e.g. now-24h)
  --status: list # Filter by alert workflow status. Provide one or more of the allowed workflow states. (e.g. [open, acknowledged])
  --with-replacements: oneof<nothing, bool> # When true, return the created Attack discoveries with text replacements applied to the detailsMarkdown, entitySummaryMarkdown, summaryMarkdown, and title fields. Defaults to `true`. (default: true, e.g. true)
]: nothing -> record<connector_names: list<string>, data: table<alert_ids: list, alert_rule_uuid: string, alert_start: string, alert_updated_at: string, alert_updated_by_user_id: string, alert_updated_by_user_name: string, alert_workflow_status: string, alert_workflow_status_updated_at: string, assignees: list, connector_id: string, connector_name: string, details_markdown: string, entity_summary_markdown: string, generation_uuid: string, id: string, index: string, mitre_attack_tactics: list, replacements: record, risk_score: int, summary_markdown: string, tags: list, timestamp: string, title: string, user_id: string, user_name: string, users: list>, page: int, per_page: int, total: int, unique_alert_ids: list<string>, unique_alert_ids_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alert_ids" $alert_ids "multi") (serialize-qp "connector_names" $connector_names "multi") (serialize-qp "enable_field_rendering" $enable_field_rendering "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "ids" $ids "multi") (serialize-qp "include_unique_alert_ids" $include_unique_alert_ids "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "shared" $shared "scalar") (serialize-qp "include_all_authors" $include_all_authors "scalar") (serialize-qp "scheduled" $scheduled "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "status" $status "multi") (serialize-qp "with_replacements" $with_replacements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/attack_discovery/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate attack discoveries from alerts
#
# POST /api/attack_discovery/_generate
# operationId: PostAttackDiscoveryGenerate
# --anonymizationFields item shape: {allowed?: bool, anonymized?: bool, createdAt?: string, createdBy?: string, field: string, id: string, namespace?: string, timestamp?: string, updatedAt?: string, updatedBy?: string}
# --apiConfig shape: {actionTypeId: string, connectorId: string, defaultSystemPromptId?: string, model?: string, provider?: "OpenAI"|"Azure OpenAI"|"Other"}
export def "attack-discovery-generate PostAttackDiscoveryGenerate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alertsIndexPattern: string # The (space specific) index pattern that contains the alerts to use as context for the attack discovery. Example: .alerts-security.alerts-default
  anonymizationFields: list # The list of fields, and whether or not they are anonymized, allowed to be sent to LLMs. Consider using the output of the `/api/security_ai_assistant/anonymization_fields/_find` API (for a specific Kibana space) to provide this value. — item shape: {allowed?: bool, anonymized?: bool, createdAt?: string, createdBy?: string, field: string, id: string, namespace?: string, timestamp?: string, updatedAt?: string, updatedBy?: string}
  apiConfig: record # shape: {actionTypeId: string, connectorId: string, defaultSystemPromptId?: string, model?: string, provider?: "OpenAI"|"Azure OpenAI"|"Other"}
  --connectorName: string
  --end: string
  --filter: record # An Elasticsearch-style query DSL object used to filter alerts. For example: ```json {   "filter": {     "bool": {       "must": [],       "filter": [         {           "bool": {             "should": [               {                 "term": {                   "user.name": { "value": "james" }                 }               }             ],             "minimum_should_match": 1           }         }       ],       "should": [],       "must_not": []     }   } } ```
  --model: string
  --replacements: record # Replacements object used to anonymize/deanonymize messages
  size: float
  --start: string
  subAction: string@subAction-completer
]: any -> record<execution_uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/attack_discovery/_generate")
  let body = {alertsIndexPattern: $alertsIndexPattern, anonymizationFields: $anonymizationFields, apiConfig: $apiConfig, connectorName: $connectorName, end: $end, filter: $filter, model: $model, replacements: $replacements, size: $size, start: $start, subAction: $subAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the latest Attack Discovery generations metadata for the current user
#
# GET /api/attack_discovery/generations
# operationId: GetAttackDiscoveryGenerations
export def "attack-discovery-generations GetAttackDiscoveryGenerations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end: string # End of the time range for filtering generations. Accepts absolute timestamps (ISO 8601) or relative date math (e.g. "now", "now-24h"). (e.g. now)
  --size: float # The maximum number of generations to retrieve (default: 50, e.g. 50)
  --start: string # Start of the time range for filtering generations. Accepts absolute timestamps (ISO 8601) or relative date math (e.g. "now-7d"). (e.g. now-24h)
]: nothing -> record<generations: table<alerts_context_count: float, connector_id: string, connector_stats: record, discoveries: float, end: string, execution_uuid: string, loading_message: string, reason: string, start: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "end" $end "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/attack_discovery/generations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single Attack Discovery generation, including its discoveries and (optional) generation metadata
#
# GET /api/attack_discovery/generations/{execution_uuid}
# operationId: GetAttackDiscoveryGeneration
export def "attack-discovery-generations GetAttackDiscoveryGeneration" [
  execution_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-field-rendering: oneof<nothing, bool> # Enables a markdown syntax used to render pivot fields, for example `{{ user.name james }}`. When disabled, the same example would be rendered as `james`. This is primarily used for Attack Discovery views within Kibana. Defaults to `false`. (default: false, e.g. false)
  --with-replacements: oneof<nothing, bool> # When true, return the created Attack discoveries with text replacements applied to the detailsMarkdown, entitySummaryMarkdown, summaryMarkdown, and title fields. Defaults to `true`. (default: true, e.g. true)
]: nothing -> record<data: table<alert_ids: list, alert_rule_uuid: string, alert_start: string, alert_updated_at: string, alert_updated_by_user_id: string, alert_updated_by_user_name: string, alert_workflow_status: string, alert_workflow_status_updated_at: string, assignees: list, connector_id: string, connector_name: string, details_markdown: string, entity_summary_markdown: string, generation_uuid: string, id: string, index: string, mitre_attack_tactics: list, replacements: record, risk_score: int, summary_markdown: string, tags: list, timestamp: string, title: string, user_id: string, user_name: string, users: list>, generation: record<alerts_context_count: float, connector_id: string, connector_stats: record<average_successful_duration_nanoseconds: float, successful_generations: float>, discoveries: float, end: string, execution_uuid: string, loading_message: string, reason: string, start: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_field_rendering" $enable_field_rendering "scalar") (serialize-qp "with_replacements" $with_replacements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/attack_discovery/generations/($execution_uuid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss an Attack Discovery generation
#
# POST /api/attack_discovery/generations/{execution_uuid}/_dismiss
# operationId: PostAttackDiscoveryGenerationsDismiss
export def "attack-discovery-generations-dismiss PostAttackDiscoveryGenerationsDismiss" [
  execution_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alerts_context_count: float, connector_id: string, connector_stats: record<average_successful_duration_nanoseconds: float, successful_generations: float>, discoveries: float, end: string, execution_uuid: string, loading_message: string, reason: string, start: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/attack_discovery/generations/($execution_uuid)/_dismiss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Attack Discovery schedule
#
# POST /api/attack_discovery/schedules
# operationId: CreateAttackDiscoverySchedules
# --params shape: {alerts_index_pattern: string, api_config: any, combined_filter?: record, end?: string, filters?: list, query?: record, size: float, start?: string}
# --schedule shape: {interval: string}
export def "attack-discovery-schedules CreateAttackDiscoverySchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actions: list # The Attack Discovery schedule actions
  --enabled: oneof<nothing, bool> # Indicates whether the schedule is enabled
  name: string # The name of the schedule
  params: record # An Attack Discovery schedule params — shape: {alerts_index_pattern: string, api_config: any, combined_filter?: record, end?: string, filters?: list, query?: record, size: float, start?: string}
  schedule: record # shape: {interval: string}
]: any -> record<actions: list<any>, created_at: string, created_by: string, enabled: bool, id: string, last_execution: record<date: string, duration: float, message: string, status: string>, name: string, params: record<alerts_index_pattern: string, api_config: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string, name: string>, combined_filter: record, end: string, filters: list<any>, query: record<language: string, query: any>, size: float, start: string>, schedule: record<interval: string>, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/attack_discovery/schedules")
  let body = {actions: $actions, enabled: $enabled, name: $name, params: $params, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete Attack Discovery schedules
#
# POST /api/attack_discovery/schedules/_bulk_delete
# operationId: BulkDeleteAttackDiscoverySchedules
export def "attack-discovery-schedules-bulk-delete BulkDeleteAttackDiscoverySchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # The unique identifiers of the Attack Discovery schedules to update.
]: any -> record<errors: table<message: string, rule: record, status: float>, ids: list<string>, total: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/attack_discovery/schedules/_bulk_delete")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk disable Attack Discovery schedules
#
# POST /api/attack_discovery/schedules/_bulk_disable
# operationId: BulkDisableAttackDiscoverySchedules
export def "attack-discovery-schedules-bulk-disable BulkDisableAttackDiscoverySchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # The unique identifiers of the Attack Discovery schedules to update.
]: any -> record<errors: table<message: string, rule: record, status: float>, ids: list<string>, total: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/attack_discovery/schedules/_bulk_disable")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk enable Attack Discovery schedules
#
# POST /api/attack_discovery/schedules/_bulk_enable
# operationId: BulkEnableAttackDiscoverySchedules
export def "attack-discovery-schedules-bulk-enable BulkEnableAttackDiscoverySchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # The unique identifiers of the Attack Discovery schedules to update.
]: any -> record<errors: table<message: string, rule: record, status: float>, ids: list<string>, total: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/attack_discovery/schedules/_bulk_enable")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Attack Discovery schedules that match the search criteria
#
# GET /api/attack_discovery/schedules/_find
# operationId: FindAttackDiscoverySchedules
export def "attack-discovery-schedules-find FindAttackDiscoverySchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number to return (used for pagination). Defaults to 1. (e.g. 1)
  --per-page: float # Number of Attack Discovery schedules to return per page (used for pagination). Defaults to 10. (e.g. 10)
  --sort-field: string # Field used to sort results. Common fields include 'name', 'created_at', 'updated_at', and 'enabled'. (format: nonempty, e.g. I am a string)
  --sort-direction: string@sort-direction-completer # Sort order direction. Use 'asc' for ascending or 'desc' for descending. Defaults to 'asc'. (e.g. asc)
]: nothing -> record<data: table<actions: list, created_at: string, created_by: string, enabled: bool, id: string, last_execution: record, name: string, params: record, schedule: record, updated_at: string, updated_by: string>, page: float, per_page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/attack_discovery/schedules/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Attack Discovery schedule
#
# DELETE /api/attack_discovery/schedules/{id}
# operationId: DeleteAttackDiscoverySchedules
export def "attack-discovery-schedules DeleteAttackDiscoverySchedules" [
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
  let full_url = (build-url $base $"/api/attack_discovery/schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attack Discovery schedule by ID
#
# GET /api/attack_discovery/schedules/{id}
# operationId: GetAttackDiscoverySchedules
export def "attack-discovery-schedules GetAttackDiscoverySchedules" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<actions: list<any>, created_at: string, created_by: string, enabled: bool, id: string, last_execution: record<date: string, duration: float, message: string, status: string>, name: string, params: record<alerts_index_pattern: string, api_config: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string, name: string>, combined_filter: record, end: string, filters: list<any>, query: record<language: string, query: any>, size: float, start: string>, schedule: record<interval: string>, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/attack_discovery/schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Attack Discovery schedule
#
# PUT /api/attack_discovery/schedules/{id}
# operationId: UpdateAttackDiscoverySchedules
# --params shape: {alerts_index_pattern: string, api_config: any, combined_filter?: record, end?: string, filters?: list, query?: record, size: float, start?: string}
# --schedule shape: {interval: string}
export def "attack-discovery-schedules UpdateAttackDiscoverySchedules" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actions: list # The Attack Discovery schedule actions
  name: string # The name of the schedule
  params: record # An Attack Discovery schedule params — shape: {alerts_index_pattern: string, api_config: any, combined_filter?: record, end?: string, filters?: list, query?: record, size: float, start?: string}
  schedule: record # shape: {interval: string}
]: any -> record<actions: list<any>, created_at: string, created_by: string, enabled: bool, id: string, last_execution: record<date: string, duration: float, message: string, status: string>, name: string, params: record<alerts_index_pattern: string, api_config: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string, name: string>, combined_filter: record, end: string, filters: list<any>, query: record<language: string, query: any>, size: float, start: string>, schedule: record<interval: string>, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/attack_discovery/schedules/($id)")
  let body = {actions: $actions, name: $name, params: $params, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable Attack Discovery schedule
#
# POST /api/attack_discovery/schedules/{id}/_disable
# operationId: DisableAttackDiscoverySchedules
export def "attack-discovery-schedules-disable DisableAttackDiscoverySchedules" [
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
  let full_url = (build-url $base $"/api/attack_discovery/schedules/($id)/_disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Attack Discovery schedule
#
# POST /api/attack_discovery/schedules/{id}/_enable
# operationId: EnableAttackDiscoverySchedules
export def "attack-discovery-schedules-enable EnableAttackDiscoverySchedules" [
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
  let full_url = (build-url $base $"/api/attack_discovery/schedules/($id)/_enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dashboards
#
# GET /api/dashboards
# operationId: get-dashboards-redirect
export def "dashboards get-dashboards-redirect" [
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
  let full_url = (build-url $base "/api/dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dashboard
#
# POST /api/dashboards
# operationId: create-dashboard-redirect
export def "dashboards create-dashboard-redirect" [
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
  let full_url = (build-url $base "/api/dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a dashboard
#
# GET /api/dashboards/{id}
# operationId: get-dashboard-redirect
export def "dashboards get-dashboard-redirect" [
  id: any
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
  let full_url = (build-url $base $"/api/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard
#
# PUT /api/dashboards/{id}
# operationId: update-dashboard-redirect
export def "dashboards update-dashboard-redirect" [
  id: any
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
  let full_url = (build-url $base $"/api/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a dashboard
#
# DELETE /api/dashboards/{id}
# operationId: delete-dashboard-redirect
export def "dashboards delete-dashboard-redirect" [
  id: any
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
  let full_url = (build-url $base $"/api/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all data views
#
# GET /api/data_views
# operationId: getAllDataViewsDefault
export def "data-views get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_view: table<id: string, name: string, namespaces: list, title: string, typeMeta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data_views")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a data view
#
# POST /api/data_views/data_view
# operationId: createDataViewDefaultw
# --data_view shape: {allowNoIndex?: bool, fieldAttrs?: record, fieldFormats?: record, fields?: record, id?: string, name?: string, namespaces?: list, runtimeFieldMap?: record, sourceFilters?: list, timeFieldName?: string, title: string, type?: string, typeMeta?: record, version?: string}
export def "data-views-data-view createDataViewDefaultw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  data_view: record # The data view object. — shape: {allowNoIndex?: bool, fieldAttrs?: record, fieldFormats?: record, fields?: record, id?: string, name?: string, namespaces?: list, runtimeFieldMap?: record, sourceFilters?: list, timeFieldName?: string, title: string, type?: string, typeMeta?: record, version?: string}
  --override: oneof<nothing, bool> # Override an existing data view if a data view with the provided title already exists. (default: false)
]: any -> record<data_view: record<allowNoIndex: bool, fieldAttrs: record, fieldFormats: record, fields: record, id: string, name: string, namespaces: list<string>, runtimeFieldMap: record, sourceFilters: list<record>, timeFieldName: string, title: string, typeMeta: record<aggs: record, params: record>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data_views/data_view")
  let body = {data_view: $data_view, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a data view
#
# DELETE /api/data_views/data_view/{viewId}
# operationId: deleteDataViewDefault
export def "data-views-data-view delete" [
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a data view
#
# GET /api/data_views/data_view/{viewId}
# operationId: getDataViewDefault
export def "data-views-data-view get" [
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_view: record<allowNoIndex: bool, fieldAttrs: record, fieldFormats: record, fields: record, id: string, name: string, namespaces: list<string>, runtimeFieldMap: record, sourceFilters: list<record>, timeFieldName: string, title: string, typeMeta: record<aggs: record, params: record>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a data view
#
# POST /api/data_views/data_view/{viewId}
# operationId: updateDataViewDefault
# --data_view shape: {allowNoIndex?: bool, fieldFormats?: record, fields?: record, name?: string, runtimeFieldMap?: record, sourceFilters?: list, timeFieldName?: string, title?: string, type?: string, typeMeta?: record}
export def "data-views-data-view updateDataViewDefault" [
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  data_view: record # The data view properties you want to update. Only the specified properties are updated in the data view. Unspecified fields stay as they are persisted. — shape: {allowNoIndex?: bool, fieldFormats?: record, fields?: record, name?: string, runtimeFieldMap?: record, sourceFilters?: list, timeFieldName?: string, title?: string, type?: string, typeMeta?: record}
  --refresh-fields: oneof<nothing, bool> # Reloads the data view fields after the data view is updated. (default: false)
]: any -> record<data_view: record<allowNoIndex: bool, fieldAttrs: record, fieldFormats: record, fields: record, id: string, name: string, namespaces: list<string>, runtimeFieldMap: record, sourceFilters: list<record>, timeFieldName: string, title: string, typeMeta: record<aggs: record, params: record>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)")
  let body = {data_view: $data_view, refresh_fields: $refresh_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update field metadata
#
# POST /api/data_views/data_view/{viewId}/fields
# operationId: updateFieldsMetadataDefault
export def "data-views-data-view-fields updateFieldsMetadataDefault" [
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  --body-fields: record # The field object.
]: any -> record<acknowledged: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)/fields")
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a runtime field
#
# POST /api/data_views/data_view/{viewId}/runtime_field
# operationId: createRuntimeFieldDefault
export def "data-views-data-view-runtime-field createRuntimeFieldDefault" [
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  name: string # The name for a runtime field.
  runtimeField: record # The runtime field definition object.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)/runtime_field")
  let body = {name: $name, runtimeField: $runtimeField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update a runtime field
#
# PUT /api/data_views/data_view/{viewId}/runtime_field
# operationId: createUpdateRuntimeFieldDefault
export def "data-views-data-view-runtime-field createUpdateRuntimeFieldDefault" [
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  name: string # The name for a runtime field.
  runtimeField: record # The runtime field definition object.
]: any -> record<data_view: record, fields: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)/runtime_field")
  let body = {name: $name, runtimeField: $runtimeField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a runtime field
#
# DELETE /api/data_views/data_view/{viewId}/runtime_field/{fieldName}
# operationId: deleteRuntimeFieldDefault
export def "data-views-data-view-runtime-field delete" [
  fieldName: string
  viewId: string
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
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)/runtime_field/($fieldName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a runtime field
#
# GET /api/data_views/data_view/{viewId}/runtime_field/{fieldName}
# operationId: getRuntimeFieldDefault
export def "data-views-data-view-runtime-field get" [
  fieldName: string
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_view: record, fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)/runtime_field/($fieldName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a runtime field
#
# POST /api/data_views/data_view/{viewId}/runtime_field/{fieldName}
# operationId: updateRuntimeFieldDefault
export def "data-views-data-view-runtime-field updateRuntimeFieldDefault" [
  fieldName: string
  viewId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  runtimeField: record # The runtime field definition object.  You can update following fields:  - `type` - `script`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data_views/data_view/($viewId)/runtime_field/($fieldName)")
  let body = {runtimeField: $runtimeField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the default data view
#
# GET /api/data_views/default
# operationId: getDefaultDataViewDefault
export def "data-views-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_view_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data_views/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the default data view
#
# POST /api/data_views/default
# operationId: setDefaultDatailViewDefault
export def "data-views-default setDefaultDatailViewDefault" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  --data-view-id: string # The data view identifier. NOTE: The API does not validate whether it is a valid identifier. Use `null` to unset the default data view.  (nullable)
  --force: oneof<nothing, bool> # Update an existing default data view identifier. (default: false)
]: any -> record<acknowledged: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data_views/default")
  let body = {data_view_id: $data_view_id, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Swap saved object references
#
# POST /api/data_views/swap_references
# operationId: swapDataViewsDefault
export def "data-views-swap-references swapDataViewsDefault" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  --delete: oneof<nothing, bool> # Deletes referenced saved object if all references are removed.
  --forId: any # Limit the affected saved objects to one or more by identifier.
  --forType: string # Limit the affected saved objects by type.
  fromId: string # The saved object reference to change.
  --fromType: string # Specify the type of the saved object reference to alter. The default value is `index-pattern` for data views.
  toId: string # New saved object reference value to replace the old value.
]: any -> record<deleteStatus: record<deletePerformed: bool, remainingRefs: int>, result: table<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data_views/swap_references")
  let body = {delete: $delete, forId: $forId, forType: $forType, fromId: $fromId, fromType: $fromType, toId: $toId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview swap references
#
# POST /api/data_views/swap_references/_preview
# operationId: previewSwapDataViewsDefault
export def "data-views-swap-references-preview previewSwapDataViewsDefault" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  --delete: oneof<nothing, bool> # Deletes referenced saved object if all references are removed.
  --forId: any # Limit the affected saved objects to one or more by identifier.
  --forType: string # Limit the affected saved objects by type.
  fromId: string # The saved object reference to change.
  --fromType: string # Specify the type of the saved object reference to alter. The default value is `index-pattern` for data views.
  toId: string # New saved object reference value to replace the old value.
]: any -> record<result: table<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data_views/swap_references/_preview")
  let body = {delete: $delete, forId: $forId, forType: $forType, fromId: $fromId, fromType: $fromType, toId: $toId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns user privileges for the Kibana space
#
# GET /api/detection_engine/privileges
# operationId: ReadPrivileges
export def "detection-engine-privileges ReadPrivileges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<has_encryption_key: bool, is_authenticated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/detection_engine/privileges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a detection rule
#
# DELETE /api/detection_engine/rules
# Discriminator (response): type = eql, esql, machine_learning, new_terms, query, saved_query, threat_match, threshold
# operationId: DeleteRule
export def "detection-engine-rules DeleteRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The rule's `id` value. (format: uuid)
  --rule-id: string # The rule's `rule_id` value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "rule_id" $rule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a detection rule
#
# GET /api/detection_engine/rules
# Discriminator (response): type = eql, esql, machine_learning, new_terms, query, saved_query, threat_match, threshold
# operationId: ReadRule
export def "detection-engine-rules ReadRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The rule's `id` value. (format: uuid)
  --rule-id: string # The rule's `rule_id` value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "rule_id" $rule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a detection rule
#
# PATCH /api/detection_engine/rules
# Discriminator (response): type = eql, esql, machine_learning, new_terms, query, saved_query, threat_match, threshold
# operationId: PatchRule
export def "detection-engine-rules PatchRule" [
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
  let full_url = (build-url $base "/api/detection_engine/rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a detection rule
#
# POST /api/detection_engine/rules
# Discriminator (request): type = eql, esql, machine_learning, new_terms, query, saved_query, threat_match, threshold
# operationId: CreateRule
export def "detection-engine-rules CreateRule" [
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
  let full_url = (build-url $base "/api/detection_engine/rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a detection rule
#
# PUT /api/detection_engine/rules
# Discriminator (request): type = eql, esql, machine_learning, new_terms, query, saved_query, threat_match, threshold
# operationId: UpdateRule
export def "detection-engine-rules UpdateRule" [
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
  let full_url = (build-url $base "/api/detection_engine/rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply a bulk action to detection rules
#
# POST /api/detection_engine/rules/_bulk_action
# operationId: PerformRulesBulkAction
# --duplicate shape: {include_exceptions: bool, include_expired_exceptions: bool}
# --run shape: {end_date: string, start_date: string}
# --fill_gaps shape: {end_date: string, start_date: string}
export def "detection-engine-rules-bulk-action PerformRulesBulkAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run: oneof<nothing, bool> # Enables dry run mode for the request call.  Enable dry run mode to verify that bulk actions can be applied to specified rules. Certain rules, such as prebuilt Elastic rules on a Basic subscription, can’t be edited and will return errors in the request response. Error details will contain an explanation, the rule name and/or ID, and additional troubleshooting information.  To enable dry run mode on a request, add the query parameter `dry_run=true` to the end of the request URL. Rules specified in the request will be temporarily updated. These updates won’t be written to Elasticsearch. > info > Dry run mode is not supported for the `export` bulk action. A 400 error will be returned in the request response.
  --action: string@action-completer-1
  --gap-auto-fill-scheduler-id: string # Gap auto fill scheduler ID used to determine gap fill status for rules
  --gap-fill-statuses: list # Gap fill statuses to filter rules with gaps by status (used together with gaps_range_*).
  --gaps-range-end: string # Gaps range end, valid only when query is provided
  --gaps-range-start: string # Gaps range start, valid only when query is provided
  --ids: list # Array of rule `id`s to which a bulk action will be applied. Do not use rule's `rule_id` here. Only valid when query property is undefined.
  --body-query: string # Query to filter rules.
  --duplicate: record # Duplicate object that describes applying an update action. — shape: {include_exceptions: bool, include_expired_exceptions: bool}
  --run: record # Object that describes applying a manual rule run action. — shape: {end_date: string, start_date: string}
  --fill-gaps: record # Object that describes applying a manual gap fill action for the specified time range. — shape: {end_date: string, start_date: string}
  --edit: list # Array of objects containing the edit operations
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dry_run" $dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules/_bulk_action" $qp)
  let body = {action: $action, gap_auto_fill_scheduler_id: $gap_auto_fill_scheduler_id, gap_fill_statuses: $gap_fill_statuses, gaps_range_end: $gaps_range_end, gaps_range_start: $gaps_range_start, ids: $ids, query: $body_query, duplicate: $duplicate, run: $run, fill_gaps: $fill_gaps, edit: $edit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export detection rules
#
# POST /api/detection_engine/rules/_export
# operationId: ExportRules
# --objects item shape: {rule_id: string}
export def "detection-engine-rules-export ExportRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exclude-export-details: oneof<nothing, bool> # Determines whether a summary of the exported rules is returned. (default: false)
  --file-name: string # File name for saving the exported rules. > info > When using cURL to export rules to a file, use the -O and -J options to save the rules to the file name specified in the URL.  (default: export.ndjson)
  objects: list # Array of objects with a rule's `rule_id` field. Do not use rule's `id` here. Exports all rules when unspecified. — item shape: {rule_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclude_export_details" $exclude_export_details "scalar") (serialize-qp "file_name" $file_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules/_export" $qp)
  let body = {objects: $objects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all detection rules
#
# GET /api/detection_engine/rules/_find
# operationId: FindRules
export def "detection-engine-rules-find FindRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # List of `alert.attributes` field names to return for each rule (for example `name`, `enabled`). If omitted, the default field set is returned. Repeat the parameter to pass multiple field names, or use comma-separated values when supported by your client.
  --filter: string # Search query  Filters the returned results according to the value of the specified field, using the alert.attributes.<field name>:<field value> syntax, where <field name> can be: - name - enabled - tags - createdBy - interval - updatedBy > info > Even though the JSON rule object uses created_by and updated_by fields, you must use createdBy and updatedBy fields in the filter.
  --sort-field: string@sort-field-completer-4 # Field to sort by
  --sort-order: string@sort-order-completer # Sort order
  --page: int # Page number (default: 1)
  --per-page: int # Rules per page (default: 20)
  --gaps-range-start: string # Gaps range start
  --gaps-range-end: string # Gaps range end
  --gap-fill-statuses: list # Gap fill statuses
  --gap-auto-fill-scheduler-id: string # Gap auto fill scheduler ID used to determine gap fill status for rules
]: nothing -> record<data: list<any>, page: int, perPage: int, total: int, warnings: table<actionPath: string, buttonLabel: string, message: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "gaps_range_start" $gaps_range_start "scalar") (serialize-qp "gaps_range_end" $gaps_range_end "scalar") (serialize-qp "gap_fill_statuses" $gap_fill_statuses "multi") (serialize-qp "gap_auto_fill_scheduler_id" $gap_auto_fill_scheduler_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import detection rules
#
# POST /api/detection_engine/rules/_import
# operationId: ImportRules
export def "detection-engine-rules-import ImportRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: oneof<nothing, bool> # Determines whether existing rules with the same `rule_id` are overwritten. (default: false)
  --overwrite-exceptions: oneof<nothing, bool> # Determines whether existing exception lists with the same `list_id` are overwritten. Both the exception list container and its items are overwritten. (default: false)
  --overwrite-action-connectors: oneof<nothing, bool> # Determines whether existing actions with the same `kibana.alert.rule.actions.id` are overwritten. (default: false)
  --as-new-list: oneof<nothing, bool> # Generates a new list ID for each imported exception list. (default: false)
  --file: string # The `.ndjson` file containing the rules. (format: binary)
]: any -> record<action_connectors_errors: table<error: record, id: string, item_id: string, list_id: string, rule_id: string>, action_connectors_success: bool, action_connectors_success_count: int, action_connectors_warnings: table<actionPath: string, buttonLabel: string, message: string, type: string>, errors: table<error: record, id: string, item_id: string, list_id: string, rule_id: string>, exceptions_errors: table<error: record, id: string, item_id: string, list_id: string, rule_id: string>, exceptions_success: bool, exceptions_success_count: int, rules_count: int, success: bool, success_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overwrite" $overwrite "scalar") (serialize-qp "overwrite_exceptions" $overwrite_exceptions "scalar") (serialize-qp "overwrite_action_connectors" $overwrite_action_connectors "scalar") (serialize-qp "as_new_list" $as_new_list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules/_import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create rule exception items
#
# POST /api/detection_engine/rules/{id}/exceptions
# operationId: CreateRuleExceptionListItems
# --items item shape: {comments?: list, description: string, entries: list, expire_time?: string, item_id?: string, meta?: record, name: string, namespace_type?: "agnostic"|"single", os_types?: list, tags?: list, type: "simple"}
export def "detection-engine-rules-exceptions CreateRuleExceptionListItems" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # item shape: {comments?: list, description: string, entries: list, expire_time?: string, item_id?: string, meta?: record, name: string, namespace_type?: "agnostic"|"single", os_types?: list, tags?: list, type: "simple"}
]: any -> table<_version: string, comments: list<record>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/detection_engine/rules/($id)/exceptions")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview rule alerts generated on specified time range
#
# POST /api/detection_engine/rules/preview
# Discriminator (request): type
# operationId: RulePreview
export def "detection-engine-rules-preview RulePreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logged-requests: oneof<nothing, bool> # Enables logging and returning in response ES queries, performed during rule execution
  --body: record
]: any -> record<isAborted: bool, logs: table<duration: int, errors: list, requests: list, startedAt: string, warnings: list>, previewId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logged_requests" $enable_logged_requests "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/detection_engine/rules/preview" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign and unassign users from detection alerts
#
# POST /api/detection_engine/signals/assignees
# operationId: SetAlertAssignees
# --assignees shape: {add: list, remove: list}
export def "detection-engine-signals-assignees SetAlertAssignees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  assignees: record # shape: {add: list, remove: list}
  ids: list # A list of alerts `id`s.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/detection_engine/signals/assignees")
  let body = {assignees: $assignees, ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find and/or aggregate detection alerts
#
# POST /api/detection_engine/signals/search
# operationId: SearchAlerts
export def "detection-engine-signals-search SearchAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: any
  --aggs: record
  --body-fields: list
  --body-query: record
  --runtime-mappings: record
  --size: int
  --body-sort: any
  --track-total-hits: oneof<nothing, bool>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/detection_engine/signals/search")
  let body = {_source: $body_source, aggs: $aggs, fields: $body_fields, query: $body_query, runtime_mappings: $runtime_mappings, size: $size, sort: $body_sort, track_total_hits: $track_total_hits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set a detection alert status
#
# POST /api/detection_engine/signals/status
# operationId: SetAlertsStatus
export def "detection-engine-signals-status SetAlertsStatus" [
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
  let full_url = (build-url $base "/api/detection_engine/signals/status")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add and remove detection alert tags
#
# POST /api/detection_engine/signals/tags
# operationId: SetAlertTags
# --tags shape: {tags_to_add: list, tags_to_remove: list}
export def "detection-engine-signals-tags SetAlertTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # A list of alerts `id`s.
  tags: record # Object with list of tags to add and remove. — shape: {tags_to_add: list, tags_to_remove: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/detection_engine/signals/tags")
  let body = {ids: $ids, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all detection rule tags
#
# GET /api/detection_engine/tags
# operationId: ReadTags
export def "detection-engine-tags ReadTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/detection_engine/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Elastic Endpoint rule exception list
#
# POST /api/endpoint_list
# operationId: CreateEndpointList
export def "endpoint-list CreateEndpointList" [
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
  let full_url = (build-url $base "/api/endpoint_list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Elastic Endpoint exception list item
#
# DELETE /api/endpoint_list/items
# operationId: DeleteEndpointListItem
export def "endpoint-list-items DeleteEndpointListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Either `id` or `item_id` must be specified (format: nonempty, e.g. 71a9f4b2-c85c-49b4-866f-c71eb9e67da2)
  --item-id: string # Either `id` or `item_id` must be specified (format: nonempty, e.g. simple_list_item)
]: nothing -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "item_id" $item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint_list/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Elastic Endpoint rule exception list item
#
# GET /api/endpoint_list/items
# operationId: ReadEndpointListItem
export def "endpoint-list-items ReadEndpointListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Either `id` or `item_id` must be specified (format: nonempty, e.g. 71a9f4b2-c85c-49b4-866f-c71eb9e67da2)
  --item-id: string # Either `id` or `item_id` must be specified (format: nonempty, e.g. simple_list_item)
]: nothing -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "item_id" $item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint_list/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Elastic Endpoint rule exception list item
#
# POST /api/endpoint_list/items
# operationId: CreateEndpointListItem
# --comments item shape: {comment: string, created_at: string, created_by: string, id: string, updated_at?: string, updated_by?: string}
export def "endpoint-list-items CreateEndpointListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comments: list # Array of comment fields:  - comment (string): Comments about the exception item. — item shape: {comment: string, created_at: string, created_by: string, id: string, updated_at?: string, updated_by?: string}
  description: string # Describes the exception list.
  entries: list
  --item-id: string # Human readable string identifier, e.g. `trusted-linux-processes` (format: nonempty, e.g. simple_list_item)
  --meta: record
  name: string # Exception list name. (format: nonempty)
  --os-types: list
  --tags: list
  type: string@type-completer-1
]: any -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint_list/items")
  let body = {comments: $comments, description: $description, entries: $entries, item_id: $item_id, meta: $meta, name: $name, os_types: $os_types, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an Elastic Endpoint rule exception list item
#
# PUT /api/endpoint_list/items
# operationId: UpdateEndpointListItem
# --comments item shape: {comment: string, created_at: string, created_by: string, id: string, updated_at?: string, updated_by?: string}
export def "endpoint-list-items UpdateEndpointListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version id, normally returned by the API when the item is retrieved. Use it ensure updates are made against the latest version.
  --comments: list # Array of comment fields:  - comment (string): Comments about the exception item. — item shape: {comment: string, created_at: string, created_by: string, id: string, updated_at?: string, updated_by?: string}
  description: string # Describes the exception list.
  entries: list
  --id: string # Exception's identifier. (format: nonempty, e.g. 71a9f4b2-c85c-49b4-866f-c71eb9e67da2)
  --item-id: string # Human readable string identifier, e.g. `trusted-linux-processes` (format: nonempty, e.g. simple_list_item)
  --meta: record
  name: string # Exception list name. (format: nonempty)
  --os-types: list
  --tags: list
  type: string@type-completer-1
]: any -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint_list/items")
  let body = {_version: $version, comments: $comments, description: $description, entries: $entries, id: $id, item_id: $item_id, meta: $meta, name: $name, os_types: $os_types, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Elastic Endpoint exception list items
#
# GET /api/endpoint_list/items/_find
# operationId: FindEndpointListItems
export def "endpoint-list-items-find FindEndpointListItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Filters the returned results according to the value of the specified field, using the `<field name>:<field value>` syntax.  (format: nonempty)
  --page: int # The page number to return
  --per-page: int # The number of exception list items to return per page
  --sort-field: string # Determines which field is used to sort the results (format: nonempty)
  --sort-order: string@sort-order-completer # Determines the sort order, which can be `desc` or `asc`
]: nothing -> record<data: table<_version: string, comments: list, created_at: string, created_by: string, description: string, entries: list, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list, tags: list, tie_breaker_id: string, type: string, updated_at: string, updated_by: string>, page: int, per_page: int, pit: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint_list/items/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get response actions
#
# GET /api/endpoint/action
# operationId: EndpointGetActionsList
export def "endpoint-action EndpointGetActionsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1, e.g. 1)
  --pageSize: int # The number of response actions to return per page. (default: 10, e.g. 10)
  --commands: list # A list of response action command names to filter by. (e.g. [isolate, unisolate])
  --agentIds: string # A list of Elastic Agent IDs to filter the response actions by. (e.g. [agent-id-1, agent-id-2])
  --userIds: string # A list of user IDs that submitted the response actions. (e.g. [user-id-1, user-id-2])
  --startDate: string # A start date in ISO 8601 format or Date Math format (for example, `now-24h`). (e.g. 2023-10-31T00:00:00.000Z)
  --endDate: string # An end date in ISO 8601 format or Date Math format (for example, `now`). (e.g. 2023-10-31T23:59:59.999Z)
  --agentTypes: string@agentTypes-completer # The agent type to filter response actions by. Defaults to `endpoint`. (e.g. endpoint)
  --withOutputs: string # A list of response action IDs whose outputs should be included in the response. (e.g. [action-id-1, action-id-2])
  --types: list # A list of response action types to filter by (`automated`, `manual`). (e.g. [automated, manual])
]: nothing -> record<agentTypes: list<string>, commands: list<string>, data: table<agents: list, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>, elasticAgentIds: list<string>, endDate: string, page: int, pageSize: int, startDate: string, statuses: list<string>, total: int, userIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "commands" $commands "multi") (serialize-qp "agentIds" $agentIds "scalar") (serialize-qp "userIds" $userIds "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "agentTypes" $agentTypes "scalar") (serialize-qp "withOutputs" $withOutputs "scalar") (serialize-qp "types" $types "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint/action" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get response actions status
#
# GET /api/endpoint/action_status
# operationId: EndpointGetActionsStatus
export def "endpoint-action-status EndpointGetActionsStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-ids: string # A list of agent IDs to get the action status for. (e.g. [agent-id-1, agent-id-2])
]: nothing -> record<data: table<agent_id: string, pending_actions: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_ids" $agent_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint/action_status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get action details
#
# GET /api/endpoint/action/{action_id}
# Discriminator (response): command = cancel, execute, get-file, isolate, kill-process, memory-dump, running-processes, runscript, scan, suspend-process, unisolate, upload
# operationId: EndpointGetActionsDetails
export def "endpoint-action EndpointGetActionsDetails" [
  action_id: string
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
  let full_url = (build-url $base $"/api/endpoint/action/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file information
#
# GET /api/endpoint/action/{action_id}/file/{file_id}
# operationId: EndpointFileInfo
export def "endpoint-action-file EndpointFileInfo" [
  action_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<actionId: string, agentId: string, agentType: string, created: string, id: string, mimeType: string, name: string, size: float, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoint/action/($action_id)/file/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a file
#
# GET /api/endpoint/action/{action_id}/file/{file_id}/download
# operationId: EndpointFileDownload
export def "endpoint-action-file-download EndpointFileDownload" [
  action_id: string
  file_id: string
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
  let full_url = (build-url $base $"/api/endpoint/action/($action_id)/file/($file_id)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a response action
#
# POST /api/endpoint/action/cancel
# operationId: CancelAction
# --parameters shape: {id: string}
export def "endpoint-action-cancel CancelAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: record # shape: {id: string}
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/cancel")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a command
#
# POST /api/endpoint/action/execute
# operationId: EndpointExecuteAction
# --parameters shape: {command: string, timeout?: int}
export def "endpoint-action-execute EndpointExecuteAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: record # shape: {command: string, timeout?: int}
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/execute")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a file
#
# POST /api/endpoint/action/get_file
# operationId: EndpointGetFileAction
# --parameters shape: {path: string}
export def "endpoint-action-get-file EndpointGetFileAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: record # shape: {path: string}
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/get_file")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Isolate an endpoint
#
# POST /api/endpoint/action/isolate
# operationId: EndpointIsolateAction
export def "endpoint-action-isolate EndpointIsolateAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  --parameters: record # Parameters object
]: any -> record<action: string, data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/isolate")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Terminate a process
#
# POST /api/endpoint/action/kill_process
# operationId: EndpointKillProcessAction
export def "endpoint-action-kill-process EndpointKillProcessAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: any
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/kill_process")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a memory dump from the host machine
#
# POST /api/endpoint/action/memory_dump
# operationId: EndpointGenerateMemoryDump
export def "endpoint-action-memory-dump EndpointGenerateMemoryDump" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: any
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/memory_dump")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a script
#
# POST /api/endpoint/action/run_script
# operationId: RunScriptAction
export def "endpoint-action-run-script RunScriptAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: any # One of the following set of parameters must be provided for the `agentType` that is specified.
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/run_script")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get running processes
#
# POST /api/endpoint/action/running_procs
# operationId: EndpointGetProcessesAction
export def "endpoint-action-running-procs EndpointGetProcessesAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  --parameters: record # Parameters object
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/running_procs")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Scan a file or directory
#
# POST /api/endpoint/action/scan
# operationId: EndpointScanAction
# --parameters shape: {path: string}
export def "endpoint-action-scan EndpointScanAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: record # shape: {path: string}
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/scan")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get actions state
#
# GET /api/endpoint/action/state
# operationId: EndpointGetActionsState
export def "endpoint-action-state EndpointGetActionsState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<canEncrypt: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspend a process
#
# POST /api/endpoint/action/suspend_process
# operationId: EndpointSuspendProcessAction
export def "endpoint-action-suspend-process EndpointSuspendProcessAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: any
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/suspend_process")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Release an isolated endpoint
#
# POST /api/endpoint/action/unisolate
# operationId: EndpointUnisolateAction
export def "endpoint-action-unisolate EndpointUnisolateAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  --parameters: record # Parameters object
]: any -> record<action: string, data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/unisolate")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload a file
#
# POST /api/endpoint/action/upload
# operationId: EndpointUploadAction
# --parameters shape: {overwrite?: bool}
export def "endpoint-action-upload EndpointUploadAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-type: string@agent-type-completer # List of agent types to retrieve. Defaults to `endpoint`. (e.g. endpoint)
  --alert-ids: list # If this action is associated with any alerts, they can be specified here. The action will be logged in any cases associated with the specified alerts. Max of 50. (e.g. [alert-id-1, alert-id-2])
  --case-ids: list # The IDs of cases where the action taken will be logged. Max of 50. (e.g. [case-id-1, case-id-2])
  --comment: string # Optional comment (e.g. This is a comment)
  endpoint_ids: list # List of endpoint IDs (cannot contain empty strings). Max of 250. (e.g. [endpoint-id-1, endpoint-id-2])
  parameters: record # shape: {overwrite?: bool}
  file: string # The binary content of the file. (format: binary, e.g. RWxhc3RpYw==)
]: any -> record<data: record<agents: list<string>, agentState: record, agentType: string, command: string, completedAt: string, createdBy: string, hosts: record, id: string, isComplete: bool, isExpired: bool, outputs: record, parameters: record, startedAt: string, status: string, wasSuccessful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/action/upload")
  let body = {agent_type: $agent_type, alert_ids: $alert_ids, case_ids: $case_ids, comment: $comment, endpoint_ids: $endpoint_ids, parameters: $parameters, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a metadata list
#
# GET /api/endpoint/metadata
# operationId: GetEndpointMetadataList
export def "endpoint-metadata GetEndpointMetadataList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (default: 1, e.g. 1)
  --pageSize: int # The number of endpoints to return per page. (default: 10, e.g. 10)
  --kuery: string # A KQL string to filter the endpoint metadata results. (e.g. united.endpoint.host.os.name : 'Windows')
  --hostStatuses: list # A set of host statuses to filter the results by (for example, `healthy`, `updating`). (e.g. [healthy, updating])
  --sortField: string@sortField-completer # The field used to sort the results. (e.g. enrolled_at)
  --sortDirection: string@sortDirection-completer # The sort order, either `asc` or `desc`. (e.g. desc)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "kuery" $kuery "scalar") (serialize-qp "hostStatuses" $hostStatuses "multi") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metadata
#
# GET /api/endpoint/metadata/{id}
# operationId: GetEndpointMetadata
export def "endpoint-metadata GetEndpointMetadata" [
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
  let full_url = (build-url $base $"/api/endpoint/metadata/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a policy response
#
# GET /api/endpoint/policy_response
# operationId: GetPolicyResponse
export def "endpoint-policy-response GetPolicyResponse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agentId: string # The agent ID to retrieve the policy response for.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agentId" $agentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint/policy_response" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a protection updates note
#
# GET /api/endpoint/protection_updates_note/{package_policy_id}
# operationId: GetProtectionUpdatesNote
export def "endpoint-protection-updates-note GetProtectionUpdatesNote" [
  package_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<note: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoint/protection_updates_note/($package_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a protection updates note
#
# POST /api/endpoint/protection_updates_note/{package_policy_id}
# operationId: CreateUpdateProtectionUpdatesNote
export def "endpoint-protection-updates-note CreateUpdateProtectionUpdatesNote" [
  package_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # The note content.
]: any -> record<note: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoint/protection_updates_note/($package_policy_id)")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of scripts
#
# GET /api/endpoint/scripts_library
# operationId: EndpointScriptLibraryListScripts
export def "endpoint-scripts-library EndpointScriptLibraryListScripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number of the results to return. Defaults to 1. (default: 1, e.g. 1)
  --pageSize: int # Number of results to return per page. Defaults to 10. Max value is 1000. (default: 10, e.g. 10)
  --sortField: string@sortField-completer-1 # The field to sort the results by. Defaults to name. (e.g. updatedAt)
  --sortDirection: string@sortDirection-completer # The direction to sort the results by. Defaults to asc (ascending). (e.g. desc)
  --kuery: string # A KQL query string to filter the list of scripts. Nearly all fields in the script object are searchable.
]: nothing -> record<data: table<createdAt: string, createdBy: string, description: string, downloadUri: string, example: string, fileHash: string, fileName: string, fileSize: int, id: string, instructions: string, name: string, pathToExecutable: string, platform: list, requiresInput: bool, tags: list, updatedAt: string, updatedBy: string, version: string>, page: int, pageSize: int, sortDirection: string, sortField: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "kuery" $kuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/endpoint/scripts_library" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create script
#
# POST /api/endpoint/scripts_library
# operationId: EndpointScriptLibraryCreateScript
export def "endpoint-scripts-library EndpointScriptLibraryCreateScript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the script and its purpose/functionality
  --example: string # Example usage of the script
  file: record # The script file upload (format: binary)
  fileType: string@fileType-completer # The type of the uploaded file, which determines the expected value of `pathToExecutable`. If `fileType` is "script", then `pathToExecutable` should not be included. If `fileType` is "archive", then `pathToExecutable` is required and should specify the path to the executable file within the archive.
  --instructions: string # Instructions for using the script, including details around its supported input arguments
  name: string # Name of the script
  --pathToExecutable: string # Used only for when the uploaded script is an archive (.zip file for example). This property defines the relative path to the file included in the archive that should be executed once its contents are extracted. The path should be relative to the root of the archive. (e.g. ./bin/script.sh)
  platform: list # Platforms supported by the the script
  --requiresInput: oneof<nothing, bool> # Whether the script requires input arguments
  --tags: list # Tags to categorize the script
]: any -> record<data: record<createdAt: string, createdBy: string, description: string, downloadUri: string, example: string, fileHash: string, fileName: string, fileSize: int, id: string, instructions: string, name: string, pathToExecutable: string, platform: list<string>, requiresInput: bool, tags: list<string>, updatedAt: string, updatedBy: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoint/scripts_library")
  let body = {description: $description, example: $example, file: $file, fileType: $fileType, instructions: $instructions, name: $name, pathToExecutable: $pathToExecutable, platform: $platform, requiresInput: $requiresInput, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a script
#
# DELETE /api/endpoint/scripts_library/{script_id}
# operationId: EndpointScriptLibraryDeleteScript
export def "endpoint-scripts-library EndpointScriptLibraryDeleteScript" [
  script_id: string
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
  let full_url = (build-url $base $"/api/endpoint/scripts_library/($script_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get script
#
# GET /api/endpoint/scripts_library/{script_id}
# operationId: EndpointScriptLibraryGetOneScript
export def "endpoint-scripts-library EndpointScriptLibraryGetOneScript" [
  script_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, createdBy: string, description: string, downloadUri: string, example: string, fileHash: string, fileName: string, fileSize: int, id: string, instructions: string, name: string, pathToExecutable: string, platform: list<string>, requiresInput: bool, tags: list<string>, updatedAt: string, updatedBy: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoint/scripts_library/($script_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update script
#
# PATCH /api/endpoint/scripts_library/{script_id}
# operationId: EndpointScriptLibraryPatchUpdateScript
export def "endpoint-scripts-library EndpointScriptLibraryPatchUpdateScript" [
  script_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the script and its purpose/functionality
  --example: string # Example usage of the script
  --file: record # The script file upload (format: binary)
  --fileType: string@fileType-completer # The type of the uploaded file, which determines the expected value of `pathToExecutable`. If `fileType` is "script", then `pathToExecutable` should not be included. If `fileType` is "archive", then `pathToExecutable` is required and should specify the path to the executable file within the archive.
  --instructions: string # Instructions for using the script, including details around its supported input arguments
  --name: string # Name of the script
  --pathToExecutable: string # Used only for when the uploaded script is an archive (.zip file for example). This property defines the relative path to the file included in the archive that should be executed once its contents are extracted. The path should be relative to the root of the archive. (e.g. ./bin/script.sh)
  --platform: list # Platforms supported by the the script
  --requiresInput: oneof<nothing, bool> # Whether the script requires input arguments
  --tags: list # Tags to categorize the script
]: any -> record<data: record<createdAt: string, createdBy: string, description: string, downloadUri: string, example: string, fileHash: string, fileName: string, fileSize: int, id: string, instructions: string, name: string, pathToExecutable: string, platform: list<string>, requiresInput: bool, tags: list<string>, updatedAt: string, updatedBy: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoint/scripts_library/($script_id)")
  let body = {description: $description, example: $example, file: $file, fileType: $fileType, instructions: $instructions, name: $name, pathToExecutable: $pathToExecutable, platform: $platform, requiresInput: $requiresInput, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Download a script file
#
# GET /api/endpoint/scripts_library/{script_id}/download
# operationId: EndpointScriptLibraryDownloadScript
export def "endpoint-scripts-library-download EndpointScriptLibraryDownloadScript" [
  script_id: string
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
  let full_url = (build-url $base $"/api/endpoint/scripts_library/($script_id)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Privilege Monitoring Engine
#
# DELETE /api/entity_analytics/monitoring/engine/delete
# operationId: DeleteMonitoringEngine
export def "entity-analytics-monitoring-engine-delete DeleteMonitoringEngine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: oneof<nothing, bool> # Whether to delete all the privileged user data (default: false)
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity_analytics/monitoring/engine/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable the Privilege Monitoring Engine
#
# POST /api/entity_analytics/monitoring/engine/disable
# operationId: DisableMonitoringEngine
export def "entity-analytics-monitoring-engine-disable DisableMonitoringEngine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<message: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/engine/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize the Privilege Monitoring Engine
#
# POST /api/entity_analytics/monitoring/engine/init
# operationId: InitMonitoringEngine
export def "entity-analytics-monitoring-engine-init InitMonitoringEngine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<message: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/engine/init")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule the Privilege Monitoring Engine
#
# POST /api/entity_analytics/monitoring/engine/schedule_now
# operationId: ScheduleMonitoringEngine
export def "entity-analytics-monitoring-engine-schedule-now ScheduleMonitoringEngine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/engine/schedule_now")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Health check on Privilege Monitoring
#
# GET /api/entity_analytics/monitoring/privileges/health
# operationId: PrivMonHealth
export def "entity-analytics-monitoring-privileges-health PrivMonHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<message: string>, status: string, users: record<current_count: int, max_allowed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/privileges/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a privileges check on Privilege Monitoring
#
# GET /api/entity_analytics/monitoring/privileges/privileges
# operationId: PrivMonPrivileges
export def "entity-analytics-monitoring-privileges-privileges PrivMonPrivileges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<has_all_required: bool, has_read_permissions: bool, has_write_permissions: bool, privileges: record<elasticsearch: record<cluster: record, index: record>, kibana: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/privileges/privileges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new monitored user
#
# POST /api/entity_analytics/monitoring/users
# operationId: CreatePrivMonUser
# --entity_analytics_monitoring shape: {labels?: list}
# --user shape: {name?: string}
export def "entity-analytics-monitoring-users CreatePrivMonUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-analytics-monitoring: record # Entity analytics monitoring configuration for the user — shape: {labels?: list}
  --user: record # shape: {name?: string}
]: any -> record<entity_analytics_monitoring: record<labels: list<record>>, id: string, labels: record<source_ids: list<string>, source_integrations: list<string>, sources: list<any>>, user: record<entity: record<attributes: record>, is_privileged: bool, name: string>, _timestamp: string, event: record<_timestamp: string, ingested: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/users")
  let body = {entity_analytics_monitoring: $entity_analytics_monitoring, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert multiple monitored users via CSV upload
#
# POST /api/entity_analytics/monitoring/users/_csv
# operationId: PrivmonBulkUploadUsersCSV
export def "entity-analytics-monitoring-users-csv PrivmonBulkUploadUsersCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The CSV file to upload. (format: binary)
]: any -> record<errors: table<index: int, message: string, username: string>, stats: record<failedOperations: int, successfulOperations: int, totalOperations: int, uploaded: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/monitoring/users/_csv")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a monitored user
#
# DELETE /api/entity_analytics/monitoring/users/{id}
# operationId: DeletePrivMonUser
export def "entity-analytics-monitoring-users DeletePrivMonUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acknowledged: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/monitoring/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a monitored user
#
# PUT /api/entity_analytics/monitoring/users/{id}
# operationId: UpdatePrivMonUser
# --entity_analytics_monitoring shape: {labels?: list}
# --labels shape: {source_ids?: list, source_integrations?: list, sources?: list}
# --user shape: {is_privileged?: bool, name?: string}
export def "entity-analytics-monitoring-users UpdatePrivMonUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-analytics-monitoring: record # shape: {labels?: list}
  --body-id: string
  --labels: record # shape: {source_ids?: list, source_integrations?: list, sources?: list}
  --user: record # shape: {is_privileged?: bool, name?: string}
]: any -> record<entity_analytics_monitoring: record<labels: list<record>>, id: string, labels: record<source_ids: list<string>, source_integrations: list<string>, sources: list<any>>, user: record<entity: record<attributes: record>, is_privileged: bool, name: string>, _timestamp: string, event: record<_timestamp: string, ingested: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/monitoring/users/($id)")
  let body = {entity_analytics_monitoring: $entity_analytics_monitoring, id: $body_id, labels: $labels, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all monitored users
#
# GET /api/entity_analytics/monitoring/users/list
# operationId: ListPrivMonUsers
export def "entity-analytics-monitoring-users-list ListPrivMonUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kql: string # KQL query to filter the list of monitored users
]: nothing -> table<entity_analytics_monitoring: record<labels: list>, id: string, labels: record<source_ids: list, source_integrations: list, sources: list>, user: record<entity: record, is_privileged: bool, name: string>, _timestamp: string, event: record<_timestamp: string, ingested: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kql" $kql "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity_analytics/monitoring/users/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Installs the privileged access detection package for the Entity Analytics privileged user monitoring experience
#
# POST /api/entity_analytics/privileged_user_monitoring/pad/install
# operationId: InstallPrivilegedAccessDetectionPackage
export def "entity-analytics-privileged-user-monitoring-pad-install InstallPrivilegedAccessDetectionPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/privileged_user_monitoring/pad/install")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the status of the privileged access detection package for the Entity Analytics privileged user monitoring experience
#
# GET /api/entity_analytics/privileged_user_monitoring/pad/status
# operationId: GetPrivilegedAccessDetectionPackageStatus
export def "entity-analytics-privileged-user-monitoring-pad-status GetPrivilegedAccessDetectionPackageStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobs: table<description: string, job_id: string, state: string>, ml_module_setup_status: string, package_installation_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/privileged_user_monitoring/pad/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new watchlist
#
# POST /api/entity_analytics/watchlists
# operationId: CreateWatchlist
# --entitySources item shape: {enabled?: bool, filter?: record, identifierField?: string, indexPattern?: string, integrationName?: string, matchers?: list, name: string, queryRule?: string, range?: record, type: "index"|"entity_analytics_integration"|"store"}
export def "entity-analytics-watchlists CreateWatchlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the watchlist
  --entitySources: list # Optional entity sources to create and link to the watchlist — item shape: {enabled?: bool, filter?: record, identifierField?: string, indexPattern?: string, integrationName?: string, matchers?: list, name: string, queryRule?: string, range?: record, type: "index"|"entity_analytics_integration"|"store"}
  --managed: oneof<nothing, bool> # Indicates if the watchlist is managed by the system
  name: string # Unique name for the watchlist
  riskModifier: float # Risk score modifier associated with the watchlist
]: any -> record<createdAt: string, description: string, entityCount: float, entitySourceIds: list<string>, id: string, managed: bool, name: string, riskModifier: float, updatedAt: string, entitySources: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/watchlists")
  let body = {description: $description, entitySources: $entitySources, managed: $managed, name: $name, riskModifier: $riskModifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a watchlist by ID
#
# GET /api/entity_analytics/watchlists/{id}
# operationId: GetWatchlist
export def "entity-analytics-watchlists GetWatchlist" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, description: string, entityCount: float, entitySourceIds: list<string>, id: string, managed: bool, name: string, riskModifier: float, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/watchlists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing watchlist
#
# PUT /api/entity_analytics/watchlists/{id}
# operationId: UpdateWatchlist
export def "entity-analytics-watchlists UpdateWatchlist" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the watchlist
  --managed: oneof<nothing, bool> # Indicates if the watchlist is managed by the system
  name: string # Unique name of the watchlist
  riskModifier: float # Risk score modifier associated with the watchlist
]: any -> record<createdAt: string, description: string, entityCount: float, entitySourceIds: list<string>, id: string, managed: bool, name: string, riskModifier: float, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/watchlists/($id)")
  let body = {description: $description, managed: $managed, name: $name, riskModifier: $riskModifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload a CSV file to add entities to a watchlist
#
# POST /api/entity_analytics/watchlists/{watchlist_id}/csv_upload
# operationId: UploadWatchlistCsv
export def "entity-analytics-watchlists-csv-upload UploadWatchlistCsv" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The CSV file to upload. (format: binary)
]: any -> record<failed: int, items: table<error: string, matchedEntities: int, status: string>, successful: int, total: int, unmatched: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/watchlists/($watchlist_id)/csv_upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Manually assign entities to a watchlist
#
# POST /api/entity_analytics/watchlists/{watchlist_id}/entities/assign
# operationId: AssignWatchlistEntities
export def "entity-analytics-watchlists-entities-assign AssignWatchlistEntities" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  euids: list # The EUIDs of the entities to assign (e.g. [user:john.doe, host:web-01])
]: any -> record<failed: int, items: table<error: string, euid: string, status: string>, not_found: int, successful: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/watchlists/($watchlist_id)/entities/assign")
  let body = {euids: $euids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually unassign entities from a watchlist
#
# POST /api/entity_analytics/watchlists/{watchlist_id}/entities/unassign
# operationId: UnassignWatchlistEntities
export def "entity-analytics-watchlists-entities-unassign UnassignWatchlistEntities" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  euids: list # The EUIDs of the entities to unassign (e.g. [user:john.doe, host:web-01])
]: any -> record<failed: int, items: table<error: string, euid: string, status: string>, not_found: int, successful: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_analytics/watchlists/($watchlist_id)/entities/unassign")
  let body = {euids: $euids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all watchlists
#
# GET /api/entity_analytics/watchlists/list
# operationId: ListWatchlists
export def "entity-analytics-watchlists-list ListWatchlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<createdAt: string, description: string, entityCount: float, entitySourceIds: list<string>, id: string, managed: bool, name: string, riskModifier: float, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_analytics/watchlists/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize the Entity Store
#
# POST /api/entity_store/enable
# operationId: InitEntityStore
export def "entity-store-enable InitEntityStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay: string # The delay before the transform will run. (default: 1m)
  --docsPerSecond: int # The number of documents per second to process. (default: -1)
  --enrichPolicyExecutionInterval: string # Interval in which enrich policy runs. For example, `"1h"` means the rule runs every hour. Must be less than or equal to half the duration of the lookback period, (e.g. 1h)
  --entityTypes: list
  --fieldHistoryLength: int # The number of historical values to keep for each field. (default: 10)
  --filter: string
  --frequency: string # The frequency at which the transform will run. (default: 1m)
  --indexPattern: string # An additional Elasticsearch index pattern to include as a source for entity data. Merged with the default data view indices when the engine runs. (e.g. logs-*)
  --lookbackPeriod: string # The amount of time the transform looks back to calculate the aggregations. (default: 3h)
  --maxPageSearchSize: int # The initial page size to use for the composite aggregation of each checkpoint. (default: 500)
  --timeout: string # The timeout for initializing the aggregating transform. (default: 180s)
  --timestampField: string # The field to use as the timestamp. (default: @timestamp)
]: any -> record<engines: table<delay: string, docsPerSecond: int, error: record, fieldHistoryLength: int, filter: string, frequency: string, indexPattern: string, lookbackPeriod: string, status: string, timeout: string, timestampField: string, type: string>, succeeded: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_store/enable")
  let body = {delay: $delay, docsPerSecond: $docsPerSecond, enrichPolicyExecutionInterval: $enrichPolicyExecutionInterval, entityTypes: $entityTypes, fieldHistoryLength: $fieldHistoryLength, filter: $filter, frequency: $frequency, indexPattern: $indexPattern, lookbackPeriod: $lookbackPeriod, maxPageSearchSize: $maxPageSearchSize, timeout: $timeout, timestampField: $timestampField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Entity Engines
#
# DELETE /api/entity_store/engines
# operationId: DeleteEntityEngines
export def "entity-store-engines DeleteEntityEngines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityTypes: list # The entity type of the engine ('user', 'host', 'service', 'generic').
  --delete-data: oneof<nothing, bool> # Control flag to also delete the entity data.
]: nothing -> record<deleted: list<string>, still_running: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entityTypes" $entityTypes "multi") (serialize-qp "delete_data" $delete_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity_store/engines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the Entity Engines
#
# GET /api/entity_store/engines
# operationId: ListEntityEngines
export def "entity-store-engines ListEntityEngines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, engines: table<delay: string, docsPerSecond: int, error: record, fieldHistoryLength: int, filter: string, frequency: string, indexPattern: string, lookbackPeriod: string, status: string, timeout: string, timestampField: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_store/engines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Entity Engine
#
# DELETE /api/entity_store/engines/{entityType}
# operationId: DeleteEntityEngine
@deprecated --flag data
export def "entity-store-engines DeleteEntityEngine" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-data: oneof<nothing, bool> # Control flag to also delete the entity data.
  --data: oneof<nothing, bool> # Control flag to also delete the entity data. (DEPRECATED)
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_data" $delete_data "scalar") (serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/entity_store/engines/($entityType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Entity Engine
#
# GET /api/entity_store/engines/{entityType}
# operationId: GetEntityEngine
export def "entity-store-engines GetEntityEngine" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<delay: string, docsPerSecond: int, error: record<action: string, message: string>, fieldHistoryLength: int, filter: string, frequency: string, indexPattern: string, lookbackPeriod: string, status: string, timeout: string, timestampField: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_store/engines/($entityType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize an Entity Engine
#
# POST /api/entity_store/engines/{entityType}/init
# operationId: InitEntityEngine
export def "entity-store-engines-init InitEntityEngine" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay: string # The delay before the transform will run. (default: 1m)
  --docsPerSecond: int # The number of documents per second to process. (default: -1)
  --enrichPolicyExecutionInterval: string # Interval in which enrich policy runs. For example, `"1h"` means the rule runs every hour. Must be less than or equal to half the duration of the lookback period, (e.g. 1h)
  --fieldHistoryLength: int # The number of historical values to keep for each field. (default: 10)
  --filter: string
  --frequency: string # The frequency at which the transform will run. (default: 1m)
  --indexPattern: string # An additional Elasticsearch index pattern to include as a source for entity data. Merged with the default data view indices when the engine runs. (e.g. logs-*)
  --lookbackPeriod: string # The amount of time the transform looks back to calculate the aggregations. (default: 3h)
  --maxPageSearchSize: int # The initial page size to use for the composite aggregation of each checkpoint. (default: 500)
  --timeout: string # The timeout for initializing the aggregating transform. (default: 180s)
  --timestampField: string # The field to use as the timestamp for the entity type. (default: @timestamp)
]: any -> record<delay: string, docsPerSecond: int, error: record<action: string, message: string>, fieldHistoryLength: int, filter: string, frequency: string, indexPattern: string, lookbackPeriod: string, status: string, timeout: string, timestampField: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_store/engines/($entityType)/init")
  let body = {delay: $delay, docsPerSecond: $docsPerSecond, enrichPolicyExecutionInterval: $enrichPolicyExecutionInterval, fieldHistoryLength: $fieldHistoryLength, filter: $filter, frequency: $frequency, indexPattern: $indexPattern, lookbackPeriod: $lookbackPeriod, maxPageSearchSize: $maxPageSearchSize, timeout: $timeout, timestampField: $timestampField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start an Entity Engine
#
# POST /api/entity_store/engines/{entityType}/start
# operationId: StartEntityEngine
export def "entity-store-engines-start StartEntityEngine" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<started: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_store/engines/($entityType)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop an Entity Engine
#
# POST /api/entity_store/engines/{entityType}/stop
# operationId: StopEntityEngine
export def "entity-store-engines-stop StopEntityEngine" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stopped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_store/engines/($entityType)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply DataView indices to all installed engines
#
# POST /api/entity_store/engines/apply_dataview_indices
# operationId: ApplyEntityEngineDataviewIndices
export def "entity-store-engines-apply-dataview-indices ApplyEntityEngineDataviewIndices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: table<changes: record, type: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity_store/engines/apply_dataview_indices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an entity in Entity Store
#
# DELETE /api/entity_store/entities/{entityType}
# operationId: DeleteSingleEntity
export def "entity-store-entities DeleteSingleEntity" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # Identifier of the entity to be deleted, commonly entity.id value. (e.g. arn:aws:iam::123456789012:user/jane.doe)
]: any -> record<deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity_store/entities/($entityType)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert an entity in Entity Store
#
# PUT /api/entity_store/entities/{entityType}
# operationId: UpsertEntity
# --asset shape: {business_unit?: string, criticality?: "low_impact"|"medium_impact"|"high_impact"|"extreme_impact", environment?: string, id?: string, model?: string, name?: string, owner?: string, serial_number?: string, vendor?: string}
# --entity shape: {attributes?: record, behaviors?: record, EngineMetadata?: record, id: string, lifecycle?: record, name?: string, relationships?: record, risk?: record, source?: string, sub_type?: string, type?: string}
# --event shape: {ingested?: string}
# --user shape: {domain?: list, email?: list, full_name?: list, hash?: list, id?: list, name: string, risk?: record, roles?: list}
# --host shape: {architecture?: list, domain?: list, entity?: record, hostname?: list, id?: list, ip?: list, mac?: list, name: string, os?: record, risk?: record, type?: list}
# --service shape: {entity?: record, name: string, risk?: record}
export def "entity-store-entities UpsertEntity" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, allows updating protected fields. (default: false)
  --timestamp: string # The time the entity record was last updated. (format: date-time)
  --asset: record # Asset metadata associated with the entity. — shape: {business_unit?: string, criticality?: "low_impact"|"medium_impact"|"high_impact"|"extreme_impact", environment?: string, id?: string, model?: string, name?: string, owner?: string, serial_number?: string, vendor?: string}
  --entity: record # Core entity fields shared across all entity types. The `entity` namespace is a root-level field in the Entity Store latest index. — shape: {attributes?: record, behaviors?: record, EngineMetadata?: record, id: string, lifecycle?: record, name?: string, relationships?: record, risk?: record, source?: string, sub_type?: string, type?: string}
  --event: record # shape: {ingested?: string}
  --user: record # Elastic Common Schema (ECS) user fields collected on the entity. — shape: {domain?: list, email?: list, full_name?: list, hash?: list, id?: list, name: string, risk?: record, roles?: list}
  --host: record # Elastic Common Schema (ECS) host fields collected on the entity. — shape: {architecture?: list, domain?: list, entity?: record, hostname?: list, id?: list, ip?: list, mac?: list, name: string, os?: record, risk?: record, type?: list}
  --service: record # Elastic Common Schema (ECS) service fields collected on the entity. — shape: {entity?: record, name: string, risk?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/entity_store/entities/($entityType)" $qp)
  let body = {@timestamp: $timestamp, asset: $asset, entity: $entity, event: $event, user: $user, host: $host, service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert many entities in Entity Store
#
# PUT /api/entity_store/entities/bulk
# operationId: UpsertEntitiesBulk
# --entities item shape: {record: any, type: "user"|"host"|"service"|"generic"}
export def "entity-store-entities-bulk UpsertEntitiesBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, allows updating protected fields. (default: false)
  entities: list # The entities to create or update. — item shape: {record: any, type: "user"|"host"|"service"|"generic"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity_store/entities/bulk" $qp)
  let body = {entities: $entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Entity Store Entities
#
# GET /api/entity_store/entities/list
# operationId: ListEntities
export def "entity-store-entities-list ListEntities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-field: string # Field to sort results by. (e.g. entity.name)
  --sort-order: string@sort-order-completer # Sort order.
  --page: int # Page number to return (1-indexed). (e.g. 1)
  --per-page: int # Number of entities per page. (e.g. 10)
  --filterQuery: string # An ES query to filter by.
  --entity-types: list # Entity types to include in the results.
]: nothing -> record<inspect: record<dsl: list<string>, response: list<string>>, page: int, per_page: int, records: list<any>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filterQuery" $filterQuery "scalar") (serialize-qp "entity_types" $entity_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity_store/entities/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of the Entity Store
#
# GET /api/entity_store/status
# operationId: GetEntityStoreStatus
export def "entity-store-status GetEntityStoreStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-components: oneof<nothing, bool> # If true, returns a detailed status of each engine including all its components. (e.g. true)
]: nothing -> record<engines: table<delay: string, docsPerSecond: int, error: record, fieldHistoryLength: int, filter: string, frequency: string, indexPattern: string, lookbackPeriod: string, status: string, timeout: string, timestampField: string, type: string, components: list>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_components" $include_components "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity_store/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an exception list
#
# DELETE /api/exception_lists
# operationId: DeleteExceptionList
export def "exception-lists DeleteExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Exception list's identifier. Either `id` or `list_id` must be specified. (format: nonempty, e.g. 9e5fc75a-a3da-46c5-96e3-a2ec59c6bb85)
  --list-id: string # Human readable exception list string identifier, e.g. `trusted-linux-processes`. Either `id` or `list_id` must be specified. (format: nonempty, e.g. simple_list)
  --namespace-type: string@namespace-type-completer # `single` deletes the list in the current Kibana space; `agnostic` deletes a global list. Must match the list you are removing when using `list_id` or `id`.
]: nothing -> record<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get exception list details
#
# GET /api/exception_lists
# operationId: ReadExceptionList
export def "exception-lists ReadExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Exception list's identifier. Either `id` or `list_id` must be specified. (format: nonempty, e.g. 9e5fc75a-a3da-46c5-96e3-a2ec59c6bb85)
  --list-id: string # Human readable exception list string identifier, e.g. `trusted-linux-processes`. Either `id` or `list_id` must be specified. (format: nonempty, e.g. simple_list)
  --namespace-type: string@namespace-type-completer # When `single`, the list is resolved in the current Kibana space. When `agnostic`, the list is a global (space-agnostic) container. Required for looking up the correct list when `list_id` is not unique.
]: nothing -> record<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an exception list
#
# POST /api/exception_lists
# operationId: CreateExceptionList
export def "exception-lists CreateExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Describes the exception list. (e.g. This list tracks allowlisted values.)
  --list-id: string # The exception list's human-readable string identifier.  For endpoint artifacts, use one of the following values:  * `endpoint_list`: [Elastic Endpoint exception list](https://www.elastic.co/docs/solutions/security/detect-and-alert/add-manage-exceptions) * `endpoint_trusted_apps`: [Trusted applications list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/trusted-applications) * `endpoint_trusted_devices`: [Trusted devices list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/trusted-devices) * `endpoint_event_filters`: [Event filters list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/event-filters) * `endpoint_host_isolation_exceptions`: [Host isolation exceptions list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/host-isolation-exceptions) * `endpoint_blocklists`: [Blocklists list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/blocklist)  (format: nonempty, e.g. simple_list)
  --meta: record # Placeholder for metadata about the list container.
  name: string # The name of the exception list. (e.g. My exception list)
  --namespace-type: string@namespace-type-completer # Determines whether the exception container is available in all Kibana spaces or just the space in which it is created, where:  - `single`: Only available in the Kibana space in which it is created. - `agnostic`: Available in all Kibana spaces.  For endpoint artifacts, the `namespace_type` must always be `agnostic`. Space awareness for endpoint artifacts is enforced based on Elastic Defend policy assignments.
  --os-types: list # Use this field to specify the operating system. Only enter one value.
  --tags: list # String array containing words and phrases to help categorize exception containers.
  type: string@type-completer-2 # The type of exception list to be created. Different list types may denote where they can be utilized.
  --version: int # The document version, automatically increasd on updates.
]: any -> record<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/exception_lists")
  let body = {description: $description, list_id: $list_id, meta: $meta, name: $name, namespace_type: $namespace_type, os_types: $os_types, tags: $tags, type: $type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an exception list
#
# PUT /api/exception_lists
# operationId: UpdateExceptionList
export def "exception-lists UpdateExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version id, normally returned by the API when the item was retrieved. Use it ensure updates are done against the latest version.
  description: string # Describes the exception list. (e.g. This list tracks allowlisted values.)
  --id: string # Exception list's identifier. (format: nonempty, e.g. 9e5fc75a-a3da-46c5-96e3-a2ec59c6bb85)
  --list-id: string # The exception list's human-readable string identifier.  For endpoint artifacts, use one of the following values:  * `endpoint_list`: [Elastic Endpoint exception list](https://www.elastic.co/docs/solutions/security/detect-and-alert/add-manage-exceptions) * `endpoint_trusted_apps`: [Trusted applications list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/trusted-applications) * `endpoint_trusted_devices`: [Trusted devices list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/trusted-devices) * `endpoint_event_filters`: [Event filters list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/event-filters) * `endpoint_host_isolation_exceptions`: [Host isolation exceptions list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/host-isolation-exceptions) * `endpoint_blocklists`: [Blocklists list](https://www.elastic.co/docs/solutions/security/manage-elastic-defend/blocklist)  (format: nonempty, e.g. simple_list)
  --meta: record # Placeholder for metadata about the list container.
  name: string # The name of the exception list. (e.g. My exception list)
  --namespace-type: string@namespace-type-completer # Determines whether the exception container is available in all Kibana spaces or just the space in which it is created, where:  - `single`: Only available in the Kibana space in which it is created. - `agnostic`: Available in all Kibana spaces.  For endpoint artifacts, the `namespace_type` must always be `agnostic`. Space awareness for endpoint artifacts is enforced based on Elastic Defend policy assignments.
  --os-types: list # Use this field to specify the operating system. Only enter one value.
  --tags: list # String array containing words and phrases to help categorize exception containers.
  type: string@type-completer-2 # The type of exception list to be created. Different list types may denote where they can be utilized.
  --version: int # The document version, automatically increasd on updates.
]: any -> record<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/exception_lists")
  let body = {_version: $version, description: $description, id: $id, list_id: $list_id, meta: $meta, name: $name, namespace_type: $namespace_type, os_types: $os_types, tags: $tags, type: $type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate an exception list
#
# POST /api/exception_lists/_duplicate
# operationId: DuplicateExceptionList
export def "exception-lists-duplicate DuplicateExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: string # The `list_id` of the existing exception list to copy (source list). (format: nonempty, e.g. simple_list)
  --namespace-type: string@namespace-type-completer # Scope in which the source list is defined (`single` = current space, `agnostic` = all spaces).
  --include-expired-exceptions: string@include-expired-exceptions-completer # Determines whether to include expired exceptions in the duplicated list. Expiration date defined by `expire_time`. (default: true, e.g. true)
]: nothing -> record<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar") (serialize-qp "include_expired_exceptions" $include_expired_exceptions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/_duplicate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export an exception list
#
# POST /api/exception_lists/_export
# operationId: ExportExceptionList
export def "exception-lists-export ExportExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Exception list's internal `id` (UUID) returned on create; use with `list_id` and `namespace_type` for an unambiguous target. (format: nonempty, e.g. 9e5fc75a-a3da-46c5-96e3-a2ec59c6bb85)
  --list-id: string # Human-readable `list_id` of the exception list to export, as shown in the UI and API responses. (format: nonempty, e.g. simple_list)
  --namespace-type: string@namespace-type-completer # `single` exports a list in the current Kibana space; `agnostic` exports a global (space-agnostic) list.
  --include-expired-exceptions: string@include-expired-exceptions-completer # Determines whether to include expired exceptions in the exported list. Expiration date defined by `expire_time`. (default: true, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar") (serialize-qp "include_expired_exceptions" $include_expired_exceptions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/_export" $qp)
  let accept_val = "application/ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get exception lists
#
# GET /api/exception_lists/_find
# operationId: FindExceptionLists
export def "exception-lists-find FindExceptionLists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Filters the returned results according to the value of the specified field.  Uses the `so type.field name:field` value syntax, where `so type` can be:  - `exception-list`: Specify a space-aware exception list. - `exception-list-agnostic`: Specify an exception list that is shared across spaces.  (e.g. exception-list.attributes.name:%Detection%20List)
  --namespace-type: list # Determines whether the returned containers are Kibana associated with a Kibana space or available in all spaces (`agnostic` or `single`)  (default: [single])
  --page: int # The page number to return (e.g. 1)
  --per-page: int # The number of exception lists to return per page (e.g. 20)
  --sort-field: string # Determines which field is used to sort the results. (e.g. name)
  --sort-order: string@sort-order-completer # Determines the sort order, which can be `desc` or `asc`. (e.g. desc)
]: nothing -> record<data: table<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list, tags: list, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int>, page: int, per_page: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "namespace_type" $namespace_type "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import an exception list
#
# POST /api/exception_lists/_import
# operationId: ImportExceptionList
export def "exception-lists-import ImportExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: oneof<nothing, bool> # Determines whether existing exception lists with the same `list_id` are overwritten. If any exception items have the same `item_id`, those are also overwritten.  (default: false, e.g. false)
  --as-new-list: oneof<nothing, bool> # Determines whether the list being imported will have a new `list_id` generated. Additional `item_id`'s are generated for each exception item. Both the exception list and its items are overwritten.  (default: false, e.g. false)
  --file: string # A `.ndjson` file containing the exception list (format: binary, e.g. {"_version":"WzExNDU5LDFd","created_at":"2025-01-09T16:18:17.757Z","created_by":"elastic","description":"This is a sample detection type exception","id":"c86c2da0-2ab6-4343-b81c-216ef27e8d75","immutable":false,"list_id":"simple_list","name":"Sample Detection Exception List","namespace_type":"single","os_types":[],"tags":["user added string for a tag","malware"],"tie_breaker_id":"cf4a7b92-732d-47f0-a0d5-49a35a1736bf","type":"detection","updated_at":"2025-01-09T16:18:17.757Z","updated_by":"elastic","version":1} {"_version":"WzExNDYxLDFd","comments":[],"created_at":"2025-01-09T16:18:42.308Z","created_by":"elastic","description":"This is a sample endpoint type exception","entries":[{"type":"exists","field":"actingProcess.file.signer","operator":"excluded"},{"type":"match_any","field":"host.name","value":["some host","another host"],"operator":"included"}],"id":"f37597ce-eaa7-4b64-9100-4301118f6806","item_id":"simple_list_item","list_id":"simple_list","name":"Sample Endpoint Exception List","namespace_type":"single","os_types":["linux"],"tags":["user added string for a tag","malware"],"tie_breaker_id":"4ca3ef3e-9721-42c0-8107-cf47e094d40f","type":"simple","updated_at":"2025-01-09T16:18:42.308Z","updated_by":"elastic"} )
]: any -> record<errors: table<error: record, id: string, item_id: string, list_id: string>, success: bool, success_count: int, success_count_exception_list_items: int, success_count_exception_lists: int, success_exception_list_items: bool, success_exception_lists: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overwrite" $overwrite "scalar") (serialize-qp "as_new_list" $as_new_list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/_import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete an exception list item
#
# DELETE /api/exception_lists/items
# operationId: DeleteExceptionListItem
export def "exception-lists-items DeleteExceptionListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Exception item's identifier. Either `id` or `item_id` must be specified (format: nonempty, e.g. 71a9f4b2-c85c-49b4-866f-c71eb9e67da2)
  --item-id: string # Human readable exception item string identifier, e.g. `trusted-linux-processes`. Either `id` or `item_id` must be specified (format: nonempty, e.g. simple_list_item)
  --namespace-type: string@namespace-type-completer # `single` deletes the item in the current Kibana space; `agnostic` deletes an item in a space-agnostic list. Must match the list that owns the item.
]: nothing -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "item_id" $item_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an exception list item
#
# GET /api/exception_lists/items
# operationId: ReadExceptionListItem
export def "exception-lists-items ReadExceptionListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Exception list item's identifier. Either `id` or `item_id` must be specified. (format: nonempty, e.g. 71a9f4b2-c85c-49b4-866f-c71eb9e67da2)
  --item-id: string # Human readable exception item string identifier, e.g. `trusted-linux-processes`. Either `id` or `item_id` must be specified. (format: nonempty, e.g. simple_list_item)
  --namespace-type: string@namespace-type-completer # `single` fetches the item in the current space; `agnostic` fetches a global (space-agnostic) item. Must match how the list was created.
]: nothing -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "item_id" $item_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an exception list item
#
# POST /api/exception_lists/items
# operationId: CreateExceptionListItem
export def "exception-lists-items CreateExceptionListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/exception_lists/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an exception list item
#
# PUT /api/exception_lists/items
# operationId: UpdateExceptionListItem
export def "exception-lists-items UpdateExceptionListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<_version: string, comments: table<comment: string, created_at: string, created_by: string, id: string, updated_at: string, updated_by: string>, created_at: string, created_by: string, description: string, entries: list<any>, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/exception_lists/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get exception list items
#
# GET /api/exception_lists/items/_find
# operationId: FindExceptionListItems
export def "exception-lists-items-find FindExceptionListItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: list # The `list_id`s of the items to fetch.
  --filter: list # Filters the returned results according to the value of the specified field, using the `<field name>:<field value>` syntax.  (default: [])
  --namespace-type: list # Determines whether the returned containers are Kibana associated with a Kibana space or available in all spaces (`agnostic` or `single`)  (default: [single])
  --search: string # Free-text search term applied to exception list item fields (for example a hostname or file path fragment).  (e.g. host.name)
  --page: int # The page number to return (e.g. 1)
  --per-page: int # The number of exception list items to return per page (e.g. 20)
  --sort-field: string # Determines which field is used to sort the results. (format: nonempty, e.g. name)
  --sort-order: string@sort-order-completer # Determines the sort order, which can be `desc` or `asc`. (e.g. desc)
]: nothing -> record<data: table<_version: string, comments: list, created_at: string, created_by: string, description: string, entries: list, expire_time: string, id: string, item_id: string, list_id: string, meta: record, name: string, namespace_type: string, os_types: list, tags: list, tie_breaker_id: string, type: string, updated_at: string, updated_by: string>, page: int, per_page: int, pit: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "namespace_type" $namespace_type "multi") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/items/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an exception list summary
#
# GET /api/exception_lists/summary
# operationId: ReadExceptionListSummary
export def "exception-lists-summary ReadExceptionListSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Exception list's identifier generated upon creation. (format: nonempty, e.g. 9e5fc75a-a3da-46c5-96e3-a2ec59c6bb85)
  --list-id: string # Exception list's human readable identifier. (format: nonempty, e.g. simple_list)
  --namespace-type: string@namespace-type-completer # `single` returns summary for a list in the current space; `agnostic` for a space-agnostic list. Must line up with `id` / `list_id` used to look up the list.
  --filter: string # Search filter clause (e.g. exception-list-agnostic.attributes.tags:"policy:policy-1" OR exception-list-agnostic.attributes.tags:"policy:all")
]: nothing -> record<linux: int, macos: int, total: int, windows: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "namespace_type" $namespace_type "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/exception_lists/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a shared exception list
#
# POST /api/exceptions/shared
# operationId: CreateSharedExceptionList
export def "exceptions-shared CreateSharedExceptionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Describes the exception list. (e.g. This list tracks allowlisted values.)
  name: string # The name of the exception list. (e.g. My exception list)
]: any -> record<_version: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, list_id: string, meta: record, name: string, namespace_type: string, os_types: list<string>, tags: list<string>, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/exceptions/shared")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent binary download sources
#
# GET /api/fleet/agent_download_sources
# operationId: get-fleet-agent-download-sources
export def "fleet-agent-download-sources get-fleet-agent-download-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<auth: record, host: string, id: string, is_default: bool, name: string, proxy_id: string, secrets: record, ssl: record>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agent_download_sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an agent binary download source
#
# POST /api/fleet/agent_download_sources
# operationId: post-fleet-agent-download-sources
# --auth shape: {api_key?: string, headers?: list, password?: string, username?: string}
# --secrets shape: {auth?: record, ssl?: record}
# --ssl shape: {certificate?: string, certificate_authorities?: list, key?: string}
export def "fleet-agent-download-sources post-fleet-agent-download-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body-auth: record # nullable — shape: {api_key?: string, headers?: list, password?: string, username?: string}
  host: string # format: uri
  --id: string
  --is-default: oneof<nothing, bool> # default: false
  name: string
  --proxy-id: string # The ID of the proxy to use for this download source. See the proxies API for more information. (nullable)
  --secrets: record # shape: {auth?: record, ssl?: record}
  --ssl: record # shape: {certificate?: string, certificate_authorities?: list, key?: string}
]: any -> record<item: record<auth: record<api_key: string, headers: list, password: string, username: string>, host: string, id: string, is_default: bool, name: string, proxy_id: string, secrets: record<auth: record, ssl: record>, ssl: record<certificate: string, certificate_authorities: list, key: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agent_download_sources")
  let body = {auth: $body_auth, host: $host, id: $id, is_default: $is_default, name: $name, proxy_id: $proxy_id, secrets: $secrets, ssl: $ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an agent binary download source
#
# DELETE /api/fleet/agent_download_sources/{sourceId}
# operationId: delete-fleet-agent-download-sources-sourceid
export def "fleet-agent-download-sources delete-fleet-agent-download-sources-sourceid" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agent_download_sources/($sourceId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an agent binary download source
#
# GET /api/fleet/agent_download_sources/{sourceId}
# operationId: get-fleet-agent-download-sources-sourceid
export def "fleet-agent-download-sources get-fleet-agent-download-sources-sourceid" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<auth: record<api_key: string, headers: list, password: string, username: string>, host: string, id: string, is_default: bool, name: string, proxy_id: string, secrets: record<auth: record, ssl: record>, ssl: record<certificate: string, certificate_authorities: list, key: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agent_download_sources/($sourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent binary download source
#
# PUT /api/fleet/agent_download_sources/{sourceId}
# operationId: put-fleet-agent-download-sources-sourceid
# --auth shape: {api_key?: string, headers?: list, password?: string, username?: string}
# --secrets shape: {auth?: record, ssl?: record}
# --ssl shape: {certificate?: string, certificate_authorities?: list, key?: string}
export def "fleet-agent-download-sources put-fleet-agent-download-sources-sourceid" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body-auth: record # nullable — shape: {api_key?: string, headers?: list, password?: string, username?: string}
  host: string # format: uri
  --id: string
  --is-default: oneof<nothing, bool> # default: false
  name: string
  --proxy-id: string # The ID of the proxy to use for this download source. See the proxies API for more information. (nullable)
  --secrets: record # shape: {auth?: record, ssl?: record}
  --ssl: record # shape: {certificate?: string, certificate_authorities?: list, key?: string}
]: any -> record<item: record<auth: record<api_key: string, headers: list, password: string, username: string>, host: string, id: string, is_default: bool, name: string, proxy_id: string, secrets: record<auth: record, ssl: record>, ssl: record<certificate: string, certificate_authorities: list, key: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agent_download_sources/($sourceId)")
  let body = {auth: $body_auth, host: $host, id: $id, is_default: $is_default, name: $name, proxy_id: $proxy_id, secrets: $secrets, ssl: $ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent policies
#
# GET /api/fleet/agent_policies
# operationId: get-fleet-agent-policies
export def "fleet-agent-policies get-fleet-agent-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number
  --perPage: float # Number of results per page
  --sortField: string # Field to sort results by
  --sortOrder: string@sortOrder-completer # Sort order, ascending or descending
  --showUpgradeable: oneof<nothing, bool> # When true, only show policies with upgradeable agents
  --kuery: string # A KQL query string to filter results
  --noAgentCount: oneof<nothing, bool> # use withAgentCount instead
  --withAgentCount: oneof<nothing, bool> # get policies with agent count
  --full: oneof<nothing, bool> # get full policies with package policies populated
  --format: string@format-completer # Format for the response: simplified or legacy
]: nothing -> record<items: table<advanced_settings: record, agent_features: list, agentless: record, agents: float, agents_per_version: list, created_at: string, data_output_id: string, description: string, download_source_id: string, fips_agents: float, fleet_server_host_id: string, global_data_tags: list, has_agent_version_conditions: bool, has_fleet_server: bool, id: string, inactivity_timeout: float, is_default: bool, is_default_fleet_server: bool, is_managed: bool, is_preconfigured: bool, is_protected: bool, is_verifier: bool, keep_monitoring_alive: bool, min_agent_version: string, monitoring_diagnostics: record, monitoring_enabled: list, monitoring_http: record, monitoring_output_id: string, monitoring_pprof_enabled: bool, name: string, namespace: string, overrides: record, package_agent_version_conditions: list, package_policies: any, required_versions: list, revision: float, schema_version: string, space_ids: list, status: string, supports_agentless: bool, unenroll_timeout: float, unprivileged_agents: float, updated_at: string, updated_by: string, version: string>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "showUpgradeable" $showUpgradeable "scalar") (serialize-qp "kuery" $kuery "scalar") (serialize-qp "noAgentCount" $noAgentCount "scalar") (serialize-qp "withAgentCount" $withAgentCount "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agent_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an agent policy
#
# POST /api/fleet/agent_policies
# operationId: post-fleet-agent-policies
# --advanced_settings shape: {agent_download_target_directory?: any, agent_download_timeout?: any, agent_features_disable_policy_change_acks_enabled?: any, agent_internal?: any, agent_limits_go_max_procs?: any, agent_logging_files_interval?: any, agent_logging_files_keepfiles?: any, agent_logging_files_rotateeverybytes?: any, agent_logging_level?: any, agent_logging_metrics_period?: any, agent_logging_to_files?: any, agent_monitoring_runtime_experimental?: any}
# --agent_features item shape: {enabled: bool, name: string}
# --agentless shape: {cloud_connectors?: record, cluster_id?: string, resources?: record}
# --global_data_tags item shape: {name: string, value: any}
# --monitoring_diagnostics shape: {limit?: record, uploader?: record}
# --monitoring_http shape: {buffer?: record, enabled?: bool, host?: string, port?: float}
# --package_agent_version_conditions item shape: {name: string, title: string, version_condition: string}
# --required_versions item shape: {percentage: float, version: string}
@deprecated --flag supports-agentless
export def "fleet-agent-policies post-fleet-agent-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sys-monitoring: oneof<nothing, bool> # Whether to add the system integration to the new agent policy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --advanced-settings: record # shape: {agent_download_target_directory?: any, agent_download_timeout?: any, agent_features_disable_policy_change_acks_enabled?: any, agent_internal?: any, agent_limits_go_max_procs?: any, agent_logging_files_interval?: any, agent_logging_files_keepfiles?: any, agent_logging_files_rotateeverybytes?: any, agent_logging_level?: any, agent_logging_metrics_period?: any, agent_logging_to_files?: any, agent_monitoring_runtime_experimental?: any}
  --agent-features: list # item shape: {enabled: bool, name: string}
  --agentless: record # shape: {cloud_connectors?: record, cluster_id?: string, resources?: record}
  --bumpRevision: oneof<nothing, bool>
  --data-output-id: string # nullable
  --description: string
  --download-source-id: string # nullable
  --fleet-server-host-id: string # nullable
  --force: oneof<nothing, bool>
  --global-data-tags: list # User defined data tags that are added to all of the inputs. The values can be strings or numbers. — item shape: {name: string, value: any}
  --has-agent-version-conditions: oneof<nothing, bool>
  --has-fleet-server: oneof<nothing, bool>
  --id: string
  --inactivity-timeout: float # default: 1209600
  --is-default: oneof<nothing, bool>
  --is-default-fleet-server: oneof<nothing, bool>
  --is-managed: oneof<nothing, bool>
  --is-protected: oneof<nothing, bool>
  --is-verifier: oneof<nothing, bool>
  --keep-monitoring-alive: oneof<nothing, bool> # When set to true, monitoring will be enabled but logs/metrics collection will be disabled (nullable)
  --min-agent-version: string # nullable
  --monitoring-diagnostics: record # shape: {limit?: record, uploader?: record}
  --monitoring-enabled: list
  --monitoring-http: record # shape: {buffer?: record, enabled?: bool, host?: string, port?: float}
  --monitoring-output-id: string # nullable
  --monitoring-pprof-enabled: oneof<nothing, bool>
  name: string
  namespace: string
  --overrides: record # Override settings that are defined in the agent policy. Input settings cannot be overridden. The override option should be used only in unusual circumstances and not as a routine procedure. (nullable)
  --package-agent-version-conditions: list # nullable — item shape: {name: string, title: string, version_condition: string}
  --required-versions: list # nullable — item shape: {percentage: float, version: string}
  --space-ids: list
  --supports-agentless: oneof<nothing, bool> # Indicates whether the agent policy supports agentless integrations. Deprecated in favor of the Fleet agentless policies API. (DEPRECATED, nullable)
  --unenroll-timeout: float
]: any -> record<item: record<advanced_settings: record<agent_download_target_directory: any, agent_download_timeout: any, agent_features_disable_policy_change_acks_enabled: any, agent_internal: any, agent_limits_go_max_procs: any, agent_logging_files_interval: any, agent_logging_files_keepfiles: any, agent_logging_files_rotateeverybytes: any, agent_logging_level: any, agent_logging_metrics_period: any, agent_logging_to_files: any, agent_monitoring_runtime_experimental: any>, agent_features: list<record>, agentless: record<cloud_connectors: record, cluster_id: string, resources: record>, agents: float, agents_per_version: list<record>, created_at: string, data_output_id: string, description: string, download_source_id: string, fips_agents: float, fleet_server_host_id: string, global_data_tags: list<record>, has_agent_version_conditions: bool, has_fleet_server: bool, id: string, inactivity_timeout: float, is_default: bool, is_default_fleet_server: bool, is_managed: bool, is_preconfigured: bool, is_protected: bool, is_verifier: bool, keep_monitoring_alive: bool, min_agent_version: string, monitoring_diagnostics: record<limit: record, uploader: record>, monitoring_enabled: list<string>, monitoring_http: record<buffer: record, enabled: bool, host: string, port: float>, monitoring_output_id: string, monitoring_pprof_enabled: bool, name: string, namespace: string, overrides: record, package_agent_version_conditions: list<record>, package_policies: any, required_versions: list<record>, revision: float, schema_version: string, space_ids: list<string>, status: string, supports_agentless: bool, unenroll_timeout: float, unprivileged_agents: float, updated_at: string, updated_by: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sys_monitoring" $sys_monitoring "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agent_policies" $qp)
  let body = {advanced_settings: $advanced_settings, agent_features: $agent_features, agentless: $agentless, bumpRevision: $bumpRevision, data_output_id: $data_output_id, description: $description, download_source_id: $download_source_id, fleet_server_host_id: $fleet_server_host_id, force: $force, global_data_tags: $global_data_tags, has_agent_version_conditions: $has_agent_version_conditions, has_fleet_server: $has_fleet_server, id: $id, inactivity_timeout: $inactivity_timeout, is_default: $is_default, is_default_fleet_server: $is_default_fleet_server, is_managed: $is_managed, is_protected: $is_protected, is_verifier: $is_verifier, keep_monitoring_alive: $keep_monitoring_alive, min_agent_version: $min_agent_version, monitoring_diagnostics: $monitoring_diagnostics, monitoring_enabled: $monitoring_enabled, monitoring_http: $monitoring_http, monitoring_output_id: $monitoring_output_id, monitoring_pprof_enabled: $monitoring_pprof_enabled, name: $name, namespace: $namespace, overrides: $overrides, package_agent_version_conditions: $package_agent_version_conditions, required_versions: $required_versions, space_ids: $space_ids, supports_agentless: $supports_agentless, unenroll_timeout: $unenroll_timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk get agent policies
#
# POST /api/fleet/agent_policies/_bulk_get
# operationId: post-fleet-agent-policies-bulk-get
export def "fleet-agent-policies-bulk-get post-fleet-agent-policies-bulk-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --full: oneof<nothing, bool> # get full policies with package policies populated
  ids: list # list of package policy ids
  --ignoreMissing: oneof<nothing, bool>
]: any -> record<items: table<advanced_settings: record, agent_features: list, agentless: record, agents: float, agents_per_version: list, created_at: string, data_output_id: string, description: string, download_source_id: string, fips_agents: float, fleet_server_host_id: string, global_data_tags: list, has_agent_version_conditions: bool, has_fleet_server: bool, id: string, inactivity_timeout: float, is_default: bool, is_default_fleet_server: bool, is_managed: bool, is_preconfigured: bool, is_protected: bool, is_verifier: bool, keep_monitoring_alive: bool, min_agent_version: string, monitoring_diagnostics: record, monitoring_enabled: list, monitoring_http: record, monitoring_output_id: string, monitoring_pprof_enabled: bool, name: string, namespace: string, overrides: record, package_agent_version_conditions: list, package_policies: any, required_versions: list, revision: float, schema_version: string, space_ids: list, status: string, supports_agentless: bool, unenroll_timeout: float, unprivileged_agents: float, updated_at: string, updated_by: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agent_policies/_bulk_get" $qp)
  let body = {full: $full, ids: $ids, ignoreMissing: $ignoreMissing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an agent policy
#
# GET /api/fleet/agent_policies/{agentPolicyId}
# operationId: get-fleet-agent-policies-agentpolicyid
export def "fleet-agent-policies get-fleet-agent-policies-agentpolicyid" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
]: nothing -> record<item: record<advanced_settings: record<agent_download_target_directory: any, agent_download_timeout: any, agent_features_disable_policy_change_acks_enabled: any, agent_internal: any, agent_limits_go_max_procs: any, agent_logging_files_interval: any, agent_logging_files_keepfiles: any, agent_logging_files_rotateeverybytes: any, agent_logging_level: any, agent_logging_metrics_period: any, agent_logging_to_files: any, agent_monitoring_runtime_experimental: any>, agent_features: list<record>, agentless: record<cloud_connectors: record, cluster_id: string, resources: record>, agents: float, agents_per_version: list<record>, created_at: string, data_output_id: string, description: string, download_source_id: string, fips_agents: float, fleet_server_host_id: string, global_data_tags: list<record>, has_agent_version_conditions: bool, has_fleet_server: bool, id: string, inactivity_timeout: float, is_default: bool, is_default_fleet_server: bool, is_managed: bool, is_preconfigured: bool, is_protected: bool, is_verifier: bool, keep_monitoring_alive: bool, min_agent_version: string, monitoring_diagnostics: record<limit: record, uploader: record>, monitoring_enabled: list<string>, monitoring_http: record<buffer: record, enabled: bool, host: string, port: float>, monitoring_output_id: string, monitoring_pprof_enabled: bool, name: string, namespace: string, overrides: record, package_agent_version_conditions: list<record>, package_policies: any, required_versions: list<record>, revision: float, schema_version: string, space_ids: list<string>, status: string, supports_agentless: bool, unenroll_timeout: float, unprivileged_agents: float, updated_at: string, updated_by: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent policy
#
# PUT /api/fleet/agent_policies/{agentPolicyId}
# operationId: put-fleet-agent-policies-agentpolicyid
# --advanced_settings shape: {agent_download_target_directory?: any, agent_download_timeout?: any, agent_features_disable_policy_change_acks_enabled?: any, agent_internal?: any, agent_limits_go_max_procs?: any, agent_logging_files_interval?: any, agent_logging_files_keepfiles?: any, agent_logging_files_rotateeverybytes?: any, agent_logging_level?: any, agent_logging_metrics_period?: any, agent_logging_to_files?: any, agent_monitoring_runtime_experimental?: any}
# --agent_features item shape: {enabled: bool, name: string}
# --agentless shape: {cloud_connectors?: record, cluster_id?: string, resources?: record}
# --global_data_tags item shape: {name: string, value: any}
# --monitoring_diagnostics shape: {limit?: record, uploader?: record}
# --monitoring_http shape: {buffer?: record, enabled?: bool, host?: string, port?: float}
# --package_agent_version_conditions item shape: {name: string, title: string, version_condition: string}
# --required_versions item shape: {percentage: float, version: string}
@deprecated --flag supports-agentless
export def "fleet-agent-policies put-fleet-agent-policies-agentpolicyid" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --advanced-settings: record # shape: {agent_download_target_directory?: any, agent_download_timeout?: any, agent_features_disable_policy_change_acks_enabled?: any, agent_internal?: any, agent_limits_go_max_procs?: any, agent_logging_files_interval?: any, agent_logging_files_keepfiles?: any, agent_logging_files_rotateeverybytes?: any, agent_logging_level?: any, agent_logging_metrics_period?: any, agent_logging_to_files?: any, agent_monitoring_runtime_experimental?: any}
  --agent-features: list # item shape: {enabled: bool, name: string}
  --agentless: record # shape: {cloud_connectors?: record, cluster_id?: string, resources?: record}
  --bumpRevision: oneof<nothing, bool>
  --data-output-id: string # nullable
  --description: string
  --download-source-id: string # nullable
  --fleet-server-host-id: string # nullable
  --force: oneof<nothing, bool>
  --global-data-tags: list # User defined data tags that are added to all of the inputs. The values can be strings or numbers. — item shape: {name: string, value: any}
  --has-agent-version-conditions: oneof<nothing, bool>
  --has-fleet-server: oneof<nothing, bool>
  --id: string
  --inactivity-timeout: float # default: 1209600
  --is-default: oneof<nothing, bool>
  --is-default-fleet-server: oneof<nothing, bool>
  --is-managed: oneof<nothing, bool>
  --is-protected: oneof<nothing, bool>
  --is-verifier: oneof<nothing, bool>
  --keep-monitoring-alive: oneof<nothing, bool> # When set to true, monitoring will be enabled but logs/metrics collection will be disabled (nullable)
  --min-agent-version: string # nullable
  --monitoring-diagnostics: record # shape: {limit?: record, uploader?: record}
  --monitoring-enabled: list
  --monitoring-http: record # shape: {buffer?: record, enabled?: bool, host?: string, port?: float}
  --monitoring-output-id: string # nullable
  --monitoring-pprof-enabled: oneof<nothing, bool>
  name: string
  namespace: string
  --overrides: record # Override settings that are defined in the agent policy. Input settings cannot be overridden. The override option should be used only in unusual circumstances and not as a routine procedure. (nullable)
  --package-agent-version-conditions: list # nullable — item shape: {name: string, title: string, version_condition: string}
  --required-versions: list # nullable — item shape: {percentage: float, version: string}
  --space-ids: list
  --supports-agentless: oneof<nothing, bool> # Indicates whether the agent policy supports agentless integrations. Deprecated in favor of the Fleet agentless policies API. (DEPRECATED, nullable)
  --unenroll-timeout: float
]: any -> record<item: record<advanced_settings: record<agent_download_target_directory: any, agent_download_timeout: any, agent_features_disable_policy_change_acks_enabled: any, agent_internal: any, agent_limits_go_max_procs: any, agent_logging_files_interval: any, agent_logging_files_keepfiles: any, agent_logging_files_rotateeverybytes: any, agent_logging_level: any, agent_logging_metrics_period: any, agent_logging_to_files: any, agent_monitoring_runtime_experimental: any>, agent_features: list<record>, agentless: record<cloud_connectors: record, cluster_id: string, resources: record>, agents: float, agents_per_version: list<record>, created_at: string, data_output_id: string, description: string, download_source_id: string, fips_agents: float, fleet_server_host_id: string, global_data_tags: list<record>, has_agent_version_conditions: bool, has_fleet_server: bool, id: string, inactivity_timeout: float, is_default: bool, is_default_fleet_server: bool, is_managed: bool, is_preconfigured: bool, is_protected: bool, is_verifier: bool, keep_monitoring_alive: bool, min_agent_version: string, monitoring_diagnostics: record<limit: record, uploader: record>, monitoring_enabled: list<string>, monitoring_http: record<buffer: record, enabled: bool, host: string, port: float>, monitoring_output_id: string, monitoring_pprof_enabled: bool, name: string, namespace: string, overrides: record, package_agent_version_conditions: list<record>, package_policies: any, required_versions: list<record>, revision: float, schema_version: string, space_ids: list<string>, status: string, supports_agentless: bool, unenroll_timeout: float, unprivileged_agents: float, updated_at: string, updated_by: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)" $qp)
  let body = {advanced_settings: $advanced_settings, agent_features: $agent_features, agentless: $agentless, bumpRevision: $bumpRevision, data_output_id: $data_output_id, description: $description, download_source_id: $download_source_id, fleet_server_host_id: $fleet_server_host_id, force: $force, global_data_tags: $global_data_tags, has_agent_version_conditions: $has_agent_version_conditions, has_fleet_server: $has_fleet_server, id: $id, inactivity_timeout: $inactivity_timeout, is_default: $is_default, is_default_fleet_server: $is_default_fleet_server, is_managed: $is_managed, is_protected: $is_protected, is_verifier: $is_verifier, keep_monitoring_alive: $keep_monitoring_alive, min_agent_version: $min_agent_version, monitoring_diagnostics: $monitoring_diagnostics, monitoring_enabled: $monitoring_enabled, monitoring_http: $monitoring_http, monitoring_output_id: $monitoring_output_id, monitoring_pprof_enabled: $monitoring_pprof_enabled, name: $name, namespace: $namespace, overrides: $overrides, package_agent_version_conditions: $package_agent_version_conditions, required_versions: $required_versions, space_ids: $space_ids, supports_agentless: $supports_agentless, unenroll_timeout: $unenroll_timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get auto upgrade agent status
#
# GET /api/fleet/agent_policies/{agentPolicyId}/auto_upgrade_agents_status
# operationId: get-fleet-agent-policies-agentpolicyid-auto-upgrade-agents-status
export def "fleet-agent-policies-auto-upgrade-agents-status get-fleet-agent-policies-agentpolicyid-auto-upgrade-agents-status" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currentVersions: table<agents: float, failedUpgradeActionIds: list, failedUpgradeAgents: float, inProgressUpgradeActionIds: list, inProgressUpgradeAgents: float, version: string>, totalAgents: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)/auto_upgrade_agents_status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy an agent policy
#
# POST /api/fleet/agent_policies/{agentPolicyId}/copy
# operationId: post-fleet-agent-policies-agentpolicyid-copy
export def "fleet-agent-policies-copy post-fleet-agent-policies-agentpolicyid-copy" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --description: string
  name: string
]: any -> record<item: record<advanced_settings: record<agent_download_target_directory: any, agent_download_timeout: any, agent_features_disable_policy_change_acks_enabled: any, agent_internal: any, agent_limits_go_max_procs: any, agent_logging_files_interval: any, agent_logging_files_keepfiles: any, agent_logging_files_rotateeverybytes: any, agent_logging_level: any, agent_logging_metrics_period: any, agent_logging_to_files: any, agent_monitoring_runtime_experimental: any>, agent_features: list<record>, agentless: record<cloud_connectors: record, cluster_id: string, resources: record>, agents: float, agents_per_version: list<record>, created_at: string, data_output_id: string, description: string, download_source_id: string, fips_agents: float, fleet_server_host_id: string, global_data_tags: list<record>, has_agent_version_conditions: bool, has_fleet_server: bool, id: string, inactivity_timeout: float, is_default: bool, is_default_fleet_server: bool, is_managed: bool, is_preconfigured: bool, is_protected: bool, is_verifier: bool, keep_monitoring_alive: bool, min_agent_version: string, monitoring_diagnostics: record<limit: record, uploader: record>, monitoring_enabled: list<string>, monitoring_http: record<buffer: record, enabled: bool, host: string, port: float>, monitoring_output_id: string, monitoring_pprof_enabled: bool, name: string, namespace: string, overrides: record, package_agent_version_conditions: list<record>, package_policies: any, required_versions: list<record>, revision: float, schema_version: string, space_ids: list<string>, status: string, supports_agentless: bool, unenroll_timeout: float, unprivileged_agents: float, updated_at: string, updated_by: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)/copy" $qp)
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download an agent policy
#
# GET /api/fleet/agent_policies/{agentPolicyId}/download
# operationId: get-fleet-agent-policies-agentpolicyid-download
export def "fleet-agent-policies-download get-fleet-agent-policies-agentpolicyid-download" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --download: oneof<nothing, bool> # If true, returns the policy as a downloadable file
  --standalone: oneof<nothing, bool> # If true, returns the policy formatted for standalone agents
  --kubernetes: oneof<nothing, bool> # If true, returns the policy formatted for Kubernetes deployment
  --revision: float # If provided, returns the policy at the specified revision. Cannot be used with standalone or kubernetes flags.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "standalone" $standalone "scalar") (serialize-qp "kubernetes" $kubernetes "scalar") (serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a full agent policy
#
# GET /api/fleet/agent_policies/{agentPolicyId}/full
# operationId: get-fleet-agent-policies-agentpolicyid-full
export def "fleet-agent-policies-full get-fleet-agent-policies-agentpolicyid-full" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --download: oneof<nothing, bool> # If true, returns the policy as a downloadable file
  --standalone: oneof<nothing, bool> # If true, returns the policy formatted for standalone agents
  --kubernetes: oneof<nothing, bool> # If true, returns the policy formatted for Kubernetes deployment
  --revision: float # If provided, returns the policy at the specified revision. Cannot be used with standalone or kubernetes flags.
]: nothing -> record<item: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "standalone" $standalone "scalar") (serialize-qp "kubernetes" $kubernetes "scalar") (serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)/full" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outputs for an agent policy
#
# GET /api/fleet/agent_policies/{agentPolicyId}/outputs
# operationId: get-fleet-agent-policies-agentpolicyid-outputs
export def "fleet-agent-policies-outputs get-fleet-agent-policies-agentpolicyid-outputs" [
  agentPolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<agentPolicyId: string, data: record<integrations: list, output: record>, monitoring: record<output: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agent_policies/($agentPolicyId)/outputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an agent policy
#
# POST /api/fleet/agent_policies/delete
# operationId: post-fleet-agent-policies-delete
export def "fleet-agent-policies-delete post-fleet-agent-policies-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agentPolicyId: string # The ID of the agent policy
  --force: oneof<nothing, bool> # bypass validation checks that can prevent agent policy deletion
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agent_policies/delete")
  let body = {agentPolicyId: $agentPolicyId, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get outputs for agent policies
#
# POST /api/fleet/agent_policies/outputs
# operationId: post-fleet-agent-policies-outputs
export def "fleet-agent-policies-outputs post-fleet-agent-policies-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  ids: list # list of package policy ids
]: any -> record<items: table<agentPolicyId: string, data: record, monitoring: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agent_policies/outputs")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an agent status summary
#
# GET /api/fleet/agent_status
# operationId: get-fleet-agent-status
export def "fleet-agent-status get-fleet-agent-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policyId: string # Filter by agent policy ID
  --policyIds: list # Filter by one or more agent policy IDs
  --kuery: string # A KQL query string to filter results
]: nothing -> record<results: record<active: float, all: float, error: float, events: float, inactive: float, offline: float, online: float, orphaned: float, other: float, unenrolled: float, uninstalled: float, updating: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policyId" $policyId "scalar") (serialize-qp "policyIds" $policyIds "multi") (serialize-qp "kuery" $kuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agent_status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incoming agent data
#
# GET /api/fleet/agent_status/data
# operationId: get-fleet-agent-status-data
export def "fleet-agent-status-data get-fleet-agent-status-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agentsIds: list # Agent IDs to check data for, as an array or comma-separated string
  --pkgName: string # Filter by integration package name
  --pkgVersion: string # Filter by integration package version
  --previewData: oneof<nothing, bool> # When true, return a preview of the ingested data (default: false)
]: nothing -> record<dataPreview: list<any>, items: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agentsIds" $agentsIds "multi") (serialize-qp "pkgName" $pkgName "scalar") (serialize-qp "pkgVersion" $pkgVersion "scalar") (serialize-qp "previewData" $previewData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agent_status/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an agentless policy
#
# POST /api/fleet/agentless_policies
# operationId: post-fleet-agentless-policies
# --cloud_connector shape: {cloud_connector_id?: string, enabled?: bool, name?: string, target_csp?: "aws"|"azure"|"gcp"}
# --global_data_tags item shape: {name: string, value: any}
# --package shape: {experimental_data_stream_features?: list, fips_compatible?: bool, name: string, requires_root?: bool, title?: string, version: string}
export def "fleet-agentless-policies post-fleet-agentless-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # The format of the response package policy. (default: simplified)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --additional-datastreams-permissions: list # Additional data stream permissions that will be added to the agent policy. (nullable)
  --cloud-connector: record # shape: {cloud_connector_id?: string, enabled?: bool, name?: string, target_csp?: "aws"|"azure"|"gcp"}
  --condition: string # Agent condition expression to evaluate whether to apply this integration to its inputs. (nullable)
  --create-dataset-templates: oneof<nothing, bool> # When true, install dedicated index templates for streams with a custom data_stream.dataset. Defaults to true for input packages, false for integration packages.
  --description: string # Policy description.
  --force: oneof<nothing, bool> # Force package policy creation even if the package is not verified, or if the agent policy is managed.
  --global-data-tags: list # item shape: {name: string, value: any}
  --id: string # Policy unique identifier.
  --inputs: record # Package policy inputs. Refer to the integration documentation to know which inputs are available.
  name: string # Unique name for the policy.
  --namespace: string # Policy namespace. When not specified, it inherits the agent policy namespace.
  package: record # shape: {experimental_data_stream_features?: list, fips_compatible?: bool, name: string, requires_root?: bool, title?: string, version: string}
  --policy-template: string # The policy template to use for the agentless package policy. If not provided, the default policy template will be used.
  --var-group-selections: record # Variable group selections. Maps var_group name to the selected option name within that group.
  --vars: record # Input/stream level variable. Refer to the integration documentation for more information.
]: any -> record<item: record<additional_datastreams_permissions: list<string>, agents: float, cloud_connector_id: string, cloud_connector_name: string, condition: string, created_at: string, created_by: string, description: string, elasticsearch: record<privileges: record>, enabled: bool, global_data_tags: list<record>, id: string, inputs: any, is_managed: bool, name: string, namespace: string, output_id: string, overrides: record<inputs: record>, package: record<experimental_data_stream_features: list, fips_compatible: bool, name: string, requires_root: bool, title: string, version: string>, package_agent_version_condition: string, policy_id: string, policy_ids: list<string>, revision: float, secret_references: list<record>, spaceIds: list<string>, supports_agentless: bool, supports_cloud_connector: bool, updated_at: string, updated_by: string, var_group_selections: record, vars: any, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agentless_policies" $qp)
  let body = {additional_datastreams_permissions: $additional_datastreams_permissions, cloud_connector: $cloud_connector, condition: $condition, create_dataset_templates: $create_dataset_templates, description: $description, force: $force, global_data_tags: $global_data_tags, id: $id, inputs: $inputs, name: $name, namespace: $namespace, package: $package, policy_template: $policy_template, var_group_selections: $var_group_selections, vars: $vars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an agentless policy
#
# DELETE /api/fleet/agentless_policies/{policyId}
# operationId: delete-fleet-agentless-policies-policyid
export def "fleet-agentless-policies delete-fleet-agentless-policies-policyid" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Force delete the policy even if the policy is managed.
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agentless_policies/($policyId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agents
#
# GET /api/fleet/agents
# operationId: get-fleet-agents
export def "fleet-agents get-fleet-agents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number
  --perPage: float # Number of results per page (default: 20)
  --kuery: string # A KQL query string to filter results
  --showAgentless: oneof<nothing, bool> # When true, include agentless agents in the results (default: true)
  --showInactive: oneof<nothing, bool> # When true, include inactive agents in the results (default: false)
  --withMetrics: oneof<nothing, bool> # When true, include CPU and memory metrics in the response (default: false)
  --showUpgradeable: oneof<nothing, bool> # When true, only return agents that are upgradeable (default: false)
  --getStatusSummary: oneof<nothing, bool> # When true, return a summary of agent statuses in the response (default: false)
  --sortField: string # Field to sort results by
  --sortOrder: string@sortOrder-completer # Sort order, ascending or descending
  --searchAfter: string # JSON-encoded array of sort values for `search_after` pagination
  --openPit: oneof<nothing, bool> # When true, opens a new point-in-time for pagination
  --pitId: string # Point-in-time ID for pagination
  --pitKeepAlive: string # Duration to keep the point-in-time alive, for example, `1m`
]: nothing -> record<items: table<access_api_key: string, access_api_key_id: string, active: bool, agent: record, audit_unenrolled_reason: string, capabilities: list, components: list, default_api_key: string, default_api_key_history: list, default_api_key_id: string, effective_config: any, enrolled_at: string, health: record, id: string, identifying_attributes: record, last_checkin: string, last_checkin_message: string, last_checkin_status: string, last_known_status: string, local_metadata: record, metrics: record, namespaces: list, non_identifying_attributes: record, outputs: record, packages: list, pipeline_config: string, policy_id: string, policy_revision: float, sequence_num: float, signals: list, sort: list, status: string, tags: list, type: string, unenrolled_at: string, unenrollment_started_at: string, unhealthy_reason: list, upgrade: record, upgrade_attempts: list, upgrade_details: record, upgrade_started_at: string, upgraded_at: string, user_provided_metadata: record>, nextSearchAfter: string, page: float, perPage: float, pit: string, statusSummary: record, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "kuery" $kuery "scalar") (serialize-qp "showAgentless" $showAgentless "scalar") (serialize-qp "showInactive" $showInactive "scalar") (serialize-qp "withMetrics" $withMetrics "scalar") (serialize-qp "showUpgradeable" $showUpgradeable "scalar") (serialize-qp "getStatusSummary" $getStatusSummary "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "searchAfter" $searchAfter "scalar") (serialize-qp "openPit" $openPit "scalar") (serialize-qp "pitId" $pitId "scalar") (serialize-qp "pitKeepAlive" $pitKeepAlive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agents by action ids
#
# POST /api/fleet/agents
# operationId: post-fleet-agents
export def "fleet-agents post-fleet-agents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  actionIds: list
]: any -> record<items: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents")
  let body = {actionIds: $actionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an agent
#
# DELETE /api/fleet/agents/{agentId}
# operationId: delete-fleet-agents-agentid
export def "fleet-agents delete-fleet-agents-agentid" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an agent
#
# GET /api/fleet/agents/{agentId}
# operationId: get-fleet-agents-agentid
export def "fleet-agents get-fleet-agents-agentid" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withMetrics: oneof<nothing, bool> # When true, include CPU and memory metrics in the response (default: false)
]: nothing -> record<item: record<access_api_key: string, access_api_key_id: string, active: bool, agent: record<id: string, type: string, version: string>, audit_unenrolled_reason: string, capabilities: list<string>, components: list<record>, default_api_key: string, default_api_key_history: list<record>, default_api_key_id: string, effective_config: any, enrolled_at: string, health: record, id: string, identifying_attributes: record, last_checkin: string, last_checkin_message: string, last_checkin_status: string, last_known_status: string, local_metadata: record, metrics: record<cpu_avg: float, memory_size_byte_avg: float>, namespaces: list<string>, non_identifying_attributes: record, outputs: record, packages: list<string>, pipeline_config: string, policy_id: string, policy_revision: float, sequence_num: float, signals: list<string>, sort: list<any>, status: string, tags: list<string>, type: string, unenrolled_at: string, unenrollment_started_at: string, unhealthy_reason: list<string>, upgrade: record<rollbacks: list>, upgrade_attempts: list<string>, upgrade_details: record<action_id: string, metadata: record, state: string, target_version: string>, upgrade_started_at: string, upgraded_at: string, user_provided_metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withMetrics" $withMetrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent by ID
#
# PUT /api/fleet/agents/{agentId}
# operationId: put-fleet-agents-agentid
export def "fleet-agents put-fleet-agents-agentid" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --tags: list
  --user-provided-metadata: record
]: any -> record<item: record<access_api_key: string, access_api_key_id: string, active: bool, agent: record<id: string, type: string, version: string>, audit_unenrolled_reason: string, capabilities: list<string>, components: list<record>, default_api_key: string, default_api_key_history: list<record>, default_api_key_id: string, effective_config: any, enrolled_at: string, health: record, id: string, identifying_attributes: record, last_checkin: string, last_checkin_message: string, last_checkin_status: string, last_known_status: string, local_metadata: record, metrics: record<cpu_avg: float, memory_size_byte_avg: float>, namespaces: list<string>, non_identifying_attributes: record, outputs: record, packages: list<string>, pipeline_config: string, policy_id: string, policy_revision: float, sequence_num: float, signals: list<string>, sort: list<any>, status: string, tags: list<string>, type: string, unenrolled_at: string, unenrollment_started_at: string, unhealthy_reason: list<string>, upgrade: record<rollbacks: list>, upgrade_attempts: list<string>, upgrade_details: record<action_id: string, metadata: record, state: string, target_version: string>, upgrade_started_at: string, upgraded_at: string, user_provided_metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)")
  let body = {tags: $tags, user_provided_metadata: $user_provided_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an agent action
#
# POST /api/fleet/agents/{agentId}/actions
# operationId: post-fleet-agents-agentid-actions
export def "fleet-agents-actions post-fleet-agents-agentid-actions" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  action: any
]: any -> record<item: record<ack_data: any, agents: list<string>, created_at: string, data: any, expiration: string, id: string, minimum_execution_duration: float, namespaces: list<string>, rollout_duration_seconds: float, sent_at: string, source_uri: string, start_time: string, total: float, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/actions")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an agent's effective config
#
# GET /api/fleet/agents/{agentId}/effective_config
# operationId: get-fleet-agents-agentid-effective-config
export def "fleet-agents-effective-config get-fleet-agents-agentid-effective-config" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<effective_config: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/effective_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate a single agent
#
# POST /api/fleet/agents/{agentId}/migrate
# operationId: post-fleet-agents-agentid-migrate
# --settings shape: {ca_sha256?: string, certificate_authorities?: string, elastic_agent_cert?: string, elastic_agent_cert_key?: string, elastic_agent_cert_key_passphrase?: string, headers?: record, insecure?: bool, proxy_disabled?: bool, proxy_headers?: record, proxy_url?: string, replace_token?: string, staging?: string, tags?: list}
export def "fleet-agents-migrate post-fleet-agents-agentid-migrate" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  enrollment_token: string
  --settings: record # shape: {ca_sha256?: string, certificate_authorities?: string, elastic_agent_cert?: string, elastic_agent_cert_key?: string, elastic_agent_cert_key_passphrase?: string, headers?: record, insecure?: bool, proxy_disabled?: bool, proxy_headers?: record, proxy_url?: string, replace_token?: string, staging?: string, tags?: list}
  uri: string # format: uri
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/migrate")
  let body = {enrollment_token: $enrollment_token, settings: $settings, uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change agent privilege level
#
# POST /api/fleet/agents/{agentId}/privilege_level_change
# operationId: post-fleet-agents-agentid-privilege-level-change
# --user_info shape: {groupname?: string, password?: string, username?: string}
export def "fleet-agents-privilege-level-change post-fleet-agents-agentid-privilege-level-change" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --user-info: record # shape: {groupname?: string, password?: string, username?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/privilege_level_change")
  let body = {user_info: $user_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reassign an agent
#
# POST /api/fleet/agents/{agentId}/reassign
# operationId: post-fleet-agents-agentid-reassign
export def "fleet-agents-reassign post-fleet-agents-agentid-reassign" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  policy_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/reassign")
  let body = {policy_id: $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an OpAMP collector
#
# POST /api/fleet/agents/{agentId}/remove_collector
# operationId: post-fleet-agents-agentid-remove-collector
export def "fleet-agents-remove-collector post-fleet-agents-agentid-remove-collector" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/remove_collector")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request agent diagnostics
#
# POST /api/fleet/agents/{agentId}/request_diagnostics
# operationId: post-fleet-agents-agentid-request-diagnostics
export def "fleet-agents-request-diagnostics post-fleet-agents-agentid-request-diagnostics" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --additional-metrics: list
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/request_diagnostics")
  let body = {additional_metrics: $additional_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rollback an agent
#
# POST /api/fleet/agents/{agentId}/rollback
# operationId: post-fleet-agents-agentid-rollback
export def "fleet-agents-rollback post-fleet-agents-agentid-rollback" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/rollback")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unenroll an agent
#
# POST /api/fleet/agents/{agentId}/unenroll
# operationId: post-fleet-agents-agentid-unenroll
export def "fleet-agents-unenroll post-fleet-agents-agentid-unenroll" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool>
  --revoke: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/unenroll")
  let body = {force: $force, revoke: $revoke} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrade an agent
#
# POST /api/fleet/agents/{agentId}/upgrade
# operationId: post-fleet-agents-agentid-upgrade
export def "fleet-agents-upgrade post-fleet-agents-agentid-upgrade" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool>
  --skipRateLimitCheck: oneof<nothing, bool>
  --source-uri: string
  version: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/upgrade")
  let body = {force: $force, skipRateLimitCheck: $skipRateLimitCheck, source_uri: $source_uri, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent uploads
#
# GET /api/fleet/agents/{agentId}/uploads
# operationId: get-fleet-agents-agentid-uploads
export def "fleet-agents-uploads get-fleet-agents-agentid-uploads" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<actionId: string, createTime: string, error: string, filePath: string, id: string, name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/($agentId)/uploads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an agent action status
#
# GET /api/fleet/agents/action_status
# operationId: get-fleet-agents-action-status
export def "fleet-agents-action-status get-fleet-agents-action-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number (default: 0)
  --perPage: float # Number of results per page (default: 20)
  --date: string # Return actions created before this date
  --latest: float # Return only the latest N actions
  --errorSize: float # Number of error details to include per action (default: 5)
]: nothing -> record<items: table<actionId: string, cancellationTime: string, completionTime: string, creationTime: string, expiration: string, hasRolloutPeriod: bool, is_automatic: bool, latestErrors: list, nbAgentsAck: float, nbAgentsActionCreated: float, nbAgentsActioned: float, nbAgentsFailed: float, newPolicyId: string, policyId: string, revision: float, startTime: string, status: string, type: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "errorSize" $errorSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agents/action_status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an agent action
#
# POST /api/fleet/agents/actions/{actionId}/cancel
# operationId: post-fleet-agents-actions-actionid-cancel
export def "fleet-agents-actions-cancel post-fleet-agents-actions-actionid-cancel" [
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> record<item: record<ack_data: any, agents: list<string>, created_at: string, data: any, expiration: string, id: string, minimum_execution_duration: float, namespaces: list<string>, rollout_duration_seconds: float, sent_at: string, source_uri: string, start_time: string, total: float, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/actions/($actionId)/cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get available agent versions
#
# GET /api/fleet/agents/available_versions
# operationId: get-fleet-agents-available-versions
export def "fleet-agents-available-versions get-fleet-agents-available-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/available_versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate multiple agents
#
# POST /api/fleet/agents/bulk_migrate
# operationId: post-fleet-agents-bulk-migrate
# --settings shape: {ca_sha256?: string, certificate_authorities?: string, elastic_agent_cert?: string, elastic_agent_cert_key?: string, elastic_agent_cert_key_passphrase?: string, headers?: record, insecure?: bool, proxy_disabled?: bool, proxy_headers?: record, proxy_url?: string, staging?: string, tags?: list}
export def "fleet-agents-bulk-migrate post-fleet-agents-bulk-migrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  enrollment_token: string
  --settings: record # shape: {ca_sha256?: string, certificate_authorities?: string, elastic_agent_cert?: string, elastic_agent_cert_key?: string, elastic_agent_cert_key_passphrase?: string, headers?: record, insecure?: bool, proxy_disabled?: bool, proxy_headers?: record, proxy_url?: string, staging?: string, tags?: list}
  uri: string # format: uri
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_migrate")
  let body = {agents: $agents, batchSize: $batchSize, enrollment_token: $enrollment_token, settings: $settings, uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk change agent privilege level
#
# POST /api/fleet/agents/bulk_privilege_level_change
# operationId: post-fleet-agents-bulk-privilege-level-change
# --user_info shape: {groupname?: string, password?: string, username?: string}
export def "fleet-agents-bulk-privilege-level-change post-fleet-agents-bulk-privilege-level-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  --user-info: record # shape: {groupname?: string, password?: string, username?: string}
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_privilege_level_change")
  let body = {agents: $agents, batchSize: $batchSize, user_info: $user_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk reassign agents
#
# POST /api/fleet/agents/bulk_reassign
# operationId: post-fleet-agents-bulk-reassign
export def "fleet-agents-bulk-reassign post-fleet-agents-bulk-reassign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  --includeInactive: oneof<nothing, bool> # default: false
  policy_id: string
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_reassign")
  let body = {agents: $agents, batchSize: $batchSize, includeInactive: $includeInactive, policy_id: $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk remove OpAMP collectors
#
# POST /api/fleet/agents/bulk_remove_collectors
# operationId: post-fleet-agents-bulk-remove-collectors
export def "fleet-agents-bulk-remove-collectors post-fleet-agents-bulk-remove-collectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --includeInactive: oneof<nothing, bool> # When passing collectors by KQL query, also removes inactive collectors
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_remove_collectors")
  let body = {agents: $agents, includeInactive: $includeInactive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk request diagnostics from agents
#
# POST /api/fleet/agents/bulk_request_diagnostics
# operationId: post-fleet-agents-bulk-request-diagnostics
export def "fleet-agents-bulk-request-diagnostics post-fleet-agents-bulk-request-diagnostics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --additional-metrics: list
  agents: any
  --batchSize: float
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_request_diagnostics")
  let body = {additional_metrics: $additional_metrics, agents: $agents, batchSize: $batchSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk rollback agents
#
# POST /api/fleet/agents/bulk_rollback
# operationId: post-fleet-agents-bulk-rollback
export def "fleet-agents-bulk-rollback post-fleet-agents-bulk-rollback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  --includeInactive: oneof<nothing, bool> # default: false
]: any -> record<actionIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_rollback")
  let body = {agents: $agents, batchSize: $batchSize, includeInactive: $includeInactive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk unenroll agents
#
# POST /api/fleet/agents/bulk_unenroll
# operationId: post-fleet-agents-bulk-unenroll
export def "fleet-agents-bulk-unenroll post-fleet-agents-bulk-unenroll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  --force: oneof<nothing, bool> # Unenrolls hosted agents too
  --includeInactive: oneof<nothing, bool> # When passing agents by KQL query, unenrolls inactive agents too
  --revoke: oneof<nothing, bool> # Revokes API keys of agents
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_unenroll")
  let body = {agents: $agents, batchSize: $batchSize, force: $force, includeInactive: $includeInactive, revoke: $revoke} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update agent tags
#
# POST /api/fleet/agents/bulk_update_agent_tags
# operationId: post-fleet-agents-bulk-update-agent-tags
export def "fleet-agents-bulk-update-agent-tags post-fleet-agents-bulk-update-agent-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  --includeInactive: oneof<nothing, bool> # default: false
  --tagsToAdd: list
  --tagsToRemove: list
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_update_agent_tags")
  let body = {agents: $agents, batchSize: $batchSize, includeInactive: $includeInactive, tagsToAdd: $tagsToAdd, tagsToRemove: $tagsToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk upgrade agents
#
# POST /api/fleet/agents/bulk_upgrade
# operationId: post-fleet-agents-bulk-upgrade
export def "fleet-agents-bulk-upgrade post-fleet-agents-bulk-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  agents: any
  --batchSize: float
  --force: oneof<nothing, bool>
  --includeInactive: oneof<nothing, bool> # default: false
  --rollout-duration-seconds: float
  --skipRateLimitCheck: oneof<nothing, bool>
  --source-uri: string
  --start-time: string
  version: string
]: any -> record<actionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/bulk_upgrade")
  let body = {agents: $agents, batchSize: $batchSize, force: $force, includeInactive: $includeInactive, rollout_duration_seconds: $rollout_duration_seconds, skipRateLimitCheck: $skipRateLimitCheck, source_uri: $source_uri, start_time: $start_time, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get collector groups
#
# GET /api/fleet/agents/collector_groups
# operationId: get-fleet-agents-collector-groups
export def "fleet-agents-collector-groups get-fleet-agents-collector-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupBy: string@groupBy-completer # Field to group collectors by (default: collector.group)
  --kuery: string # A KQL query string to filter collectors before grouping
  --perPage: float # Number of groups per page (default: 20)
  --afterKey: string # After key is used for cursor-based pagination, use it to get the next page of results
  --showInactive: oneof<nothing, bool> # When true, include inactive collectors in the results (default: false)
]: nothing -> record<afterKey: string, items: table<docCount: float, group: string, groupDisplayName: string, isUngrouped: bool, signals: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "kuery" $kuery "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "afterKey" $afterKey "scalar") (serialize-qp "showInactive" $showInactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agents/collector_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an uploaded file
#
# DELETE /api/fleet/agents/files/{fileId}
# operationId: delete-fleet-agents-files-fileid
export def "fleet-agents-files delete-fleet-agents-files-fileid" [
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<deleted: bool, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/agents/files/($fileId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an uploaded file
#
# GET /api/fleet/agents/files/{fileId}/{fileName}
# operationId: get-fleet-agents-files-fileid-filename
export def "fleet-agents-files get-fleet-agents-files-fileid-filename" [
  fileId: string
  fileName: string
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
  let full_url = (build-url $base $"/api/fleet/agents/files/($fileId)/($fileName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent setup info
#
# GET /api/fleet/agents/setup
# operationId: get-fleet-agents-setup
export def "fleet-agents-setup get-fleet-agents-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<is_action_secrets_storage_enabled: bool, is_secrets_storage_enabled: bool, is_space_awareness_enabled: bool, is_ssl_secrets_storage_enabled: bool, isReady: bool, missing_optional_features: list<string>, missing_requirements: list<string>, package_verification_key_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/setup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Fleet setup
#
# POST /api/fleet/agents/setup
# operationId: post-fleet-agents-setup
export def "fleet-agents-setup post-fleet-agents-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<isInitialized: bool, nonFatalErrors: table<message: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/agents/setup")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent tags
#
# GET /api/fleet/agents/tags
# operationId: get-fleet-agents-tags
export def "fleet-agents-tags get-fleet-agents-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kuery: string # A KQL query string to filter results
  --showInactive: oneof<nothing, bool> # When true, include tags from inactive agents (default: false)
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kuery" $kuery "scalar") (serialize-qp "showInactive" $showInactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/agents/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check permissions
#
# GET /api/fleet/check-permissions
# operationId: get-fleet-check-permissions
export def "fleet-check-permissions get-fleet-check-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fleetServerSetup: oneof<nothing, bool> # When true, check Fleet Server setup privileges in addition to standard Fleet privileges
]: nothing -> record<error: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fleetServerSetup" $fleetServerSetup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/check-permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cloud connectors
#
# GET /api/fleet/cloud_connectors
# operationId: get-fleet-cloud-connectors
export def "fleet-cloud-connectors get-fleet-cloud-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # The page number for pagination.
  --perPage: string # The number of items per page.
  --kuery: string # KQL query to filter cloud connectors.
]: nothing -> record<items: table<accountType: string, cloudProvider: string, created_at: string, id: string, name: string, namespace: string, packagePolicyCount: float, updated_at: string, vars: record, verification_failed_at: string, verification_started_at: string, verification_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "kuery" $kuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/cloud_connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create cloud connector
#
# POST /api/fleet/cloud_connectors
# operationId: post-fleet-cloud-connectors
export def "fleet-cloud-connectors post-fleet-cloud-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --accountType: string@accountType-completer # The account type: single-account (single account/subscription) or organization-account (organization-wide).
  cloudProvider: string@cloudProvider-completer # The cloud provider type: aws, azure, or gcp.
  name: string # The name of the cloud connector.
  vars: record
]: any -> record<item: record<accountType: string, cloudProvider: string, created_at: string, id: string, name: string, namespace: string, packagePolicyCount: float, updated_at: string, vars: record, verification_failed_at: string, verification_started_at: string, verification_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/cloud_connectors")
  let body = {accountType: $accountType, cloudProvider: $cloudProvider, name: $name, vars: $vars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete cloud connector (supports force deletion)
#
# DELETE /api/fleet/cloud_connectors/{cloudConnectorId}
# operationId: delete-fleet-cloud-connectors-cloudconnectorid
export def "fleet-cloud-connectors delete-fleet-cloud-connectors-cloudconnectorid" [
  cloudConnectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If true, forces deletion even if the cloud connector is in use.
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/cloud_connectors/($cloudConnectorId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cloud connector
#
# GET /api/fleet/cloud_connectors/{cloudConnectorId}
# operationId: get-fleet-cloud-connectors-cloudconnectorid
export def "fleet-cloud-connectors get-fleet-cloud-connectors-cloudconnectorid" [
  cloudConnectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<accountType: string, cloudProvider: string, created_at: string, id: string, name: string, namespace: string, packagePolicyCount: float, updated_at: string, vars: record, verification_failed_at: string, verification_started_at: string, verification_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/cloud_connectors/($cloudConnectorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update cloud connector
#
# PUT /api/fleet/cloud_connectors/{cloudConnectorId}
# operationId: put-fleet-cloud-connectors-cloudconnectorid
export def "fleet-cloud-connectors put-fleet-cloud-connectors-cloudconnectorid" [
  cloudConnectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --accountType: string@accountType-completer # The account type: single-account (single account/subscription) or organization-account (organization-wide).
  --name: string # The name of the cloud connector.
  --vars: record
]: any -> record<item: record<accountType: string, cloudProvider: string, created_at: string, id: string, name: string, namespace: string, packagePolicyCount: float, updated_at: string, vars: record, verification_failed_at: string, verification_started_at: string, verification_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/cloud_connectors/($cloudConnectorId)")
  let body = {accountType: $accountType, name: $name, vars: $vars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get cloud connector usage (package policies using the connector)
#
# GET /api/fleet/cloud_connectors/{cloudConnectorId}/usage
# operationId: get-fleet-cloud-connectors-cloudconnectorid-usage
export def "fleet-cloud-connectors-usage get-fleet-cloud-connectors-cloudconnectorid-usage" [
  cloudConnectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # The page number for pagination.
  --perPage: float # The number of items per page.
]: nothing -> record<items: table<created_at: string, id: string, name: string, package: record, policy_ids: list, updated_at: string>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/cloud_connectors/($cloudConnectorId)/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get data streams
#
# GET /api/fleet/data_streams
# operationId: get-fleet-data-streams
export def "fleet-data-streams get-fleet-data-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_streams: table<dashboards: list, dataset: string, index: string, last_activity_ms: float, namespace: string, package: string, package_version: string, serviceDetails: record, size_in_bytes: float, size_in_bytes_formatted: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/data_streams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get enrollment API keys
#
# GET /api/fleet/enrollment_api_keys
# operationId: get-fleet-enrollment-api-keys
export def "fleet-enrollment-api-keys get-fleet-enrollment-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number (default: 1)
  --perPage: float # Number of results per page (default: 20)
  --kuery: string # A KQL query string to filter results
]: nothing -> record<items: table<active: bool, api_key: string, api_key_id: string, created_at: string, hidden: bool, id: string, name: string, policy_id: string>, list: table<active: bool, api_key: string, api_key_id: string, created_at: string, hidden: bool, id: string, name: string, policy_id: string>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "kuery" $kuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/enrollment_api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an enrollment API key
#
# POST /api/fleet/enrollment_api_keys
# operationId: post-fleet-enrollment-api-keys
export def "fleet-enrollment-api-keys post-fleet-enrollment-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --expiration: string
  --name: string
  policy_id: string
]: any -> record<action: string, item: record<active: bool, api_key: string, api_key_id: string, created_at: string, hidden: bool, id: string, name: string, policy_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/enrollment_api_keys")
  let body = {expiration: $expiration, name: $name, policy_id: $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk revoke or delete enrollment API keys
#
# POST /api/fleet/enrollment_api_keys/_bulk_delete
# operationId: post-fleet-enrollment-api-keys-bulk-delete
export def "fleet-enrollment-api-keys-bulk-delete post-fleet-enrollment-api-keys-bulk-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --forceDelete: oneof<nothing, bool> # When false (default), invalidate the API key and mark the token as inactive. When true, also delete the token document. (default: false)
  --includeHidden: oneof<nothing, bool> # When true, allow deletion of hidden enrollment tokens (managed/agentless policies). Defaults to false. (default: false)
  --kuery: string # KQL query to select enrollment tokens to delete.
  --tokenIds: list # List of enrollment token IDs to delete.
]: any -> record<action: string, count: float, errorCount: float, successCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/enrollment_api_keys/_bulk_delete")
  let body = {forceDelete: $forceDelete, includeHidden: $includeHidden, kuery: $kuery, tokenIds: $tokenIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke or delete an enrollment API key
#
# DELETE /api/fleet/enrollment_api_keys/{keyId}
# operationId: delete-fleet-enrollment-api-keys-keyid
export def "fleet-enrollment-api-keys delete-fleet-enrollment-api-keys-keyid" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceDelete: oneof<nothing, bool> # When false (default), invalidate the API key and mark the token as inactive. When true, also delete the token document. (default: false)
  --includeHidden: oneof<nothing, bool> # When true, allow deletion of hidden enrollment tokens (managed/agentless policies). Defaults to false. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceDelete" $forceDelete "scalar") (serialize-qp "includeHidden" $includeHidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/enrollment_api_keys/($keyId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an enrollment API key
#
# GET /api/fleet/enrollment_api_keys/{keyId}
# operationId: get-fleet-enrollment-api-keys-keyid
export def "fleet-enrollment-api-keys get-fleet-enrollment-api-keys-keyid" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: string, item: record<active: bool, api_key: string, api_key_id: string, created_at: string, hidden: bool, id: string, name: string, policy_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/enrollment_api_keys/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk get assets
#
# POST /api/fleet/epm/bulk_assets
# operationId: post-fleet-epm-bulk-assets
# --assetIds item shape: {id: string, type: string}
export def "fleet-epm-bulk-assets post-fleet-epm-bulk-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  assetIds: list # item shape: {id: string, type: string}
]: any -> record<items: table<appLink: string, attributes: record, id: string, type: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/bulk_assets")
  let body = {assetIds: $assetIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get package categories
#
# GET /api/fleet/epm/categories
# operationId: get-fleet-epm-categories
export def "fleet-epm-categories get-fleet-epm-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prerelease: oneof<nothing, bool> # When true, include prerelease packages in the results
  --include-policy-templates: oneof<nothing, bool> # When true, include categories that only contain policy templates
]: nothing -> record<items: table<count: float, id: string, parent_id: string, parent_title: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "include_policy_templates" $include_policy_templates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/epm/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom integration
#
# POST /api/fleet/epm/custom_integrations
# operationId: post-fleet-epm-custom-integrations
# --datasets item shape: {name: string, type: "logs"|"metrics"|"traces"|"synthetics"|"profiling"}
export def "fleet-epm-custom-integrations post-fleet-epm-custom-integrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  datasets: list # item shape: {name: string, type: "logs"|"metrics"|"traces"|"synthetics"|"profiling"}
  --force: oneof<nothing, bool>
  integrationName: string
]: any -> record<_meta: record<install_source: string, name: string>, items: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/custom_integrations")
  let body = {datasets: $datasets, force: $force, integrationName: $integrationName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a custom integration
#
# PUT /api/fleet/epm/custom_integrations/{pkgName}
# operationId: put-fleet-epm-custom-integrations-pkgname
export def "fleet-epm-custom-integrations put-fleet-epm-custom-integrations-pkgname" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --categories: list
  readMeData: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/custom_integrations/($pkgName)")
  let body = {categories: $categories, readMeData: $readMeData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get data streams
#
# GET /api/fleet/epm/data_streams
# operationId: get-fleet-epm-data-streams
export def "fleet-epm-data-streams get-fleet-epm-data-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-3 # Filter by data stream type
  --datasetQuery: string # Filter data streams by dataset name
  --sortOrder: string@sortOrder-completer # Sort order, ascending or descending (default: asc)
  --uncategorisedOnly: oneof<nothing, bool> # When true, only return data streams that are not associated with a package (default: false)
]: nothing -> record<items: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "datasetQuery" $datasetQuery "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "uncategorisedOnly" $uncategorisedOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/epm/data_streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get packages
#
# GET /api/fleet/epm/packages
# operationId: get-fleet-epm-packages
export def "fleet-epm-packages get-fleet-epm-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category: string # Filter packages by category
  --prerelease: oneof<nothing, bool> # When true, include prerelease packages in the results
  --excludeInstallStatus: oneof<nothing, bool> # When true, exclude the install status from the response
  --withPackagePoliciesCount: oneof<nothing, bool> # When true, include the number of package policies per package
]: nothing -> record<items: table<categories: list, conditions: record, data_streams: list, deprecated: record, description: string, discovery: record, download: string, format_version: string, icons: list, id: string, installationInfo: record, integration: string, internal: bool, latestVersion: string, name: string, owner: record, path: string, policy_templates: list, readme: string, release: string, signature_path: string, source: record, status: string, title: string, type: any, var_groups: list, vars: list, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "excludeInstallStatus" $excludeInstallStatus "scalar") (serialize-qp "withPackagePoliciesCount" $withPackagePoliciesCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/epm/packages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install a package by upload
#
# POST /api/fleet/epm/packages
# operationId: post-fleet-epm-packages
export def "fleet-epm-packages post-fleet-epm-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --ignoreMappingUpdateErrors: oneof<nothing, bool> # When true, ignore mapping update errors during installation (default: false)
  --skipDataStreamRollover: oneof<nothing, bool> # When true, skip data stream rollover after installation (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreMappingUpdateErrors" $ignoreMappingUpdateErrors "scalar") (serialize-qp "skipDataStreamRollover" $skipDataStreamRollover "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/epm/packages" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/gzip; application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/gzip" $body
}

# Bulk install packages
#
# POST /api/fleet/epm/packages/_bulk
# operationId: post-fleet-epm-packages-bulk
export def "fleet-epm-packages-bulk post-fleet-epm-packages-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prerelease: oneof<nothing, bool> # When true, allow installing prerelease versions
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool> # default: false
  packages: list
]: any -> record<items: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prerelease" $prerelease "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/epm/packages/_bulk" $qp)
  let body = {force: $force, packages: $packages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk enable/disable namespace-level customization for packages
#
# POST /api/fleet/epm/packages/_bulk_namespace_customization
# operationId: post-fleet-epm-packages-bulk-namespace-customization
export def "fleet-epm-packages-bulk-namespace-customization post-fleet-epm-packages-bulk-namespace-customization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --disable: list # Namespaces to disable namespace-level customization for on each package.
  --enable: list # Namespaces to enable namespace-level customization for on each package.
  packages: list # Package names to apply the customization changes to.
]: any -> record<items: table<error: string, name: string, namespace_customization_enabled_for: list, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/packages/_bulk_namespace_customization")
  let body = {disable: $disable, enable: $enable, packages: $packages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk rollback packages
#
# POST /api/fleet/epm/packages/_bulk_rollback
# operationId: post-fleet-epm-packages-bulk-rollback
# --packages item shape: {name: string}
export def "fleet-epm-packages-bulk-rollback post-fleet-epm-packages-bulk-rollback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  packages: list # item shape: {name: string}
]: any -> record<taskId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/packages/_bulk_rollback")
  let body = {packages: $packages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Bulk rollback packages details
#
# GET /api/fleet/epm/packages/_bulk_rollback/{taskId}
# operationId: get-fleet-epm-packages-bulk-rollback-taskid
export def "fleet-epm-packages-bulk-rollback get-fleet-epm-packages-bulk-rollback-taskid" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<message: string>, results: table<error: record, name: string, success: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/_bulk_rollback/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk uninstall packages
#
# POST /api/fleet/epm/packages/_bulk_uninstall
# operationId: post-fleet-epm-packages-bulk-uninstall
# --packages item shape: {name: string, version: string}
export def "fleet-epm-packages-bulk-uninstall post-fleet-epm-packages-bulk-uninstall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool> # default: false
  packages: list # item shape: {name: string, version: string}
]: any -> record<taskId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/packages/_bulk_uninstall")
  let body = {force: $force, packages: $packages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Bulk uninstall packages details
#
# GET /api/fleet/epm/packages/_bulk_uninstall/{taskId}
# operationId: get-fleet-epm-packages-bulk-uninstall-taskid
export def "fleet-epm-packages-bulk-uninstall get-fleet-epm-packages-bulk-uninstall-taskid" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<message: string>, results: table<error: record, name: string, success: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/_bulk_uninstall/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk upgrade packages
#
# POST /api/fleet/epm/packages/_bulk_upgrade
# operationId: post-fleet-epm-packages-bulk-upgrade
# --packages item shape: {name: string, version?: string}
export def "fleet-epm-packages-bulk-upgrade post-fleet-epm-packages-bulk-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool> # default: false
  packages: list # item shape: {name: string, version?: string}
  --prerelease: oneof<nothing, bool>
  --upgrade-package-policies: oneof<nothing, bool> # default: false
]: any -> record<taskId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/packages/_bulk_upgrade")
  let body = {force: $force, packages: $packages, prerelease: $prerelease, upgrade_package_policies: $upgrade_package_policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Bulk upgrade packages details
#
# GET /api/fleet/epm/packages/_bulk_upgrade/{taskId}
# operationId: get-fleet-epm-packages-bulk-upgrade-taskid
export def "fleet-epm-packages-bulk-upgrade get-fleet-epm-packages-bulk-upgrade-taskid" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<message: string>, results: table<error: record, name: string, success: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/_bulk_upgrade/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a package
#
# DELETE /api/fleet/epm/packages/{pkgName}
# operationId: delete-fleet-epm-packages-pkgname
export def "fleet-epm-packages delete-fleet-epm-packages-pkgname" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, delete the package even if it has active package policies
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<items: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package
#
# GET /api/fleet/epm/packages/{pkgName}
# operationId: get-fleet-epm-packages-pkgname
export def "fleet-epm-packages get-fleet-epm-packages-pkgname" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignoreUnverified: oneof<nothing, bool> # When true, returns the package even if the signature cannot be verified
  --prerelease: oneof<nothing, bool> # When true, include prerelease versions
  --full: oneof<nothing, bool> # When true, return the full package info including assets
  --withMetadata: oneof<nothing, bool> # When true, include package metadata such as whether it has package policies (default: false)
]: nothing -> record<item: record<agent: record<privileges: record>, asset_tags: list<record>, assets: record, categories: list<string>, conditions: record<deprecated: record, elastic: record, kibana: record>, data_streams: list<record>, deprecated: record<description: string, replaced_by: record, since: string>, description: string, discovery: record<datasets: list, fields: list>, download: string, elasticsearch: record, format_version: string, icons: list<record>, installationInfo: record<additional_spaces_installed_kibana: record, created_at: string, experimental_data_stream_features: list, install_format_schema_version: string, install_source: string, install_status: string, installed_es: list, installed_kibana: list, installed_kibana_space_id: string, is_rollback_ttl_expired: bool, latest_executed_state: record, latest_install_failed_attempts: list, name: string, namespaces: list, previous_version: string, rolled_back: bool, type: string, updated_at: string, verification_key_id: string, verification_status: string, version: string>, internal: bool, keepPoliciesUpToDate: bool, latestVersion: string, license: string, licensePath: string, name: string, notice: string, owner: record<github: string, type: string>, path: string, policy_templates: list<record>, readme: string, release: string, screenshots: list<record>, signature_path: string, source: record<license: string>, status: string, title: string, type: any, var_groups: list<record>, vars: list<record>, version: string>, metadata: record<has_policies: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreUnverified" $ignoreUnverified "scalar") (serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "withMetadata" $withMetadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install a package from the registry
#
# POST /api/fleet/epm/packages/{pkgName}
# operationId: post-fleet-epm-packages-pkgname
export def "fleet-epm-packages post-fleet-epm-packages-pkgname" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prerelease: oneof<nothing, bool> # When true, allow installing prerelease versions
  --ignoreMappingUpdateErrors: oneof<nothing, bool> # When true, ignore mapping update errors during installation (default: false)
  --skipDataStreamRollover: oneof<nothing, bool> # When true, skip data stream rollover after installation (default: false)
  --skipDependencyCheck: oneof<nothing, bool> # Skip dependency validation when installing a package with dependencies (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool> # default: false
  --ignore-constraints: oneof<nothing, bool> # default: false
]: any -> record<_meta: record<install_source: string, name: string>, items: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "ignoreMappingUpdateErrors" $ignoreMappingUpdateErrors "scalar") (serialize-qp "skipDataStreamRollover" $skipDataStreamRollover "scalar") (serialize-qp "skipDependencyCheck" $skipDependencyCheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)" $qp)
  let body = {force: $force, ignore_constraints: $ignore_constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update package settings
#
# PUT /api/fleet/epm/packages/{pkgName}
# operationId: put-fleet-epm-packages-pkgname
export def "fleet-epm-packages put-fleet-epm-packages-pkgname" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --keepPoliciesUpToDate: oneof<nothing, bool>
  --namespace-customization-enabled-for: list # Namespaces for which namespace-level customization is enabled on this package.
]: any -> record<item: record<agent: record<privileges: record>, asset_tags: list<record>, assets: record, categories: list<string>, conditions: record<deprecated: record, elastic: record, kibana: record>, data_streams: list<record>, deprecated: record<description: string, replaced_by: record, since: string>, description: string, discovery: record<datasets: list, fields: list>, download: string, elasticsearch: record, format_version: string, icons: list<record>, installationInfo: record<additional_spaces_installed_kibana: record, created_at: string, experimental_data_stream_features: list, install_format_schema_version: string, install_source: string, install_status: string, installed_es: list, installed_kibana: list, installed_kibana_space_id: string, is_rollback_ttl_expired: bool, latest_executed_state: record, latest_install_failed_attempts: list, name: string, namespaces: list, previous_version: string, rolled_back: bool, type: string, updated_at: string, verification_key_id: string, verification_status: string, version: string>, internal: bool, keepPoliciesUpToDate: bool, latestVersion: string, license: string, licensePath: string, name: string, notice: string, owner: record<github: string, type: string>, path: string, policy_templates: list<record>, readme: string, release: string, screenshots: list<record>, signature_path: string, source: record<license: string>, status: string, title: string, type: any, var_groups: list<record>, vars: list<record>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)")
  let body = {keepPoliciesUpToDate: $keepPoliciesUpToDate, namespace_customization_enabled_for: $namespace_customization_enabled_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a package
#
# DELETE /api/fleet/epm/packages/{pkgName}/{pkgVersion}
# operationId: delete-fleet-epm-packages-pkgname-pkgversion
export def "fleet-epm-packages delete-fleet-epm-packages-pkgname-pkgversion" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, delete the package even if it has active package policies
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<items: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package
#
# GET /api/fleet/epm/packages/{pkgName}/{pkgVersion}
# operationId: get-fleet-epm-packages-pkgname-pkgversion
export def "fleet-epm-packages get-fleet-epm-packages-pkgname-pkgversion" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignoreUnverified: oneof<nothing, bool> # When true, returns the package even if the signature cannot be verified
  --prerelease: oneof<nothing, bool> # When true, include prerelease versions
  --full: oneof<nothing, bool> # When true, return the full package info including assets
  --withMetadata: oneof<nothing, bool> # When true, include package metadata such as whether it has package policies (default: false)
]: nothing -> record<item: record<agent: record<privileges: record>, asset_tags: list<record>, assets: record, categories: list<string>, conditions: record<deprecated: record, elastic: record, kibana: record>, data_streams: list<record>, deprecated: record<description: string, replaced_by: record, since: string>, description: string, discovery: record<datasets: list, fields: list>, download: string, elasticsearch: record, format_version: string, icons: list<record>, installationInfo: record<additional_spaces_installed_kibana: record, created_at: string, experimental_data_stream_features: list, install_format_schema_version: string, install_source: string, install_status: string, installed_es: list, installed_kibana: list, installed_kibana_space_id: string, is_rollback_ttl_expired: bool, latest_executed_state: record, latest_install_failed_attempts: list, name: string, namespaces: list, previous_version: string, rolled_back: bool, type: string, updated_at: string, verification_key_id: string, verification_status: string, version: string>, internal: bool, keepPoliciesUpToDate: bool, latestVersion: string, license: string, licensePath: string, name: string, notice: string, owner: record<github: string, type: string>, path: string, policy_templates: list<record>, readme: string, release: string, screenshots: list<record>, signature_path: string, source: record<license: string>, status: string, title: string, type: any, var_groups: list<record>, vars: list<record>, version: string>, metadata: record<has_policies: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreUnverified" $ignoreUnverified "scalar") (serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "withMetadata" $withMetadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install a package from the registry
#
# POST /api/fleet/epm/packages/{pkgName}/{pkgVersion}
# operationId: post-fleet-epm-packages-pkgname-pkgversion
export def "fleet-epm-packages post-fleet-epm-packages-pkgname-pkgversion" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prerelease: oneof<nothing, bool> # When true, allow installing prerelease versions
  --ignoreMappingUpdateErrors: oneof<nothing, bool> # When true, ignore mapping update errors during installation (default: false)
  --skipDataStreamRollover: oneof<nothing, bool> # When true, skip data stream rollover after installation (default: false)
  --skipDependencyCheck: oneof<nothing, bool> # Skip dependency validation when installing a package with dependencies (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool> # default: false
  --ignore-constraints: oneof<nothing, bool> # default: false
]: any -> record<_meta: record<install_source: string, name: string>, items: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "ignoreMappingUpdateErrors" $ignoreMappingUpdateErrors "scalar") (serialize-qp "skipDataStreamRollover" $skipDataStreamRollover "scalar") (serialize-qp "skipDependencyCheck" $skipDependencyCheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)" $qp)
  let body = {force: $force, ignore_constraints: $ignore_constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update package settings
#
# PUT /api/fleet/epm/packages/{pkgName}/{pkgVersion}
# operationId: put-fleet-epm-packages-pkgname-pkgversion
export def "fleet-epm-packages put-fleet-epm-packages-pkgname-pkgversion" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --keepPoliciesUpToDate: oneof<nothing, bool>
  --namespace-customization-enabled-for: list # Namespaces for which namespace-level customization is enabled on this package.
]: any -> record<item: record<agent: record<privileges: record>, asset_tags: list<record>, assets: record, categories: list<string>, conditions: record<deprecated: record, elastic: record, kibana: record>, data_streams: list<record>, deprecated: record<description: string, replaced_by: record, since: string>, description: string, discovery: record<datasets: list, fields: list>, download: string, elasticsearch: record, format_version: string, icons: list<record>, installationInfo: record<additional_spaces_installed_kibana: record, created_at: string, experimental_data_stream_features: list, install_format_schema_version: string, install_source: string, install_status: string, installed_es: list, installed_kibana: list, installed_kibana_space_id: string, is_rollback_ttl_expired: bool, latest_executed_state: record, latest_install_failed_attempts: list, name: string, namespaces: list, previous_version: string, rolled_back: bool, type: string, updated_at: string, verification_key_id: string, verification_status: string, version: string>, internal: bool, keepPoliciesUpToDate: bool, latestVersion: string, license: string, licensePath: string, name: string, notice: string, owner: record<github: string, type: string>, path: string, policy_templates: list<record>, readme: string, release: string, screenshots: list<record>, signature_path: string, source: record<license: string>, status: string, title: string, type: any, var_groups: list<record>, vars: list<record>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)")
  let body = {keepPoliciesUpToDate: $keepPoliciesUpToDate, namespace_customization_enabled_for: $namespace_customization_enabled_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a package file
#
# GET /api/fleet/epm/packages/{pkgName}/{pkgVersion}/{filePath}
# operationId: get-fleet-epm-packages-pkgname-pkgversion-filepath
export def "fleet-epm-packages get-fleet-epm-packages-pkgname-pkgversion-filepath" [
  pkgName: string
  pkgVersion: string
  filePath: string
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
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/($filePath)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete assets for a package
#
# DELETE /api/fleet/epm/packages/{pkgName}/{pkgVersion}/datastream_assets
# operationId: delete-fleet-epm-packages-pkgname-pkgversion-datastream-assets
export def "fleet-epm-packages-datastream-assets delete-fleet-epm-packages-pkgname-pkgversion-datastream-assets" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --packagePolicyId: string # The ID of the package policy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packagePolicyId" $packagePolicyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/datastream_assets" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get package dependencies
#
# GET /api/fleet/epm/packages/{pkgName}/{pkgVersion}/dependencies
# operationId: get-fleet-epm-packages-pkgname-pkgversion-dependencies
export def "fleet-epm-packages-dependencies get-fleet-epm-packages-pkgname-pkgversion-dependencies" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<name: string, title: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Kibana assets for a package
#
# DELETE /api/fleet/epm/packages/{pkgName}/{pkgVersion}/kibana_assets
# operationId: delete-fleet-epm-packages-pkgname-pkgversion-kibana-assets
export def "fleet-epm-packages-kibana-assets delete-fleet-epm-packages-pkgname-pkgversion-kibana-assets" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/kibana_assets")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install Kibana assets for a package
#
# POST /api/fleet/epm/packages/{pkgName}/{pkgVersion}/kibana_assets
# operationId: post-fleet-epm-packages-pkgname-pkgversion-kibana-assets
export def "fleet-epm-packages-kibana-assets post-fleet-epm-packages-pkgname-pkgversion-kibana-assets" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool>
  --space-ids: list # When provided, assets are installed in the specified spaces instead of the current space.
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/kibana_assets")
  let body = {force: $force, space_ids: $space_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Install Kibana alert rule for a package
#
# POST /api/fleet/epm/packages/{pkgName}/{pkgVersion}/rule_assets
# operationId: post-fleet-epm-packages-pkgname-pkgversion-rule-assets
export def "fleet-epm-packages-rule-assets post-fleet-epm-packages-pkgname-pkgversion-rule-assets" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool>
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/rule_assets")
  let body = {force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorize transforms
#
# POST /api/fleet/epm/packages/{pkgName}/{pkgVersion}/transforms/authorize
# operationId: post-fleet-epm-packages-pkgname-pkgversion-transforms-authorize
# --transforms item shape: {transformId: string}
export def "fleet-epm-packages-transforms-authorize post-fleet-epm-packages-pkgname-pkgversion-transforms-authorize" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prerelease: oneof<nothing, bool> # When true, allow prerelease versions
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  transforms: list # item shape: {transformId: string}
]: any -> table<error: any, success: bool, transformId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prerelease" $prerelease "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/($pkgVersion)/transforms/authorize" $qp)
  let body = {transforms: $transforms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Review a pending policy upgrade for a package with deprecations
#
# POST /api/fleet/epm/packages/{pkgName}/review_upgrade
# operationId: post-fleet-epm-packages-pkgname-review-upgrade
export def "fleet-epm-packages-review-upgrade post-fleet-epm-packages-pkgname-review-upgrade" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  action: string@action-completer-2
  target_version: string
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/review_upgrade")
  let body = {action: $action, target_version: $target_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rollback a package to previous version
#
# POST /api/fleet/epm/packages/{pkgName}/rollback
# operationId: post-fleet-epm-packages-pkgname-rollback
export def "fleet-epm-packages-rollback post-fleet-epm-packages-pkgname-rollback" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<success: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/rollback")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get package stats
#
# GET /api/fleet/epm/packages/{pkgName}/stats
# operationId: get-fleet-epm-packages-pkgname-stats
export def "fleet-epm-packages-stats get-fleet-epm-packages-pkgname-stats" [
  pkgName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response: record<agent_policy_count: float, package_policy_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/epm/packages/($pkgName)/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get installed packages
#
# GET /api/fleet/epm/packages/installed
# operationId: get-fleet-epm-packages-installed
export def "fleet-epm-packages-installed get-fleet-epm-packages-installed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataStreamType: string@dataStreamType-completer # Filter by data stream type
  --showOnlyActiveDataStreams: oneof<nothing, bool> # When true, only return packages with active data streams
  --nameQuery: string # Filter packages by name
  --searchAfter: list # Sort values from the previous page for `search_after` pagination
  --perPage: float # Number of results per page (default: 15)
  --sortOrder: string@sortOrder-completer # Sort order, ascending or descending (default: asc)
]: nothing -> record<items: table<dataStreams: list, description: string, icons: list, name: string, status: string, title: string, version: string>, searchAfter: list<any>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataStreamType" $dataStreamType "scalar") (serialize-qp "showOnlyActiveDataStreams" $showOnlyActiveDataStreams "scalar") (serialize-qp "nameQuery" $nameQuery "scalar") (serialize-qp "searchAfter" $searchAfter "multi") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/epm/packages/installed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a limited package list
#
# GET /api/fleet/epm/packages/limited
# operationId: get-fleet-epm-packages-limited
export def "fleet-epm-packages-limited get-fleet-epm-packages-limited" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/epm/packages/limited")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an inputs template
#
# GET /api/fleet/epm/templates/{pkgName}/{pkgVersion}/inputs
# operationId: get-fleet-epm-templates-pkgname-pkgversion-inputs
export def "fleet-epm-templates-inputs get-fleet-epm-templates-pkgname-pkgversion-inputs" [
  pkgName: string
  pkgVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer-1 # Output format for the inputs template: json, yml, or yaml (default: json)
  --prerelease: oneof<nothing, bool> # When true, allow prerelease versions
  --ignoreUnverified: oneof<nothing, bool> # When true, return inputs even if the package signature cannot be verified
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "prerelease" $prerelease "scalar") (serialize-qp "ignoreUnverified" $ignoreUnverified "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/epm/templates/($pkgName)/($pkgVersion)/inputs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package signature verification key ID
#
# GET /api/fleet/epm/verification_key_id
# operationId: get-fleet-epm-verification-key-id
export def "fleet-epm-verification-key-id get-fleet-epm-verification-key-id" [
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
  let full_url = (build-url $base "/api/fleet/epm/verification_key_id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Fleet Server hosts
#
# GET /api/fleet/fleet_server_hosts
# operationId: get-fleet-fleet-server-hosts
export def "fleet-fleet-server-hosts get-fleet-fleet-server-hosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<host_urls: list, id: string, is_default: bool, is_internal: bool, is_preconfigured: bool, name: string, proxy_id: string, secrets: record, ssl: record>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/fleet_server_hosts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Fleet Server host
#
# POST /api/fleet/fleet_server_hosts
# operationId: post-fleet-fleet-server-hosts
# --secrets shape: {ssl?: record}
# --ssl shape: {agent_certificate?: string, agent_certificate_authorities?: list, agent_key?: string, certificate?: string, certificate_authorities?: list, client_auth?: "optional"|"required"|"none", es_certificate?: string, es_certificate_authorities?: list, es_key?: string, key?: string}
export def "fleet-fleet-server-hosts post-fleet-fleet-server-hosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  host_urls: list
  --id: string
  --is-default: oneof<nothing, bool> # default: false
  --is-internal: oneof<nothing, bool>
  --is-preconfigured: oneof<nothing, bool> # default: false
  name: string
  --proxy-id: string # nullable
  --secrets: record # shape: {ssl?: record}
  --ssl: record # nullable — shape: {agent_certificate?: string, agent_certificate_authorities?: list, agent_key?: string, certificate?: string, certificate_authorities?: list, client_auth?: "optional"|"required"|"none", es_certificate?: string, es_certificate_authorities?: list, es_key?: string, key?: string}
]: any -> record<item: record<host_urls: list<string>, id: string, is_default: bool, is_internal: bool, is_preconfigured: bool, name: string, proxy_id: string, secrets: record<ssl: record>, ssl: record<agent_certificate: string, agent_certificate_authorities: list, agent_key: string, certificate: string, certificate_authorities: list, client_auth: string, es_certificate: string, es_certificate_authorities: list, es_key: string, key: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/fleet_server_hosts")
  let body = {host_urls: $host_urls, id: $id, is_default: $is_default, is_internal: $is_internal, is_preconfigured: $is_preconfigured, name: $name, proxy_id: $proxy_id, secrets: $secrets, ssl: $ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Fleet Server host
#
# DELETE /api/fleet/fleet_server_hosts/{itemId}
# operationId: delete-fleet-fleet-server-hosts-itemid
export def "fleet-fleet-server-hosts delete-fleet-fleet-server-hosts-itemid" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/fleet_server_hosts/($itemId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Fleet Server host
#
# GET /api/fleet/fleet_server_hosts/{itemId}
# operationId: get-fleet-fleet-server-hosts-itemid
export def "fleet-fleet-server-hosts get-fleet-fleet-server-hosts-itemid" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<host_urls: list<string>, id: string, is_default: bool, is_internal: bool, is_preconfigured: bool, name: string, proxy_id: string, secrets: record<ssl: record>, ssl: record<agent_certificate: string, agent_certificate_authorities: list, agent_key: string, certificate: string, certificate_authorities: list, client_auth: string, es_certificate: string, es_certificate_authorities: list, es_key: string, key: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/fleet_server_hosts/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Fleet Server host
#
# PUT /api/fleet/fleet_server_hosts/{itemId}
# operationId: put-fleet-fleet-server-hosts-itemid
# --secrets shape: {ssl?: record}
# --ssl shape: {agent_certificate?: string, agent_certificate_authorities?: list, agent_key?: string, certificate?: string, certificate_authorities?: list, client_auth?: "optional"|"required"|"none", es_certificate?: string, es_certificate_authorities?: list, es_key?: string, key?: string}
export def "fleet-fleet-server-hosts put-fleet-fleet-server-hosts-itemid" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --host-urls: list
  --is-default: oneof<nothing, bool>
  --is-internal: oneof<nothing, bool>
  --name: string
  --proxy-id: string # nullable
  --secrets: record # shape: {ssl?: record}
  --ssl: record # nullable — shape: {agent_certificate?: string, agent_certificate_authorities?: list, agent_key?: string, certificate?: string, certificate_authorities?: list, client_auth?: "optional"|"required"|"none", es_certificate?: string, es_certificate_authorities?: list, es_key?: string, key?: string}
]: any -> record<item: record<host_urls: list<string>, id: string, is_default: bool, is_internal: bool, is_preconfigured: bool, name: string, proxy_id: string, secrets: record<ssl: record>, ssl: record<agent_certificate: string, agent_certificate_authorities: list, agent_key: string, certificate: string, certificate_authorities: list, client_auth: string, es_certificate: string, es_certificate_authorities: list, es_key: string, key: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/fleet_server_hosts/($itemId)")
  let body = {host_urls: $host_urls, is_default: $is_default, is_internal: $is_internal, name: $name, proxy_id: $proxy_id, secrets: $secrets, ssl: $ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check Fleet Server health
#
# POST /api/fleet/health_check
# operationId: post-fleet-health-check
export def "fleet-health-check post-fleet-health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  id: string
]: any -> record<host_id: string, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/health_check")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a full K8s agent manifest
#
# GET /api/fleet/kubernetes
# operationId: get-fleet-kubernetes
export def "fleet-kubernetes get-fleet-kubernetes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --download: oneof<nothing, bool> # If true, returns the manifest as a downloadable file
  --fleetServer: string # Fleet Server host URL to include in the manifest
  --enrolToken: string # Enrollment token to include in the manifest
]: nothing -> record<item: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "fleetServer" $fleetServer "scalar") (serialize-qp "enrolToken" $enrolToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/kubernetes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download an agent manifest
#
# GET /api/fleet/kubernetes/download
# operationId: get-fleet-kubernetes-download
export def "fleet-kubernetes-download get-fleet-kubernetes-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --download: oneof<nothing, bool> # If true, returns the manifest as a downloadable file
  --fleetServer: string # Fleet Server host URL to include in the manifest
  --enrolToken: string # Enrollment token to include in the manifest
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "fleetServer" $fleetServer "scalar") (serialize-qp "enrolToken" $enrolToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/kubernetes/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Logstash API key
#
# POST /api/fleet/logstash_api_keys
# operationId: post-fleet-logstash-api-keys
export def "fleet-logstash-api-keys post-fleet-logstash-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/logstash_api_keys")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate a Fleet message signing key pair
#
# POST /api/fleet/message_signing_service/rotate_key_pair
# operationId: post-fleet-message-signing-service-rotate-key-pair
export def "fleet-message-signing-service-rotate-key-pair post-fleet-message-signing-service-rotate-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acknowledge: oneof<nothing, bool> # Set to true to confirm you understand the risks of rotating the key pair (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acknowledge" $acknowledge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/message_signing_service/rotate_key_pair" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outputs
#
# GET /api/fleet/outputs
# operationId: get-fleet-outputs
export def "fleet-outputs get-fleet-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: list<any>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/outputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create output
#
# POST /api/fleet/outputs
# Discriminator (request): type = elasticsearch, kafka, logstash, remote_elasticsearch
# operationId: post-fleet-outputs
# --secrets shape: {ssl?: record}
# --hash shape: {hash?: string, random?: bool}
# --headers item shape: {key: string, value: string}
# --random shape: {group_events?: float}
# --round_robin shape: {group_events?: float}
# --sasl shape: {mechanism?: "PLAIN"|"SCRAM-SHA-256"|"SCRAM-SHA-512"}
export def "fleet-outputs post-fleet-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --allow-edit: list
  --ca-sha256: string # nullable
  --ca-trusted-fingerprint: string # nullable
  --config-yaml: string # nullable
  --hosts: list
  --id: string
  --is-default: oneof<nothing, bool> # default: false
  --is-default-monitoring: oneof<nothing, bool> # default: false
  --is-internal: oneof<nothing, bool>
  --is-preconfigured: oneof<nothing, bool>
  --name: string
  --otel-disable-beatsauth: oneof<nothing, bool> # nullable
  --otel-exporter-config-yaml: string # nullable
  --preset: string@preset-completer
  --proxy-id: string # nullable
  --secrets: record # shape: {ssl?: record}
  --shipper: any # nullable
  --ssl: any # nullable
  type: string@type-completer-4
  --write-to-logs-streams: oneof<nothing, bool> # nullable
  --kibana-api-key: string # nullable
  --kibana-url: string # nullable
  --service-token: string # nullable
  --sync-integrations: oneof<nothing, bool>
  --sync-uninstalled-integrations: oneof<nothing, bool>
  --auth-type: string@auth-type-completer
  --broker-timeout: float
  --client-id: string
  --compression: string@compression-completer
  --compression-level: float # nullable
  --connection-type: string@connection-type-completer
  --hash: record # shape: {hash?: string, random?: bool}
  --headers: list # item shape: {key: string, value: string}
  --key: string
  --partition: string@partition-completer
  --password: string # nullable
  --random: record # shape: {group_events?: float}
  --required-acks: int@required-acks-completer
  --round-robin: record # shape: {group_events?: float}
  --sasl: record # nullable — shape: {mechanism?: "PLAIN"|"SCRAM-SHA-256"|"SCRAM-SHA-512"}
  --timeout: float
  --topic: string
  --username: string # nullable
  --version: string
]: any -> record<item: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/outputs")
  let body = {allow_edit: $allow_edit, ca_sha256: $ca_sha256, ca_trusted_fingerprint: $ca_trusted_fingerprint, config_yaml: $config_yaml, hosts: $hosts, id: $id, is_default: $is_default, is_default_monitoring: $is_default_monitoring, is_internal: $is_internal, is_preconfigured: $is_preconfigured, name: $name, otel_disable_beatsauth: $otel_disable_beatsauth, otel_exporter_config_yaml: $otel_exporter_config_yaml, preset: $preset, proxy_id: $proxy_id, secrets: $secrets, shipper: $shipper, ssl: $ssl, type: $type, write_to_logs_streams: $write_to_logs_streams, kibana_api_key: $kibana_api_key, kibana_url: $kibana_url, service_token: $service_token, sync_integrations: $sync_integrations, sync_uninstalled_integrations: $sync_uninstalled_integrations, auth_type: $auth_type, broker_timeout: $broker_timeout, client_id: $client_id, compression: $compression, compression_level: $compression_level, connection_type: $connection_type, hash: $hash, headers: $headers, key: $key, partition: $partition, password: $password, random: $random, required_acks: $required_acks, round_robin: $round_robin, sasl: $sasl, timeout: $timeout, topic: $topic, username: $username, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete output
#
# DELETE /api/fleet/outputs/{outputId}
# operationId: delete-fleet-outputs-outputid
export def "fleet-outputs delete-fleet-outputs-outputid" [
  outputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/outputs/($outputId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get output
#
# GET /api/fleet/outputs/{outputId}
# operationId: get-fleet-outputs-outputid
export def "fleet-outputs get-fleet-outputs-outputid" [
  outputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/outputs/($outputId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update output
#
# PUT /api/fleet/outputs/{outputId}
# operationId: put-fleet-outputs-outputid
# --secrets shape: {ssl?: record}
# --hash shape: {hash?: string, random?: bool}
# --headers item shape: {key: string, value: string}
# --random shape: {group_events?: float}
# --round_robin shape: {group_events?: float}
# --sasl shape: {mechanism?: "PLAIN"|"SCRAM-SHA-256"|"SCRAM-SHA-512"}
export def "fleet-outputs put-fleet-outputs-outputid" [
  outputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --allow-edit: list
  --ca-sha256: string # nullable
  --ca-trusted-fingerprint: string # nullable
  --config-yaml: string # nullable
  --hosts: list
  --id: string
  --is-default: oneof<nothing, bool>
  --is-default-monitoring: oneof<nothing, bool>
  --is-internal: oneof<nothing, bool>
  --is-preconfigured: oneof<nothing, bool>
  --name: string
  --otel-disable-beatsauth: oneof<nothing, bool> # nullable
  --otel-exporter-config-yaml: string # nullable
  --preset: string@preset-completer
  --proxy-id: string # nullable
  --secrets: record # shape: {ssl?: record}
  --shipper: any # nullable
  --ssl: any # nullable
  --type: string@type-completer-5
  --write-to-logs-streams: oneof<nothing, bool> # nullable
  --kibana-api-key: string # nullable
  --kibana-url: string # nullable
  --service-token: string # nullable
  --sync-integrations: oneof<nothing, bool>
  --sync-uninstalled-integrations: oneof<nothing, bool>
  --auth-type: string@auth-type-completer
  --broker-timeout: float
  --client-id: string
  --compression: string@compression-completer
  --compression-level: float # nullable
  --connection-type: string@connection-type-completer
  --hash: record # shape: {hash?: string, random?: bool}
  --headers: list # item shape: {key: string, value: string}
  --key: string
  --partition: string@partition-completer
  --password: string # nullable
  --random: record # shape: {group_events?: float}
  --required-acks: int@required-acks-completer
  --round-robin: record # shape: {group_events?: float}
  --sasl: record # nullable — shape: {mechanism?: "PLAIN"|"SCRAM-SHA-256"|"SCRAM-SHA-512"}
  --timeout: float
  --topic: string
  --username: string # nullable
  --version: string
]: any -> record<item: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/outputs/($outputId)")
  let body = {allow_edit: $allow_edit, ca_sha256: $ca_sha256, ca_trusted_fingerprint: $ca_trusted_fingerprint, config_yaml: $config_yaml, hosts: $hosts, id: $id, is_default: $is_default, is_default_monitoring: $is_default_monitoring, is_internal: $is_internal, is_preconfigured: $is_preconfigured, name: $name, otel_disable_beatsauth: $otel_disable_beatsauth, otel_exporter_config_yaml: $otel_exporter_config_yaml, preset: $preset, proxy_id: $proxy_id, secrets: $secrets, shipper: $shipper, ssl: $ssl, type: $type, write_to_logs_streams: $write_to_logs_streams, kibana_api_key: $kibana_api_key, kibana_url: $kibana_url, service_token: $service_token, sync_integrations: $sync_integrations, sync_uninstalled_integrations: $sync_uninstalled_integrations, auth_type: $auth_type, broker_timeout: $broker_timeout, client_id: $client_id, compression: $compression, compression_level: $compression_level, connection_type: $connection_type, hash: $hash, headers: $headers, key: $key, partition: $partition, password: $password, random: $random, required_acks: $required_acks, round_robin: $round_robin, sasl: $sasl, timeout: $timeout, topic: $topic, username: $username, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the latest output health
#
# GET /api/fleet/outputs/{outputId}/health
# operationId: get-fleet-outputs-outputid-health
export def "fleet-outputs-health get-fleet-outputs-outputid-health" [
  outputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, state: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/outputs/($outputId)/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get package policies
#
# GET /api/fleet/package_policies
# operationId: get-fleet-package-policies
export def "fleet-package-policies get-fleet-package-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number
  --perPage: float # Number of results per page
  --sortField: string # Field to sort results by
  --sortOrder: string@sortOrder-completer # Sort order, ascending or descending
  --showUpgradeable: oneof<nothing, bool> # When true, only show policies with available upgrades
  --kuery: string # A KQL query string to filter results
  --format: string@format-completer # Format for the response: simplified or legacy
  --withAgentCount: oneof<nothing, bool> # When true, include the agent count per package policy
]: nothing -> record<items: table<additional_datastreams_permissions: list, agents: float, cloud_connector_id: string, cloud_connector_name: string, condition: string, created_at: string, created_by: string, description: string, elasticsearch: record, enabled: bool, global_data_tags: list, id: string, inputs: any, is_managed: bool, name: string, namespace: string, output_id: string, overrides: record, package: record, package_agent_version_condition: string, policy_id: string, policy_ids: list, revision: float, secret_references: list, spaceIds: list, supports_agentless: bool, supports_cloud_connector: bool, updated_at: string, updated_by: string, var_group_selections: record, vars: any, version: string>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "showUpgradeable" $showUpgradeable "scalar") (serialize-qp "kuery" $kuery "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "withAgentCount" $withAgentCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/package_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a package policy
#
# POST /api/fleet/package_policies
# operationId: post-fleet-package-policies
# --global_data_tags item shape: {name: string, value: any}
# --inputs item shape: {condition?: string, config?: record, deprecated?: record, enabled: bool, id?: string, keep_enabled?: bool, migrate_from?: string, name?: string, policy_template?: string, streams?: list, type: string, var_group_selections?: record, vars?: record}
# --overrides shape: {inputs?: record}
# --package shape: {experimental_data_stream_features?: list, fips_compatible?: bool, name: string, requires_root?: bool, title?: string, version: string}
# --cloud_connector shape: {cloud_connector_id?: string, enabled?: bool, name?: string, target_csp?: "aws"|"azure"|"gcp"}
@deprecated --flag policy-id
@deprecated --flag supports-agentless
export def "fleet-package-policies post-fleet-package-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --additional-datastreams-permissions: list # Additional data stream permissions that will be added to the agent policy. (nullable)
  --cloud-connector-id: string # ID of the cloud connector associated with this package policy. (nullable)
  --cloud-connector-name: string # Transient field for cloud connector name during creation. (nullable)
  --condition: string # Agent condition expression to evaluate whether to apply this integration to its inputs. (nullable)
  --create-dataset-templates: oneof<nothing, bool> # When true, install dedicated index templates for streams with a custom data_stream.dataset. Defaults to true for input packages, false for integration packages.
  --description: string # Package policy description
  --enabled: oneof<nothing, bool>
  --force: oneof<nothing, bool> # Force package policy creation even if the package is not verified, or if the agent policy is managed.
  --global-data-tags: list # nullable — item shape: {name: string, value: any}
  --id: string # Package policy unique identifier
  --inputs: list # item shape: {condition?: string, config?: record, deprecated?: record, enabled: bool, id?: string, keep_enabled?: bool, migrate_from?: string, name?: string, policy_template?: string, streams?: list, type: string, var_group_selections?: record, vars?: record}
  --is-managed: oneof<nothing, bool>
  --name: string # Unique name for the package policy.
  --namespace: string # The package policy namespace. Leave blank to inherit the agent policy's namespace.
  --output-id: string # nullable
  --overrides: record # Override settings that are defined in the package policy. The override option should be used only in unusual circumstances and not as a routine procedure. (nullable) — shape: {inputs?: record}
  --package: record # shape: {experimental_data_stream_features?: list, fips_compatible?: bool, name: string, requires_root?: bool, title?: string, version: string}
  --package-agent-version-condition: string
  --policy-id: string # ID of the agent policy which the package policy will be added to. (DEPRECATED, nullable)
  --policy-ids: list
  --spaceIds: list
  --supports-agentless: oneof<nothing, bool> # Indicates whether the package policy belongs to an agentless agent policy. Deprecated in favor of the Fleet agentless policies API. (DEPRECATED, nullable)
  --supports-cloud-connector: oneof<nothing, bool> # Indicates whether the package policy supports cloud connectors. (nullable)
  --var-group-selections: record # Variable group selections. Maps var_group name to the selected option name within that group.
  --vars: record # Package variable (see integration documentation for more information)
  --cloud-connector: record # shape: {cloud_connector_id?: string, enabled?: bool, name?: string, target_csp?: "aws"|"azure"|"gcp"}
  --policy-template: string # The policy template to use for the agentless package policy. If not provided, the default policy template will be used.
]: any -> record<item: record<additional_datastreams_permissions: list<string>, agents: float, cloud_connector_id: string, cloud_connector_name: string, condition: string, created_at: string, created_by: string, description: string, elasticsearch: record<privileges: record>, enabled: bool, global_data_tags: list<record>, id: string, inputs: any, is_managed: bool, name: string, namespace: string, output_id: string, overrides: record<inputs: record>, package: record<experimental_data_stream_features: list, fips_compatible: bool, name: string, requires_root: bool, title: string, version: string>, package_agent_version_condition: string, policy_id: string, policy_ids: list<string>, revision: float, secret_references: list<record>, spaceIds: list<string>, supports_agentless: bool, supports_cloud_connector: bool, updated_at: string, updated_by: string, var_group_selections: record, vars: any, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/package_policies" $qp)
  let body = {additional_datastreams_permissions: $additional_datastreams_permissions, cloud_connector_id: $cloud_connector_id, cloud_connector_name: $cloud_connector_name, condition: $condition, create_dataset_templates: $create_dataset_templates, description: $description, enabled: $enabled, force: $force, global_data_tags: $global_data_tags, id: $id, inputs: $inputs, is_managed: $is_managed, name: $name, namespace: $namespace, output_id: $output_id, overrides: $overrides, package: $package, package_agent_version_condition: $package_agent_version_condition, policy_id: $policy_id, policy_ids: $policy_ids, spaceIds: $spaceIds, supports_agentless: $supports_agentless, supports_cloud_connector: $supports_cloud_connector, var_group_selections: $var_group_selections, vars: $vars, cloud_connector: $cloud_connector, policy_template: $policy_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk get package policies
#
# POST /api/fleet/package_policies/_bulk_get
# operationId: post-fleet-package-policies-bulk-get
export def "fleet-package-policies-bulk-get post-fleet-package-policies-bulk-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  ids: list # list of package policy ids
  --ignoreMissing: oneof<nothing, bool>
]: any -> record<items: table<additional_datastreams_permissions: list, agents: float, cloud_connector_id: string, cloud_connector_name: string, condition: string, created_at: string, created_by: string, description: string, elasticsearch: record, enabled: bool, global_data_tags: list, id: string, inputs: any, is_managed: bool, name: string, namespace: string, output_id: string, overrides: record, package: record, package_agent_version_condition: string, policy_id: string, policy_ids: list, revision: float, secret_references: list, spaceIds: list, supports_agentless: bool, supports_cloud_connector: bool, updated_at: string, updated_by: string, var_group_selections: record, vars: any, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/package_policies/_bulk_get" $qp)
  let body = {ids: $ids, ignoreMissing: $ignoreMissing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a package policy
#
# DELETE /api/fleet/package_policies/{packagePolicyId}
# operationId: delete-fleet-package-policies-packagepolicyid
export def "fleet-package-policies delete-fleet-package-policies-packagepolicyid" [
  packagePolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, delete the package policy even if it is managed
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/package_policies/($packagePolicyId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package policy
#
# GET /api/fleet/package_policies/{packagePolicyId}
# operationId: get-fleet-package-policies-packagepolicyid
export def "fleet-package-policies get-fleet-package-policies-packagepolicyid" [
  packagePolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
]: nothing -> record<item: record<additional_datastreams_permissions: list<string>, agents: float, cloud_connector_id: string, cloud_connector_name: string, condition: string, created_at: string, created_by: string, description: string, elasticsearch: record<privileges: record>, enabled: bool, global_data_tags: list<record>, id: string, inputs: any, is_managed: bool, name: string, namespace: string, output_id: string, overrides: record<inputs: record>, package: record<experimental_data_stream_features: list, fips_compatible: bool, name: string, requires_root: bool, title: string, version: string>, package_agent_version_condition: string, policy_id: string, policy_ids: list<string>, revision: float, secret_references: list<record>, spaceIds: list<string>, supports_agentless: bool, supports_cloud_connector: bool, updated_at: string, updated_by: string, var_group_selections: record, vars: any, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/package_policies/($packagePolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a package policy
#
# PUT /api/fleet/package_policies/{packagePolicyId}
# operationId: put-fleet-package-policies-packagepolicyid
# --global_data_tags item shape: {name: string, value: any}
# --inputs item shape: {condition?: string, config?: record, deprecated?: record, enabled: bool, id?: string, keep_enabled?: bool, migrate_from?: string, name?: string, policy_template?: string, streams?: list, type: string, var_group_selections?: record, vars?: record}
# --overrides shape: {inputs?: record}
# --package shape: {experimental_data_stream_features?: list, fips_compatible?: bool, name: string, requires_root?: bool, title?: string, version: string}
# --cloud_connector shape: {cloud_connector_id?: string, enabled?: bool, name?: string, target_csp?: "aws"|"azure"|"gcp"}
@deprecated --flag policy-id
export def "fleet-package-policies put-fleet-package-policies-packagepolicyid" [
  packagePolicyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format for the response: simplified or legacy
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --additional-datastreams-permissions: list # Additional data stream permissions that will be added to the agent policy. (nullable)
  --cloud-connector-id: string # ID of the cloud connector associated with this package policy. (nullable)
  --cloud-connector-name: string # Transient field for cloud connector name during creation. (nullable)
  --condition: string # Agent condition expression to evaluate whether to apply this integration to its inputs. (nullable)
  --description: string # Package policy description
  --enabled: oneof<nothing, bool>
  --force: oneof<nothing, bool>
  --global-data-tags: list # nullable — item shape: {name: string, value: any}
  --inputs: list # item shape: {condition?: string, config?: record, deprecated?: record, enabled: bool, id?: string, keep_enabled?: bool, migrate_from?: string, name?: string, policy_template?: string, streams?: list, type: string, var_group_selections?: record, vars?: record}
  --is-managed: oneof<nothing, bool>
  --name: string
  --namespace: string # The package policy namespace. Leave blank to inherit the agent policy's namespace.
  --output-id: string # nullable
  --overrides: record # Override settings that are defined in the package policy. The override option should be used only in unusual circumstances and not as a routine procedure. (nullable) — shape: {inputs?: record}
  --package: record # shape: {experimental_data_stream_features?: list, fips_compatible?: bool, name: string, requires_root?: bool, title?: string, version: string}
  --package-agent-version-condition: string
  --policy-id: string # ID of the agent policy which the package policy will be added to. (DEPRECATED, nullable)
  --policy-ids: list
  --spaceIds: list
  --supports-agentless: oneof<nothing, bool> # Indicates whether the package policy belongs to an agentless agent policy. (nullable)
  --supports-cloud-connector: oneof<nothing, bool> # Indicates whether the package policy supports cloud connectors. (nullable)
  --var-group-selections: record # Variable group selections. Maps var_group name to the selected option name within that group.
  --vars: record # Package variable (see integration documentation for more information)
  --version: string
  --cloud-connector: record # shape: {cloud_connector_id?: string, enabled?: bool, name?: string, target_csp?: "aws"|"azure"|"gcp"}
  --create-dataset-templates: oneof<nothing, bool> # When true, install dedicated index templates for streams with a custom data_stream.dataset. Defaults to true for input packages, false for integration packages.
  --id: string # Policy unique identifier.
  --policy-template: string # The policy template to use for the agentless package policy. If not provided, the default policy template will be used.
]: any -> record<item: record<additional_datastreams_permissions: list<string>, agents: float, cloud_connector_id: string, cloud_connector_name: string, condition: string, created_at: string, created_by: string, description: string, elasticsearch: record<privileges: record>, enabled: bool, global_data_tags: list<record>, id: string, inputs: any, is_managed: bool, name: string, namespace: string, output_id: string, overrides: record<inputs: record>, package: record<experimental_data_stream_features: list, fips_compatible: bool, name: string, requires_root: bool, title: string, version: string>, package_agent_version_condition: string, policy_id: string, policy_ids: list<string>, revision: float, secret_references: list<record>, spaceIds: list<string>, supports_agentless: bool, supports_cloud_connector: bool, updated_at: string, updated_by: string, var_group_selections: record, vars: any, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/fleet/package_policies/($packagePolicyId)" $qp)
  let body = {additional_datastreams_permissions: $additional_datastreams_permissions, cloud_connector_id: $cloud_connector_id, cloud_connector_name: $cloud_connector_name, condition: $condition, description: $description, enabled: $enabled, force: $force, global_data_tags: $global_data_tags, inputs: $inputs, is_managed: $is_managed, name: $name, namespace: $namespace, output_id: $output_id, overrides: $overrides, package: $package, package_agent_version_condition: $package_agent_version_condition, policy_id: $policy_id, policy_ids: $policy_ids, spaceIds: $spaceIds, supports_agentless: $supports_agentless, supports_cloud_connector: $supports_cloud_connector, var_group_selections: $var_group_selections, vars: $vars, version: $version, cloud_connector: $cloud_connector, create_dataset_templates: $create_dataset_templates, id: $id, policy_template: $policy_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete package policies
#
# POST /api/fleet/package_policies/delete
# operationId: post-fleet-package-policies-delete
export def "fleet-package-policies-delete post-fleet-package-policies-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --force: oneof<nothing, bool>
  packagePolicyIds: list
]: any -> table<body: record<message: string>, id: string, name: string, statusCode: float, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/package_policies/delete")
  let body = {force: $force, packagePolicyIds: $packagePolicyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrade a package policy
#
# POST /api/fleet/package_policies/upgrade
# operationId: post-fleet-package-policies-upgrade
export def "fleet-package-policies-upgrade post-fleet-package-policies-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  packagePolicyIds: list
]: any -> table<body: record<message: string>, id: string, name: string, statusCode: float, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/package_policies/upgrade")
  let body = {packagePolicyIds: $packagePolicyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dry run a package policy upgrade
#
# POST /api/fleet/package_policies/upgrade/dryrun
# operationId: post-fleet-package-policies-upgrade-dryrun
export def "fleet-package-policies-upgrade-dryrun post-fleet-package-policies-upgrade-dryrun" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  packagePolicyIds: list
  --packageVersion: string
]: any -> table<agent_diff: list<list>, body: record<message: string>, diff: list<any>, hasErrors: bool, name: string, statusCode: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/package_policies/upgrade/dryrun")
  let body = {packagePolicyIds: $packagePolicyIds, packageVersion: $packageVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get proxies
#
# GET /api/fleet/proxies
# operationId: get-fleet-proxies
export def "fleet-proxies get-fleet-proxies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<certificate: string, certificate_authorities: string, certificate_key: string, id: string, is_preconfigured: bool, name: string, proxy_headers: record, url: string>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/proxies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a proxy
#
# POST /api/fleet/proxies
# operationId: post-fleet-proxies
export def "fleet-proxies post-fleet-proxies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --certificate: string # nullable
  --certificate-authorities: string # nullable
  --certificate-key: string # nullable
  --id: string
  --is-preconfigured: oneof<nothing, bool> # default: false
  name: string
  --proxy-headers: record # nullable
  --body-url: string
]: any -> record<item: record<certificate: string, certificate_authorities: string, certificate_key: string, id: string, is_preconfigured: bool, name: string, proxy_headers: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/proxies")
  let body = {certificate: $certificate, certificate_authorities: $certificate_authorities, certificate_key: $certificate_key, id: $id, is_preconfigured: $is_preconfigured, name: $name, proxy_headers: $proxy_headers, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a proxy
#
# DELETE /api/fleet/proxies/{itemId}
# operationId: delete-fleet-proxies-itemid
export def "fleet-proxies delete-fleet-proxies-itemid" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/proxies/($itemId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a proxy
#
# GET /api/fleet/proxies/{itemId}
# operationId: get-fleet-proxies-itemid
export def "fleet-proxies get-fleet-proxies-itemid" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<certificate: string, certificate_authorities: string, certificate_key: string, id: string, is_preconfigured: bool, name: string, proxy_headers: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/proxies/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a proxy
#
# PUT /api/fleet/proxies/{itemId}
# operationId: put-fleet-proxies-itemid
export def "fleet-proxies put-fleet-proxies-itemid" [
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --certificate: string # nullable
  --certificate-authorities: string # nullable
  --certificate-key: string # nullable
  --name: string
  --proxy-headers: record # nullable
  --body-url: string
]: any -> record<item: record<certificate: string, certificate_authorities: string, certificate_key: string, id: string, is_preconfigured: bool, name: string, proxy_headers: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/proxies/($itemId)")
  let body = {certificate: $certificate, certificate_authorities: $certificate_authorities, certificate_key: $certificate_key, name: $name, proxy_headers: $proxy_headers, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a service token
#
# POST /api/fleet/service_tokens
# operationId: post-fleet-service-tokens
export def "fleet-service-tokens post-fleet-service-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --remote: oneof<nothing, bool> # default: false
]: any -> record<name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/service_tokens")
  let body = {remote: $remote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get settings
#
# GET /api/fleet/settings
# operationId: get-fleet-settings
export def "fleet-settings get-fleet-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<action_secret_storage_requirements_met: bool, delete_unenrolled_agents: record<enabled: bool, is_preconfigured: bool>, download_source_auth_secret_storage_requirements_met: bool, has_seen_add_data_notice: bool, id: string, ilm_migration_status: record<logs: string, metrics: string, synthetics: string>, integration_knowledge_enabled: bool, output_secret_storage_requirements_met: bool, preconfigured_fields: list<string>, prerelease_integrations_enabled: bool, secret_storage_requirements_met: bool, ssl_secret_storage_requirements_met: bool, use_space_awareness_migration_started_at: string, use_space_awareness_migration_status: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update settings
#
# PUT /api/fleet/settings
# operationId: put-fleet-settings
# --delete_unenrolled_agents shape: {enabled: bool, is_preconfigured: bool}
@deprecated --flag additional-yaml-config
@deprecated --flag has-seen-add-data-notice
@deprecated --flag kibana-ca-sha256
@deprecated --flag kibana-urls
export def "fleet-settings put-fleet-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --additional-yaml-config: string # DEPRECATED
  --delete-unenrolled-agents: record # shape: {enabled: bool, is_preconfigured: bool}
  --has-seen-add-data-notice: oneof<nothing, bool> # DEPRECATED
  --integration-knowledge-enabled: oneof<nothing, bool>
  --kibana-ca-sha256: string # DEPRECATED
  --kibana-urls: list # DEPRECATED
  --prerelease-integrations-enabled: oneof<nothing, bool>
]: any -> record<item: record<action_secret_storage_requirements_met: bool, delete_unenrolled_agents: record<enabled: bool, is_preconfigured: bool>, download_source_auth_secret_storage_requirements_met: bool, has_seen_add_data_notice: bool, id: string, ilm_migration_status: record<logs: string, metrics: string, synthetics: string>, integration_knowledge_enabled: bool, output_secret_storage_requirements_met: bool, preconfigured_fields: list<string>, prerelease_integrations_enabled: bool, secret_storage_requirements_met: bool, ssl_secret_storage_requirements_met: bool, use_space_awareness_migration_started_at: string, use_space_awareness_migration_status: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/settings")
  let body = {additional_yaml_config: $additional_yaml_config, delete_unenrolled_agents: $delete_unenrolled_agents, has_seen_add_data_notice: $has_seen_add_data_notice, integration_knowledge_enabled: $integration_knowledge_enabled, kibana_ca_sha256: $kibana_ca_sha256, kibana_urls: $kibana_urls, prerelease_integrations_enabled: $prerelease_integrations_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initiate Fleet setup
#
# POST /api/fleet/setup
# operationId: post-fleet-setup
export def "fleet-setup post-fleet-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<isInitialized: bool, nonFatalErrors: table<message: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/setup")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get space settings
#
# GET /api/fleet/space_settings
# operationId: get-fleet-space-settings
export def "fleet-space-settings get-fleet-space-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<allowed_namespace_prefixes: list<string>, managed_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/space_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create space settings
#
# PUT /api/fleet/space_settings
# operationId: put-fleet-space-settings
export def "fleet-space-settings put-fleet-space-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --allowed-namespace-prefixes: list
]: any -> record<item: record<allowed_namespace_prefixes: list<string>, managed_by: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/fleet/space_settings")
  let body = {allowed_namespace_prefixes: $allowed_namespace_prefixes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata for latest uninstall tokens
#
# GET /api/fleet/uninstall_tokens
# operationId: get-fleet-uninstall-tokens
export def "fleet-uninstall-tokens get-fleet-uninstall-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policyId: string # Partial match filtering for policy IDs
  --search: string # Partial match filtering for uninstall token values
  --perPage: float # The number of items to return
  --page: float # Page number
]: nothing -> record<items: table<created_at: string, id: string, namespaces: list, policy_id: string, policy_name: string>, page: float, perPage: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policyId" $policyId "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fleet/uninstall_tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a decrypted uninstall token
#
# GET /api/fleet/uninstall_tokens/{uninstallTokenId}
# operationId: get-fleet-uninstall-tokens-uninstalltokenid
export def "fleet-uninstall-tokens get-fleet-uninstall-tokens-uninstalltokenid" [
  uninstallTokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<created_at: string, id: string, namespaces: list<string>, policy_id: string, policy_name: string, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/fleet/uninstall_tokens/($uninstallTokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a value list
#
# DELETE /api/lists
# operationId: DeleteList
export def "lists DeleteList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Value list identifier to delete, including all of its list items. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --deleteReferences: oneof<nothing, bool> # Determines whether exception items referencing this value list should be deleted. (default: false, e.g. false)
  --ignoreReferences: oneof<nothing, bool> # Determines whether to delete value list without performing any additional checks of where this list may be utilized. (default: false, e.g. false)
]: nothing -> record<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "deleteReferences" $deleteReferences "scalar") (serialize-qp "ignoreReferences" $ignoreReferences "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get value list details
#
# GET /api/lists
# operationId: ReadList
export def "lists ReadList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Value list identifier (`id`) returned when the list was created. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
]: nothing -> record<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a value list
#
# PATCH /api/lists
# operationId: PatchList
export def "lists PatchList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version id, normally returned by the API when the document is retrieved. Use it ensure updates are done against the latest version.  (e.g. WzIsMV0=)
  --description: string # Describes the value list. (format: nonempty)
  id: string # Value list's identifier. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --meta: record # Placeholder for metadata about the value list.
  --name: string # Value list's name. (format: nonempty, e.g. List of bad IPs)
  --version: int # The document version number. (e.g. 1)
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists")
  let body = {_version: $version, description: $description, id: $id, meta: $meta, name: $name, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a value list
#
# POST /api/lists
# operationId: CreateList
export def "lists CreateList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Describes the value list. (format: nonempty)
  --id: string # Value list's identifier. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --meta: record # Placeholder for metadata about the value list.
  name: string # Value list's name. (format: nonempty, e.g. List of bad IPs)
  type: string@type-completer-6 # Specifies the Elasticsearch data type of excludes the list container holds. Some common examples:  - `keyword`: Many ECS fields are Elasticsearch keywords - `ip`: IP addresses - `ip_range`: Range of IP addresses (supports IPv4, IPv6, and CIDR notation)
  --version: int # default: 1
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists")
  let body = {description: $description, id: $id, meta: $meta, name: $name, type: $type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a value list
#
# PUT /api/lists
# operationId: UpdateList
export def "lists UpdateList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version id, normally returned by the API when the document is retrieved. Use it ensure updates are done against the latest version.  (e.g. WzIsMV0=)
  description: string # Describes the value list. (format: nonempty)
  id: string # Value list's identifier. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --meta: record # Placeholder for metadata about the value list.
  name: string # Value list's name. (format: nonempty, e.g. List of bad IPs)
  --version: int # The document version number. (e.g. 1)
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists")
  let body = {_version: $version, description: $description, id: $id, meta: $meta, name: $name, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get value lists
#
# GET /api/lists/_find
# operationId: FindLists
export def "lists-find FindLists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (e.g. 1)
  --per-page: int # The number of value lists to return per page. (e.g. 20)
  --sort-field: string # Determines which field is used to sort the results. (format: nonempty, e.g. name)
  --sort-order: string@sort-order-completer # Determines the sort order, which can be `desc` or `asc` (e.g. asc)
  --cursor: string # Returns the lists that come after the last lists returned in the previous call (use the `cursor` value returned in the previous call). This parameter uses the `tie_breaker_id` field to ensure all lists are sorted and returned correctly. (format: nonempty, e.g. WzIwLFsiYjU3Yzc2MmMtMzAzNi00NjVjLTliZmItN2JmYjVlNmU1MTVhIl1d)
  --filter: string # Filters the returned results according to the value of the specified field, using the <field name>:<field value> syntax.  (e.g. value:127.0.0.1)
]: nothing -> record<cursor: string, data: table<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int>, page: int, per_page: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete value list data streams
#
# DELETE /api/lists/index
# operationId: DeleteListIndex
export def "lists-index DeleteListIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acknowledged: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/index")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get status of value list data streams
#
# GET /api/lists/index
# operationId: ReadListIndex
export def "lists-index ReadListIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<list_index: bool, list_item_index: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/index")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create list data streams
#
# POST /api/lists/index
# DEPRECATED
# operationId: CreateListIndex
@deprecated
export def "lists-index CreateListIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acknowledged: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/index")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a value list item
#
# DELETE /api/lists/items
# operationId: DeleteListItem
export def "lists-items DeleteListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Value list item's identifier. Required if `list_id` and `value` are not specified. (format: nonempty, e.g. 54b01cfb-058d-44b9-838c-282be16c91cd)
  --list-id: string # Value list's identifier. Required if `id` is not specified. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --value: string # The value used to evaluate exceptions. Required if `id` is not specified. (e.g. 255.255.255.255)
  --refresh: string@refresh-completer-1 # Determines when changes made by the request are made visible to search. (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a value list item
#
# GET /api/lists/items
# operationId: ReadListItem
export def "lists-items ReadListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Value list item identifier. Required if `list_id` and `value` are not specified. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --list-id: string # Value list item list's `id` identfier. Required if `id` is not specified. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --value: string # The value used to evaluate exceptions. Required if `id` is not specified. (e.g. 127.0.0.2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "list_id" $list_id "scalar") (serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a value list item
#
# PATCH /api/lists/items
# operationId: PatchListItem
export def "lists-items PatchListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version id, normally returned by the API when the document is retrieved. Use it ensure updates are done against the latest version.  (e.g. WzIsMV0=)
  id: string # Value list item's identifier. (format: nonempty, e.g. 54b01cfb-058d-44b9-838c-282be16c91cd)
  --meta: record # Placeholder for metadata about the value list item.
  --refresh: string@refresh-completer-1 # Determines when changes made by the request are made visible to search.
  --value: string # The value used to evaluate exceptions. (format: nonempty)
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, id: string, list_id: string, meta: record, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/items")
  let body = {_version: $version, id: $id, meta: $meta, refresh: $refresh, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a value list item
#
# POST /api/lists/items
# operationId: CreateListItem
export def "lists-items CreateListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Value list item's identifier. (format: nonempty, e.g. 54b01cfb-058d-44b9-838c-282be16c91cd)
  list_id: string # Value list's identifier. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --meta: record # Placeholder for metadata about the value list item.
  --refresh: string@refresh-completer-1 # Determines when changes made by the request are made visible to search. (e.g. wait_for)
  value: string # The value used to evaluate exceptions. (format: nonempty)
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, id: string, list_id: string, meta: record, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/items")
  let body = {id: $id, list_id: $list_id, meta: $meta, refresh: $refresh, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a value list item
#
# PUT /api/lists/items
# operationId: UpdateListItem
export def "lists-items UpdateListItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The version id, normally returned by the API when the document is retrieved. Use it ensure updates are done against the latest version.  (e.g. WzIsMV0=)
  id: string # Value list item's identifier. (format: nonempty, e.g. 54b01cfb-058d-44b9-838c-282be16c91cd)
  --meta: record # Placeholder for metadata about the value list item.
  value: string # The value used to evaluate exceptions. (format: nonempty)
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, id: string, list_id: string, meta: record, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/items")
  let body = {_version: $version, id: $id, meta: $meta, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export value list items
#
# POST /api/lists/items/_export
# operationId: ExportListItems
export def "lists-items-export ExportListItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: string # Value list's `id` to export. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/items/_export" $qp)
  let accept_val = "application/ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get value list items
#
# GET /api/lists/items/_find
# operationId: FindListItems
export def "lists-items-find FindListItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: string # Parent value list's `id` to page through items for. (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --page: int # The page number to return. (e.g. 1)
  --per-page: int # The number of list items to return per page. (e.g. 20)
  --sort-field: string # Determines which field is used to sort the results. (format: nonempty, e.g. value)
  --sort-order: string@sort-order-completer # Determines the sort order, which can be `desc` or `asc` (e.g. asc)
  --cursor: string # Opaque cursor returned in a previous response; pass it to continue listing from the next page. Omit on the first request.  (format: nonempty, e.g. WzIwLFsiYjU3Yzc2MmMtMzAzNi00NjVjLTliZmItN2JmYjVlNmU1MTVhIl1d)
  --filter: string # Filters the returned results according to the value of the specified field, using the <field name>:<field value> syntax.  (e.g. value:127.0.0.1)
]: nothing -> record<cursor: string, data: table<_version: string, _timestamp: string, created_at: string, created_by: string, id: string, list_id: string, meta: record, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, value: string>, page: int, per_page: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/items/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import value list items
#
# POST /api/lists/items/_import
# operationId: ImportListItems
export def "lists-items-import ImportListItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: string # List's id.  Required when importing to an existing list.  (format: nonempty, e.g. 21b01cfb-058d-44b9-838c-282be16c91cd)
  --type: string@type-completer-6 # Type of the importing list.  Required when importing a new list whose list `id` is not specified.
  --refresh: string@refresh-completer-1 # Determines when changes made by the request are made visible to search. (e.g. true)
  --file: string # A `.txt` or `.csv` file containing newline separated list items. (format: binary, e.g. 127.0.0.1 127.0.0.2 127.0.0.3 127.0.0.4 127.0.0.5 127.0.0.6 127.0.0.7 127.0.0.8 127.0.0.9 )
]: any -> record<_version: string, _timestamp: string, created_at: string, created_by: string, description: string, id: string, immutable: bool, meta: record, name: string, tie_breaker_id: string, type: string, updated_at: string, updated_by: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "refresh" $refresh "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/items/_import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get value list privileges
#
# GET /api/lists/privileges
# operationId: ReadListPrivileges
export def "lists-privileges ReadListPrivileges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<is_authenticated: bool, listItems: record<application: record, cluster: record, has_all_requested: bool, index: record, username: string>, lists: record<application: record, cluster: record, has_all_requested: bool, index: record, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/privileges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a maintenance window.
#
# POST /api/maintenance_window
# operationId: post-maintenance-window
# --schedule shape: {custom: record}
# --scope shape: {alerting: record}
export def "maintenance-window post-maintenance-window" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --enabled: oneof<nothing, bool> # Whether the current maintenance window is enabled. Disabled maintenance windows do not suppress notifications.
  schedule: record # shape: {custom: record}
  --scope: record # shape: {alerting: record}
  title: string # The name of the maintenance window. While this name does not have to be unique, a distinctive name can help you identify a specific maintenance window.
]: any -> record<created_at: string, created_by: string, enabled: bool, id: string, schedule: record<custom: record<duration: string, recurring: record, start: string, timezone: string>>, scope: record<alerting: record<query: record>>, status: string, title: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/maintenance_window")
  let body = {enabled: $enabled, schedule: $schedule, scope: $scope, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for a maintenance window.
#
# GET /api/maintenance_window/_find
# operationId: get-maintenance-window-find
export def "maintenance-window-find get-maintenance-window-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the maintenance window.
  --created-by: string # The user who created the maintenance window.
  --status: list # The status of the maintenance window. It can be "running", "upcoming", "finished", "archived", or "disabled".
  --page: float # The page number to return. (default: 1)
  --per-page: float # The number of maintenance windows to return per page. (default: 10)
]: nothing -> record<maintenanceWindows: table<created_at: string, created_by: string, enabled: bool, id: string, schedule: record, scope: record, status: string, title: string, updated_at: string, updated_by: string>, page: float, per_page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "status" $status "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/maintenance_window/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a maintenance window.
#
# DELETE /api/maintenance_window/{id}
# operationId: delete-maintenance-window-id
export def "maintenance-window delete-maintenance-window-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/maintenance_window/($id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get maintenance window details.
#
# GET /api/maintenance_window/{id}
# operationId: get-maintenance-window-id
export def "maintenance-window get-maintenance-window-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, enabled: bool, id: string, schedule: record<custom: record<duration: string, recurring: record, start: string, timezone: string>>, scope: record<alerting: record<query: record>>, status: string, title: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/maintenance_window/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a maintenance window.
#
# PATCH /api/maintenance_window/{id}
# operationId: patch-maintenance-window-id
# --schedule shape: {custom: record}
# --scope shape: {alerting: record}
export def "maintenance-window patch-maintenance-window-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --enabled: oneof<nothing, bool> # Whether the current maintenance window is enabled. Disabled maintenance windows do not suppress notifications.
  --schedule: record # shape: {custom: record}
  --scope: record # shape: {alerting: record}
  --title: string # The name of the maintenance window. While this name does not have to be unique, a distinctive name can help you identify a specific maintenance window.
]: any -> record<created_at: string, created_by: string, enabled: bool, id: string, schedule: record<custom: record<duration: string, recurring: record, start: string, timezone: string>>, scope: record<alerting: record<query: record>>, status: string, title: string, updated_at: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/maintenance_window/($id)")
  let body = {enabled: $enabled, schedule: $schedule, scope: $scope, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a maintenance window.
#
# POST /api/maintenance_window/{id}/_archive
# operationId: post-maintenance-window-id-archive
export def "maintenance-window-archive post-maintenance-window-id-archive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<created_at: string, created_by: string, enabled: bool, id: string, schedule: record<custom: record<duration: string, recurring: record, start: string, timezone: string>>, scope: record<alerting: record<query: record>>, status: string, title: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/maintenance_window/($id)/_archive")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive a maintenance window.
#
# POST /api/maintenance_window/{id}/_unarchive
# operationId: post-maintenance-window-id-unarchive
export def "maintenance-window-unarchive post-maintenance-window-id-unarchive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> record<created_at: string, created_by: string, enabled: bool, id: string, schedule: record<custom: record<duration: string, recurring: record, start: string, timezone: string>>, scope: record<alerting: record<query: record>>, status: string, title: string, updated_at: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/maintenance_window/($id)/_unarchive")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sync saved objects in the default space
#
# GET /api/ml/saved_objects/sync
# operationId: mlSync
export def "ml-saved-objects-sync mlSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --simulate: oneof<nothing, bool> # When true, simulates the synchronization by returning only the list of actions that would be performed. (e.g. true)
]: nothing -> record<datafeedsAdded: record, datafeedsRemoved: record, savedObjectsCreated: record<anomaly_detector: record, data_frame_analytics: record, trained_model: record>, savedObjectsDeleted: record<anomaly_detector: record, data_frame_analytics: record, trained_model: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "simulate" $simulate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ml/saved_objects/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update jobs spaces
#
# POST /api/ml/saved_objects/update_jobs_spaces
# operationId: mlUpdateJobsSpaces
export def "ml-saved-objects-update-jobs-spaces mlUpdateJobsSpaces" [
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
  let full_url = (build-url $base "/api/ml/saved_objects/update_jobs_spaces")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update trained models spaces
#
# POST /api/ml/saved_objects/update_trained_models_spaces
# operationId: mlUpdateTrainedModelsSpaces
export def "ml-saved-objects-update-trained-models-spaces mlUpdateTrainedModelsSpaces" [
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
  let full_url = (build-url $base "/api/ml/saved_objects/update_trained_models_spaces")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete one or more notes
#
# DELETE /api/note
# operationId: DeleteNote
export def "note DeleteNote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --noteId: string # Saved object ID of the note to delete.
  --noteIds: list # Saved object IDs of the notes to delete. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/note")
  let body = {noteId: $noteId, noteIds: $noteIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get notes
#
# GET /api/note
# operationId: GetNotes
export def "note GetNotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --documentIds: string # Event document `_id` values to match against each note's `eventId`. When this parameter is present, the response is all matching notes (up to the server's hard limit), not a paged list using `page`/`perPage`.
  --savedObjectIds: string # Timeline `savedObjectId` value(s). Returns notes that reference those timelines. When present, list-mode pagination parameters are not used; up to the server's hard limit of notes may be returned.
  --page: string # Page number for list mode (when `documentIds` and `savedObjectIds` are omitted). Passed as a string; default 1.  (nullable, e.g. 1)
  --perPage: string # Page size for list mode (when `documentIds` and `savedObjectIds` are omitted). Passed as a string; default 10.  (nullable, e.g. 20)
  --search: string # Search string for saved-objects find (list mode only). (nullable)
  --sortField: string # Field to sort by for saved-objects find (list mode only). (nullable)
  --sortOrder: string # Sort order (`asc` or `desc`) for saved-objects find (list mode only). (nullable, e.g. desc)
  --filter: string # Kuery filter string combined with other list-mode filters (for example `createdByFilter` or `associatedFilter`). Typed as a string for API compatibility; interpreted by the saved-objects layer (list mode only).  (nullable)
  --createdByFilter: string # Kibana user profile **UID** (UUID). The server resolves the user's display identifiers and returns notes whose `createdBy` matches any of them (list mode only).  (nullable, e.g. f1c2d3e4-5b6a-7890-abcd-ef1234567890)
  --associatedFilter: string@associatedFilter-completer # Restricts notes by how they relate to a Timeline and/or an event document (list mode only). Some values apply extra filtering after the query. Ignored when `documentIds` or `savedObjectIds` is used.
]: nothing -> record<notes: table<noteId: string, version: string>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentIds" $documentIds "scalar") (serialize-qp "savedObjectIds" $savedObjectIds "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "createdByFilter" $createdByFilter "scalar") (serialize-qp "associatedFilter" $associatedFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/note" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update a note
#
# PATCH /api/note
# Docs: https://www.elastic.co/guide/en/security/current/timeline-api-update.html — Add or update a note on a Timeline
# operationId: PersistNoteRoute
export def "note PersistNoteRoute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  note: any
  --noteId: string # The `savedObjectId` of the note to update. Omit when creating a new note. (nullable, e.g. 709f99c6-89b6-4953-9160-35945c8e174e)
  --version: string # Saved object version string from a previous read; optional on update. (nullable, e.g. WzQ2LDFd)
]: any -> record<note: record<noteId: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/note")
  let body = {note: $note, noteId: $noteId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a chat completion
#
# POST /api/observability_ai_assistant/chat/complete
# operationId: observability-ai-assistant-chat-complete
# --actions item shape: {description?: string, name?: string, parameters?: record}
# --messages item shape: {@timestamp: string, message: record}
export def "observability-ai-assistant-chat-complete observability-ai-assistant-chat-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actions: list # item shape: {description?: string, name?: string, parameters?: record}
  connectorId: string # A unique identifier for the connector.
  --conversationId: string # A unique identifier for the conversation if you are continuing an existing conversation.
  --disableFunctions: oneof<nothing, bool> # Flag indicating whether all function calls should be disabled for the conversation. If true, no calls to functions will be made.
  --instructions: list # An array of instruction objects, which can be either simple strings or detailed objects.
  messages: list # An array of message objects containing the conversation history. — item shape: {@timestamp: string, message: record}
  --persist: oneof<nothing, bool> # Indicates whether the conversation should be saved to storage. If true, the conversation will be saved and will be available in Kibana.
  --title: string # A title for the conversation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/observability_ai_assistant/chat/complete")
  let body = {actions: $actions, connectorId: $connectorId, conversationId: $conversationId, disableFunctions: $disableFunctions, instructions: $instructions, messages: $messages, persist: $persist, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get unified query history
#
# GET /api/osquery/history
# operationId: OsqueryGetUnifiedHistory
export def "osquery-history OsqueryGetUnifiedHistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: int # The number of results to return per page. (default: 20)
  --nextPage: string # A base64-encoded cursor for pagination. Use the value from the previous response to fetch the next page.
  --kuery: string # A search string to filter history entries by pack name, query text, or query ID.
  --userIds: string # Comma-separated list of user IDs to filter live query history. (e.g. elastic,admin)
  --sourceFilters: string # Comma-separated list of source types to include. Valid values are `live`, `rule`, and `scheduled`. (e.g. live,scheduled)
  --startDate: string # The start of the time range filter (ISO 8601). (e.g. 2024-01-01T00:00:00Z)
  --endDate: string # The end of the time range filter (ISO 8601). (e.g. 2024-12-31T23:59:59Z)
]: nothing -> record<data: list<any>, hasMore: bool, nextPage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "kuery" $kuery "scalar") (serialize-qp "userIds" $userIds "scalar") (serialize-qp "sourceFilters" $sourceFilters "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/osquery/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get live queries
#
# GET /api/osquery/live_queries
# operationId: OsqueryFindLiveQueries
export def "osquery-live-queries OsqueryFindLiveQueries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kuery: string # A KQL search string to filter live queries. (nullable, e.g. agent.id: 16d7caf5-efd2-4212-9b62-73dafc91fa13)
  --page: int # The page number to return. (nullable, e.g. 1)
  --pageSize: int # The number of results to return per page. (nullable, e.g. 20)
  --qp-sort: string # The field to sort results by. (nullable, default: createdAt, e.g. createdAt)
  --sortOrder: string@sortOrder-completer # The sort order. (e.g. desc)
]: nothing -> record<data: record<items: list<record>, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kuery" $kuery "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/osquery/live_queries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a live query
#
# POST /api/osquery/live_queries
# operationId: OsqueryCreateLiveQuery
# --queries item shape: {ecs_mapping?: record, id?: string, platform?: string, query?: string, removed?: bool, snapshot?: bool, version?: string}
export def "osquery-live-queries OsqueryCreateLiveQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-all: oneof<nothing, bool> # When `true`, the query runs on all agents.
  --agent-ids: list # A list of agent IDs to run the query on.
  --agent-platforms: list # A list of agent platforms to run the query on.
  --agent-policy-ids: list # A list of agent policy IDs to run the query on.
  --alert-ids: list # A list of alert IDs associated with the live query.
  --case-ids: list # A list of case IDs associated with the live query.
  --ecs-mapping: record # Map osquery results columns or static values to Elastic Common Schema (ECS) fields (e.g. {host.uptime: {field: total_seconds}})
  --event-ids: list # A list of event IDs associated with the live query.
  --metadata: record # Custom metadata object associated with the live query. (nullable)
  --pack-id: string # The ID of the pack. (e.g. 3c42c847-eb30-4452-80e0-728584042334)
  --queries: list # An array of queries to run. — item shape: {ecs_mapping?: record, id?: string, platform?: string, query?: string, removed?: bool, snapshot?: bool, version?: string}
  --body-query: string # The SQL query you want to run. (e.g. select * from uptime;)
  --saved-query-id: string # The ID of a saved query. (e.g. 3c42c847-eb30-4452-80e0-728584042334)
]: any -> record<data: record<_timestamp: string, action_id: string, agent_all: bool, agent_ids: list<string>, agent_platforms: list<string>, agent_policy_ids: list<string>, agents: list<string>, expiration: string, input_type: string, metadata: record, pack_id: string, queries: list<record>, type: string, user_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/osquery/live_queries")
  let body = {agent_all: $agent_all, agent_ids: $agent_ids, agent_platforms: $agent_platforms, agent_policy_ids: $agent_policy_ids, alert_ids: $alert_ids, case_ids: $case_ids, ecs_mapping: $ecs_mapping, event_ids: $event_ids, metadata: $metadata, pack_id: $pack_id, queries: $queries, query: $body_query, saved_query_id: $saved_query_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get live query details
#
# GET /api/osquery/live_queries/{id}
# operationId: OsqueryGetLiveQueryDetails
export def "osquery-live-queries OsqueryGetLiveQueryDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_timestamp: string, action_id: string, agents: list<string>, expiration: string, pack_id: string, pack_name: string, prebuilt_pack: bool, queries: list<record>, status: string, tags: list<string>, user_id: string, user_profile_uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/live_queries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get live query results
#
# GET /api/osquery/live_queries/{id}/results/{actionId}
# operationId: OsqueryGetLiveQueryResults
export def "osquery-live-queries-results OsqueryGetLiveQueryResults" [
  id: string
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kuery: string # A KQL search string to filter results. (nullable, e.g. agent.id: 16d7caf5-efd2-4212-9b62-73dafc91fa13)
  --page: int # The page number to return. (nullable, e.g. 1)
  --pageSize: int # The number of results to return per page. (nullable, e.g. 20)
  --qp-sort: string # The field to sort results by. (nullable, default: createdAt, e.g. createdAt)
  --sortOrder: string@sortOrder-completer # The sort order. (e.g. desc)
]: nothing -> record<data: record<edges: list<record>, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kuery" $kuery "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/osquery/live_queries/($id)/results/($actionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get packs
#
# GET /api/osquery/packs
# operationId: OsqueryFindPacks
export def "osquery-packs OsqueryFindPacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (nullable, e.g. 1)
  --pageSize: int # The number of results to return per page. (nullable, e.g. 20)
  --qp-sort: string # The field to sort results by. (nullable, default: createdAt, e.g. createdAt)
  --sortOrder: string@sortOrder-completer # The sort order. (e.g. desc)
]: nothing -> record<data: table<created_at: string, created_by: string, created_by_profile_uid: string, description: string, enabled: bool, interval: int, name: string, policy_ids: list, queries: list, read_only: bool, rrule_schedule: record, saved_object_id: string, schedule_type: string, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: int>, page: int, per_page: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/osquery/packs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pack
#
# POST /api/osquery/packs
# operationId: OsqueryCreatePacks
# --rrule_schedule shape: {end_date?: string, rrule: string, splay?: string, start_date: string, timeout?: float}
export def "osquery-packs OsqueryCreatePacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The pack description. (e.g. Pack description)
  --enabled: oneof<nothing, bool> # Enables the pack. (e.g. true)
  --interval: int # Pack-level interval, in seconds. Used when `schedule_type` is `interval`. Mutually exclusive with `rrule_schedule`. (e.g. 60)
  --name: string # The pack name. (e.g. my_pack)
  --policy-ids: list # A list of agents policy IDs. (e.g. [policyId1, policyId2])
  --queries: record # An object of queries.
  --rrule-schedule: record # RRULE schedule configuration consumed by osquerybeat. Loose date forms like `"2024-01-01"` are rejected with 400. DTSTART is NOT embedded in `rrule`; the separate `start_date` field is the schedule anchor. — shape: {end_date?: string, rrule: string, splay?: string, start_date: string, timeout?: float}
  --schedule-type: string@schedule-type-completer # Discriminator for the pack's schedule mode. `interval` uses native osqueryd interval scheduling (seconds). `rrule` uses osquerybeat's RRULE-based recurrence scheduling. Per-query overrides MUST use the same mode as the pack — cross-mode overrides are rejected with 400.  (e.g. rrule)
  --shards: record # An object with shard configuration for policies included in the pack. For each policy, set the shard configuration to a percentage (1–100) of target hosts. (e.g. {policy_id: 50})
]: any -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, enabled: bool, interval: int, name: string, policy_ids: list<string>, queries: record, rrule_schedule: record<end_date: string, rrule: string, splay: string, start_date: string, timeout: float>, saved_object_id: string, schedule_type: string, shards: list<record>, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/osquery/packs")
  let body = {description: $description, enabled: $enabled, interval: $interval, name: $name, policy_ids: $policy_ids, queries: $queries, rrule_schedule: $rrule_schedule, schedule_type: $schedule_type, shards: $shards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a pack
#
# DELETE /api/osquery/packs/{id}
# operationId: OsqueryDeletePacks
export def "osquery-packs OsqueryDeletePacks" [
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
  let full_url = (build-url $base $"/api/osquery/packs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pack details
#
# GET /api/osquery/packs/{id}
# operationId: OsqueryGetPacksDetails
export def "osquery-packs OsqueryGetPacksDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, enabled: bool, interval: int, name: string, namespaces: list<string>, policy_ids: list<string>, queries: record, read_only: bool, rrule_schedule: record<end_date: string, rrule: string, splay: string, start_date: string, timeout: float>, saved_object_id: string, schedule_type: string, shards: record, type: string, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/packs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a pack
#
# PUT /api/osquery/packs/{id}
# operationId: OsqueryUpdatePacks
# --rrule_schedule shape: {end_date?: string, rrule: string, splay?: string, start_date: string, timeout?: float}
export def "osquery-packs OsqueryUpdatePacks" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The pack description. (e.g. Pack description)
  --enabled: oneof<nothing, bool> # Enables the pack. (e.g. true)
  --interval: int # Pack-level interval, in seconds. Used when `schedule_type` is `interval`. Mutually exclusive with `rrule_schedule`. (e.g. 60)
  --name: string # The pack name. (e.g. my_pack)
  --policy-ids: list # A list of agents policy IDs. (e.g. [policyId1, policyId2])
  --queries: record # An object of queries.
  --rrule-schedule: record # RRULE schedule configuration consumed by osquerybeat. Loose date forms like `"2024-01-01"` are rejected with 400. DTSTART is NOT embedded in `rrule`; the separate `start_date` field is the schedule anchor. — shape: {end_date?: string, rrule: string, splay?: string, start_date: string, timeout?: float}
  --schedule-type: string@schedule-type-completer # Discriminator for the pack's schedule mode. `interval` uses native osqueryd interval scheduling (seconds). `rrule` uses osquerybeat's RRULE-based recurrence scheduling. Per-query overrides MUST use the same mode as the pack — cross-mode overrides are rejected with 400.  (e.g. rrule)
  --shards: record # An object with shard configuration for policies included in the pack. For each policy, set the shard configuration to a percentage (1–100) of target hosts. (e.g. {policy_id: 50})
]: any -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, enabled: bool, interval: int, name: string, policy_ids: list<string>, queries: record, rrule_schedule: record<end_date: string, rrule: string, splay: string, start_date: string, timeout: float>, saved_object_id: string, schedule_type: string, shards: record, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/packs/($id)")
  let body = {description: $description, enabled: $enabled, interval: $interval, name: $name, policy_ids: $policy_ids, queries: $queries, rrule_schedule: $rrule_schedule, schedule_type: $schedule_type, shards: $shards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy a pack
#
# POST /api/osquery/packs/{id}/copy
# operationId: OsqueryCopyPacks
export def "osquery-packs-copy OsqueryCopyPacks" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, enabled: bool, interval: int, name: string, policy_ids: list<string>, queries: list<record>, rrule_schedule: record<end_date: string, rrule: string, splay: string, start_date: string, timeout: float>, saved_object_id: string, schedule_type: string, shards: list<record>, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/packs/($id)/copy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get saved queries
#
# GET /api/osquery/saved_queries
# operationId: OsqueryFindSavedQueries
export def "osquery-saved-queries OsqueryFindSavedQueries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. (nullable, e.g. 1)
  --pageSize: int # The number of results to return per page. (nullable, e.g. 20)
  --qp-sort: string # The field to sort results by. (nullable, default: createdAt, e.g. createdAt)
  --sortOrder: string@sortOrder-completer # The sort order. (e.g. desc)
]: nothing -> record<data: table<created_at: string, created_by: string, created_by_profile_uid: string, description: string, ecs_mapping: record, id: string, interval: any, platform: string, prebuilt: bool, query: string, removed: bool, saved_object_id: string, snapshot: bool, timeout: int, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: any>, page: int, per_page: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/osquery/saved_queries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a saved query
#
# POST /api/osquery/saved_queries
# operationId: OsqueryCreateSavedQuery
export def "osquery-saved-queries OsqueryCreateSavedQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The saved query description. (e.g. Saved query description)
  --ecs-mapping: record # Map osquery results columns or static values to Elastic Common Schema (ECS) fields (e.g. {host.uptime: {field: total_seconds}})
  --id: string # The ID of a saved query. (e.g. 3c42c847-eb30-4452-80e0-728584042334)
  --interval: string # An interval, in seconds, on which to run the query. (e.g. 60)
  --platform: string # Restricts the query to a specified platform. The default is all platforms. To specify multiple platforms, use commas. For example, `linux,darwin`. (e.g. linux,darwin)
  --body-query: string # The SQL query you want to run. (e.g. select * from uptime;)
  --removed: oneof<nothing, bool> # Indicates whether the query is removed. (e.g. false)
  --snapshot: oneof<nothing, bool> # Indicates whether the query is a snapshot. (e.g. true)
  --version: string # Uses the Osquery versions greater than or equal to the specified version string. (e.g. 1.0.0)
]: any -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, ecs_mapping: record, id: string, interval: any, platform: string, prebuilt: bool, query: string, removed: bool, saved_object_id: string, snapshot: bool, timeout: int, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/osquery/saved_queries")
  let body = {description: $description, ecs_mapping: $ecs_mapping, id: $id, interval: $interval, platform: $platform, query: $body_query, removed: $removed, snapshot: $snapshot, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a saved query
#
# DELETE /api/osquery/saved_queries/{id}
# operationId: OsqueryDeleteSavedQuery
export def "osquery-saved-queries OsqueryDeleteSavedQuery" [
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
  let full_url = (build-url $base $"/api/osquery/saved_queries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get saved query details
#
# GET /api/osquery/saved_queries/{id}
# operationId: OsqueryGetSavedQueryDetails
export def "osquery-saved-queries OsqueryGetSavedQueryDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, ecs_mapping: record, id: string, interval: any, platform: string, prebuilt: bool, query: string, removed: bool, saved_object_id: string, snapshot: bool, timeout: int, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/saved_queries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a saved query
#
# PUT /api/osquery/saved_queries/{id}
# operationId: OsqueryUpdateSavedQuery
export def "osquery-saved-queries OsqueryUpdateSavedQuery" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The saved query description. (e.g. Saved query description)
  --ecs-mapping: record # Map osquery results columns or static values to Elastic Common Schema (ECS) fields (e.g. {host.uptime: {field: total_seconds}})
  --body-id: string # The ID of a saved query. (e.g. 3c42c847-eb30-4452-80e0-728584042334)
  --interval: string # An interval, in seconds, on which to run the query. (e.g. 60)
  --platform: string # Restricts the query to a specified platform. The default is all platforms. To specify multiple platforms, use commas. For example, `linux,darwin`. (e.g. linux,darwin)
  --body-query: string # The SQL query you want to run. (e.g. select * from uptime;)
  --removed: oneof<nothing, bool> # Indicates whether the query is removed. (e.g. false)
  --snapshot: oneof<nothing, bool> # Indicates whether the query is a snapshot. (e.g. true)
  --version: string # Uses the Osquery versions greater than or equal to the specified version string. (e.g. 1.0.0)
]: any -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, ecs_mapping: record, id: string, interval: any, platform: string, prebuilt: bool, query: string, removed: bool, saved_object_id: string, snapshot: bool, timeout: int, updated_at: string, updated_by: string, updated_by_profile_uid: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/saved_queries/($id)")
  let body = {description: $description, ecs_mapping: $ecs_mapping, id: $body_id, interval: $interval, platform: $platform, query: $body_query, removed: $removed, snapshot: $snapshot, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy a saved query
#
# POST /api/osquery/saved_queries/{id}/copy
# operationId: OsqueryCopySavedQuery
export def "osquery-saved-queries-copy OsqueryCopySavedQuery" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<created_at: string, created_by: string, created_by_profile_uid: string, description: string, ecs_mapping: record, id: string, interval: any, platform: string, query: string, removed: bool, saved_object_id: string, snapshot: bool, timeout: int, updated_at: string, updated_by: string, updated_by_profile_uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/osquery/saved_queries/($id)/copy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scheduled action results
#
# GET /api/osquery/scheduled_results/{scheduleId}/{executionCount}
# operationId: OsqueryGetScheduledActionResults
export def "osquery-scheduled-results OsqueryGetScheduledActionResults" [
  scheduleId: string
  executionCount: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kuery: string # The kuery to filter the results by. (nullable, e.g. agent.id: 16d7caf5-efd2-4212-9b62-73dafc91fa13)
  --page: int # The page number to return. The default is 1. (nullable, e.g. 1)
  --pageSize: int # The number of results to return per page. The default is 20. (nullable, e.g. 20)
  --qp-sort: string # The field that is used to sort the results. (nullable, default: createdAt, e.g. createdAt)
  --sortOrder: string@sortOrder-completer # Specifies the sort order. (e.g. desc)
]: nothing -> record<aggregations: record<failed: int, pending: int, successful: int, totalResponded: int, totalRowCount: int>, currentPage: int, edges: list<record>, inspect: record, metadata: record<executionCount: int, packId: string, packName: string, queryName: string, queryText: string, scheduleId: string, timestamp: string>, pageSize: int, total: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kuery" $kuery "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/osquery/scheduled_results/($scheduleId)/($executionCount)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scheduled query results
#
# GET /api/osquery/scheduled_results/{scheduleId}/{executionCount}/results
# operationId: OsqueryGetScheduledQueryResults
export def "osquery-scheduled-results-results OsqueryGetScheduledQueryResults" [
  scheduleId: string
  executionCount: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kuery: string # The kuery to filter the results by. (nullable, e.g. agent.id: 16d7caf5-efd2-4212-9b62-73dafc91fa13)
  --page: int # The page number to return. The default is 1. (nullable, e.g. 1)
  --pageSize: int # The number of results to return per page. The default is 20. (nullable, e.g. 20)
  --qp-sort: string # The field that is used to sort the results. (nullable, default: createdAt, e.g. createdAt)
  --sortOrder: string@sortOrder-completer # Specifies the sort order. (e.g. desc)
  --startDate: string # The start date filter (ISO 8601) to narrow down results. (e.g. 2024-01-01T00:00:00Z)
]: nothing -> record<data: record<edges: list<record>, inspect: record, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kuery" $kuery "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "startDate" $startDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/osquery/scheduled_results/($scheduleId)/($executionCount)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin/unpin an event
#
# PATCH /api/pinned_event
# operationId: PersistPinnedEventRoute
export def "pinned-event PersistPinnedEventRoute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventId: string # The `_id` of the associated event for this pinned event. (e.g. d3a1d35a3e84a81b2f8f3859e064c224cdee1b4bc)
  --pinnedEventId: string # The `savedObjectId` of the pinned event you want to unpin. (nullable, e.g. 10r1929b-0af7-42bd-85a8-56e234f98h2f3)
  timelineId: string # The `savedObjectId` of the timeline that you want this pinned event unpinned from. (e.g. 15c1929b-0af7-42bd-85a8-56e234cc7c4e)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pinned_event")
  let body = {eventId: $eventId, pinnedEventId: $pinnedEventId, timelineId: $timelineId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cleanup the Risk Engine
#
# DELETE /api/risk_score/engine/dangerously_delete_data
# operationId: CleanUpRiskEngine
export def "risk-score-engine-dangerously-delete-data CleanUpRiskEngine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cleanup_successful: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/risk_score/engine/dangerously_delete_data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure the Risk Engine Saved Object
#
# PATCH /api/risk_score/engine/saved_object/configure
# operationId: ConfigureRiskEngineSavedObject
# --filters item shape: {entity_types: list, filter: string}
# --range shape: {end?: string, start?: string}
export def "risk-score-engine-saved-object-configure ConfigureRiskEngineSavedObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-reset-to-zero: oneof<nothing, bool>
  --exclude-alert-statuses: list
  --exclude-alert-tags: list
  --filters: list # item shape: {entity_types: list, filter: string}
  --page-size: int # Number of entities to score per page. Higher values reduce total scoring time by reducing the number of alert-index scans, but cannot exceed the ES|QL result limit (10,000 by default).
  --range: record # shape: {end?: string, start?: string}
]: any -> record<risk_engine_saved_object_configured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/risk_score/engine/saved_object/configure")
  let body = {enable_reset_to_zero: $enable_reset_to_zero, exclude_alert_statuses: $exclude_alert_statuses, exclude_alert_tags: $exclude_alert_tags, filters: $filters, page_size: $page_size, range: $range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run the risk scoring engine
#
# POST /api/risk_score/engine/schedule_now
# operationId: ScheduleRiskEngineNow
export def "risk-score-engine-schedule-now ScheduleRiskEngineNow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/risk_score/engine/schedule_now")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export saved objects
#
# POST /api/saved_objects/_export
# operationId: post-saved-objects-export
# --objects item shape: {id: string, type: string}
export def "saved-objects-export post-saved-objects-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --excludeExportDetails: oneof<nothing, bool> # Do not add export details entry at the end of the stream. (default: false)
  --hasReference: any
  --includeReferencesDeep: oneof<nothing, bool> # Includes all of the referenced objects in the exported objects. (default: false)
  --objects: list # A list of objects to export. NOTE: this optional parameter cannot be combined with the `types` option — item shape: {id: string, type: string}
  --search: string # Search for documents to export using the Elasticsearch Simple Query String syntax.
  --type: any # The saved object types to include in the export. Use `*` to export all the types. Valid options depend on enabled plugins, but may include `visualization`, `dashboard`, `search`, `index-pattern`, `tag`, `config`, `config-global`, `lens`, `map`, `event-annotation-group`, `query`, `url`, `action`, `alert`, `alerting_rule_template`, `apm-indices`, `cases-user-actions`, `cases`, `cases-comments`, `infrastructure-monitoring-log-view`, `ml-trained-model`, `osquery-saved-query`, `osquery-pack`, `osquery-pack-asset`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/saved_objects/_export")
  let body = {excludeExportDetails: $excludeExportDetails, hasReference: $hasReference, includeReferencesDeep: $includeReferencesDeep, objects: $objects, search: $search, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/x-ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import saved objects
#
# POST /api/saved_objects/_import
# operationId: post-saved-objects-import
export def "saved-objects-import post-saved-objects-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: oneof<nothing, bool> # Overwrites saved objects when they already exist. When used, potential conflict errors are automatically resolved by overwriting the destination object. NOTE: This option cannot be used with the `createNewCopies` option. (default: false)
  --createNewCopies: oneof<nothing, bool> # Creates copies of saved objects, regenerates each object ID, and resets the origin. When used, potential conflict errors are avoided. NOTE: This option cannot be used with the `overwrite` and `compatibilityMode` options. (default: false)
  --compatibilityMode: oneof<nothing, bool> # Applies various adjustments to the saved objects that are being imported to maintain compatibility between different Kibana versions. Use this option only if you encounter issues with imported saved objects. NOTE: This option cannot be used with the `createNewCopies` option. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  file: record # A file exported using the export API. Changing the contents of the exported file in any way before importing it can cause errors, crashes or data loss. NOTE: The `savedObjects.maxImportExportSize` configuration setting limits the number of saved objects which may be included in this file. Similarly, the `savedObjects.maxImportPayloadBytes` setting limits the overall size of the file that can be imported.
]: any -> record<errors: list<record>, success: bool, successCount: float, successResults: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overwrite" $overwrite "scalar") (serialize-qp "createNewCopies" $createNewCopies "scalar") (serialize-qp "compatibilityMode" $compatibilityMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/saved_objects/_import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Resolve import errors
#
# POST /api/saved_objects/_resolve_import_errors
# operationId: post-saved-objects-resolve-import-errors
# --retries item shape: {createNewCopy?: bool, destinationId?: string, id: string, ignoreMissingReferences?: bool, overwrite?: bool, replaceReferences?: list, type: string}
export def "saved-objects-resolve-import-errors post-saved-objects-resolve-import-errors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createNewCopies: oneof<nothing, bool> # Creates copies of saved objects, regenerates each object ID, and resets the origin. (default: false)
  --compatibilityMode: oneof<nothing, bool> # Applies adjustments to maintain compatibility between different Kibana versions. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  file: record
  retries: list # item shape: {createNewCopy?: bool, destinationId?: string, id: string, ignoreMissingReferences?: bool, overwrite?: bool, replaceReferences?: list, type: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createNewCopies" $createNewCopies "scalar") (serialize-qp "compatibilityMode" $compatibilityMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/saved_objects/_resolve_import_errors" $qp)
  let body = {file: $file, retries: $retries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Apply a bulk action to anonymization fields
#
# POST /api/security_ai_assistant/anonymization_fields/_bulk_action
# operationId: PerformAnonymizationFieldsBulkAction
# --create item shape: {allowed?: bool, anonymized?: bool, field: string}
# --delete shape: {ids?: list, query?: string}
# --update item shape: {allowed?: bool, anonymized?: bool, id: string}
export def "security-ai-assistant-anonymization-fields-bulk-action PerformAnonymizationFieldsBulkAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --create: list # Array of anonymization fields to create. — item shape: {allowed?: bool, anonymized?: bool, field: string}
  --delete: record # Object containing the query to filter anonymization fields and/or an array of anonymization field IDs to delete. — shape: {ids?: list, query?: string}
  --update: list # Array of anonymization fields to update. — item shape: {allowed?: bool, anonymized?: bool, id: string}
]: any -> record<anonymization_fields_count: int, attributes: record<errors: list<record>, results: record<created: list, deleted: list, skipped: list, updated: list>, summary: record<failed: int, skipped: int, succeeded: int, total: int>>, message: string, status_code: int, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security_ai_assistant/anonymization_fields/_bulk_action")
  let body = {create: $create, delete: $delete, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get anonymization fields
#
# GET /api/security_ai_assistant/anonymization_fields/_find
# operationId: FindAnonymizationFields
export def "security-ai-assistant-anonymization-fields-find FindAnonymizationFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # Fields to return (e.g. [id, field, anonymized, allowed])
  --filter: string # Search query (e.g. field: "user.name")
  --sort-field: string@sort-field-completer-5 # Field to sort by (e.g. created_at)
  --sort-order: string@sort-order-completer # Sort order (e.g. asc)
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # AnonymizationFields per page (default: 20, e.g. 20)
  --all-data: oneof<nothing, bool> # If true, additionally fetch all anonymization fields, otherwise fetch only the provided page
]: nothing -> record<aggregations: record<field_status: record<buckets: record>>, all: table<allowed: bool, anonymized: bool, createdAt: string, createdBy: string, field: string, id: string, namespace: string, timestamp: string, updatedAt: string, updatedBy: string>, data: table<allowed: bool, anonymized: bool, createdAt: string, createdBy: string, field: string, id: string, namespace: string, timestamp: string, updatedAt: string, updatedBy: string>, page: int, perPage: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "all_data" $all_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security_ai_assistant/anonymization_fields/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a model response
#
# POST /api/security_ai_assistant/chat/complete
# operationId: ChatComplete
# --messages item shape: {content?: string, data?: record, fields_to_anonymize?: list, role: "system"|"user"|"assistant"}
export def "security-ai-assistant-chat-complete ChatComplete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content-references-disabled: oneof<nothing, bool> # If true, the response will not include content references. (default: false, e.g. false)
  connectorId: string # Required connector identifier to route the request. (e.g. conn-001)
  --conversationId: string # A string that does not contain only whitespace characters. (format: nonempty, e.g. I am a string)
  --isStream: oneof<nothing, bool> # If true, the response will be streamed in chunks. (e.g. true)
  --langSmithApiKey: string # API key for LangSmith integration. (e.g. <LANGSMITH_API_KEY>)
  --langSmithProject: string # LangSmith project name for tracing. (e.g. security_ai_project)
  messages: list # List of chat messages exchanged so far. — item shape: {content?: string, data?: record, fields_to_anonymize?: list, role: "system"|"user"|"assistant"}
  --model: string # Model ID or name to use for the response. (e.g. gpt-4)
  --persist: oneof<nothing, bool> # Whether to persist the chat and response to storage. (e.g. true)
  --promptId: string # Prompt template identifier. (e.g. prompt_001)
  --responseLanguage: string # ISO language code for the assistant's response. (e.g. en)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "content_references_disabled" $content_references_disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security_ai_assistant/chat/complete" $qp)
  let body = {connectorId: $connectorId, conversationId: $conversationId, isStream: $isStream, langSmithApiKey: $langSmithApiKey, langSmithProject: $langSmithProject, messages: $messages, model: $model, persist: $persist, promptId: $promptId, responseLanguage: $responseLanguage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete conversations
#
# DELETE /api/security_ai_assistant/current_user/conversations
# operationId: DeleteAllConversations
export def "security-ai-assistant-current-user-conversations DeleteAllConversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --excludedIds: list # Optional list of conversation IDs to delete. (e.g. [abc123, def456])
]: any -> record<failures: list<string>, success: bool, totalDeleted: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security_ai_assistant/current_user/conversations")
  let body = {excludedIds: $excludedIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a conversation
#
# POST /api/security_ai_assistant/current_user/conversations
# operationId: CreateConversation
# --apiConfig shape: {actionTypeId: string, connectorId: string, defaultSystemPromptId?: string, model?: string, provider?: "OpenAI"|"Azure OpenAI"|"Other"}
# --messages item shape: {content: string, id?: string, isError?: bool, metadata?: record, reader?: record, refusal?: string, role: "system"|"user"|"assistant", timestamp: string, traceData?: record, user?: record}
export def "security-ai-assistant-current-user-conversations CreateConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiConfig: record # shape: {actionTypeId: string, connectorId: string, defaultSystemPromptId?: string, model?: string, provider?: "OpenAI"|"Azure OpenAI"|"Other"}
  --category: string@category-completer # The conversation category. (e.g. assistant)
  --excludeFromLastConversationStorage: oneof<nothing, bool> # Exclude from last conversation storage.
  --id: string # The conversation id. (e.g. conversation123)
  --messages: list # The conversation messages. — item shape: {content: string, id?: string, isError?: bool, metadata?: record, reader?: record, refusal?: string, role: "system"|"user"|"assistant", timestamp: string, traceData?: record, user?: record}
  --replacements: record # Replacements object used to anonymize/deanonymize messages
  title: string # The conversation title. (e.g. Security AI Assistant Setup)
]: any -> record<apiConfig: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string>, category: string, createdAt: string, createdBy: record<id: string, name: string>, excludeFromLastConversationStorage: bool, id: string, messages: table<content: string, id: string, isError: bool, metadata: record, reader: record, refusal: string, role: string, timestamp: string, traceData: record, user: record>, namespace: string, replacements: record, timestamp: string, title: string, updatedAt: string, users: table<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security_ai_assistant/current_user/conversations")
  let body = {apiConfig: $apiConfig, category: $category, excludeFromLastConversationStorage: $excludeFromLastConversationStorage, id: $id, messages: $messages, replacements: $replacements, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get conversations
#
# GET /api/security_ai_assistant/current_user/conversations/_find
# operationId: FindConversations
export def "security-ai-assistant-current-user-conversations-find FindConversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A list of fields to include in the response. If omitted, all fields are returned. (e.g. [id, title, createdAt])
  --filter: string # A search query to filter the conversations. Can match against titles, messages, or other conversation attributes. (e.g. Security Issue)
  --sort-field: string@sort-field-completer-6 # The field by which to sort the results. Valid fields are `created_at`, `title`, and `updated_at`. (e.g. created_at)
  --sort-order: string@sort-order-completer # The order in which to sort the results. Can be either `asc` for ascending or `desc` for descending. (e.g. asc)
  --page: int # The page number of the results to retrieve. Default is 1. (default: 1, e.g. 1)
  --per-page: int # The number of conversations to return per page. Default is 20. (default: 20, e.g. 20)
  --is-owner: oneof<nothing, bool> # Whether to return conversations that the current user owns. If true, only conversations owned by the user are returned. (default: false, e.g. true)
]: nothing -> record<data: table<apiConfig: record, category: string, createdAt: string, createdBy: record, excludeFromLastConversationStorage: bool, id: string, messages: list, namespace: string, replacements: record, timestamp: string, title: string, updatedAt: string, users: list>, page: int, perPage: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "is_owner" $is_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security_ai_assistant/current_user/conversations/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a conversation
#
# DELETE /api/security_ai_assistant/current_user/conversations/{id}
# operationId: DeleteConversation
export def "security-ai-assistant-current-user-conversations DeleteConversation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiConfig: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string>, category: string, createdAt: string, createdBy: record<id: string, name: string>, excludeFromLastConversationStorage: bool, id: string, messages: table<content: string, id: string, isError: bool, metadata: record, reader: record, refusal: string, role: string, timestamp: string, traceData: record, user: record>, namespace: string, replacements: record, timestamp: string, title: string, updatedAt: string, users: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/security_ai_assistant/current_user/conversations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a conversation
#
# GET /api/security_ai_assistant/current_user/conversations/{id}
# operationId: ReadConversation
export def "security-ai-assistant-current-user-conversations ReadConversation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiConfig: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string>, category: string, createdAt: string, createdBy: record<id: string, name: string>, excludeFromLastConversationStorage: bool, id: string, messages: table<content: string, id: string, isError: bool, metadata: record, reader: record, refusal: string, role: string, timestamp: string, traceData: record, user: record>, namespace: string, replacements: record, timestamp: string, title: string, updatedAt: string, users: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/security_ai_assistant/current_user/conversations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a conversation
#
# PUT /api/security_ai_assistant/current_user/conversations/{id}
# operationId: UpdateConversation
# --apiConfig shape: {actionTypeId: string, connectorId: string, defaultSystemPromptId?: string, model?: string, provider?: "OpenAI"|"Azure OpenAI"|"Other"}
# --messages item shape: {content: string, id?: string, isError?: bool, metadata?: record, reader?: record, refusal?: string, role: "system"|"user"|"assistant", timestamp: string, traceData?: record, user?: record}
# --users item shape: {id?: string, name?: string}
export def "security-ai-assistant-current-user-conversations UpdateConversation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiConfig: record # shape: {actionTypeId: string, connectorId: string, defaultSystemPromptId?: string, model?: string, provider?: "OpenAI"|"Azure OpenAI"|"Other"}
  --category: string@category-completer # The conversation category. (e.g. assistant)
  --excludeFromLastConversationStorage: oneof<nothing, bool> # Exclude from last conversation storage.
  --body-id: string # A string that does not contain only whitespace characters. (format: nonempty, e.g. I am a string)
  --messages: list # The conversation messages. — item shape: {content: string, id?: string, isError?: bool, metadata?: record, reader?: record, refusal?: string, role: "system"|"user"|"assistant", timestamp: string, traceData?: record, user?: record}
  --replacements: record # Replacements object used to anonymize/deanonymize messages
  --title: string # The conversation title. (e.g. Updated Security AI Assistant Setup)
  --users: list # item shape: {id?: string, name?: string}
]: any -> record<apiConfig: record<actionTypeId: string, connectorId: string, defaultSystemPromptId: string, model: string, provider: string>, category: string, createdAt: string, createdBy: record<id: string, name: string>, excludeFromLastConversationStorage: bool, id: string, messages: table<content: string, id: string, isError: bool, metadata: record, reader: record, refusal: string, role: string, timestamp: string, traceData: record, user: record>, namespace: string, replacements: record, timestamp: string, title: string, updatedAt: string, users: table<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/security_ai_assistant/current_user/conversations/($id)")
  let body = {apiConfig: $apiConfig, category: $category, excludeFromLastConversationStorage: $excludeFromLastConversationStorage, id: $body_id, messages: $messages, replacements: $replacements, title: $title, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read a KnowledgeBase
#
# GET /api/security_ai_assistant/knowledge_base
# operationId: GetKnowledgeBase
export def "security-ai-assistant-knowledge-base GetKnowledgeBase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<defend_insights_exists: bool, elser_exists: bool, is_setup_available: bool, is_setup_in_progress: bool, product_documentation_status: string, security_labs_exists: bool, user_data_exists: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security_ai_assistant/knowledge_base")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a KnowledgeBase
#
# POST /api/security_ai_assistant/knowledge_base
# operationId: PostKnowledgeBase
export def "security-ai-assistant-knowledge-base PostKnowledgeBase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modelId: string # ELSER modelId to use when setting up the Knowledge Base. If not provided, a default model will be used. (e.g. elser-model-001)
  --ignoreSecurityLabs: oneof<nothing, bool> # Indicates whether we should or should not install Security Labs docs when setting up the Knowledge Base. Defaults to `false`. (default: false, e.g. true)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modelId" $modelId "scalar") (serialize-qp "ignoreSecurityLabs" $ignoreSecurityLabs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security_ai_assistant/knowledge_base" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a KnowledgeBase for a resource
#
# GET /api/security_ai_assistant/knowledge_base/{resource}
# operationId: ReadKnowledgeBase
export def "security-ai-assistant-knowledge-base ReadKnowledgeBase" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<defend_insights_exists: bool, elser_exists: bool, is_setup_available: bool, is_setup_in_progress: bool, product_documentation_status: string, security_labs_exists: bool, user_data_exists: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/security_ai_assistant/knowledge_base/($resource)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a KnowledgeBase for a resource
#
# POST /api/security_ai_assistant/knowledge_base/{resource}
# operationId: CreateKnowledgeBase
export def "security-ai-assistant-knowledge-base CreateKnowledgeBase" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modelId: string # ELSER modelId to use when setting up the Knowledge Base. If not provided, a default model will be used. (e.g. elser-model-001)
  --ignoreSecurityLabs: oneof<nothing, bool> # Indicates whether we should or should not install Security Labs docs when setting up the Knowledge Base. Defaults to `false`. (default: false, e.g. true)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modelId" $modelId "scalar") (serialize-qp "ignoreSecurityLabs" $ignoreSecurityLabs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/security_ai_assistant/knowledge_base/($resource)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Knowledge Base Entry
#
# POST /api/security_ai_assistant/knowledge_base/entries
# Discriminator (request): type = document, index
# operationId: CreateKnowledgeBaseEntry
export def "security-ai-assistant-knowledge-base-entries CreateKnowledgeBaseEntry" [
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
  let full_url = (build-url $base "/api/security_ai_assistant/knowledge_base/entries")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Applies a bulk action to multiple Knowledge Base Entries
#
# POST /api/security_ai_assistant/knowledge_base/entries/_bulk_action
# operationId: PerformKnowledgeBaseEntryBulkAction
# --delete shape: {ids?: list, query?: string}
export def "security-ai-assistant-knowledge-base-entries-bulk-action PerformKnowledgeBaseEntryBulkAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --create: list # List of Knowledge Base Entries to create. (e.g. [{kbResource: user, name: New Entry, source: manual, text: This is the content of the new entry., type: document}])
  --delete: record # shape: {ids?: list, query?: string}
  --update: list # List of Knowledge Base Entries to update. (e.g. [{id: 123, kbResource: user, name: Updated Entry, source: manual, text: Updated content., type: document}])
]: any -> record<attributes: record<errors: list<record>, results: record<created: list, deleted: list, skipped: list, updated: list>, summary: record<failed: int, skipped: int, succeeded: int, total: int>>, knowledgeBaseEntriesCount: int, message: string, statusCode: int, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security_ai_assistant/knowledge_base/entries/_bulk_action")
  let body = {create: $create, delete: $delete, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds Knowledge Base Entries that match the given query.
#
# GET /api/security_ai_assistant/knowledge_base/entries/_find
# operationId: FindKnowledgeBaseEntries
export def "security-ai-assistant-knowledge-base-entries-find FindKnowledgeBaseEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A list of fields to include in the response. If not provided, all fields will be included. (e.g. [name, created_at])
  --filter: string # Search query to filter Knowledge Base Entries by specific criteria. (e.g. error handling)
  --sort-field: string@sort-field-completer-7 # Field to sort the Knowledge Base Entries by. (e.g. title)
  --sort-order: string@sort-order-completer # Sort order for the results, either asc or desc. (e.g. asc)
  --page: int # Page number for paginated results. Defaults to 1. (default: 1, e.g. 2)
  --per-page: int # Number of Knowledge Base Entries to return per page. Defaults to 20. (default: 20, e.g. 10)
]: nothing -> record<data: list<any>, page: int, perPage: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security_ai_assistant/knowledge_base/entries/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a single Knowledge Base Entry using the `id` field
#
# DELETE /api/security_ai_assistant/knowledge_base/entries/{id}
# operationId: DeleteKnowledgeBaseEntry
export def "security-ai-assistant-knowledge-base-entries DeleteKnowledgeBaseEntry" [
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
  let full_url = (build-url $base $"/api/security_ai_assistant/knowledge_base/entries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a Knowledge Base Entry
#
# GET /api/security_ai_assistant/knowledge_base/entries/{id}
# Discriminator (response): type = document, index
# operationId: ReadKnowledgeBaseEntry
export def "security-ai-assistant-knowledge-base-entries ReadKnowledgeBaseEntry" [
  id: string
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
  let full_url = (build-url $base $"/api/security_ai_assistant/knowledge_base/entries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Knowledge Base Entry
#
# PUT /api/security_ai_assistant/knowledge_base/entries/{id}
# Discriminator (request): type = document, index
# operationId: UpdateKnowledgeBaseEntry
export def "security-ai-assistant-knowledge-base-entries UpdateKnowledgeBaseEntry" [
  id: string
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
  let full_url = (build-url $base $"/api/security_ai_assistant/knowledge_base/entries/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply a bulk action to prompts
#
# POST /api/security_ai_assistant/prompts/_bulk_action
# operationId: PerformPromptsBulkAction
# --create item shape: {categories?: list, color?: string, consumer?: string, content: string, isDefault?: bool, isNewConversationDefault?: bool, name: string, promptType: "system"|"quick"}
# --delete shape: {ids?: list, query?: string}
# --update item shape: {categories?: list, color?: string, consumer?: string, content?: string, id: string, isDefault?: bool, isNewConversationDefault?: bool}
export def "security-ai-assistant-prompts-bulk-action PerformPromptsBulkAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --create: list # List of prompts to be created. — item shape: {categories?: list, color?: string, consumer?: string, content: string, isDefault?: bool, isNewConversationDefault?: bool, name: string, promptType: "system"|"quick"}
  --delete: record # Criteria for deleting prompts in bulk. — shape: {ids?: list, query?: string}
  --update: list # List of prompts to be updated. — item shape: {categories?: list, color?: string, consumer?: string, content?: string, id: string, isDefault?: bool, isNewConversationDefault?: bool}
]: any -> record<attributes: record<errors: list<record>, results: record<created: list, deleted: list, skipped: list, updated: list>, summary: record<failed: int, skipped: int, succeeded: int, total: int>>, message: string, prompts_count: int, status_code: int, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security_ai_assistant/prompts/_bulk_action")
  let body = {create: $create, delete: $delete, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get prompts
#
# GET /api/security_ai_assistant/prompts/_find
# operationId: FindPrompts
export def "security-ai-assistant-prompts-find FindPrompts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # List of specific fields to include in each returned prompt. (e.g. [id, name, content])
  --filter: string # Search query string to filter prompts by matching fields. (e.g. error handling)
  --sort-field: string@sort-field-completer-8 # Field to sort prompts by. (e.g. created_at)
  --sort-order: string@sort-order-completer # Sort order, either asc or desc. (e.g. asc)
  --page: int # Page number for pagination. (default: 1, e.g. 1)
  --per-page: int # Number of prompts per page. (default: 20, e.g. 20)
]: nothing -> record<data: table<categories: list, color: string, consumer: string, content: string, createdAt: string, createdBy: string, id: string, isDefault: bool, isNewConversationDefault: bool, name: string, namespace: string, promptType: string, timestamp: string, updatedAt: string, updatedBy: string, users: list>, page: int, perPage: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security_ai_assistant/prompts/_find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Entity Store
#
# PUT /api/security/entity_store
# operationId: put-security-entity-store
# --logExtraction shape: {additionalIndexPatterns?: list, delay?: string, docsLimit?: int, excludedIndexPatterns?: list, fieldHistoryLength?: int, frequency?: string, lookbackPeriod?: string, maxLogsPerPage?: int, maxLogsPerWindow?: int, maxLogsPerWindowCapBehavior?: "defer"|"drop", maxTimeWindowSize?: string}
export def "security-entity-store put-security-entity-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  logExtraction: record # shape: {additionalIndexPatterns?: list, delay?: string, docsLimit?: int, excludedIndexPatterns?: list, fieldHistoryLength?: int, frequency?: string, lookbackPeriod?: string, maxLogsPerPage?: int, maxLogsPerWindow?: int, maxLogsPerWindowCapBehavior?: "defer"|"drop", maxTimeWindowSize?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store")
  let body = {logExtraction: $logExtraction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List entities
#
# GET /api/security/entity_store/entities
# operationId: get-security-entity-store-entities
export def "security-entity-store-entities get-security-entity-store-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A Kibana Query Language (KQL) filter for the search-after mode.
  --size: int # Number of entities to return in search-after mode.
  --searchAfter: string # JSON-encoded search_after value for cursor-based pagination.
  --qp-source: list # Fields to include in the response source.
  --qp-fields: list # Fields to include in the response.
  --sort-field: string # Field to sort results by in page mode.
  --sort-order: string@sort-order-completer # Sort order in page mode.
  --page: int # Page number to return (1-indexed) in page mode.
  --per-page: int # Number of entities per page in page mode.
  --filterQuery: string # An Elasticsearch query string to filter entities in page mode.
  --entity-types: list # Entity types to include in the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "searchAfter" $searchAfter "scalar") (serialize-qp "source" $qp_source "multi") (serialize-qp "fields" $qp_fields "multi") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filterQuery" $filterQuery "scalar") (serialize-qp "entity_types" $entity_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security/entity_store/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an entity
#
# DELETE /api/security/entity_store/entities/
# operationId: delete-security-entity-store-entities
export def "security-entity-store-entities delete-security-entity-store-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  entityId: string # The identifier of the entity to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/entities/")
  let body = {entityId: $entityId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an entity
#
# POST /api/security/entity_store/entities/{entityType}
# operationId: post-security-entity-store-entities-entitytype
# --asset shape: {business_unit?: string, criticality?: any, environment?: string, id?: string, model?: string, name?: string, owner?: string, serial_number?: string, vendor?: string}
# --entity shape: {attributes?: record, behaviors?: record, EngineMetadata?: record, id?: string, lifecycle?: record, name?: string, relationships?: record, risk?: record, schema_version?: string, source?: list, sub_type?: string, type?: string, url?: string}
# --event shape: {ingested?: string}
# --user shape: {domain?: list, email?: list, full_name?: list, hash?: list, id?: list, name?: string, risk?: record, roles?: list}
# --host shape: {architecture?: list, domain?: list, hostname?: list, id?: list, ip?: list, mac?: list, name?: string, os?: record, risk?: record, type?: list}
# --service shape: {address?: string, environment?: string, ephemeral_id?: string, id?: string, name?: string, node?: record, risk?: record, state?: string, type?: string, version?: string}
# --cloud shape: {account?: record, availability_zone?: string, instance?: record, machine?: record, project?: record, provider?: string, region?: string, service?: record}
# --orchestrator shape: {api_version?: string, cluster?: record, namespace?: string, organization?: string, resource?: record, type?: string}
export def "security-entity-store-entities post-security-entity-store-entities-entitytype" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --timestamp: string # format: date-time
  --asset: record # shape: {business_unit?: string, criticality?: any, environment?: string, id?: string, model?: string, name?: string, owner?: string, serial_number?: string, vendor?: string}
  --entity: record # shape: {attributes?: record, behaviors?: record, EngineMetadata?: record, id?: string, lifecycle?: record, name?: string, relationships?: record, risk?: record, schema_version?: string, source?: list, sub_type?: string, type?: string, url?: string}
  --event: record # shape: {ingested?: string}
  --labels: record
  --tags: list
  --user: record # shape: {domain?: list, email?: list, full_name?: list, hash?: list, id?: list, name?: string, risk?: record, roles?: list}
  --host: record # shape: {architecture?: list, domain?: list, hostname?: list, id?: list, ip?: list, mac?: list, name?: string, os?: record, risk?: record, type?: list}
  --service: record # shape: {address?: string, environment?: string, ephemeral_id?: string, id?: string, name?: string, node?: record, risk?: record, state?: string, type?: string, version?: string}
  --cloud: record # shape: {account?: record, availability_zone?: string, instance?: record, machine?: record, project?: record, provider?: string, region?: string, service?: record}
  --orchestrator: record # shape: {api_version?: string, cluster?: record, namespace?: string, organization?: string, resource?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/security/entity_store/entities/($entityType)")
  let body = {@timestamp: $timestamp, asset: $asset, entity: $entity, event: $event, labels: $labels, tags: $tags, user: $user, host: $host, service: $service, cloud: $cloud, orchestrator: $orchestrator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an entity
#
# PUT /api/security/entity_store/entities/{entityType}
# operationId: put-security-entity-store-entities-entitytype
# --asset shape: {business_unit?: string, criticality?: any, environment?: string, id?: string, model?: string, name?: string, owner?: string, serial_number?: string, vendor?: string}
# --entity shape: {attributes?: record, behaviors?: record, EngineMetadata?: record, id?: string, lifecycle?: record, name?: string, relationships?: record, risk?: record, schema_version?: string, source?: list, sub_type?: string, type?: string, url?: string}
# --event shape: {ingested?: string}
# --user shape: {domain?: list, email?: list, full_name?: list, hash?: list, id?: list, name?: string, risk?: record, roles?: list}
# --host shape: {architecture?: list, domain?: list, hostname?: list, id?: list, ip?: list, mac?: list, name?: string, os?: record, risk?: record, type?: list}
# --service shape: {address?: string, environment?: string, ephemeral_id?: string, id?: string, name?: string, node?: record, risk?: record, state?: string, type?: string, version?: string}
# --cloud shape: {account?: record, availability_zone?: string, instance?: record, machine?: record, project?: record, provider?: string, region?: string, service?: record}
# --orchestrator shape: {api_version?: string, cluster?: record, namespace?: string, organization?: string, resource?: record, type?: string}
export def "security-entity-store-entities put-security-entity-store-entities-entitytype" [
  entityType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string # When true, allows updating protected fields. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --timestamp: string # format: date-time
  --asset: record # shape: {business_unit?: string, criticality?: any, environment?: string, id?: string, model?: string, name?: string, owner?: string, serial_number?: string, vendor?: string}
  --entity: record # shape: {attributes?: record, behaviors?: record, EngineMetadata?: record, id?: string, lifecycle?: record, name?: string, relationships?: record, risk?: record, schema_version?: string, source?: list, sub_type?: string, type?: string, url?: string}
  --event: record # shape: {ingested?: string}
  --labels: record
  --tags: list
  --user: record # shape: {domain?: list, email?: list, full_name?: list, hash?: list, id?: list, name?: string, risk?: record, roles?: list}
  --host: record # shape: {architecture?: list, domain?: list, hostname?: list, id?: list, ip?: list, mac?: list, name?: string, os?: record, risk?: record, type?: list}
  --service: record # shape: {address?: string, environment?: string, ephemeral_id?: string, id?: string, name?: string, node?: record, risk?: record, state?: string, type?: string, version?: string}
  --cloud: record # shape: {account?: record, availability_zone?: string, instance?: record, machine?: record, project?: record, provider?: string, region?: string, service?: record}
  --orchestrator: record # shape: {api_version?: string, cluster?: record, namespace?: string, organization?: string, resource?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/security/entity_store/entities/($entityType)" $qp)
  let body = {@timestamp: $timestamp, asset: $asset, entity: $entity, event: $event, labels: $labels, tags: $tags, user: $user, host: $host, service: $service, cloud: $cloud, orchestrator: $orchestrator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update entities
#
# PUT /api/security/entity_store/entities/bulk
# operationId: put-security-entity-store-entities-bulk
# --entities item shape: {doc?: any, type: "user"|"host"|"service"|"generic"}
export def "security-entity-store-entities-bulk put-security-entity-store-entities-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string # When true, allows updating protected fields. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  entities: list # The entities to update. — item shape: {doc?: any, type: "user"|"host"|"service"|"generic"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security/entity_store/entities/bulk" $qp)
  let body = {entities: $entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Install the Entity Store
#
# POST /api/security/entity_store/install
# operationId: post-security-entity-store-install
# --historySnapshot shape: {frequency?: string}
# --logExtraction shape: {additionalIndexPatterns?: list, delay?: string, docsLimit?: int, excludedIndexPatterns?: list, fieldHistoryLength?: int, frequency?: string, lookbackPeriod?: string, maxLogsPerPage?: int, maxLogsPerWindow?: int, maxLogsPerWindowCapBehavior?: "defer"|"drop", maxTimeWindowSize?: string}
export def "security-entity-store-install post-security-entity-store-install" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --entityTypes: list # default: [user, host, service, generic]
  --historySnapshot: record # shape: {frequency?: string}
  --logExtraction: record # shape: {additionalIndexPatterns?: list, delay?: string, docsLimit?: int, excludedIndexPatterns?: list, fieldHistoryLength?: int, frequency?: string, lookbackPeriod?: string, maxLogsPerPage?: int, maxLogsPerWindow?: int, maxLogsPerWindowCapBehavior?: "defer"|"drop", maxTimeWindowSize?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/install")
  let body = {entityTypes: $entityTypes, historySnapshot: $historySnapshot, logExtraction: $logExtraction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get resolution group
#
# GET /api/security/entity_store/resolution/group
# operationId: get-security-entity-store-resolution-group
export def "security-entity-store-resolution-group get-security-entity-store-resolution-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-id: string # The entity identifier to look up the resolution group for.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security/entity_store/resolution/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link entities
#
# POST /api/security/entity_store/resolution/link
# operationId: post-security-entity-store-resolution-link
export def "security-entity-store-resolution-link post-security-entity-store-resolution-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  entity_ids: list # Entity identifiers to link to the target entity. Minimum 1, maximum 1000.
  target_id: string # The entity identifier to resolve the linked entities to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/resolution/link")
  let body = {entity_ids: $entity_ids, target_id: $target_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink entities
#
# POST /api/security/entity_store/resolution/unlink
# operationId: post-security-entity-store-resolution-unlink
export def "security-entity-store-resolution-unlink post-security-entity-store-resolution-unlink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  entity_ids: list # Entity identifiers to unlink from their resolution group. Minimum 1, maximum 1000.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/resolution/unlink")
  let body = {entity_ids: $entity_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start Entity Store engines
#
# PUT /api/security/entity_store/start
# operationId: put-security-entity-store-start
export def "security-entity-store-start put-security-entity-store-start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --entityTypes: list # Entity types to start. Defaults to all installed types. (default: [user, host, service, generic])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/start")
  let body = {entityTypes: $entityTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Entity Store status
#
# GET /api/security/entity_store/status
# operationId: get-security-entity-store-status
export def "security-entity-store-status get-security-entity-store-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-components: string # If true, returns a detailed status of each engine including all its components. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_components" $include_components "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security/entity_store/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop Entity Store engines
#
# PUT /api/security/entity_store/stop
# operationId: put-security-entity-store-stop
export def "security-entity-store-stop put-security-entity-store-stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --entityTypes: list # Entity types to stop. Defaults to all running types. (default: [user, host, service, generic])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/stop")
  let body = {entityTypes: $entityTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Uninstall the Entity Store
#
# POST /api/security/entity_store/uninstall
# operationId: post-security-entity-store-uninstall
export def "security-entity-store-uninstall post-security-entity-store-uninstall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --entityTypes: list # Entity types to uninstall. Defaults to all installed types. (default: [user, host, service, generic])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/entity_store/uninstall")
  let body = {entityTypes: $entityTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all roles
#
# GET /api/security/role
# operationId: get-security-role
export def "security-role get-security-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replaceDeprecatedPrivileges: oneof<nothing, bool> # If `true` and the response contains any privileges that are associated with deprecated features, they are omitted in favor of details about the appropriate replacement feature privileges.
]: nothing -> table<_transform_error: list<record>, _unrecognized_applications: list<string>, description: string, elasticsearch: record<cluster: list, indices: list, remote_cluster: list, remote_indices: list, run_as: list>, kibana: list<record>, metadata: record, name: string, transient_metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replaceDeprecatedPrivileges" $replaceDeprecatedPrivileges "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/security/role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query roles
#
# POST /api/security/role/_query
# operationId: post-security-role-query
# --filters shape: {showReservedRoles?: bool}
# --sort shape: {direction: "asc"|"desc", field: string}
export def "security-role-query post-security-role-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --filters: record # The filter criteria for the query. — shape: {showReservedRoles?: bool}
  --body-from: float
  --body-query: string
  --size: float
  --body-sort: record # The sort criteria for the query. — shape: {direction: "asc"|"desc", field: string}
]: any -> record<count: float, roles: table<_transform_error: list, _unrecognized_applications: list, description: string, elasticsearch: record, kibana: list, metadata: record, name: string, transient_metadata: record>, total: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/role/_query")
  let body = {filters: $filters, from: $body_from, query: $body_query, size: $size, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /api/security/role/{name}
# operationId: delete-security-role-name
export def "security-role delete-security-role-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/security/role/($name)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a role
#
# GET /api/security/role/{name}
# operationId: get-security-role-name
export def "security-role get-security-role-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replaceDeprecatedPrivileges: oneof<nothing, bool> # If `true` and the response contains any privileges that are associated with deprecated features, they are omitted in favor of details about the appropriate replacement feature privileges.
]: nothing -> record<_transform_error: table<reason: string, state: list>, _unrecognized_applications: list<string>, description: string, elasticsearch: record<cluster: list<string>, indices: list<record>, remote_cluster: list<record>, remote_indices: list<record>, run_as: list<string>>, kibana: table<_reserved: list, base: list, feature: record, spaces: list>, metadata: record, name: string, transient_metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replaceDeprecatedPrivileges" $replaceDeprecatedPrivileges "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/security/role/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a role
#
# PUT /api/security/role/{name}
# operationId: put-security-role-name
# --elasticsearch shape: {cluster?: list, indices?: list, remote_cluster?: list, remote_indices?: list, run_as?: list}
# --kibana item shape: {base: any, feature?: record, spaces?: any}
export def "security-role put-security-role-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOnly: oneof<nothing, bool> # When true, a role is not overwritten if it already exists. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --description: string # A description for the role.
  elasticsearch: record # The Elasticsearch cluster, index, and remote cluster security privileges for the role. — shape: {cluster?: list, indices?: list, remote_cluster?: list, remote_indices?: list, run_as?: list}
  --kibana: list # item shape: {base: any, feature?: record, spaces?: any}
  --metadata: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createOnly" $createOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/security/role/($name)" $qp)
  let body = {description: $description, elasticsearch: $elasticsearch, kibana: $kibana, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update roles
#
# POST /api/security/roles
# operationId: post-security-roles
export def "security-roles post-security-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  roles: record
]: any -> record<created: list<string>, errors: record, noop: list<string>, updated: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/security/roles")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all spaces
#
# GET /api/spaces/space
# operationId: get-spaces-space
export def "spaces-space get-spaces-space" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --purpose: string@purpose-completer # Specifies which authorization checks are applied to the API call. The default value is `any`.
  --include-authorized-purposes: oneof<nothing, bool> # When enabled, the API returns any spaces the user is authorized to access in any capacity, each including the purposes for which the user is authorized. This is useful for identifying spaces the user can read but is not authorized for a given purpose. Without the security plugin, this parameter has no effect, because no authorization checks are performed. This parameter cannot be used together with the `purpose` parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purpose" $purpose "scalar") (serialize-qp "include_authorized_purposes" $include_authorized_purposes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/spaces/space" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a space
#
# POST /api/spaces/space
# operationId: post-spaces-space
export def "spaces-space post-spaces-space" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --reserved: oneof<nothing, bool>
  --color: string # The hexadecimal color code used in the space avatar. By default, the color is automatically generated from the space name.
  --description: string # A description for the space.
  --disabledFeatures: list # default: []
  id: string # The space ID that is part of the Kibana URL when inside the space. Space IDs are limited to lowercase alphanumeric, underscore, and hyphen characters (a-z, 0-9, _, and -). You are cannot change the ID with the update operation.
  --imageUrl: string # The data-URL encoded image to display in the space avatar. If specified, initials will not be displayed and the color will be visible as the background color for transparent images. For best results, your image should be 64x64. Images will not be optimized by this API call, so care should be taken when using custom images.
  --initials: string # One or two characters that are shown in the space avatar. By default, the initials are automatically generated from the space name.
  name: string # The display name for the space. 
  --projectRouting: string # Cross-project search default routing configuration for this space. Controls whether searches are scoped to a single project or span multiple projects in serverless environments.
]: any -> record<_reserved: bool, color: string, description: string, disabledFeatures: list<string>, id: string, imageUrl: string, initials: string, name: string, projectRouting: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/spaces/space")
  let body = {_reserved: $reserved, color: $color, description: $description, disabledFeatures: $disabledFeatures, id: $id, imageUrl: $imageUrl, initials: $initials, name: $name, projectRouting: $projectRouting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a space
#
# DELETE /api/spaces/space/{id}
# operationId: delete-spaces-space-id
export def "spaces-space delete-spaces-space-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/spaces/space/($id)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a space
#
# GET /api/spaces/space/{id}
# operationId: get-spaces-space-id
export def "spaces-space get-spaces-space-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_reserved: bool, color: string, description: string, disabledFeatures: list<string>, id: string, imageUrl: string, initials: string, name: string, projectRouting: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/spaces/space/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a space
#
# PUT /api/spaces/space/{id}
# operationId: put-spaces-space-id
export def "spaces-space put-spaces-space-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --reserved: oneof<nothing, bool>
  --color: string # The hexadecimal color code used in the space avatar. By default, the color is automatically generated from the space name.
  --description: string # A description for the space.
  --disabledFeatures: list # default: []
  --body-id: string # The space ID that is part of the Kibana URL when inside the space. Space IDs are limited to lowercase alphanumeric, underscore, and hyphen characters (a-z, 0-9, _, and -). You are cannot change the ID with the update operation.
  --imageUrl: string # The data-URL encoded image to display in the space avatar. If specified, initials will not be displayed and the color will be visible as the background color for transparent images. For best results, your image should be 64x64. Images will not be optimized by this API call, so care should be taken when using custom images.
  --initials: string # One or two characters that are shown in the space avatar. By default, the initials are automatically generated from the space name.
  name: string # The display name for the space. 
  --projectRouting: string # Cross-project search default routing configuration for this space. Controls whether searches are scoped to a single project or span multiple projects in serverless environments.
]: any -> record<_reserved: bool, color: string, description: string, disabledFeatures: list<string>, id: string, imageUrl: string, initials: string, name: string, projectRouting: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/spaces/space/($id)")
  let body = {_reserved: $reserved, color: $color, description: $description, disabledFeatures: $disabledFeatures, id: $body_id, imageUrl: $imageUrl, initials: $initials, name: $name, projectRouting: $projectRouting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Kibana's current status
#
# GET /api/status
# operationId: get-status
export def "status get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v7format: oneof<nothing, bool> # Set to "true" to get the response in v7 format.
  --v8format: oneof<nothing, bool> # Set to "true" to get the response in v8 format.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v7format" $v7format "scalar") (serialize-qp "v8format" $v8format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stream list
#
# GET /api/streams
# operationId: get-streams
export def "streams get-streams" [
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
  let full_url = (build-url $base "/api/streams")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable streams
#
# POST /api/streams/_disable
# operationId: post-streams-disable
export def "streams-disable post-streams-disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/streams/_disable")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable streams
#
# POST /api/streams/_enable
# operationId: post-streams-enable
export def "streams-enable post-streams-enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/streams/_enable")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resync streams
#
# POST /api/streams/_resync
# operationId: post-streams-resync
export def "streams-resync post-streams-resync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/streams/_resync")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a stream
#
# DELETE /api/streams/{name}
# operationId: delete-streams-name
export def "streams delete-streams-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a stream
#
# GET /api/streams/{name}
# operationId: get-streams-name
export def "streams get-streams-name" [
  name: string
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
  let full_url = (build-url $base $"/api/streams/($name)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update a stream
#
# PUT /api/streams/{name}
# operationId: put-streams-name
# --queries item shape: {description: string, esql: record, evidence?: list, features?: list, id: string, severity_score?: float, title: string, type?: "match"|"stats"}
# --stream shape: {description: string, ingest: record, query_streams?: list, type: "wired"}
export def "streams put-streams-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --dashboards: list
  --queries: list # item shape: {description: string, esql: record, evidence?: list, features?: list, id: string, severity_score?: float, title: string, type?: "match"|"stats"}
  --rules: list
  --stream: record # shape: {description: string, ingest: record, query_streams?: list, type: "wired"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)")
  let body = {dashboards: $dashboards, queries: $queries, rules: $rules, stream: $stream} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fork a stream
#
# POST /api/streams/{name}/_fork
# operationId: post-streams-name-fork
# --stream shape: {name: string}
export def "streams-fork post-streams-name-fork" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --draft: oneof<nothing, bool>
  --status: string@status-completer
  stream: record # shape: {name: string}
  --body-where: any # The root condition object. It can be a simple filter or a combination of other conditions.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/_fork")
  let body = {draft: $draft, status: $status, stream: $stream, where: $body_where} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ingest stream settings
#
# GET /api/streams/{name}/_ingest
# operationId: get-streams-name-ingest
export def "streams-ingest get-streams-name-ingest" [
  name: string
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
  let full_url = (build-url $base $"/api/streams/($name)/_ingest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update ingest stream settings
#
# PUT /api/streams/{name}/_ingest
# operationId: put-streams-name-ingest
export def "streams-ingest put-streams-name-ingest" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  ingest: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/_ingest")
  let body = {ingest: $ingest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get query stream settings
#
# GET /api/streams/{name}/_query
# operationId: get-streams-name-query
export def "streams-query get-streams-name-query" [
  name: string
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
  let full_url = (build-url $base $"/api/streams/($name)/_query")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert query stream settings
#
# PUT /api/streams/{name}/_query
# operationId: put-streams-name-query
# --query shape: {esql: string}
export def "streams-query put-streams-name-query" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --field-descriptions: record
  --body-query: record # shape: {esql: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/_query")
  let body = {field_descriptions: $field_descriptions, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export stream content
#
# POST /api/streams/{name}/content/export
# operationId: post-streams-name-content-export
export def "streams-content-export post-streams-name-content-export" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  description: string
  include: any
  --body-name: string
  version: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/content/export")
  let body = {description: $description, include: $include, name: $body_name, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import content into a stream
#
# POST /api/streams/{name}/content/import
# operationId: post-streams-name-content-import
export def "streams-content-import post-streams-name-content-import" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  content: any
  include: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/content/import")
  let body = {content: $content, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get stream queries
#
# GET /api/streams/{name}/queries
# operationId: get-streams-name-queries
export def "streams-queries get-streams-name-queries" [
  name: string
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
  let full_url = (build-url $base $"/api/streams/($name)/queries")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update queries
#
# POST /api/streams/{name}/queries/_bulk
# operationId: post-streams-name-queries-bulk
export def "streams-queries-bulk post-streams-name-queries-bulk" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  operations: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/queries/_bulk")
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a query from a stream
#
# DELETE /api/streams/{name}/queries/{queryId}
# operationId: delete-streams-name-queries-queryid
export def "streams-queries delete-streams-name-queries-queryid" [
  name: string
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/queries/($queryId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert a query to a stream
#
# PUT /api/streams/{name}/queries/{queryId}
# operationId: put-streams-name-queries-queryid
# --esql shape: {query: string}
export def "streams-queries put-streams-name-queries-queryid" [
  name: string
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --description: string # default: 
  esql: record # shape: {query: string}
  --evidence: list
  --severity-score: float
  title: string # A non-empty string.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($name)/queries/($queryId)")
  let body = {description: $description, esql: $esql, evidence: $evidence, severity_score: $severity_score, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read the significant events
#
# GET /api/streams/{name}/significant_events
# operationId: get-streams-name-significant-events
export def "streams-significant-events get-streams-name-significant-events" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start of the time range as an ISO 8601 date string.
  --qp-to: string # End of the time range as an ISO 8601 date string.
  --bucketSize: string # The bucket size for aggregating events (e.g. "1m", "1h").
  --qp-query: string # Query string to filter significant events on metadata fields
  --searchMode: string@searchMode-completer # Search mode: keyword (BM25), semantic (vector), or hybrid (RRF). When omitted, defaults to hybrid with a silent keyword fallback on failure. When set explicitly, failures propagate as errors.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "bucketSize" $bucketSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "searchMode" $searchMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/streams/($name)/significant_events" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get stream attachments
#
# GET /api/streams/{streamName}/attachments
# operationId: get-streams-streamname-attachments
export def "streams-attachments get-streams-streamname-attachments" [
  streamName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query to filter attachments by title
  --attachmentTypes: list # Filter by attachment types (single value or array)
  --tags: list # Filter by tags (single value or array)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "attachmentTypes" $attachmentTypes "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/streams/($streamName)/attachments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update attachments
#
# POST /api/streams/{streamName}/attachments/_bulk
# operationId: post-streams-streamname-attachments-bulk
export def "streams-attachments-bulk post-streams-streamname-attachments-bulk" [
  streamName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  operations: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($streamName)/attachments/_bulk")
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink an attachment from a stream
#
# DELETE /api/streams/{streamName}/attachments/{attachmentType}/{attachmentId}
# operationId: delete-streams-streamname-attachments-attachmenttype-attachmentid
export def "streams-attachments delete-streams-streamname-attachments-attachmenttype-attachmentid" [
  streamName: string
  attachmentType: string
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($streamName)/attachments/($attachmentType)/($attachmentId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Link an attachment to a stream
#
# PUT /api/streams/{streamName}/attachments/{attachmentType}/{attachmentId}
# operationId: put-streams-streamname-attachments-attachmenttype-attachmentid
export def "streams-attachments put-streams-streamname-attachments-attachmenttype-attachmentid" [
  streamName: string
  attachmentType: string
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/streams/($streamName)/attachments/($attachmentType)/($attachmentId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the task manager health
#
# GET /api/task_manager/_health
# operationId: task-manager-health
export def "task-manager-health task-manager-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, last_update: string, stats: record<configuration: record, workload: record>, status: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/task_manager/_health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Timelines or Timeline templates
#
# DELETE /api/timeline
# operationId: DeleteTimelines
export def "timeline DeleteTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  savedObjectIds: list # The list of IDs of the Timelines or Timeline templates to delete
  --searchIds: list # Saved search IDs that should be deleted alongside the timelines
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline")
  let body = {savedObjectIds: $savedObjectIds, searchIds: $searchIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Timeline or Timeline template details
#
# GET /api/timeline
# operationId: GetTimeline
export def "timeline GetTimeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template-timeline-id: string # The `savedObjectId` of the Timeline template to retrieve.
  --id: string # The `savedObjectId` of the Timeline to retrieve.
]: nothing -> record<columns: table<aggregatable: bool, category: string, columnHeaderType: string, description: string, example: string, id: string, indexes: list, name: string, placeholder: string, searchable: bool, type: string>, created: float, createdBy: string, dataProviders: table<and: list, enabled: bool, excluded: bool, id: string, kqlQuery: string, name: string, queryMatch: record, type: string>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: table<favoriteDate: float, fullName: string, userName: string>, filters: table<exists: string, match_all: string, meta: record, missing: string, query: string, range: string, script: string>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record<kuery: record, serializedQuery: string>>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: table<noteId: string, version: string>, noteIds: list<string>, notes: table<noteId: string, version: string>, pinnedEventIds: list<string>, pinnedEventsSaveObject: table<pinnedEventId: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template_timeline_id" $template_timeline_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Timeline
#
# PATCH /api/timeline
# operationId: PatchTimeline
# --timeline shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string}
export def "timeline PatchTimeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timeline: record # shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string}
  --timelineId: string # The `savedObjectId` of the Timeline or Timeline template that you’re updating. (nullable, e.g. 15c1929b-0af7-42bd-85a8-56e234cc7c4e)
  --version: string # The version of the Timeline or Timeline template that you’re updating. (nullable, e.g. WzE0LDFd)
]: any -> record<columns: table<aggregatable: bool, category: string, columnHeaderType: string, description: string, example: string, id: string, indexes: list, name: string, placeholder: string, searchable: bool, type: string>, created: float, createdBy: string, dataProviders: table<and: list, enabled: bool, excluded: bool, id: string, kqlQuery: string, name: string, queryMatch: record, type: string>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: table<favoriteDate: float, fullName: string, userName: string>, filters: table<exists: string, match_all: string, meta: record, missing: string, query: string, range: string, script: string>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record<kuery: record, serializedQuery: string>>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: table<noteId: string, version: string>, noteIds: list<string>, notes: table<noteId: string, version: string>, pinnedEventIds: list<string>, pinnedEventsSaveObject: table<pinnedEventId: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline")
  let body = {timeline: $timeline, timelineId: $timelineId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Timeline or Timeline template
#
# POST /api/timeline
# operationId: CreateTimelines
# --timeline shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string}
export def "timeline CreateTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # The status of the Timeline.
  --templateTimelineId: string # A unique identifier for the Timeline template. (nullable, e.g. 6ce1b592-84e3-4b4a-9552-f189d4b82075)
  --templateTimelineVersion: float # Timeline template version number. (nullable, e.g. 12)
  timeline: record # shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string}
  --timelineId: string # A unique identifier for the Timeline. (nullable, e.g. 6ce1b592-84e3-4b4a-9552-f189d4b82075)
  --timelineType: string@timelineType-completer # The type of Timeline.
  --version: string # nullable
]: any -> record<columns: table<aggregatable: bool, category: string, columnHeaderType: string, description: string, example: string, id: string, indexes: list, name: string, placeholder: string, searchable: bool, type: string>, created: float, createdBy: string, dataProviders: table<and: list, enabled: bool, excluded: bool, id: string, kqlQuery: string, name: string, queryMatch: record, type: string>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: table<favoriteDate: float, fullName: string, userName: string>, filters: table<exists: string, match_all: string, meta: record, missing: string, query: string, range: string, script: string>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record<kuery: record, serializedQuery: string>>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: table<noteId: string, version: string>, noteIds: list<string>, notes: table<noteId: string, version: string>, pinnedEventIds: list<string>, pinnedEventsSaveObject: table<pinnedEventId: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline")
  let body = {status: $status, templateTimelineId: $templateTimelineId, templateTimelineVersion: $templateTimelineVersion, timeline: $timeline, timelineId: $timelineId, timelineType: $timelineType, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copies timeline or timeline template
#
# POST /api/timeline/_copy
# operationId: CopyTimeline
# --timeline shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string}
export def "timeline-copy CopyTimeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timeline: record # shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string}
  timelineIdToCopy: string # The `savedObjectId` of the timeline or template to duplicate.
]: any -> record<columns: table<aggregatable: bool, category: string, columnHeaderType: string, description: string, example: string, id: string, indexes: list, name: string, placeholder: string, searchable: bool, type: string>, created: float, createdBy: string, dataProviders: table<and: list, enabled: bool, excluded: bool, id: string, kqlQuery: string, name: string, queryMatch: record, type: string>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: table<favoriteDate: float, fullName: string, userName: string>, filters: table<exists: string, match_all: string, meta: record, missing: string, query: string, range: string, script: string>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record<kuery: record, serializedQuery: string>>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: table<noteId: string, version: string>, noteIds: list<string>, notes: table<noteId: string, version: string>, pinnedEventIds: list<string>, pinnedEventsSaveObject: table<pinnedEventId: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline/_copy")
  let body = {timeline: $timeline, timelineIdToCopy: $timelineIdToCopy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get draft Timeline or Timeline template details
#
# GET /api/timeline/_draft
# operationId: GetDraftTimelines
export def "timeline-draft GetDraftTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timelineType: string@timelineType-completer # Which draft to load (`default` investigation timeline or `template` timeline template).
]: nothing -> record<columns: table<aggregatable: bool, category: string, columnHeaderType: string, description: string, example: string, id: string, indexes: list, name: string, placeholder: string, searchable: bool, type: string>, created: float, createdBy: string, dataProviders: table<and: list, enabled: bool, excluded: bool, id: string, kqlQuery: string, name: string, queryMatch: record, type: string>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: table<favoriteDate: float, fullName: string, userName: string>, filters: table<exists: string, match_all: string, meta: record, missing: string, query: string, range: string, script: string>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record<kuery: record, serializedQuery: string>>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: table<noteId: string, version: string>, noteIds: list<string>, notes: table<noteId: string, version: string>, pinnedEventIds: list<string>, pinnedEventsSaveObject: table<pinnedEventId: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timelineType" $timelineType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/timeline/_draft" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a clean draft Timeline or Timeline template
#
# POST /api/timeline/_draft
# operationId: CleanDraftTimelines
export def "timeline-draft CleanDraftTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timelineType: string@timelineType-completer # The type of Timeline.
]: any -> record<columns: table<aggregatable: bool, category: string, columnHeaderType: string, description: string, example: string, id: string, indexes: list, name: string, placeholder: string, searchable: bool, type: string>, created: float, createdBy: string, dataProviders: table<and: list, enabled: bool, excluded: bool, id: string, kqlQuery: string, name: string, queryMatch: record, type: string>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: table<favoriteDate: float, fullName: string, userName: string>, filters: table<exists: string, match_all: string, meta: record, missing: string, query: string, range: string, script: string>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record<kuery: record, serializedQuery: string>>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: table<noteId: string, version: string>, noteIds: list<string>, notes: table<noteId: string, version: string>, pinnedEventIds: list<string>, pinnedEventsSaveObject: table<pinnedEventId: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline/_draft")
  let body = {timelineType: $timelineType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export Timelines
#
# POST /api/timeline/_export
# operationId: ExportTimelines
export def "timeline-export ExportTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file-name: string # The name of the file to export
  --ids: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_name" $file_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/timeline/_export" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Favorite a Timeline or Timeline template
#
# PATCH /api/timeline/_favorite
# operationId: PersistFavoriteRoute
export def "timeline-favorite PersistFavoriteRoute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateTimelineId: string # nullable
  --templateTimelineVersion: float # nullable
  --timelineId: string # nullable
  timelineType: string@timelineType-completer # The type of Timeline.
]: any -> record<favorite: table<favoriteDate: float, fullName: string, userName: string>, savedObjectId: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline/_favorite")
  let body = {templateTimelineId: $templateTimelineId, templateTimelineVersion: $templateTimelineVersion, timelineId: $timelineId, timelineType: $timelineType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import Timelines
#
# POST /api/timeline/_import
# operationId: ImportTimelines
export def "timeline-import ImportTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: any
  --isImmutable: string@isImmutable-completer # Whether the Timeline should be immutable
]: any -> record<errors: table<error: record, id: string>, success: bool, success_count: float, timelines_installed: float, timelines_updated: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline/_import")
  let body = {file: $file, isImmutable: $isImmutable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Install prepackaged Timelines
#
# POST /api/timeline/_prepackaged
# operationId: InstallPrepackedTimelines
# --prepackagedTimelines item shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string, eventIdToNoteIds?: list, noteIds?: list, notes?: list, pinnedEventIds?: list, pinnedEventsSaveObject?: list, savedObjectId: string, version: string}
# --timelinesToInstall item shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string, eventNotes: list, globalNotes: list, pinnedEventIds: list, savedObjectId: string, version: string}
# --timelinesToUpdate item shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string, eventNotes: list, globalNotes: list, pinnedEventIds: list, savedObjectId: string, version: string}
export def "timeline-prepackaged InstallPrepackedTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prepackagedTimelines: list # item shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string, eventIdToNoteIds?: list, noteIds?: list, notes?: list, pinnedEventIds?: list, pinnedEventsSaveObject?: list, savedObjectId: string, version: string}
  timelinesToInstall: list # item shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string, eventNotes: list, globalNotes: list, pinnedEventIds: list, savedObjectId: string, version: string}
  timelinesToUpdate: list # item shape: {columns?: list, created?: float, createdBy?: string, dataProviders?: list, dataViewId?: string, dateRange?: record, description?: string, eqlOptions?: record, eventType?: string, excludedRowRendererIds?: list, favorite?: list, filters?: list, indexNames?: list, kqlMode?: string, kqlQuery?: record, savedQueryId?: string, savedSearchId?: string, sort?: any, status?: "active"|"draft"|"immutable", templateTimelineId?: string, templateTimelineVersion?: float, timelineType?: "default"|"template", title?: string, updated?: float, updatedBy?: string, eventNotes: list, globalNotes: list, pinnedEventIds: list, savedObjectId: string, version: string}
]: any -> record<errors: table<error: record, id: string>, success: bool, success_count: float, timelines_installed: float, timelines_updated: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/timeline/_prepackaged")
  let body = {prepackagedTimelines: $prepackagedTimelines, timelinesToInstall: $timelinesToInstall, timelinesToUpdate: $timelinesToUpdate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve a Timeline or Timeline template
#
# GET /api/timeline/resolve
# operationId: ResolveTimeline
export def "timeline-resolve ResolveTimeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template-timeline-id: string # The ID of the template timeline to resolve
  --id: string # The ID of the timeline to resolve
]: nothing -> record<alias_purpose: string, alias_target_id: string, outcome: string, timeline: record<columns: list<record>, created: float, createdBy: string, dataProviders: list<record>, dataViewId: string, dateRange: record<end: any, start: any>, description: string, eqlOptions: record<eventCategoryField: string, query: string, size: any, tiebreakerField: string, timestampField: string>, eventType: string, excludedRowRendererIds: list<string>, favorite: list<record>, filters: list<record>, indexNames: list<string>, kqlMode: string, kqlQuery: record<filterQuery: record>, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: list<record>, noteIds: list<string>, notes: list<record>, pinnedEventIds: list<string>, pinnedEventsSaveObject: list<record>, savedObjectId: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template_timeline_id" $template_timeline_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/timeline/resolve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timelines or Timeline templates
#
# GET /api/timelines
# operationId: GetTimelines
export def "timelines GetTimelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --only-user-favorite: string@only-user-favorite-completer # If `true`, only Timelines that the current user has marked as favorite are returned. (nullable)
  --timeline-type: string@timeline-type-completer # Restrict results to `default` investigation timelines or `template` timeline templates.
  --sort-field: string@sort-field-completer-9 # Field used to sort the list (`title`, `description`, `updated`, or `created`).
  --sort-order: string@sort-order-completer # Whether to sort the results `ascending` or `descending`
  --page-size: string # How many results should returned at once (nullable)
  --page-index: string # How many pages should be skipped (nullable)
  --search: string # Allows to search for timelines by their title (nullable)
  --status: string@status-completer-1 # Filter by timeline lifecycle state (`active`, `draft`, or `immutable`).
]: nothing -> record<customTemplateTimelineCount: float, defaultTimelineCount: float, elasticTemplateTimelineCount: float, favoriteCount: float, templateTimelineCount: float, timeline: table<columns: list, created: float, createdBy: string, dataProviders: list, dataViewId: string, dateRange: record, description: string, eqlOptions: record, eventType: string, excludedRowRendererIds: list, favorite: list, filters: list, indexNames: list, kqlMode: string, kqlQuery: record, savedQueryId: string, savedSearchId: string, sort: any, status: string, templateTimelineId: string, templateTimelineVersion: float, timelineType: string, title: string, updated: float, updatedBy: string, eventIdToNoteIds: list, noteIds: list, notes: list, pinnedEventIds: list, pinnedEventsSaveObject: list>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "only_user_favorite" $only_user_favorite "scalar") (serialize-qp "timeline_type" $timeline_type "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_index" $page_index "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/timelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get visualizations
#
# GET /api/visualizations
# operationId: get-visualizations-redirect
export def "visualizations get-visualizations-redirect" [
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
  let full_url = (build-url $base "/api/visualizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a visualization
#
# POST /api/visualizations
# operationId: create-visualization-redirect
export def "visualizations create-visualization-redirect" [
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
  let full_url = (build-url $base "/api/visualizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a visualization
#
# GET /api/visualizations/{id}
# operationId: get-visualization-redirect
export def "visualizations get-visualization-redirect" [
  id: any
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
  let full_url = (build-url $base $"/api/visualizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a visualization
#
# PUT /api/visualizations/{id}
# operationId: update-visualization-redirect
export def "visualizations update-visualization-redirect" [
  id: any
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
  let full_url = (build-url $base $"/api/visualizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a visualization
#
# DELETE /api/visualizations/{id}
# operationId: delete-visualization-redirect
export def "visualizations delete-visualization-redirect" [
  id: any
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
  let full_url = (build-url $base $"/api/visualizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk delete workflows
#
# DELETE /api/workflows
# operationId: delete-workflows
export def "workflows delete-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, permanently deletes the workflows (hard delete) instead of soft-deleting them. The workflow IDs become available for reuse. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  ids: list # Array of workflow IDs to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/workflows" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflows
#
# GET /api/workflows
# operationId: get-workflows
export def "workflows get-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Free-text search query.
  --size: float # Number of results per page.
  --page: float # Page number.
  --enabled: list # Filter by enabled state.
  --createdBy: list # Filter by creator.
  --tags: list # Filter by tags.
  --managed: string@managed-completer # Filter by managed status. Defaults to "unmanaged".
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "enabled" $enabled "multi") (serialize-qp "createdBy" $createdBy "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "managed" $managed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk create workflows
#
# POST /api/workflows
# operationId: post-workflows
# --workflows item shape: {id?: string, yaml: string}
export def "workflows post-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: oneof<nothing, bool> # Whether to overwrite existing workflows. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  workflows: list # item shape: {id?: string, yaml: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overwrite" $overwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/workflows" $qp)
  let body = {workflows: $workflows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflow aggregations
#
# GET /api/workflows/aggs
# operationId: get-workflows-aggs
export def "workflows-aggs get-workflows-aggs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # Field or fields to aggregate on.
  --managed: string@managed-completer # Filter aggregations by managed status.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi") (serialize-qp "managed" $managed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/workflows/aggs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available connectors
#
# GET /api/workflows/connectors
# operationId: get-workflows-connectors
export def "workflows-connectors get-workflows-connectors" [
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
  let full_url = (build-url $base "/api/workflows/connectors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a workflow execution
#
# GET /api/workflows/executions/{executionId}
# operationId: get-workflows-executions-executionid
export def "workflows-executions get-workflows-executions-executionid" [
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeInput: oneof<nothing, bool> # Include execution input data. (default: false)
  --includeOutput: oneof<nothing, bool> # Include execution output data. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeInput" $includeInput "scalar") (serialize-qp "includeOutput" $includeOutput "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/workflows/executions/($executionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a workflow execution
#
# POST /api/workflows/executions/{executionId}/cancel
# operationId: post-workflows-executions-executionid-cancel
export def "workflows-executions-cancel post-workflows-executions-executionid-cancel" [
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/executions/($executionId)/cancel")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get child executions
#
# GET /api/workflows/executions/{executionId}/children
# operationId: get-workflows-executions-executionid-children
export def "workflows-executions-children get-workflows-executions-executionid-children" [
  executionId: string
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
  let full_url = (build-url $base $"/api/workflows/executions/($executionId)/children")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get execution logs
#
# GET /api/workflows/executions/{executionId}/logs
# operationId: get-workflows-executions-executionid-logs
export def "workflows-executions-logs get-workflows-executions-executionid-logs" [
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stepExecutionId: string # Filter logs by a specific step execution ID.
  --size: float # Number of log entries per page. (default: 100)
  --page: float # Page number. (default: 1)
  --sortField: string # Field to sort by.
  --sortOrder: string@sortOrder-completer # Sort order.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stepExecutionId" $stepExecutionId "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/workflows/executions/($executionId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume a workflow execution
#
# POST /api/workflows/executions/{executionId}/resume
# operationId: post-workflows-executions-executionid-resume
export def "workflows-executions-resume post-workflows-executions-executionid-resume" [
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  input: record # Input data to resume the execution with.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/executions/($executionId)/resume")
  let body = {input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a step execution
#
# GET /api/workflows/executions/{executionId}/step/{stepExecutionId}
# operationId: get-workflows-executions-executionid-step-stepexecutionid
export def "workflows-executions-step get-workflows-executions-executionid-step-stepexecutionid" [
  executionId: string
  stepExecutionId: string
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
  let full_url = (build-url $base $"/api/workflows/executions/($executionId)/step/($stepExecutionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export workflows
#
# POST /api/workflows/export
# operationId: post-workflows-export
export def "workflows-export post-workflows-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  ids: list # Array of workflow IDs to export.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workflows/export")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a managed workflow
#
# PUT /api/workflows/managed/workflow/{id}
# operationId: put-workflows-managed-workflow-id
export def "workflows-managed-workflow put-workflows-managed-workflow-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --description: string
  --enabled: oneof<nothing, bool>
  --name: string
  --tags: list
  --yaml: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/managed/workflow/($id)")
  let body = {description: $description, enabled: $enabled, name: $name, tags: $tags, yaml: $yaml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflows by IDs
#
# POST /api/workflows/mget
# operationId: post-workflows-mget
export def "workflows-mget post-workflows-mget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  ids: list # Array of workflow IDs to look up.
  --body-source: list # Array of source fields to include.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workflows/mget")
  let body = {ids: $ids, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflow JSON schema
#
# GET /api/workflows/schema
# operationId: get-workflows-schema
export def "workflows-schema get-workflows-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loose: oneof<nothing, bool> # When true, returns a permissive schema that allows additional properties. When false, returns a strict schema for full validation.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loose" $loose "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/workflows/schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workflow statistics
#
# GET /api/workflows/stats
# operationId: get-workflows-stats
export def "workflows-stats get-workflows-stats" [
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
  let full_url = (build-url $base "/api/workflows/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test a workflow step
#
# POST /api/workflows/step/test
# operationId: post-workflows-step-test
export def "workflows-step-test post-workflows-step-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  contextOverride: record # Context overrides for the step execution.
  --executionContext: record # Execution context for the step execution.
  stepId: string # ID of the step to test.
  --workflowId: string # ID of the workflow containing the step.
  workflowYaml: string # YAML definition of the workflow containing the step.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workflows/step/test")
  let body = {contextOverride: $contextOverride, executionContext: $executionContext, stepId: $stepId, workflowId: $workflowId, workflowYaml: $workflowYaml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test a workflow
#
# POST /api/workflows/test
# operationId: post-workflows-test
export def "workflows-test post-workflows-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  inputs: record # Key-value inputs for the test execution.
  --workflowId: string # ID of an existing workflow to test.
  --workflowYaml: string # YAML definition to test.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workflows/test")
  let body = {inputs: $inputs, workflowId: $workflowId, workflowYaml: $workflowYaml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a workflow
#
# POST /api/workflows/workflow
# operationId: post-workflows-workflow
export def "workflows-workflow post-workflows-workflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --id: string
  yaml: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workflows/workflow")
  let body = {id: $id, yaml: $yaml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a workflow
#
# DELETE /api/workflows/workflow/{id}
# operationId: delete-workflows-workflow-id
export def "workflows-workflow delete-workflows-workflow-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # When true, permanently deletes the workflow (hard delete) instead of soft-deleting it. The workflow ID becomes available for reuse. (default: false)
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/workflows/workflow/($id)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a workflow
#
# GET /api/workflows/workflow/{id}
# operationId: get-workflows-workflow-id
export def "workflows-workflow get-workflows-workflow-id" [
  id: string
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
  let full_url = (build-url $base $"/api/workflows/workflow/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workflow
#
# PUT /api/workflows/workflow/{id}
# operationId: put-workflows-workflow-id
export def "workflows-workflow put-workflows-workflow-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  --description: string
  --enabled: oneof<nothing, bool>
  --name: string
  --tags: list
  --yaml: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/workflow/($id)")
  let body = {description: $description, enabled: $enabled, name: $name, tags: $tags, yaml: $yaml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone a workflow
#
# POST /api/workflows/workflow/{id}/clone
# operationId: post-workflows-workflow-id-clone
export def "workflows-workflow-clone post-workflows-workflow-id-clone" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/workflow/($id)/clone")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a workflow
#
# POST /api/workflows/workflow/{id}/run
# operationId: post-workflows-workflow-id-run
export def "workflows-workflow-run post-workflows-workflow-id-run" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
  inputs: record # Key-value inputs for the workflow execution.
  --metadata: record # Optional metadata for the execution.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/workflow/($id)/run")
  let body = {inputs: $inputs, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflow executions
#
# GET /api/workflows/workflow/{workflowId}/executions
# operationId: get-workflows-workflow-workflowid-executions
export def "workflows-workflow-executions get-workflows-workflow-workflowid-executions" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statuses: list # Filter by execution status.
  --executionTypes: list # Filter by execution type.
  --executedBy: list # Filter by the user who triggered the execution.
  --concurrencyGroupKey: string # Filter by evaluated concurrency group key.
  --omitStepRuns: oneof<nothing, bool> # Whether to exclude step-level execution data.
  --finishedAfter: string # Datemath lower bound for filtering executions by finishedAt (inclusive when parsed).
  --finishedBefore: string # Datemath upper bound for filtering executions by finishedAt (inclusive when parsed with roundUp).
  --collapse: string@collapse-completer # Field to collapse execution results by.
  --sortField: string@sortField-completer-2 # Field to sort executions by.
  --sortOrder: string@sortOrder-completer # Sort order.
  --page: float # Page number.
  --size: float # Number of results per page.
  --startedAfter: string # Datemath lower bound for filtering executions by startedAt (inclusive when parsed).
  --startedBefore: string # Datemath upper bound for filtering executions by startedAt (inclusive when parsed with roundUp).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statuses" $statuses "multi") (serialize-qp "executionTypes" $executionTypes "multi") (serialize-qp "executedBy" $executedBy "multi") (serialize-qp "concurrencyGroupKey" $concurrencyGroupKey "scalar") (serialize-qp "omitStepRuns" $omitStepRuns "scalar") (serialize-qp "finishedAfter" $finishedAfter "scalar") (serialize-qp "finishedBefore" $finishedBefore "scalar") (serialize-qp "collapse" $collapse "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "startedAfter" $startedAfter "scalar") (serialize-qp "startedBefore" $startedBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/workflows/workflow/($workflowId)/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel all active workflow executions
#
# POST /api/workflows/workflow/{workflowId}/executions/cancel
# operationId: post-workflows-workflow-workflowid-executions-cancel
export def "workflows-workflow-executions-cancel post-workflows-workflow-workflowid-executions-cancel" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # A required header to protect against CSRF attacks (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/workflows/workflow/($workflowId)/executions/cancel")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workflow step executions
#
# GET /api/workflows/workflow/{workflowId}/executions/steps
# operationId: get-workflows-workflow-workflowid-executions-steps
export def "workflows-workflow-executions-steps get-workflows-workflow-workflowid-executions-steps" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stepId: string # Filter by step ID.
  --includeInput: oneof<nothing, bool> # Include step input data.
  --includeOutput: oneof<nothing, bool> # Include step output data.
  --page: float # Page number for pagination.
  --size: float # Number of results per page.
  --startedAfter: string # Datemath lower bound for filtering step executions by startedAt (inclusive when parsed).
  --startedBefore: string # Datemath upper bound for filtering step executions by startedAt (inclusive when parsed with roundUp).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stepId" $stepId "scalar") (serialize-qp "includeInput" $includeInput "scalar") (serialize-qp "includeOutput" $includeOutput "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "startedAfter" $startedAfter "scalar") (serialize-qp "startedBefore" $startedBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/workflows/workflow/($workflowId)/executions/steps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a paginated list of SLOs
#
# GET /s/{spaceId}/api/observability/slos
# operationId: findSlosOp
export def "s-observability-slos findSlosOp" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kqlQuery: string # A valid kql query to filter the SLO with (e.g. slo.name:latency* and slo.tags : "prod")
  --size: int # The page size to use for cursor-based pagination, must be greater or equal than 1 (default: 1, e.g. 1)
  --searchAfter: list # The cursor to use for fetching the results from, when using a cursor-base pagination.
  --page: int # The page to use for pagination, must be greater or equal than 1 (default: 1, e.g. 1)
  --perPage: int # Number of SLOs returned by page (default: 25, e.g. 25)
  --sortBy: string@sortBy-completer # Sort by field (default: status, e.g. status)
  --sortDirection: string@sortDirection-completer # Sort order (default: asc, e.g. asc)
  --hideStale: oneof<nothing, bool> # Hide stale SLOs from the list as defined by stale SLO threshold in SLO settings
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> record<page: float, perPage: float, results: table<budgetingMethod: string, createdAt: string, description: string, enabled: bool, groupBy: any, id: string, indicator: any, instanceId: string, name: string, objective: record, revision: float, settings: record, summary: record, tags: list, timeWindow: record, updatedAt: string, version: float>, searchAfter: string, size: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kqlQuery" $kqlQuery "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "searchAfter" $searchAfter "multi") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "hideStale" $hideStale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SLO
#
# POST /s/{spaceId}/api/observability/slos
# operationId: createSloOp
# --artifacts shape: {dashboards?: list}
# --objective shape: {target: float, timesliceTarget?: float, timesliceWindow?: string}
# --settings shape: {frequency?: string, preventInitialBackfill?: bool, syncDelay?: string, syncField?: string}
# --timeWindow shape: {duration: string, type: "rolling"|"calendarAligned"}
export def "s-observability-slos createSloOp" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  --artifacts: record # Links to related assets for the SLO — shape: {dashboards?: list}
  budgetingMethod: string@budgetingMethod-completer # The budgeting method to use when computing the rollup data. (e.g. occurrences)
  description: string # A description for the SLO.
  --groupBy: any # optional group by field or fields to use to generate an SLO per distinct value (e.g. [[service.name], service.name, [service.name, service.environment]])
  --id: string # A optional and unique identifier for the SLO. Must be between 8 and 36 chars (e.g. my-super-slo-id)
  indicator: any
  name: string # A name for the SLO.
  objective: record # Defines properties for the SLO objective — shape: {target: float, timesliceTarget?: float, timesliceWindow?: string}
  --settings: record # Defines properties for SLO settings. — shape: {frequency?: string, preventInitialBackfill?: bool, syncDelay?: string, syncField?: string}
  --tags: list # List of tags
  timeWindow: record # Defines properties for the SLO time window — shape: {duration: string, type: "rolling"|"calendarAligned"}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos")
  let body = {artifacts: $artifacts, budgetingMethod: $budgetingMethod, description: $description, groupBy: $groupBy, id: $id, indicator: $indicator, name: $name, objective: $objective, settings: $settings, tags: $tags, timeWindow: $timeWindow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete SLO definitions and their associated summary and rollup data.
#
# POST /s/{spaceId}/api/observability/slos/_bulk_delete
# operationId: bulkDeleteOp
export def "s-observability-slos-bulk-delete bulkDeleteOp" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  list: list # An array of SLO Definition id
]: any -> record<taskId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/_bulk_delete")
  let body = {list: $list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the status of the bulk deletion
#
# GET /s/{spaceId}/api/observability/slos/_bulk_delete/{taskId}
# operationId: bulkDeleteStatusOp
export def "s-observability-slos-bulk-delete bulkDeleteStatusOp" [
  spaceId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> record<error: string, isDone: bool, results: table<error: string, id: string, success: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/_bulk_delete/($taskId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch delete rollup and summary data
#
# POST /s/{spaceId}/api/observability/slos/_bulk_purge_rollup
# operationId: deleteRollupDataOp
# --purgePolicy shape: {age?: string, purgeType?: "fixed-age", timestamp?: string}
export def "s-observability-slos-bulk-purge-rollup post" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  list: list # An array of slo ids
  purgePolicy: record # Policy that dictates which SLI documents to purge based on age — shape: {age?: string, purgeType?: "fixed-age", timestamp?: string}
]: any -> record<taskId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/_bulk_purge_rollup")
  let body = {list: $list, purgePolicy: $purgePolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch delete rollup and summary data
#
# POST /s/{spaceId}/api/observability/slos/_delete_instances
# operationId: deleteSloInstancesOp
# --list item shape: {instanceId: string, sloId: string}
export def "s-observability-slos-delete-instances post" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  list: list # An array of slo id and instance id — item shape: {instanceId: string, sloId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/_delete_instances")
  let body = {list: $list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SLO
#
# DELETE /s/{spaceId}/api/observability/slos/{sloId}
# operationId: deleteSloOp
export def "s-observability-slos delete" [
  spaceId: string
  sloId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/($sloId)")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SLO
#
# GET /s/{spaceId}/api/observability/slos/{sloId}
# operationId: getSloOp
export def "s-observability-slos get" [
  spaceId: string
  sloId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --instanceId: string # the specific instanceId used by the summary calculation (e.g. host-abcde)
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> record<budgetingMethod: string, createdAt: string, description: string, enabled: bool, groupBy: any, id: string, indicator: any, instanceId: string, name: string, objective: record<target: float, timesliceTarget: float, timesliceWindow: string>, revision: float, settings: record<frequency: string, preventInitialBackfill: bool, syncDelay: string, syncField: string>, summary: record<errorBudget: record<consumed: float, initial: float, isEstimated: bool, remaining: float>, sliValue: float, status: string>, tags: list<string>, timeWindow: record<duration: string, type: string>, updatedAt: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "instanceId" $instanceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/($sloId)" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SLO
#
# PUT /s/{spaceId}/api/observability/slos/{sloId}
# operationId: updateSloOp
# --artifacts shape: {dashboards?: list}
# --objective shape: {target: float, timesliceTarget?: float, timesliceWindow?: string}
# --settings shape: {frequency?: string, preventInitialBackfill?: bool, syncDelay?: string, syncField?: string}
# --timeWindow shape: {duration: string, type: "rolling"|"calendarAligned"}
export def "s-observability-slos updateSloOp" [
  spaceId: string
  sloId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
  --artifacts: record # Links to related assets for the SLO — shape: {dashboards?: list}
  --budgetingMethod: string@budgetingMethod-completer # The budgeting method to use when computing the rollup data. (e.g. occurrences)
  --description: string # A description for the SLO.
  --groupBy: any # optional group by field or fields to use to generate an SLO per distinct value (e.g. [[service.name], service.name, [service.name, service.environment]])
  --indicator: any
  --name: string # A name for the SLO.
  --objective: record # Defines properties for the SLO objective — shape: {target: float, timesliceTarget?: float, timesliceWindow?: string}
  --settings: record # Defines properties for SLO settings. — shape: {frequency?: string, preventInitialBackfill?: bool, syncDelay?: string, syncField?: string}
  --tags: list # List of tags
  --timeWindow: record # Defines properties for the SLO time window — shape: {duration: string, type: "rolling"|"calendarAligned"}
]: any -> record<artifacts: record<dashboards: list<record>>, budgetingMethod: string, createdAt: string, description: string, enabled: bool, groupBy: any, id: string, indicator: any, name: string, objective: record<target: float, timesliceTarget: float, timesliceWindow: string>, revision: float, settings: record<frequency: string, preventInitialBackfill: bool, syncDelay: string, syncField: string>, tags: list<string>, timeWindow: record<duration: string, type: string>, updatedAt: string, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/($sloId)")
  let body = {artifacts: $artifacts, budgetingMethod: $budgetingMethod, description: $description, groupBy: $groupBy, indicator: $indicator, name: $name, objective: $objective, settings: $settings, tags: $tags, timeWindow: $timeWindow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset an SLO
#
# POST /s/{spaceId}/api/observability/slos/{sloId}/_reset
# operationId: resetSloOp
export def "s-observability-slos-reset resetSloOp" [
  spaceId: string
  sloId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> record<artifacts: record<dashboards: list<record>>, budgetingMethod: string, createdAt: string, description: string, enabled: bool, groupBy: any, id: string, indicator: any, name: string, objective: record<target: float, timesliceTarget: float, timesliceWindow: string>, revision: float, settings: record<frequency: string, preventInitialBackfill: bool, syncDelay: string, syncField: string>, tags: list<string>, timeWindow: record<duration: string, type: string>, updatedAt: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/($sloId)/_reset")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable an SLO
#
# POST /s/{spaceId}/api/observability/slos/{sloId}/disable
# operationId: disableSloOp
export def "s-observability-slos-disable disableSloOp" [
  spaceId: string
  sloId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/($sloId)/disable")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable an SLO
#
# POST /s/{spaceId}/api/observability/slos/{sloId}/enable
# operationId: enableSloOp
export def "s-observability-slos-enable enableSloOp" [
  spaceId: string
  sloId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/s/($spaceId)/api/observability/slos/($sloId)/enable")
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the SLO definitions
#
# GET /s/{spaceId}/internal/observability/slos/_definitions
# operationId: getDefinitionsOp
export def "s-internal-observability-slos-definitions get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeOutdatedOnly: oneof<nothing, bool> # Indicates if the API returns only outdated SLO or all SLO definitions
  --includeHealth: oneof<nothing, bool> # Indicates if the API returns SLO health data with definitions (e.g. true)
  --tags: string # Filters the SLOs by tag
  --search: string # Filters the SLOs by name (e.g. my service availability)
  --page: float # The page to use for pagination, must be greater or equal than 1 (e.g. 1)
  --perPage: int # Number of SLOs returned by page (default: 100, e.g. 100)
  --kbn-xsrf: string # Cross-site request forgery protection
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeOutdatedOnly" $includeOutdatedOnly "scalar") (serialize-qp "includeHealth" $includeHealth "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/s/($spaceId)/internal/observability/slos/_definitions" $qp)
  let extra_headers = {"kbn-xsrf": $kbn_xsrf} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
