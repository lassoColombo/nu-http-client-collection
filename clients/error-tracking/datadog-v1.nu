# Auto-generated client for Datadog API V1 Collection v1.0
# Source: https://raw.githubusercontent.com/DataDog/datadog-api-client-python/master/.generator/schemas/v1/openapi.yaml
# Auth: --token flag or $env.DATADOG_API_KEY

const BASE_URL = "https://api.datadoghq.com"
const DEFAULT_AUTH = "dd-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATADOG_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "dd-api-key" => { {headers: {DD-API-KEY: $token_val}, query: ""} }
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
    "dd-application-key" => { {headers: {DD-APPLICATION-KEY: $token_val}, query: ""} }
    "query-application_key" => { {headers: {}, query: $"application_key=($token_val)"} }
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
def base-url-completer [] { ["https://api.datadoghq.com" "https://api.us3.datadoghq.com" "https://api.us5.datadoghq.com" "https://api.ap1.datadoghq.com" "https://api.ap2.datadoghq.com" "https://api.datadoghq.eu" "https://api.ddog-gov.com" "https://api.us2.ddog-gov.com" "https://ip-ranges.datadoghq.com" "https://http-intake.logs.datadoghq.com" "https://{subdomain}.{site}"] }
def auth-scheme-completer [] { ["bearer" "dd-api-key" "query-api_key" "dd-application-key" "query-application_key"] }

# Completers for enum parameters
def sort-dir-completer [] { ["asc" "desc"] }
def sort-completer [] { ["computed_on" "end_date" "size" "start_date"] }
def layout-type-completer [] { ["free" "ordered"] }
def reflow-type-completer [] { ["auto" "fixed"] }
def dashboard-type-completer [] { ["custom_screenboard" "custom_timeboard"] }
def share-type-completer [] { ["embed" "invite" "open"] }
def status-completer [] { ["active" "paused"] }
def Content-Encoding-completer [] { ["deflate"] }
def priority-completer [] { ["low" "normal"] }
def alert-type-completer [] { ["error" "info" "recommendation" "snapshot" "success" "user_update" "warning"] }
def namespace-completer [] { ["application_elb" "custom" "elb" "lambda" "network_elb" "rds" "sqs" "step_functions"] }
def encode-as-completer [] { ["form" "json"] }
def sort-completer-1 [] { ["asc" "desc"] }
def draft-status-completer [] { ["draft" "published"] }
def type-completer [] { ["audit alert" "ci-pipelines alert" "ci-tests alert" "composite" "cost alert" "data-jobs alert" "data-quality alert" "database-monitoring alert" "error-tracking alert" "event alert" "event-v2 alert" "log alert" "metric alert" "network-path alert" "network-performance alert" "process alert" "query alert" "rum alert" "service check" "slo alert" "synthetics alert" "trace-analytics alert"] }
def archiveReason-completer [] { ["false_positive" "investigated_case_opened" "none" "other" "testing_or_maintenance" "true_positive_benign" "true_positive_malicious"] }
def state-completer [] { ["archived" "open" "under_review"] }
def Content-Encoding-completer-1 [] { ["deflate" "gzip"] }
def timeframe-completer [] { ["30d" "7d" "90d" "custom"] }
def type-completer-1 [] { ["metric" "monitor" "time_slice"] }
def status-completer-1 [] { ["live" "paused"] }
def subtype-completer [] { ["dns" "grpc" "http" "icmp" "multi" "ssl" "tcp" "udp" "websocket"] }
def type-completer-2 [] { ["api"] }
def type-completer-3 [] { ["browser"] }
def type-completer-4 [] { ["mobile"] }
def new-status-completer [] { ["live" "paused"] }
def usage-type-completer [] { ["api_usage" "apm_fargate_usage" "apm_host_usage" "apm_usm_usage" "appsec_fargate_usage" "appsec_usage" "asm_serverless_traced_invocations_percentage" "asm_serverless_traced_invocations_usage" "bits_ai_investigations_usage" "browser_usage" "ci_code_coverage_committers_percentage" "ci_code_coverage_committers_usage" "ci_pipeline_indexed_spans_usage" "ci_test_indexed_spans_usage" "ci_visibility_itr_usage" "cloud_siem_usage" "code_security_host_usage" "container_excl_agent_usage" "container_usage" "cspm_containers_usage" "cspm_hosts_usage" "custom_event_usage" "custom_ingested_timeseries_usage" "custom_timeseries_usage" "cws_containers_usage" "cws_fargate_task_usage" "cws_hosts_usage" "data_jobs_monitoring_usage" "data_stream_monitoring_usage" "dbm_hosts_usage" "dbm_queries_usage" "error_tracking_percentage" "error_tracking_usage" "estimated_indexed_spans_usage" "estimated_ingested_spans_usage" "fargate_usage" "flex_logs_starter" "flex_stored_logs" "functions_usage" "incident_management_monthly_active_users_usage" "indexed_spans_usage" "infra_host_basic_usage" "infra_host_usage" "ingested_logs_bytes_usage" "ingested_spans_bytes_usage" "invocations_usage" "lambda_traced_invocations_usage" "llm_observability_usage" "llm_spans_usage" "logs_indexed_15day_usage" "logs_indexed_180day_usage" "logs_indexed_1day_usage" "logs_indexed_30day_usage" "logs_indexed_360day_usage" "logs_indexed_3day_usage" "logs_indexed_45day_usage" "logs_indexed_60day_usage" "logs_indexed_7day_usage" "logs_indexed_90day_usage" "logs_indexed_custom_retention_usage" "mobile_app_testing_usage" "ndm_netflow_usage" "network_device_wireless_usage" "npm_host_usage" "obs_pipeline_bytes_usage" "obs_pipelines_vcpu_usage" "online_archive_usage" "product_analytics_session_usage" "profiled_container_usage" "profiled_fargate_usage" "profiled_host_usage" "published_app" "rum_browser_mobile_sessions_usage" "rum_ingested_usage" "rum_investigate_usage" "rum_replay_sessions_usage" "rum_session_replay_add_on_usage" "sca_fargate_usage" "sds_scanned_bytes_usage" "serverless_apps_apm_usage" "serverless_apps_usage" "siem_12mo_retention_usage" "siem_6mo_retention_usage" "siem_analyzed_logs_add_on_usage" "siem_ingested_bytes_usage" "snmp_usage" "universal_service_monitoring_usage" "vuln_management_hosts_usage" "workflow_executions_usage"] }
def fields-completer [] { ["*" "api_percentage" "api_usage" "apm_fargate_percentage" "apm_fargate_usage" "apm_host_percentage" "apm_host_usage" "apm_usm_percentage" "apm_usm_usage" "appsec_fargate_percentage" "appsec_fargate_usage" "appsec_percentage" "appsec_usage" "asm_serverless_traced_invocations_percentage" "asm_serverless_traced_invocations_usage" "bits_ai_investigations_percentage" "bits_ai_investigations_usage" "browser_percentage" "browser_usage" "ci_pipeline_indexed_spans_percentage" "ci_pipeline_indexed_spans_usage" "ci_test_indexed_spans_percentage" "ci_test_indexed_spans_usage" "ci_visibility_itr_percentage" "ci_visibility_itr_usage" "cloud_siem_percentage" "cloud_siem_usage" "code_security_host_percentage" "code_security_host_usage" "container_excl_agent_percentage" "container_excl_agent_usage" "container_percentage" "container_usage" "cspm_containers_percentage" "cspm_containers_usage" "cspm_hosts_percentage" "cspm_hosts_usage" "custom_event_percentage" "custom_event_usage" "custom_ingested_timeseries_percentage" "custom_ingested_timeseries_usage" "custom_timeseries_percentage" "custom_timeseries_usage" "cws_containers_percentage" "cws_containers_usage" "cws_fargate_task_percentage" "cws_fargate_task_usage" "cws_hosts_percentage" "cws_hosts_usage" "data_jobs_monitoring_percentage" "data_jobs_monitoring_usage" "data_stream_monitoring_percentage" "data_stream_monitoring_usage" "dbm_hosts_percentage" "dbm_hosts_usage" "dbm_queries_percentage" "dbm_queries_usage" "error_tracking_percentage" "error_tracking_usage" "estimated_indexed_spans_percentage" "estimated_indexed_spans_usage" "estimated_ingested_spans_percentage" "estimated_ingested_spans_usage" "fargate_percentage" "fargate_usage" "flex_logs_starter_percentage" "flex_logs_starter_usage" "flex_stored_logs_percentage" "flex_stored_logs_usage" "functions_percentage" "functions_usage" "incident_management_monthly_active_users_percentage" "incident_management_monthly_active_users_usage" "indexed_spans_percentage" "indexed_spans_usage" "infra_host_basic_percentage" "infra_host_basic_usage" "infra_host_percentage" "infra_host_usage" "ingested_logs_bytes_percentage" "ingested_logs_bytes_usage" "ingested_spans_bytes_percentage" "ingested_spans_bytes_usage" "invocations_percentage" "invocations_usage" "lambda_traced_invocations_percentage" "lambda_traced_invocations_usage" "llm_observability_percentage" "llm_observability_usage" "llm_spans_percentage" "llm_spans_usage" "logs_indexed_15day_percentage" "logs_indexed_15day_usage" "logs_indexed_180day_percentage" "logs_indexed_180day_usage" "logs_indexed_1day_percentage" "logs_indexed_1day_usage" "logs_indexed_30day_percentage" "logs_indexed_30day_usage" "logs_indexed_360day_percentage" "logs_indexed_360day_usage" "logs_indexed_3day_percentage" "logs_indexed_3day_usage" "logs_indexed_45day_percentage" "logs_indexed_45day_usage" "logs_indexed_60day_percentage" "logs_indexed_60day_usage" "logs_indexed_7day_percentage" "logs_indexed_7day_usage" "logs_indexed_90day_percentage" "logs_indexed_90day_usage" "logs_indexed_custom_retention_percentage" "logs_indexed_custom_retention_usage" "mobile_app_testing_percentage" "mobile_app_testing_usage" "ndm_netflow_percentage" "ndm_netflow_usage" "network_device_wireless_percentage" "network_device_wireless_usage" "npm_host_percentage" "npm_host_usage" "obs_pipeline_bytes_percentage" "obs_pipeline_bytes_usage" "obs_pipelines_vcpu_percentage" "obs_pipelines_vcpu_usage" "online_archive_percentage" "online_archive_usage" "product_analytics_session_percentage" "product_analytics_session_usage" "profiled_container_percentage" "profiled_container_usage" "profiled_fargate_percentage" "profiled_fargate_usage" "profiled_host_percentage" "profiled_host_usage" "published_app_percentage" "published_app_usage" "rum_browser_mobile_sessions_percentage" "rum_browser_mobile_sessions_usage" "rum_ingested_percentage" "rum_ingested_usage" "rum_investigate_percentage" "rum_investigate_usage" "rum_replay_sessions_percentage" "rum_replay_sessions_usage" "rum_session_replay_add_on_percentage" "rum_session_replay_add_on_usage" "sca_fargate_percentage" "sca_fargate_usage" "sds_scanned_bytes_percentage" "sds_scanned_bytes_usage" "serverless_apps_apm_percentage" "serverless_apps_apm_usage" "serverless_apps_percentage" "serverless_apps_usage" "siem_12mo_retention_percentage" "siem_12mo_retention_usage" "siem_6mo_retention_percentage" "siem_6mo_retention_usage" "siem_analyzed_logs_add_on_percentage" "siem_analyzed_logs_add_on_usage" "siem_ingested_bytes_percentage" "siem_ingested_bytes_usage" "snmp_percentage" "snmp_usage" "universal_service_monitoring_percentage" "universal_service_monitoring_usage" "vuln_management_hosts_percentage" "vuln_management_hosts_usage" "workflow_executions_percentage" "workflow_executions_usage"] }
def sort-direction-completer [] { ["asc" "desc"] }
def sort-name-completer [] { ["*" "api_percentage" "api_usage" "apm_fargate_percentage" "apm_fargate_usage" "apm_host_percentage" "apm_host_usage" "apm_usm_percentage" "apm_usm_usage" "appsec_fargate_percentage" "appsec_fargate_usage" "appsec_percentage" "appsec_usage" "asm_serverless_traced_invocations_percentage" "asm_serverless_traced_invocations_usage" "bits_ai_investigations_percentage" "bits_ai_investigations_usage" "browser_percentage" "browser_usage" "ci_pipeline_indexed_spans_percentage" "ci_pipeline_indexed_spans_usage" "ci_test_indexed_spans_percentage" "ci_test_indexed_spans_usage" "ci_visibility_itr_percentage" "ci_visibility_itr_usage" "cloud_siem_percentage" "cloud_siem_usage" "code_security_host_percentage" "code_security_host_usage" "container_excl_agent_percentage" "container_excl_agent_usage" "container_percentage" "container_usage" "cspm_containers_percentage" "cspm_containers_usage" "cspm_hosts_percentage" "cspm_hosts_usage" "custom_event_percentage" "custom_event_usage" "custom_ingested_timeseries_percentage" "custom_ingested_timeseries_usage" "custom_timeseries_percentage" "custom_timeseries_usage" "cws_containers_percentage" "cws_containers_usage" "cws_fargate_task_percentage" "cws_fargate_task_usage" "cws_hosts_percentage" "cws_hosts_usage" "data_jobs_monitoring_percentage" "data_jobs_monitoring_usage" "data_stream_monitoring_percentage" "data_stream_monitoring_usage" "dbm_hosts_percentage" "dbm_hosts_usage" "dbm_queries_percentage" "dbm_queries_usage" "error_tracking_percentage" "error_tracking_usage" "estimated_indexed_spans_percentage" "estimated_indexed_spans_usage" "estimated_ingested_spans_percentage" "estimated_ingested_spans_usage" "fargate_percentage" "fargate_usage" "flex_logs_starter_percentage" "flex_logs_starter_usage" "flex_stored_logs_percentage" "flex_stored_logs_usage" "functions_percentage" "functions_usage" "incident_management_monthly_active_users_percentage" "incident_management_monthly_active_users_usage" "indexed_spans_percentage" "indexed_spans_usage" "infra_host_basic_percentage" "infra_host_basic_usage" "infra_host_percentage" "infra_host_usage" "ingested_logs_bytes_percentage" "ingested_logs_bytes_usage" "ingested_spans_bytes_percentage" "ingested_spans_bytes_usage" "invocations_percentage" "invocations_usage" "lambda_traced_invocations_percentage" "lambda_traced_invocations_usage" "llm_observability_percentage" "llm_observability_usage" "llm_spans_percentage" "llm_spans_usage" "logs_indexed_15day_percentage" "logs_indexed_15day_usage" "logs_indexed_180day_percentage" "logs_indexed_180day_usage" "logs_indexed_1day_percentage" "logs_indexed_1day_usage" "logs_indexed_30day_percentage" "logs_indexed_30day_usage" "logs_indexed_360day_percentage" "logs_indexed_360day_usage" "logs_indexed_3day_percentage" "logs_indexed_3day_usage" "logs_indexed_45day_percentage" "logs_indexed_45day_usage" "logs_indexed_60day_percentage" "logs_indexed_60day_usage" "logs_indexed_7day_percentage" "logs_indexed_7day_usage" "logs_indexed_90day_percentage" "logs_indexed_90day_usage" "logs_indexed_custom_retention_percentage" "logs_indexed_custom_retention_usage" "mobile_app_testing_percentage" "mobile_app_testing_usage" "ndm_netflow_percentage" "ndm_netflow_usage" "network_device_wireless_percentage" "network_device_wireless_usage" "npm_host_percentage" "npm_host_usage" "obs_pipeline_bytes_percentage" "obs_pipeline_bytes_usage" "obs_pipelines_vcpu_percentage" "obs_pipelines_vcpu_usage" "online_archive_percentage" "online_archive_usage" "product_analytics_session_percentage" "product_analytics_session_usage" "profiled_container_percentage" "profiled_container_usage" "profiled_fargate_percentage" "profiled_fargate_usage" "profiled_host_percentage" "profiled_host_usage" "published_app_percentage" "published_app_usage" "rum_browser_mobile_sessions_percentage" "rum_browser_mobile_sessions_usage" "rum_ingested_percentage" "rum_ingested_usage" "rum_investigate_percentage" "rum_investigate_usage" "rum_replay_sessions_percentage" "rum_replay_sessions_usage" "rum_session_replay_add_on_percentage" "rum_session_replay_add_on_usage" "sca_fargate_percentage" "sca_fargate_usage" "sds_scanned_bytes_percentage" "sds_scanned_bytes_usage" "serverless_apps_apm_percentage" "serverless_apps_apm_usage" "serverless_apps_percentage" "serverless_apps_usage" "siem_12mo_retention_percentage" "siem_12mo_retention_usage" "siem_6mo_retention_percentage" "siem_6mo_retention_usage" "siem_analyzed_logs_add_on_percentage" "siem_analyzed_logs_add_on_usage" "siem_ingested_bytes_percentage" "siem_ingested_bytes_usage" "snmp_percentage" "snmp_usage" "universal_service_monitoring_percentage" "universal_service_monitoring_usage" "vuln_management_hosts_percentage" "vuln_management_hosts_usage" "workflow_executions_percentage" "workflow_executions_usage"] }
def access-role-completer [] { ["ERROR" "adm" "ro" "st"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ip-ranges GetIPRanges" } } | get name | first)
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

# List IP Ranges
#
# GET /
# operationId: GetIPRanges
export def "ip-ranges GetIPRanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<agents: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, api: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, apm: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, global: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, logs: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, modified: string, orchestrator: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, process: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, remote_configuration: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, synthetics: record<prefixes_ipv4: list<string>, prefixes_ipv4_by_location: record, prefixes_ipv6: list<string>, prefixes_ipv6_by_location: record>, synthetics_private_locations: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>, version: int, webhooks: record<prefixes_ipv4: list<string>, prefixes_ipv6: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default "https://{subdomain}.{site}")
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all API keys
#
# GET /api/v1/api_key
# operationId: ListAPIKeys
export def "api-key ListAPIKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_keys: table<created: string, created_by: string, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API key
#
# POST /api/v1/api_key
# operationId: CreateAPIKey
export def "api-key CreateAPIKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of your API key. (e.g. example user)
]: any -> record<api_key: record<created: string, created_by: string, key: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/api_key")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an API key
#
# DELETE /api/v1/api_key/{key}
# operationId: DeleteAPIKey
export def "api-key DeleteAPIKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_key: record<created: string, created_by: string, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api_key/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API key
#
# GET /api/v1/api_key/{key}
# operationId: GetAPIKey
export def "api-key GetAPIKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_key: record<created: string, created_by: string, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api_key/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an API key
#
# PUT /api/v1/api_key/{key}
# operationId: UpdateAPIKey
export def "api-key UpdateAPIKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of your API key. (e.g. example user)
]: any -> record<api_key: record<created: string, created_by: string, key: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api_key/($key)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all application keys
#
# GET /api/v1/application_key
# operationId: ListApplicationKeys
export def "application-key ListApplicationKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_keys: table<hash: string, name: string, owner: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/application_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an application key
#
# POST /api/v1/application_key
# operationId: CreateApplicationKey
export def "application-key CreateApplicationKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of an application key. (e.g. example user)
]: any -> record<application_key: record<hash: string, name: string, owner: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/application_key")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an application key
#
# DELETE /api/v1/application_key/{key}
# operationId: DeleteApplicationKey
export def "application-key DeleteApplicationKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_key: record<hash: string, name: string, owner: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/application_key/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an application key
#
# GET /api/v1/application_key/{key}
# operationId: GetApplicationKey
export def "application-key GetApplicationKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_key: record<hash: string, name: string, owner: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/application_key/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an application key
#
# PUT /api/v1/application_key/{key}
# operationId: UpdateApplicationKey
export def "application-key UpdateApplicationKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of an application key. (e.g. example user)
]: any -> record<application_key: record<hash: string, name: string, owner: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/application_key/($key)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit a Service Check
#
# POST /api/v1/check_run
# operationId: SubmitServiceCheck
export def "check-run SubmitServiceCheck" [
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
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/check_run")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of available daily custom reports
#
# GET /api/v1/daily_custom_reports
# DEPRECATED
# operationId: GetDailyCustomReports
@deprecated
export def "daily-custom-reports GetDailyCustomReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pagesize: int # The number of files to return in the response. `[default=60]`. (format: int64)
  --pagenumber: int # The identifier of the first page to return. This parameter is used for the pagination feature `[default=0]`. (format: int64)
  --sort-dir: string@sort-dir-completer # The direction to sort by: `[desc, asc]`. (default: desc)
  --qp-sort: string@sort-completer # The field to sort by: `[computed_on, size, start_date, end_date]`. (default: start_date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "page[number]" $pagenumber "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/daily_custom_reports" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specified daily custom reports
#
# GET /api/v1/daily_custom_reports/{report_id}
# DEPRECATED
# operationId: GetSpecifiedDailyCustomReports
@deprecated
export def "daily-custom-reports GetSpecifiedDailyCustomReports" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/daily_custom_reports/($report_id)")
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete dashboards
#
# DELETE /api/v1/dashboard
# operationId: DeleteDashboards
# --data item shape: {id: string, type: "dashboard"}
export def "dashboard DeleteDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # List of dashboard bulk action request data objects. (e.g. [{id: 123-abc-456, type: dashboard}]) — item shape: {id: string, type: "dashboard"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboard")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all dashboards
#
# GET /api/v1/dashboard
# operationId: ListDashboards
export def "dashboard ListDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filtershared: string@bool-completer # When `true`, this query only returns shared custom created or cloned dashboards.
  --filterdeleted: string@bool-completer # When `true`, this query returns only deleted custom-created or cloned dashboards. This parameter is incompatible with `filter[shared]`.
  --count: int # The maximum number of dashboards returned in the list. (format: int64, default: 100)
  --start: int # The specific offset to use as the beginning of the returned response. (format: int64)
]: nothing -> record<dashboards: table<author_handle: string, created_at: string, description: string, id: string, is_read_only: bool, layout_type: string, modified_at: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[shared]" $filtershared "scalar") (serialize-qp "filter[deleted]" $filterdeleted "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/dashboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore deleted dashboards
#
# PATCH /api/v1/dashboard
# operationId: RestoreDashboards
# --data item shape: {id: string, type: "dashboard"}
export def "dashboard RestoreDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # List of dashboard bulk action request data objects. (e.g. [{id: 123-abc-456, type: dashboard}]) — item shape: {id: string, type: "dashboard"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboard")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new dashboard
#
# POST /api/v1/dashboard
# operationId: CreateDashboard
# --tabs item shape: {id: string, name: string, widget_ids: list}
# --template_variable_presets item shape: {name?: string, template_variables?: list}
# --template_variables item shape: {available_values?: list, default?: string, defaults?: list, name: string, prefix?: string, type?: string}
# --widgets item shape: {definition: any, id?: int, layout?: record}
@deprecated --flag is-read-only
export def "dashboard CreateDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the dashboard. (nullable)
  --is-read-only: string@bool-completer # Whether this dashboard is read-only. If True, only the author and admins can make changes to it.  This property is deprecated; please use the [Restriction Policies API](https://docs.datadoghq.com/api/latest/restriction-policies/) instead to manage write authorization for individual dashboards. (DEPRECATED, e.g. false)
  layout_type: string@layout-type-completer # Layout type of the dashboard. (e.g. ordered)
  --notify-list: list # List of handles of users to notify when changes are made to this dashboard. (nullable)
  --reflow-type: string@reflow-type-completer # Reflow type for a **new dashboard layout** dashboard. Set this only when layout type is 'ordered'. If set to 'fixed', the dashboard expects all widgets to have a layout, and if it's set to 'auto', widgets should not have layouts.
  --restricted-roles: list # A list of role identifiers. Only the author and users associated with at least one of these roles can edit this dashboard.
  --tabs: list # List of tabs for organizing dashboard widgets into groups. (nullable) — item shape: {id: string, name: string, widget_ids: list}
  --tags: list # List of team names representing ownership of a dashboard. (nullable)
  --template-variable-presets: list # Array of template variables saved views. (nullable) — item shape: {name?: string, template_variables?: list}
  --template-variables: list # List of template variables for this dashboard. (nullable) — item shape: {available_values?: list, default?: string, defaults?: list, name: string, prefix?: string, type?: string}
  title: string # Title of the dashboard. (e.g. )
  widgets: list # List of widgets to display on the dashboard. (e.g. [{definition: {requests: {fill: {q: avg:system.cpu.user{*}}}, type: hostmap}}]) — item shape: {definition: any, id?: int, layout?: record}
]: any -> record<author_handle: string, author_name: string, created_at: string, description: string, id: string, is_read_only: bool, layout_type: string, modified_at: string, notify_list: list<string>, reflow_type: string, restricted_roles: list<string>, tabs: table<id: string, name: string, widget_ids: list>, tags: list<string>, template_variable_presets: table<name: string, template_variables: list>, template_variables: table<available_values: list, default: string, defaults: list, name: string, prefix: string, type: string>, title: string, url: string, widgets: table<definition: any, id: int, layout: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboard")
  let body = {description: $description, is_read_only: $is_read_only, layout_type: $layout_type, notify_list: $notify_list, reflow_type: $reflow_type, restricted_roles: $restricted_roles, tabs: $tabs, tags: $tags, template_variable_presets: $template_variable_presets, template_variables: $template_variables, title: $title, widgets: $widgets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all dashboard lists
#
# GET /api/v1/dashboard/lists/manual
# operationId: ListDashboardLists
export def "dashboard-lists-manual ListDashboardLists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dashboard_lists: table<author: record, created: string, dashboard_count: int, id: int, is_favorite: bool, modified: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboard/lists/manual")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dashboard list
#
# POST /api/v1/dashboard/lists/manual
# operationId: CreateDashboardList
# --author shape: {email?: string, handle?: string, name?: string}
export def "dashboard-lists-manual CreateDashboardList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the dashboard list. (e.g. My Dashboard)
]: any -> record<author: record<email: string, handle: string, name: string>, created: string, dashboard_count: int, id: int, is_favorite: bool, modified: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboard/lists/manual")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard list
#
# DELETE /api/v1/dashboard/lists/manual/{list_id}
# operationId: DeleteDashboardList
export def "dashboard-lists-manual DeleteDashboardList" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_dashboard_list_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/lists/manual/($list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a dashboard list
#
# GET /api/v1/dashboard/lists/manual/{list_id}
# operationId: GetDashboardList
export def "dashboard-lists-manual GetDashboardList" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<author: record<email: string, handle: string, name: string>, created: string, dashboard_count: int, id: int, is_favorite: bool, modified: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/lists/manual/($list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard list
#
# PUT /api/v1/dashboard/lists/manual/{list_id}
# operationId: UpdateDashboardList
# --author shape: {email?: string, handle?: string, name?: string}
export def "dashboard-lists-manual UpdateDashboardList" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the dashboard list. (e.g. My Dashboard)
]: any -> record<author: record<email: string, handle: string, name: string>, created: string, dashboard_count: int, id: int, is_favorite: bool, modified: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/lists/manual/($list_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a shared dashboard
#
# POST /api/v1/dashboard/public
# operationId: CreatePublicDashboard
# --global_time shape: {live_span?: "15m"|"1h"|"4h"|"1d"|"2d"|"1w"|"1mo"|"3mo"}
# --invitees item shape: {access_expiration?: string, email: string}
# --selectable_template_vars item shape: {default_value?: string, name?: string, prefix?: string, type?: string, visible_tags?: list}
# --viewing_preferences shape: {high_density?: bool, theme?: "system"|"light"|"dark"}
@deprecated --flag share-list
export def "dashboard-public CreatePublicDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dashboard_id: string # ID of the dashboard to share. (e.g. 123-abc-456)
  dashboard_type: string@dashboard-type-completer # The type of the associated private dashboard. (e.g. custom_timeboard)
  --embeddable-domains: list # The `SharedDashboard` `embeddable_domains`. (e.g. [https://domain.atlassian.net/, http://myserver.com/])
  --expiration: string # The time when an OPEN shared dashboard becomes publicly unavailable. (nullable, format: date-time)
  --global-time: record # Object containing the live span selection for the dashboard. — shape: {live_span?: "15m"|"1h"|"4h"|"1d"|"2d"|"1w"|"1mo"|"3mo"}
  --global-time-selectable-enabled: string@bool-completer # Whether to allow viewers to select a different global time setting for the shared dashboard. (nullable)
  --invitees: list # The `SharedDashboard` `invitees`. (e.g. [{access_expiration: 2030-01-01T12:00:00.00Z, email: test@datadoghq.com}, {access_expiration: , email: test2@datadoghq.com}]) — item shape: {access_expiration?: string, email: string}
  --selectable-template-vars: list # List of objects representing template variables on the shared dashboard which can have selectable values. (nullable, e.g. [{default_value: *, name: exampleVar, prefix: test, visible_tags: [selectableValue1, selectableValue2]}]) — item shape: {default_value?: string, name?: string, prefix?: string, type?: string, visible_tags?: list}
  --share-list: list # List of email addresses that can receive an invitation to access to the shared dashboard. (DEPRECATED, nullable, e.g. [test@datadoghq.com, test2@email.com])
  --share-type: string@share-type-completer # Type of sharing access (either open to anyone who has the public URL or invite-only). (nullable)
  --status: string@status-completer # Active means the dashboard is publicly available. Paused means the dashboard is not publicly available. (e.g. active)
  --title: string # Title of the shared dashboard.
  --viewing-preferences: record # The viewing preferences for a shared dashboard. — shape: {high_density?: bool, theme?: "system"|"light"|"dark"}
]: any -> record<author: record<handle: string, name: string>, created: string, dashboard_id: string, dashboard_type: string, embeddable_domains: list<string>, expiration: string, global_time: record<live_span: string>, global_time_selectable_enabled: bool, invitees: table<access_expiration: string, created_at: string, email: string>, last_accessed: string, public_url: string, selectable_template_vars: table<default_value: string, name: string, prefix: string, type: string, visible_tags: list>, share_list: list<string>, share_type: string, status: string, title: string, token: string, viewing_preferences: record<high_density: bool, theme: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboard/public")
  let body = {dashboard_id: $dashboard_id, dashboard_type: $dashboard_type, embeddable_domains: $embeddable_domains, expiration: $expiration, global_time: $global_time, global_time_selectable_enabled: $global_time_selectable_enabled, invitees: $invitees, selectable_template_vars: $selectable_template_vars, share_list: $share_list, share_type: $share_type, status: $status, title: $title, viewing_preferences: $viewing_preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a shared dashboard URL
#
# DELETE /api/v1/dashboard/public/{token}
# operationId: DeletePublicDashboard
export def "dashboard-public DeletePublicDashboard" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_public_dashboard_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/public/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a shared dashboard
#
# GET /api/v1/dashboard/public/{token}
# operationId: GetPublicDashboard
export def "dashboard-public GetPublicDashboard" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<author: record<handle: string, name: string>, created: string, dashboard_id: string, dashboard_type: string, embeddable_domains: list<string>, expiration: string, global_time: record<live_span: string>, global_time_selectable_enabled: bool, invitees: table<access_expiration: string, created_at: string, email: string>, last_accessed: string, public_url: string, selectable_template_vars: table<default_value: string, name: string, prefix: string, type: string, visible_tags: list>, share_list: list<string>, share_type: string, status: string, title: string, token: string, viewing_preferences: record<high_density: bool, theme: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/public/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a shared dashboard
#
# PUT /api/v1/dashboard/public/{token}
# operationId: UpdatePublicDashboard
# --global_time shape: {live_span?: "15m"|"1h"|"4h"|"1d"|"2d"|"1w"|"1mo"|"3mo"}
# --invitees item shape: {access_expiration?: string, email: string}
# --selectable_template_vars item shape: {default_value?: string, name?: string, prefix?: string, type?: string, visible_tags?: list}
# --viewing_preferences shape: {high_density?: bool, theme?: "system"|"light"|"dark"}
@deprecated --flag share-list
export def "dashboard-public UpdatePublicDashboard" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --embeddable-domains: list # The `SharedDashboard` `embeddable_domains`. (e.g. [https://domain.atlassian.net/, http://myserver.com/])
  --expiration: string # The time when an OPEN shared dashboard becomes publicly unavailable. (nullable, format: date-time)
  --global-time: record # Timeframe setting for the shared dashboard. (nullable, e.g. {live_span: 1h}) — shape: {live_span?: "15m"|"1h"|"4h"|"1d"|"2d"|"1w"|"1mo"|"3mo"}
  --global-time-selectable-enabled: string@bool-completer # Whether to allow viewers to select a different global time setting for the shared dashboard. (nullable)
  --invitees: list # The `SharedDashboard` `invitees`. (e.g. [{access_expiration: 2030-01-01T12:00:00.00Z, email: test@datadoghq.com}, {access_expiration: , email: test2@datadoghq.com}]) — item shape: {access_expiration?: string, email: string}
  --selectable-template-vars: list # List of objects representing template variables on the shared dashboard which can have selectable values. (nullable, e.g. [{default_value: *, name: exampleVar, prefix: test, visible_tags: [selectableValue1, selectableValue2]}]) — item shape: {default_value?: string, name?: string, prefix?: string, type?: string, visible_tags?: list}
  --share-list: list # List of email addresses that can be given access to the shared dashboard. (DEPRECATED, nullable, e.g. [test@datadoghq.com, test2@email.com])
  --share-type: string@share-type-completer # Type of sharing access (either open to anyone who has the public URL or invite-only). (nullable)
  --status: string@status-completer # Active means the dashboard is publicly available. Paused means the dashboard is not publicly available. (e.g. active)
  --title: string # Title of the shared dashboard.
  --viewing-preferences: record # The viewing preferences for a shared dashboard. — shape: {high_density?: bool, theme?: "system"|"light"|"dark"}
]: any -> record<author: record<handle: string, name: string>, created: string, dashboard_id: string, dashboard_type: string, embeddable_domains: list<string>, expiration: string, global_time: record<live_span: string>, global_time_selectable_enabled: bool, invitees: table<access_expiration: string, created_at: string, email: string>, last_accessed: string, public_url: string, selectable_template_vars: table<default_value: string, name: string, prefix: string, type: string, visible_tags: list>, share_list: list<string>, share_type: string, status: string, title: string, token: string, viewing_preferences: record<high_density: bool, theme: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/public/($token)")
  let body = {embeddable_domains: $embeddable_domains, expiration: $expiration, global_time: $global_time, global_time_selectable_enabled: $global_time_selectable_enabled, invitees: $invitees, selectable_template_vars: $selectable_template_vars, share_list: $share_list, share_type: $share_type, status: $status, title: $title, viewing_preferences: $viewing_preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke shared dashboard invitations
#
# DELETE /api/v1/dashboard/public/{token}/invitation
# operationId: DeletePublicDashboardInvitation
# --meta shape: {page?: record}
export def "dashboard-public-invitation DeletePublicDashboardInvitation" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: any # An object or list of objects containing the information for an invitation to a shared dashboard. (e.g. [{attributes: {email: test@datadoghq.com}, type: public_dashboard_invitation}])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/public/($token)/invitation")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all invitations for a shared dashboard
#
# GET /api/v1/dashboard/public/{token}/invitation
# operationId: GetPublicDashboardInvitations
export def "dashboard-public-invitation GetPublicDashboardInvitations" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # The number of records to return in a single request. (format: int64)
  --page-number: int # The page to access (base 0). (format: int64)
]: nothing -> record<data: any, meta: record<page: record<total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/dashboard/public/($token)/invitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send shared dashboard invitation email
#
# POST /api/v1/dashboard/public/{token}/invitation
# operationId: SendPublicDashboardInvitation
# --meta shape: {page?: record}
export def "dashboard-public-invitation SendPublicDashboardInvitation" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: any # An object or list of objects containing the information for an invitation to a shared dashboard. (e.g. [{attributes: {email: test@datadoghq.com}, type: public_dashboard_invitation}])
]: any -> record<data: any, meta: record<page: record<total_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/public/($token)/invitation")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard
#
# DELETE /api/v1/dashboard/{dashboard_id}
# operationId: DeleteDashboard
export def "dashboard DeleteDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_dashboard_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/($dashboard_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a dashboard
#
# GET /api/v1/dashboard/{dashboard_id}
# operationId: GetDashboard
export def "dashboard GetDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<author_handle: string, author_name: string, created_at: string, description: string, id: string, is_read_only: bool, layout_type: string, modified_at: string, notify_list: list<string>, reflow_type: string, restricted_roles: list<string>, tabs: table<id: string, name: string, widget_ids: list>, tags: list<string>, template_variable_presets: table<name: string, template_variables: list>, template_variables: table<available_values: list, default: string, defaults: list, name: string, prefix: string, type: string>, title: string, url: string, widgets: table<definition: any, id: int, layout: record>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/($dashboard_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard
#
# PUT /api/v1/dashboard/{dashboard_id}
# operationId: UpdateDashboard
# --tabs item shape: {id: string, name: string, widget_ids: list}
# --template_variable_presets item shape: {name?: string, template_variables?: list}
# --template_variables item shape: {available_values?: list, default?: string, defaults?: list, name: string, prefix?: string, type?: string}
# --widgets item shape: {definition: any, id?: int, layout?: record}
@deprecated --flag is-read-only
export def "dashboard UpdateDashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the dashboard. (nullable)
  --is-read-only: string@bool-completer # Whether this dashboard is read-only. If True, only the author and admins can make changes to it.  This property is deprecated; please use the [Restriction Policies API](https://docs.datadoghq.com/api/latest/restriction-policies/) instead to manage write authorization for individual dashboards. (DEPRECATED, e.g. false)
  layout_type: string@layout-type-completer # Layout type of the dashboard. (e.g. ordered)
  --notify-list: list # List of handles of users to notify when changes are made to this dashboard. (nullable)
  --reflow-type: string@reflow-type-completer # Reflow type for a **new dashboard layout** dashboard. Set this only when layout type is 'ordered'. If set to 'fixed', the dashboard expects all widgets to have a layout, and if it's set to 'auto', widgets should not have layouts.
  --restricted-roles: list # A list of role identifiers. Only the author and users associated with at least one of these roles can edit this dashboard.
  --tabs: list # List of tabs for organizing dashboard widgets into groups. (nullable) — item shape: {id: string, name: string, widget_ids: list}
  --tags: list # List of team names representing ownership of a dashboard. (nullable)
  --template-variable-presets: list # Array of template variables saved views. (nullable) — item shape: {name?: string, template_variables?: list}
  --template-variables: list # List of template variables for this dashboard. (nullable) — item shape: {available_values?: list, default?: string, defaults?: list, name: string, prefix?: string, type?: string}
  title: string # Title of the dashboard. (e.g. )
  widgets: list # List of widgets to display on the dashboard. (e.g. [{definition: {requests: {fill: {q: avg:system.cpu.user{*}}}, type: hostmap}}]) — item shape: {definition: any, id?: int, layout?: record}
]: any -> record<author_handle: string, author_name: string, created_at: string, description: string, id: string, is_read_only: bool, layout_type: string, modified_at: string, notify_list: list<string>, reflow_type: string, restricted_roles: list<string>, tabs: table<id: string, name: string, widget_ids: list>, tags: list<string>, template_variable_presets: table<name: string, template_variables: list>, template_variables: table<available_values: list, default: string, defaults: list, name: string, prefix: string, type: string>, title: string, url: string, widgets: table<definition: any, id: int, layout: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboard/($dashboard_id)")
  let body = {description: $description, is_read_only: $is_read_only, layout_type: $layout_type, notify_list: $notify_list, reflow_type: $reflow_type, restricted_roles: $restricted_roles, tabs: $tabs, tags: $tags, template_variable_presets: $template_variable_presets, template_variables: $template_variables, title: $title, widgets: $widgets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit distribution points
#
# POST /api/v1/distribution_points
# operationId: SubmitDistributionPoints
export def "distribution-points SubmitDistributionPoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Encoding: string@Content-Encoding-completer # HTTP header used to compress the media-type.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/distribution_points")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/json" $body
}

# Get all downtimes
#
# GET /api/v1/downtime
# DEPRECATED
# operationId: ListDowntimes
@deprecated
export def "downtime ListDowntimes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-only: string@bool-completer # Only return downtimes that are active when the request is made.
  --with-creator: string@bool-completer # Return creator information.
]: nothing -> table<active: bool, active_child: record<active: bool, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list, mute_first_recovery_notification: bool, notify_end_states: list, notify_end_types: list, parent_id: int, recurrence: record, scope: list, start: int, timezone: string, updater_id: int>, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list>, scope: list<string>, start: int, timezone: string, updater_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_only" $current_only "scalar") (serialize-qp "with_creator" $with_creator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/downtime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a downtime
#
# POST /api/v1/downtime
# DEPRECATED
# operationId: CreateDowntime
# --active_child shape: {disabled?: bool, end?: int, message?: string, monitor_id?: int, monitor_tags?: list, mute_first_recovery_notification?: bool, notify_end_states?: list, notify_end_types?: list, parent_id?: int, recurrence?: record, scope?: list, start?: int, timezone?: string}
# --recurrence shape: {period?: int, rrule?: string, type?: string, until_date?: int, until_occurrences?: int, week_days?: list}
@deprecated
export def "downtime CreateDowntime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: string@bool-completer # If a downtime has been disabled. (e.g. false)
  --end: int # POSIX timestamp to end the downtime. If not provided, the downtime is in effect indefinitely until you cancel it. (nullable, format: int64, e.g. 1412793983)
  --message: string # A message to include with notifications for this downtime. Email notifications can be sent to specific users by using the same `@username` notation as events. (nullable, e.g. Message on the downtime)
  --monitor-id: int # A single monitor to which the downtime applies. If not provided, the downtime applies to all monitors. (nullable, format: int64, e.g. 123456)
  --monitor-tags: list # A comma-separated list of monitor tags. For example, tags that are applied directly to monitors, not tags that are used in monitor queries (which are filtered by the scope parameter), to which the downtime applies. The resulting downtime applies to monitors that match ALL provided monitor tags. For example, `service:postgres` **AND** `team:frontend`. (e.g. [*])
  --mute-first-recovery-notification: string@bool-completer # If the first recovery notification during a downtime should be muted. (e.g. false)
  --notify-end-states: list # States for which `notify_end_types` sends out notifications for. (default: [alert, no data, warn], e.g. [alert, no data, warn])
  --notify-end-types: list # If set, notifies if a monitor is in an alert-worthy state (`ALERT`, `WARNING`, or `NO DATA`) when this downtime expires or is canceled. Applied to monitors that change states during the downtime (such as from `OK` to `ALERT`, `WARNING`, or `NO DATA`), and to monitors that already have an alert-worthy state when downtime begins. (default: [expired], e.g. [canceled, expired])
  --parent-id: int # ID of the parent Downtime. (nullable, format: int64, e.g. 123)
  --recurrence: record # An object defining the recurrence of the downtime. (nullable) — shape: {period?: int, rrule?: string, type?: string, until_date?: int, until_occurrences?: int, week_days?: list}
  --scope: list # The scope(s) to which the downtime applies and must be in `key:value` format. For example, `host:app2`. Provide multiple scopes as a comma-separated list like `env:dev,env:prod`. The resulting downtime applies to sources that matches ALL provided scopes (`env:dev` **AND** `env:prod`). (e.g. [env:staging])
  --start: int # POSIX timestamp to start the downtime. If not provided, the downtime starts the moment it is created. (format: int64, e.g. 1412792983)
  --timezone: string # The timezone in which to display the downtime's start and end times in Datadog applications. (e.g. America/New_York)
]: any -> record<active: bool, active_child: record<active: bool, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list>, scope: list<string>, start: int, timezone: string, updater_id: int>, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list<string>>, scope: list<string>, start: int, timezone: string, updater_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downtime")
  let body = {disabled: $disabled, end: $end, message: $message, monitor_id: $monitor_id, monitor_tags: $monitor_tags, mute_first_recovery_notification: $mute_first_recovery_notification, notify_end_states: $notify_end_states, notify_end_types: $notify_end_types, parent_id: $parent_id, recurrence: $recurrence, scope: $scope, start: $start, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel downtimes by scope
#
# POST /api/v1/downtime/cancel/by_scope
# DEPRECATED
# operationId: CancelDowntimesByScope
@deprecated
export def "downtime-cancel-by-scope CancelDowntimesByScope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scope: string # The scope(s) to which the downtime applies and must be in `key:value` format. For example, `host:app2`. Provide multiple scopes as a comma-separated list like `env:dev,env:prod`. The resulting downtime applies to sources that matches ALL provided scopes (`env:dev` **AND** `env:prod`). (e.g. host:myserver)
]: any -> record<cancelled_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downtime/cancel/by_scope")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a downtime
#
# DELETE /api/v1/downtime/{downtime_id}
# DEPRECATED
# operationId: CancelDowntime
@deprecated
export def "downtime CancelDowntime" [
  downtime_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downtime/($downtime_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a downtime
#
# GET /api/v1/downtime/{downtime_id}
# DEPRECATED
# operationId: GetDowntime
@deprecated
export def "downtime GetDowntime" [
  downtime_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, active_child: record<active: bool, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list>, scope: list<string>, start: int, timezone: string, updater_id: int>, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list<string>>, scope: list<string>, start: int, timezone: string, updater_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downtime/($downtime_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a downtime
#
# PUT /api/v1/downtime/{downtime_id}
# DEPRECATED
# operationId: UpdateDowntime
# --active_child shape: {disabled?: bool, end?: int, message?: string, monitor_id?: int, monitor_tags?: list, mute_first_recovery_notification?: bool, notify_end_states?: list, notify_end_types?: list, parent_id?: int, recurrence?: record, scope?: list, start?: int, timezone?: string}
# --recurrence shape: {period?: int, rrule?: string, type?: string, until_date?: int, until_occurrences?: int, week_days?: list}
@deprecated
export def "downtime UpdateDowntime" [
  downtime_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: string@bool-completer # If a downtime has been disabled. (e.g. false)
  --end: int # POSIX timestamp to end the downtime. If not provided, the downtime is in effect indefinitely until you cancel it. (nullable, format: int64, e.g. 1412793983)
  --message: string # A message to include with notifications for this downtime. Email notifications can be sent to specific users by using the same `@username` notation as events. (nullable, e.g. Message on the downtime)
  --monitor-id: int # A single monitor to which the downtime applies. If not provided, the downtime applies to all monitors. (nullable, format: int64, e.g. 123456)
  --monitor-tags: list # A comma-separated list of monitor tags. For example, tags that are applied directly to monitors, not tags that are used in monitor queries (which are filtered by the scope parameter), to which the downtime applies. The resulting downtime applies to monitors that match ALL provided monitor tags. For example, `service:postgres` **AND** `team:frontend`. (e.g. [*])
  --mute-first-recovery-notification: string@bool-completer # If the first recovery notification during a downtime should be muted. (e.g. false)
  --notify-end-states: list # States for which `notify_end_types` sends out notifications for. (default: [alert, no data, warn], e.g. [alert, no data, warn])
  --notify-end-types: list # If set, notifies if a monitor is in an alert-worthy state (`ALERT`, `WARNING`, or `NO DATA`) when this downtime expires or is canceled. Applied to monitors that change states during the downtime (such as from `OK` to `ALERT`, `WARNING`, or `NO DATA`), and to monitors that already have an alert-worthy state when downtime begins. (default: [expired], e.g. [canceled, expired])
  --parent-id: int # ID of the parent Downtime. (nullable, format: int64, e.g. 123)
  --recurrence: record # An object defining the recurrence of the downtime. (nullable) — shape: {period?: int, rrule?: string, type?: string, until_date?: int, until_occurrences?: int, week_days?: list}
  --scope: list # The scope(s) to which the downtime applies and must be in `key:value` format. For example, `host:app2`. Provide multiple scopes as a comma-separated list like `env:dev,env:prod`. The resulting downtime applies to sources that matches ALL provided scopes (`env:dev` **AND** `env:prod`). (e.g. [env:staging])
  --start: int # POSIX timestamp to start the downtime. If not provided, the downtime starts the moment it is created. (format: int64, e.g. 1412792983)
  --timezone: string # The timezone in which to display the downtime's start and end times in Datadog applications. (e.g. America/New_York)
]: any -> record<active: bool, active_child: record<active: bool, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list>, scope: list<string>, start: int, timezone: string, updater_id: int>, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list<string>>, scope: list<string>, start: int, timezone: string, updater_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downtime/($downtime_id)")
  let body = {disabled: $disabled, end: $end, message: $message, monitor_id: $monitor_id, monitor_tags: $monitor_tags, mute_first_recovery_notification: $mute_first_recovery_notification, notify_end_states: $notify_end_states, notify_end_types: $notify_end_types, parent_id: $parent_id, recurrence: $recurrence, scope: $scope, start: $start, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of events
#
# GET /api/v1/events
# operationId: ListEvents
export def "events ListEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # POSIX timestamp. (format: int64)
  --end: int # POSIX timestamp. (format: int64)
  --priority: string@priority-completer # Priority of your events, either `low` or `normal`. (nullable, e.g. normal)
  --sources: string # A comma separated string of sources.
  --tags: string # A comma separated list indicating what tags, if any, should be used to filter the list of events. (e.g. host:host0)
  --unaggregated: string@bool-completer # Set unaggregated to `true` to return all events within the specified [`start`,`end`] timeframe. Otherwise if an event is aggregated to a parent event with a timestamp outside of the timeframe, it won't be available in the output. Aggregated events with `is_aggregate=true` in the response will still be returned unless exclude_aggregate is set to `true.`
  --exclude-aggregate: string@bool-completer # Set `exclude_aggregate` to `true` to only return unaggregated events where `is_aggregate=false` in the response. If the `exclude_aggregate` parameter is set to `true`, then the unaggregated parameter is ignored and will be `true` by default.
  --page: int # By default 1000 results are returned per request. Set page to the number of the page to return with `0` being the first page. The page parameter can only be used when either unaggregated or exclude_aggregate is set to `true.` (format: int32)
]: nothing -> record<events: table<alert_type: string, date_happened: int, device_name: string, host: string, id: int, id_str: string, payload: string, priority: string, source_type_name: string, tags: list, text: string, title: string, url: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "unaggregated" $unaggregated "scalar") (serialize-qp "exclude_aggregate" $exclude_aggregate "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post an event
#
# POST /api/v1/events
# operationId: CreateEvent
export def "events CreateEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aggregation-key: string # An arbitrary string to use for aggregation. Limited to 100 characters. If you specify a key, all events using that key are grouped together in the Event Stream.
  --alert-type: string@alert-type-completer # If an alert event is enabled, set its type. For example, `error`, `warning`, `info`, `success`, `user_update`, `recommendation`, and `snapshot`. (e.g. info)
  --date-happened: int # POSIX timestamp of the event. Must be sent as an integer (that is no quotes). Limited to events no older than 18 hours (format: int64)
  --device-name: string # A device name.
  --host: string # Host name to associate with the event. Any tags associated with the host are also applied to this event.
  --priority: string@priority-completer # The priority of the event. For example, `normal` or `low`. (nullable, e.g. normal)
  --related-event-id: int # ID of the parent event. Must be sent as an integer (that is no quotes). (format: int64)
  --source-type-name: string # The type of event being posted. Option examples include nagios, hudson, jenkins, my_apps, chef, puppet, git, bitbucket, etc. A complete list of source attribute values [available here](https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value).
  --tags: list # A list of tags to apply to the event. (e.g. [environment:test])
  text: string # The body of the event. Limited to 4000 characters. The text supports markdown. To use markdown in the event text, start the text block with `%%% \n` and end the text block with `\n %%%`. Use `msg_text` with the Datadog Ruby library. (e.g. Oh boy!)
  title: string # The event title. (e.g. Did you hear the news today?)
]: any -> record<event: record<alert_type: string, date_happened: int, device_name: string, host: string, id: int, id_str: string, payload: string, priority: string, source_type_name: string, tags: list<string>, text: string, title: string, url: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/events")
  let body = {aggregation_key: $aggregation_key, alert_type: $alert_type, date_happened: $date_happened, device_name: $device_name, host: $host, priority: $priority, related_event_id: $related_event_id, source_type_name: $source_type_name, tags: $tags, text: $text, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an event
#
# GET /api/v1/events/{event_id}
# operationId: GetEvent
export def "events GetEvent" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<event: record<alert_type: string, date_happened: int, device_name: string, host: string, id: int, id_str: string, payload: string, priority: string, source_type_name: string, tags: list<string>, text: string, title: string, url: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Take graph snapshots
#
# GET /api/v1/graph/snapshot
# operationId: GetGraphSnapshot
export def "graph-snapshot GetGraphSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric-query: string # The metric query.
  --start: int # The POSIX timestamp of the start of the query in seconds. (format: int64)
  --end: int # The POSIX timestamp of the end of the query in seconds. (format: int64)
  --event-query: string # A query that adds event bands to the graph.
  --graph-def: string # A JSON document defining the graph. `graph_def` can be used instead of `metric_query`. The JSON document uses the [grammar defined here](https://docs.datadoghq.com/graphing/graphing_json/#grammar) and should be formatted to a single line then URL encoded.
  --title: string # A title for the graph. If no title is specified, the graph does not have a title.
  --height: int # The height of the graph. If no height is specified, the graph's original height is used. (format: int64)
  --width: int # The width of the graph. If no width is specified, the graph's original width is used. (format: int64)
]: nothing -> record<graph_def: string, metric_query: string, snapshot_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metric_query" $metric_query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "event_query" $event_query "scalar") (serialize-qp "graph_def" $graph_def "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "width" $width "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/graph/snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mute a host
#
# POST /api/v1/host/{host_name}/mute
# operationId: MuteHost
export def "host-mute MuteHost" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end: int # POSIX timestamp in seconds when the host is unmuted. If omitted, the host remains muted until explicitly unmuted. (format: int64, e.g. 1579098130)
  --message: string # Message to associate with the muting of this host. (e.g. Muting this host for a test!)
  --override: string@bool-completer # If true and the host is already muted, replaces existing host mute settings. (e.g. false)
]: any -> record<action: string, end: int, hostname: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/host/($host_name)/mute")
  let body = {end: $end, message: $message, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unmute a host
#
# POST /api/v1/host/{host_name}/unmute
# operationId: UnmuteHost
export def "host-unmute UnmuteHost" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: string, end: int, hostname: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/host/($host_name)/unmute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all hosts for your organization
#
# GET /api/v1/hosts
# operationId: ListHosts
export def "hosts ListHosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # String to filter search results.
  --sort-field: string # Sort hosts by this field.
  --sort-dir: string # Direction of sort. Options include `asc` and `desc`.
  --start: int # Specify the starting point for the host search results. For example, if you set `count` to 100 and the first 100 results have already been returned, you can set `start` to `101` to get the next 100 results. (format: int64)
  --count: int # Number of hosts to return. Max 1000. (format: int64)
  --qp-from: int # Number of seconds since UNIX epoch from which you want to search your hosts. (format: int64)
  --include-muted-hosts-data: string@bool-completer # Include information on the muted status of hosts and when the mute expires.
  --include-hosts-metadata: string@bool-completer # Include additional metadata about the hosts (agent_version, machine, platform, processor, etc.).
]: nothing -> record<host_list: table<aliases: list, apps: list, aws_name: string, host_name: string, id: int, is_muted: bool, last_reported_time: int, meta: record, metrics: record, mute_timeout: int, name: string, sources: list, tags_by_source: record, up: bool>, total_matching: int, total_returned: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "include_muted_hosts_data" $include_muted_hosts_data "scalar") (serialize-qp "include_hosts_metadata" $include_hosts_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/hosts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the total number of active hosts
#
# GET /api/v1/hosts/totals
# operationId: GetHostTotals
export def "hosts-totals GetHostTotals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # Number of seconds from which you want to get total number of active hosts. (format: int64)
]: nothing -> record<total_active: int, total_up: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/hosts/totals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an AWS integration
#
# DELETE /api/v1/integration/aws
# DEPRECATED
# operationId: DeleteAWSAccount
@deprecated
export def "integration-aws DeleteAWSAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-key-id: string # Your AWS access key ID. Only required if your AWS account is a GovCloud or China account.
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --role-name: string # Your Datadog role delegation name. (e.g. DatadogAWSIntegrationRole)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws")
  let body = {access_key_id: $access_key_id, account_id: $account_id, role_name: $role_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all AWS integrations
#
# GET /api/v1/integration/aws
# DEPRECATED
# operationId: ListAWSAccounts
@deprecated
export def "integration-aws ListAWSAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Only return AWS accounts that matches this `account_id`.
  --role-name: string # Only return AWS accounts that matches this role_name.
  --access-key-id: string # Only return AWS accounts that matches this `access_key_id`.
]: nothing -> record<accounts: table<access_key_id: string, account_id: string, account_specific_namespace_rules: record, cspm_resource_collection_enabled: bool, excluded_regions: list, extended_resource_collection_enabled: bool, filter_tags: list, host_tags: list, metrics_collection_enabled: bool, resource_collection_enabled: bool, role_name: string, secret_access_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "role_name" $role_name "scalar") (serialize-qp "access_key_id" $access_key_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/integration/aws" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an AWS integration
#
# POST /api/v1/integration/aws
# DEPRECATED
# operationId: CreateAWSAccount
@deprecated
@deprecated --flag resource-collection-enabled
export def "integration-aws CreateAWSAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-key-id: string # Your AWS access key ID. Only required if your AWS account is a GovCloud or China account.
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --account-specific-namespace-rules: record # An object (in the form `{"namespace1":true/false, "namespace2":true/false}`) containing user-supplied overrides for AWS namespace metric collection. **Important**: This field only contains namespaces explicitly configured through API calls, not the comprehensive enabled or disabled status of all namespaces. If a namespace is absent from this field, it uses Datadog's internal defaults (all namespaces enabled by default, except `AWS/SQS`, `AWS/ElasticMapReduce`, and `AWS/Usage`). For a complete view of all namespace statuses, use the V2 AWS Integration API instead. (e.g. {auto_scaling: false, opswork: false})
  --cspm-resource-collection-enabled: string@bool-completer # Whether Datadog collects cloud security posture management resources from your AWS account. This includes additional resources not covered under the general `resource_collection`. (default: false, e.g. true)
  --excluded-regions: list # An array of [AWS regions](https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints) to exclude from metrics collection. (e.g. [us-east-1, us-west-2])
  --extended-resource-collection-enabled: string@bool-completer # Whether Datadog collects additional attributes and configuration information about the resources in your AWS account. Required for `cspm_resource_collection`. (default: false, e.g. true)
  --filter-tags: list # The array of EC2 tags (in the form `key:value`) defines a filter that Datadog uses when collecting metrics from EC2. Wildcards, such as `?` (for single characters) and `*` (for multiple characters) can also be used. Only hosts that match one of the defined tags will be imported into Datadog. The rest will be ignored. Host matching a given tag can also be excluded by adding `!` before the tag. For example, `env:production,instance-type:c1.*,!region:us-east-1` (e.g. [$KEY:$VALUE])
  --host-tags: list # Array of tags (in the form `key:value`) to add to all hosts and metrics reporting through this integration. (e.g. [$KEY:$VALUE])
  --metrics-collection-enabled: string@bool-completer # Whether Datadog collects metrics for this AWS account. (default: true, e.g. false)
  --resource-collection-enabled: string@bool-completer # Deprecated in favor of 'extended_resource_collection_enabled'. Whether Datadog collects a standard set of resources from your AWS account. (DEPRECATED, default: false, e.g. true)
  --role-name: string # Your Datadog role delegation name. (e.g. DatadogAWSIntegrationRole)
  --secret-access-key: string # Your AWS secret access key. Only required if your AWS account is a GovCloud or China account.
]: any -> record<external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws")
  let body = {access_key_id: $access_key_id, account_id: $account_id, account_specific_namespace_rules: $account_specific_namespace_rules, cspm_resource_collection_enabled: $cspm_resource_collection_enabled, excluded_regions: $excluded_regions, extended_resource_collection_enabled: $extended_resource_collection_enabled, filter_tags: $filter_tags, host_tags: $host_tags, metrics_collection_enabled: $metrics_collection_enabled, resource_collection_enabled: $resource_collection_enabled, role_name: $role_name, secret_access_key: $secret_access_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an AWS integration
#
# PUT /api/v1/integration/aws
# DEPRECATED
# operationId: UpdateAWSAccount
@deprecated
@deprecated --flag resource-collection-enabled
export def "integration-aws UpdateAWSAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Only return AWS accounts that matches this `account_id`.
  --role-name: string # Only return AWS accounts that match this `role_name`. Required if `account_id` is specified.
  --access-key-id: string # Only return AWS accounts that matches this `access_key_id`. Required if none of the other two options are specified.
  --access-key-id: string # Your AWS access key ID. Only required if your AWS account is a GovCloud or China account.
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --account-specific-namespace-rules: record # An object (in the form `{"namespace1":true/false, "namespace2":true/false}`) containing user-supplied overrides for AWS namespace metric collection. **Important**: This field only contains namespaces explicitly configured through API calls, not the comprehensive enabled or disabled status of all namespaces. If a namespace is absent from this field, it uses Datadog's internal defaults (all namespaces enabled by default, except `AWS/SQS`, `AWS/ElasticMapReduce`, and `AWS/Usage`). For a complete view of all namespace statuses, use the V2 AWS Integration API instead. (e.g. {auto_scaling: false, opswork: false})
  --cspm-resource-collection-enabled: string@bool-completer # Whether Datadog collects cloud security posture management resources from your AWS account. This includes additional resources not covered under the general `resource_collection`. (default: false, e.g. true)
  --excluded-regions: list # An array of [AWS regions](https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints) to exclude from metrics collection. (e.g. [us-east-1, us-west-2])
  --extended-resource-collection-enabled: string@bool-completer # Whether Datadog collects additional attributes and configuration information about the resources in your AWS account. Required for `cspm_resource_collection`. (default: false, e.g. true)
  --filter-tags: list # The array of EC2 tags (in the form `key:value`) defines a filter that Datadog uses when collecting metrics from EC2. Wildcards, such as `?` (for single characters) and `*` (for multiple characters) can also be used. Only hosts that match one of the defined tags will be imported into Datadog. The rest will be ignored. Host matching a given tag can also be excluded by adding `!` before the tag. For example, `env:production,instance-type:c1.*,!region:us-east-1` (e.g. [$KEY:$VALUE])
  --host-tags: list # Array of tags (in the form `key:value`) to add to all hosts and metrics reporting through this integration. (e.g. [$KEY:$VALUE])
  --metrics-collection-enabled: string@bool-completer # Whether Datadog collects metrics for this AWS account. (default: true, e.g. false)
  --resource-collection-enabled: string@bool-completer # Deprecated in favor of 'extended_resource_collection_enabled'. Whether Datadog collects a standard set of resources from your AWS account. (DEPRECATED, default: false, e.g. true)
  --role-name: string # Your Datadog role delegation name. (e.g. DatadogAWSIntegrationRole)
  --secret-access-key: string # Your AWS secret access key. Only required if your AWS account is a GovCloud or China account.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "role_name" $role_name "scalar") (serialize-qp "access_key_id" $access_key_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/integration/aws" $qp)
  let body = {access_key_id: $access_key_id, account_id: $account_id, account_specific_namespace_rules: $account_specific_namespace_rules, cspm_resource_collection_enabled: $cspm_resource_collection_enabled, excluded_regions: $excluded_regions, extended_resource_collection_enabled: $extended_resource_collection_enabled, filter_tags: $filter_tags, host_tags: $host_tags, metrics_collection_enabled: $metrics_collection_enabled, resource_collection_enabled: $resource_collection_enabled, role_name: $role_name, secret_access_key: $secret_access_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List namespace rules
#
# GET /api/v1/integration/aws/available_namespace_rules
# DEPRECATED
# operationId: ListAvailableAWSNamespaces
@deprecated
export def "integration-aws-available-namespace-rules ListAvailableAWSNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/available_namespace_rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Amazon EventBridge source
#
# DELETE /api/v1/integration/aws/event_bridge
# DEPRECATED
# operationId: DeleteAWSEventBridgeSource
@deprecated
export def "integration-aws-event-bridge DeleteAWSEventBridgeSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --event-generator-name: string # The event source name. (e.g. app-alerts-zyxw3210)
  --region: string # The event source's [AWS region](https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints). (e.g. us-east-1)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/event_bridge")
  let body = {account_id: $account_id, event_generator_name: $event_generator_name, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Amazon EventBridge sources
#
# GET /api/v1/integration/aws/event_bridge
# DEPRECATED
# operationId: ListAWSEventBridgeSources
@deprecated
export def "integration-aws-event-bridge ListAWSEventBridgeSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accounts: table<accountId: string, eventHubs: list, tags: list>, isInstalled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/event_bridge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Amazon EventBridge source
#
# POST /api/v1/integration/aws/event_bridge
# DEPRECATED
# operationId: CreateAWSEventBridgeSource
@deprecated
export def "integration-aws-event-bridge CreateAWSEventBridgeSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --create-event-bus: string@bool-completer # True if Datadog should create the event bus in addition to the event source. Requires the `events:CreateEventBus` permission. (e.g. true)
  --event-generator-name: string # The given part of the event source name, which is then combined with an assigned suffix to form the full name. (e.g. app-alerts)
  --region: string # The event source's [AWS region](https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints). (e.g. us-east-1)
]: any -> record<event_source_name: string, has_bus: bool, region: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/event_bridge")
  let body = {account_id: $account_id, create_event_bus: $create_event_bus, event_generator_name: $event_generator_name, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag filtering entry
#
# DELETE /api/v1/integration/aws/filtering
# DEPRECATED
# operationId: DeleteAWSTagFilter
@deprecated
export def "integration-aws-filtering DeleteAWSTagFilter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # The unique identifier of your AWS account. (e.g. FAKEAC0FAKEAC2FAKEAC)
  --namespace: string@namespace-completer # The namespace associated with the tag filter entry.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/filtering")
  let body = {account_id: $account_id, namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all AWS tag filters
#
# GET /api/v1/integration/aws/filtering
# DEPRECATED
# operationId: ListAWSTagFilters
@deprecated
export def "integration-aws-filtering ListAWSTagFilters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Only return AWS filters that matches this `account_id`.
]: nothing -> record<filters: table<namespace: string, tag_filter_str: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/integration/aws/filtering" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set an AWS tag filter
#
# POST /api/v1/integration/aws/filtering
# DEPRECATED
# operationId: CreateAWSTagFilter
@deprecated
export def "integration-aws-filtering CreateAWSTagFilter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --namespace: string@namespace-completer # The namespace associated with the tag filter entry.
  --tag-filter-str: string # The tag filter string. (e.g. prod*)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/filtering")
  let body = {account_id: $account_id, namespace: $namespace, tag_filter_str: $tag_filter_str} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a new external ID
#
# PUT /api/v1/integration/aws/generate_new_external_id
# DEPRECATED
# operationId: CreateNewAWSExternalID
@deprecated
@deprecated --flag resource-collection-enabled
export def "integration-aws-generate-new-external-id CreateNewAWSExternalID" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-key-id: string # Your AWS access key ID. Only required if your AWS account is a GovCloud or China account.
  --account-id: string # Your AWS Account ID without dashes. (e.g. 123456789012)
  --account-specific-namespace-rules: record # An object (in the form `{"namespace1":true/false, "namespace2":true/false}`) containing user-supplied overrides for AWS namespace metric collection. **Important**: This field only contains namespaces explicitly configured through API calls, not the comprehensive enabled or disabled status of all namespaces. If a namespace is absent from this field, it uses Datadog's internal defaults (all namespaces enabled by default, except `AWS/SQS`, `AWS/ElasticMapReduce`, and `AWS/Usage`). For a complete view of all namespace statuses, use the V2 AWS Integration API instead. (e.g. {auto_scaling: false, opswork: false})
  --cspm-resource-collection-enabled: string@bool-completer # Whether Datadog collects cloud security posture management resources from your AWS account. This includes additional resources not covered under the general `resource_collection`. (default: false, e.g. true)
  --excluded-regions: list # An array of [AWS regions](https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints) to exclude from metrics collection. (e.g. [us-east-1, us-west-2])
  --extended-resource-collection-enabled: string@bool-completer # Whether Datadog collects additional attributes and configuration information about the resources in your AWS account. Required for `cspm_resource_collection`. (default: false, e.g. true)
  --filter-tags: list # The array of EC2 tags (in the form `key:value`) defines a filter that Datadog uses when collecting metrics from EC2. Wildcards, such as `?` (for single characters) and `*` (for multiple characters) can also be used. Only hosts that match one of the defined tags will be imported into Datadog. The rest will be ignored. Host matching a given tag can also be excluded by adding `!` before the tag. For example, `env:production,instance-type:c1.*,!region:us-east-1` (e.g. [$KEY:$VALUE])
  --host-tags: list # Array of tags (in the form `key:value`) to add to all hosts and metrics reporting through this integration. (e.g. [$KEY:$VALUE])
  --metrics-collection-enabled: string@bool-completer # Whether Datadog collects metrics for this AWS account. (default: true, e.g. false)
  --resource-collection-enabled: string@bool-completer # Deprecated in favor of 'extended_resource_collection_enabled'. Whether Datadog collects a standard set of resources from your AWS account. (DEPRECATED, default: false, e.g. true)
  --role-name: string # Your Datadog role delegation name. (e.g. DatadogAWSIntegrationRole)
  --secret-access-key: string # Your AWS secret access key. Only required if your AWS account is a GovCloud or China account.
]: any -> record<external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/generate_new_external_id")
  let body = {access_key_id: $access_key_id, account_id: $account_id, account_specific_namespace_rules: $account_specific_namespace_rules, cspm_resource_collection_enabled: $cspm_resource_collection_enabled, excluded_regions: $excluded_regions, extended_resource_collection_enabled: $extended_resource_collection_enabled, filter_tags: $filter_tags, host_tags: $host_tags, metrics_collection_enabled: $metrics_collection_enabled, resource_collection_enabled: $resource_collection_enabled, role_name: $role_name, secret_access_key: $secret_access_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an AWS Logs integration
#
# DELETE /api/v1/integration/aws/logs
# operationId: DeleteAWSLambdaARN
export def "integration-aws-logs DeleteAWSLambdaARN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_id: string # Your AWS Account ID without dashes. (e.g. 1234567)
  lambda_arn: string # ARN of the Datadog Lambda created during the Datadog-Amazon Web services Log collection setup. (e.g. arn:aws:lambda:us-east-1:1234567:function:LogsCollectionAPITest)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs")
  let body = {account_id: $account_id, lambda_arn: $lambda_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all AWS Logs integrations
#
# GET /api/v1/integration/aws/logs
# DEPRECATED
# operationId: ListAWSLogsIntegrations
@deprecated
export def "integration-aws-logs ListAWSLogsIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_id: string, lambdas: list<record>, services: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add AWS Log Lambda ARN
#
# POST /api/v1/integration/aws/logs
# operationId: CreateAWSLambdaARN
export def "integration-aws-logs CreateAWSLambdaARN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_id: string # Your AWS Account ID without dashes. (e.g. 1234567)
  lambda_arn: string # ARN of the Datadog Lambda created during the Datadog-Amazon Web services Log collection setup. (e.g. arn:aws:lambda:us-east-1:1234567:function:LogsCollectionAPITest)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs")
  let body = {account_id: $account_id, lambda_arn: $lambda_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check that an AWS Lambda Function exists
#
# POST /api/v1/integration/aws/logs/check_async
# operationId: CheckAWSLogsLambdaAsync
export def "integration-aws-logs-check-async CheckAWSLogsLambdaAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_id: string # Your AWS Account ID without dashes. (e.g. 1234567)
  lambda_arn: string # ARN of the Datadog Lambda created during the Datadog-Amazon Web services Log collection setup. (e.g. arn:aws:lambda:us-east-1:1234567:function:LogsCollectionAPITest)
]: any -> record<errors: table<code: string, message: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs/check_async")
  let body = {account_id: $account_id, lambda_arn: $lambda_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get list of AWS log ready services
#
# GET /api/v1/integration/aws/logs/services
# DEPRECATED
# operationId: ListAWSLogsServices
@deprecated
export def "integration-aws-logs-services ListAWSLogsServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable an AWS Logs integration
#
# POST /api/v1/integration/aws/logs/services
# DEPRECATED
# operationId: EnableAWSLogServices
@deprecated
export def "integration-aws-logs-services EnableAWSLogServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_id: string # Your AWS Account ID without dashes. (e.g. 1234567)
  services: list # Array of services IDs set to enable automatic log collection. Discover the list of available services with the get list of AWS log ready services API endpoint. (e.g. [s3, elb, elbv2, cloudfront, redshift, lambda])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs/services")
  let body = {account_id: $account_id, services: $services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check permissions for log services
#
# POST /api/v1/integration/aws/logs/services_async
# operationId: CheckAWSLogsServicesAsync
export def "integration-aws-logs-services-async CheckAWSLogsServicesAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_id: string # Your AWS Account ID without dashes. (e.g. 1234567)
  services: list # Array of services IDs set to enable automatic log collection. Discover the list of available services with the get list of AWS log ready services API endpoint. (e.g. [s3, elb, elbv2, cloudfront, redshift, lambda])
]: any -> record<errors: table<code: string, message: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/aws/logs/services_async")
  let body = {account_id: $account_id, services: $services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Azure integration
#
# DELETE /api/v1/integration/azure
# operationId: DeleteAzureIntegration
# --resource_provider_configs item shape: {metrics_enabled?: bool, namespace?: string}
export def "integration-azure DeleteAzureIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-service-plan-filters: string # Limit the Azure app service plans that are pulled into Datadog using tags. Only app service plans that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --automute: string@bool-completer # Silence monitors for expected Azure VM shutdowns. (e.g. true)
  --client-id: string # Your Azure web application ID. (e.g. testc7f6-1234-5678-9101-3fcbf464test)
  --client-secret: string # Your Azure web application secret key. (e.g. TestingRh2nx664kUy5dIApvM54T4AtO)
  --container-app-filters: string # Limit the Azure container apps that are pulled into Datadog using tags. Only container apps that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --cspm-enabled: string@bool-completer # When enabled, Datadog’s Cloud Security Management product scans resource configurations monitored by this app registration. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --custom-metrics-enabled: string@bool-completer # Enable custom metrics for your organization. (e.g. true)
  --errors: list # Errors in your configuration. (e.g. [*])
  --host-filters: string # Limit the Azure instances that are pulled into Datadog by using tags. Only hosts that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --metrics-enabled: string@bool-completer # Enable Azure metrics for your organization. (e.g. true)
  --metrics-enabled-default: string@bool-completer # Enable Azure metrics for your organization for resource providers where no resource provider config is specified. (e.g. true)
  --new-client-id: string # Your New Azure web application ID. (e.g. new1c7f6-1234-5678-9101-3fcbf464test)
  --new-tenant-name: string # Your New Azure Active Directory ID. (e.g. new1c44-1234-5678-9101-cc00736ftest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog collects metadata and configuration info from cloud resources (compute instances, databases, load balancers, etc.) monitored by this app registration. (e.g. true)
  --resource-provider-configs: list # Configuration settings applied to resources from the specified Azure resource providers. — item shape: {metrics_enabled?: bool, namespace?: string}
  --secretless-auth-enabled: string@bool-completer # (Preview) When enabled, Datadog authenticates with this app registration using federated workload identity credentials instead of a client secret. (e.g. true)
  --tenant-name: string # Your Azure Active Directory ID. (e.g. testc44-1234-5678-9101-cc00736ftest)
  --usage-metrics-enabled: string@bool-completer # Enable azure.usage metrics for your organization. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/azure")
  let body = {app_service_plan_filters: $app_service_plan_filters, automute: $automute, client_id: $client_id, client_secret: $client_secret, container_app_filters: $container_app_filters, cspm_enabled: $cspm_enabled, custom_metrics_enabled: $custom_metrics_enabled, errors: $errors, host_filters: $host_filters, metrics_enabled: $metrics_enabled, metrics_enabled_default: $metrics_enabled_default, new_client_id: $new_client_id, new_tenant_name: $new_tenant_name, resource_collection_enabled: $resource_collection_enabled, resource_provider_configs: $resource_provider_configs, secretless_auth_enabled: $secretless_auth_enabled, tenant_name: $tenant_name, usage_metrics_enabled: $usage_metrics_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all Azure integrations
#
# GET /api/v1/integration/azure
# operationId: ListAzureIntegration
export def "integration-azure ListAzureIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<app_service_plan_filters: string, automute: bool, client_id: string, client_secret: string, container_app_filters: string, cspm_enabled: bool, custom_metrics_enabled: bool, errors: list<string>, host_filters: string, metrics_enabled: bool, metrics_enabled_default: bool, new_client_id: string, new_tenant_name: string, resource_collection_enabled: bool, resource_provider_configs: list<record>, secretless_auth_enabled: bool, tenant_name: string, usage_metrics_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/azure")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Azure integration
#
# POST /api/v1/integration/azure
# operationId: CreateAzureIntegration
# --resource_provider_configs item shape: {metrics_enabled?: bool, namespace?: string}
export def "integration-azure CreateAzureIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-service-plan-filters: string # Limit the Azure app service plans that are pulled into Datadog using tags. Only app service plans that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --automute: string@bool-completer # Silence monitors for expected Azure VM shutdowns. (e.g. true)
  --client-id: string # Your Azure web application ID. (e.g. testc7f6-1234-5678-9101-3fcbf464test)
  --client-secret: string # Your Azure web application secret key. (e.g. TestingRh2nx664kUy5dIApvM54T4AtO)
  --container-app-filters: string # Limit the Azure container apps that are pulled into Datadog using tags. Only container apps that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --cspm-enabled: string@bool-completer # When enabled, Datadog’s Cloud Security Management product scans resource configurations monitored by this app registration. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --custom-metrics-enabled: string@bool-completer # Enable custom metrics for your organization. (e.g. true)
  --errors: list # Errors in your configuration. (e.g. [*])
  --host-filters: string # Limit the Azure instances that are pulled into Datadog by using tags. Only hosts that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --metrics-enabled: string@bool-completer # Enable Azure metrics for your organization. (e.g. true)
  --metrics-enabled-default: string@bool-completer # Enable Azure metrics for your organization for resource providers where no resource provider config is specified. (e.g. true)
  --new-client-id: string # Your New Azure web application ID. (e.g. new1c7f6-1234-5678-9101-3fcbf464test)
  --new-tenant-name: string # Your New Azure Active Directory ID. (e.g. new1c44-1234-5678-9101-cc00736ftest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog collects metadata and configuration info from cloud resources (compute instances, databases, load balancers, etc.) monitored by this app registration. (e.g. true)
  --resource-provider-configs: list # Configuration settings applied to resources from the specified Azure resource providers. — item shape: {metrics_enabled?: bool, namespace?: string}
  --secretless-auth-enabled: string@bool-completer # (Preview) When enabled, Datadog authenticates with this app registration using federated workload identity credentials instead of a client secret. (e.g. true)
  --tenant-name: string # Your Azure Active Directory ID. (e.g. testc44-1234-5678-9101-cc00736ftest)
  --usage-metrics-enabled: string@bool-completer # Enable azure.usage metrics for your organization. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/azure")
  let body = {app_service_plan_filters: $app_service_plan_filters, automute: $automute, client_id: $client_id, client_secret: $client_secret, container_app_filters: $container_app_filters, cspm_enabled: $cspm_enabled, custom_metrics_enabled: $custom_metrics_enabled, errors: $errors, host_filters: $host_filters, metrics_enabled: $metrics_enabled, metrics_enabled_default: $metrics_enabled_default, new_client_id: $new_client_id, new_tenant_name: $new_tenant_name, resource_collection_enabled: $resource_collection_enabled, resource_provider_configs: $resource_provider_configs, secretless_auth_enabled: $secretless_auth_enabled, tenant_name: $tenant_name, usage_metrics_enabled: $usage_metrics_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an Azure integration
#
# PUT /api/v1/integration/azure
# operationId: UpdateAzureIntegration
# --resource_provider_configs item shape: {metrics_enabled?: bool, namespace?: string}
export def "integration-azure UpdateAzureIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-service-plan-filters: string # Limit the Azure app service plans that are pulled into Datadog using tags. Only app service plans that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --automute: string@bool-completer # Silence monitors for expected Azure VM shutdowns. (e.g. true)
  --client-id: string # Your Azure web application ID. (e.g. testc7f6-1234-5678-9101-3fcbf464test)
  --client-secret: string # Your Azure web application secret key. (e.g. TestingRh2nx664kUy5dIApvM54T4AtO)
  --container-app-filters: string # Limit the Azure container apps that are pulled into Datadog using tags. Only container apps that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --cspm-enabled: string@bool-completer # When enabled, Datadog’s Cloud Security Management product scans resource configurations monitored by this app registration. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --custom-metrics-enabled: string@bool-completer # Enable custom metrics for your organization. (e.g. true)
  --errors: list # Errors in your configuration. (e.g. [*])
  --host-filters: string # Limit the Azure instances that are pulled into Datadog by using tags. Only hosts that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --metrics-enabled: string@bool-completer # Enable Azure metrics for your organization. (e.g. true)
  --metrics-enabled-default: string@bool-completer # Enable Azure metrics for your organization for resource providers where no resource provider config is specified. (e.g. true)
  --new-client-id: string # Your New Azure web application ID. (e.g. new1c7f6-1234-5678-9101-3fcbf464test)
  --new-tenant-name: string # Your New Azure Active Directory ID. (e.g. new1c44-1234-5678-9101-cc00736ftest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog collects metadata and configuration info from cloud resources (compute instances, databases, load balancers, etc.) monitored by this app registration. (e.g. true)
  --resource-provider-configs: list # Configuration settings applied to resources from the specified Azure resource providers. — item shape: {metrics_enabled?: bool, namespace?: string}
  --secretless-auth-enabled: string@bool-completer # (Preview) When enabled, Datadog authenticates with this app registration using federated workload identity credentials instead of a client secret. (e.g. true)
  --tenant-name: string # Your Azure Active Directory ID. (e.g. testc44-1234-5678-9101-cc00736ftest)
  --usage-metrics-enabled: string@bool-completer # Enable azure.usage metrics for your organization. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/azure")
  let body = {app_service_plan_filters: $app_service_plan_filters, automute: $automute, client_id: $client_id, client_secret: $client_secret, container_app_filters: $container_app_filters, cspm_enabled: $cspm_enabled, custom_metrics_enabled: $custom_metrics_enabled, errors: $errors, host_filters: $host_filters, metrics_enabled: $metrics_enabled, metrics_enabled_default: $metrics_enabled_default, new_client_id: $new_client_id, new_tenant_name: $new_tenant_name, resource_collection_enabled: $resource_collection_enabled, resource_provider_configs: $resource_provider_configs, secretless_auth_enabled: $secretless_auth_enabled, tenant_name: $tenant_name, usage_metrics_enabled: $usage_metrics_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Azure integration host filters
#
# POST /api/v1/integration/azure/host_filters
# operationId: UpdateAzureHostFilters
# --resource_provider_configs item shape: {metrics_enabled?: bool, namespace?: string}
export def "integration-azure-host-filters UpdateAzureHostFilters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-service-plan-filters: string # Limit the Azure app service plans that are pulled into Datadog using tags. Only app service plans that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --automute: string@bool-completer # Silence monitors for expected Azure VM shutdowns. (e.g. true)
  --client-id: string # Your Azure web application ID. (e.g. testc7f6-1234-5678-9101-3fcbf464test)
  --client-secret: string # Your Azure web application secret key. (e.g. TestingRh2nx664kUy5dIApvM54T4AtO)
  --container-app-filters: string # Limit the Azure container apps that are pulled into Datadog using tags. Only container apps that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --cspm-enabled: string@bool-completer # When enabled, Datadog’s Cloud Security Management product scans resource configurations monitored by this app registration. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --custom-metrics-enabled: string@bool-completer # Enable custom metrics for your organization. (e.g. true)
  --errors: list # Errors in your configuration. (e.g. [*])
  --host-filters: string # Limit the Azure instances that are pulled into Datadog by using tags. Only hosts that match one of the defined tags are imported into Datadog. (e.g. key:value,filter:example)
  --metrics-enabled: string@bool-completer # Enable Azure metrics for your organization. (e.g. true)
  --metrics-enabled-default: string@bool-completer # Enable Azure metrics for your organization for resource providers where no resource provider config is specified. (e.g. true)
  --new-client-id: string # Your New Azure web application ID. (e.g. new1c7f6-1234-5678-9101-3fcbf464test)
  --new-tenant-name: string # Your New Azure Active Directory ID. (e.g. new1c44-1234-5678-9101-cc00736ftest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog collects metadata and configuration info from cloud resources (compute instances, databases, load balancers, etc.) monitored by this app registration. (e.g. true)
  --resource-provider-configs: list # Configuration settings applied to resources from the specified Azure resource providers. — item shape: {metrics_enabled?: bool, namespace?: string}
  --secretless-auth-enabled: string@bool-completer # (Preview) When enabled, Datadog authenticates with this app registration using federated workload identity credentials instead of a client secret. (e.g. true)
  --tenant-name: string # Your Azure Active Directory ID. (e.g. testc44-1234-5678-9101-cc00736ftest)
  --usage-metrics-enabled: string@bool-completer # Enable azure.usage metrics for your organization. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/azure/host_filters")
  let body = {app_service_plan_filters: $app_service_plan_filters, automute: $automute, client_id: $client_id, client_secret: $client_secret, container_app_filters: $container_app_filters, cspm_enabled: $cspm_enabled, custom_metrics_enabled: $custom_metrics_enabled, errors: $errors, host_filters: $host_filters, metrics_enabled: $metrics_enabled, metrics_enabled_default: $metrics_enabled_default, new_client_id: $new_client_id, new_tenant_name: $new_tenant_name, resource_collection_enabled: $resource_collection_enabled, resource_provider_configs: $resource_provider_configs, secretless_auth_enabled: $secretless_auth_enabled, tenant_name: $tenant_name, usage_metrics_enabled: $usage_metrics_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a GCP integration
#
# DELETE /api/v1/integration/gcp
# DEPRECATED
# operationId: DeleteGCPIntegration
# --monitored_resource_configs item shape: {filters?: list, type?: "cloud_function"|"cloud_run_revision"|"gce_instance"}
@deprecated
@deprecated --flag cloud-run-revision-filters
@deprecated --flag host-filters
export def "integration-gcp DeleteGCPIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-provider-x509-cert-url: string # Should be `https://www.googleapis.com/oauth2/v1/certs`. (e.g. https://www.googleapis.com/oauth2/v1/certs)
  --auth-uri: string # Should be `https://accounts.google.com/o/oauth2/auth`. (e.g. https://accounts.google.com/o/oauth2/auth)
  --automute: string@bool-completer # Silence monitors for expected GCE instance shutdowns.
  --client-email: string # Your email found in your JSON service account key. (e.g. api-dev@datadog-sandbox.iam.gserviceaccount.com)
  --client-id: string # Your ID found in your JSON service account key. (e.g. 123456712345671234567)
  --client-x509-cert-url: string # Should be `https://www.googleapis.com/robot/v1/metadata/x509/$CLIENT_EMAIL` where `$CLIENT_EMAIL` is the email found in your JSON service account key. (e.g. https://www.googleapis.com/robot/v1/metadata/x509/$CLIENT_EMAIL)
  --cloud-run-revision-filters: list # List of filters to limit the Cloud Run revisions that are pulled into Datadog by using tags. Only Cloud Run revision resources that apply to specified filters are imported into Datadog. **Note:** This field is deprecated. Instead, use `monitored_resource_configs` with `type=cloud_run_revision` (DEPRECATED, e.g. [$KEY:$VALUE])
  --errors: list # An array of errors. (e.g. [*])
  --host-filters: string # A comma-separated list of filters to limit the VM instances that are pulled into Datadog by using tags. Only VM instance resources that apply to specified filters are imported into Datadog. **Note:** This field is deprecated. Instead, use `monitored_resource_configs` with `type=gce_instance` (DEPRECATED, e.g. $KEY1:$VALUE1,$KEY2:$VALUE2)
  --is-cspm-enabled: string@bool-completer # When enabled, Datadog will activate the Cloud Security Monitoring product for this service account. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --is-resource-change-collection-enabled: string@bool-completer # When enabled, Datadog scans for all resource change data in your Google Cloud environment. (default: false, e.g. true)
  --is-security-command-center-enabled: string@bool-completer # When enabled, Datadog will attempt to collect Security Command Center Findings. Note: This requires additional permissions on the service account. (default: false, e.g. true)
  --monitored-resource-configs: list # Configurations for GCP monitored resources. (e.g. [{filters: [$KEY:$VALUE], type: gce_instance}]) — item shape: {filters?: list, type?: "cloud_function"|"cloud_run_revision"|"gce_instance"}
  --private-key: string # Your private key name found in your JSON service account key. (e.g. private_key)
  --private-key-id: string # Your private key ID found in your JSON service account key. (e.g. 123456789abcdefghi123456789abcdefghijklm)
  --project-id: string # Your Google Cloud project ID found in your JSON service account key. (e.g. datadog-apitest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog scans for all resources in your GCP environment. (e.g. true)
  --token-uri: string # Should be `https://accounts.google.com/o/oauth2/token`. (e.g. https://accounts.google.com/o/oauth2/token)
  --type: string # The value for service_account found in your JSON service account key. (e.g. service_account)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/gcp")
  let body = {auth_provider_x509_cert_url: $auth_provider_x509_cert_url, auth_uri: $auth_uri, automute: $automute, client_email: $client_email, client_id: $client_id, client_x509_cert_url: $client_x509_cert_url, cloud_run_revision_filters: $cloud_run_revision_filters, errors: $errors, host_filters: $host_filters, is_cspm_enabled: $is_cspm_enabled, is_resource_change_collection_enabled: $is_resource_change_collection_enabled, is_security_command_center_enabled: $is_security_command_center_enabled, monitored_resource_configs: $monitored_resource_configs, private_key: $private_key, private_key_id: $private_key_id, project_id: $project_id, resource_collection_enabled: $resource_collection_enabled, token_uri: $token_uri, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all GCP integrations
#
# GET /api/v1/integration/gcp
# DEPRECATED
# operationId: ListGCPIntegration
@deprecated
export def "integration-gcp ListGCPIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<auth_provider_x509_cert_url: string, auth_uri: string, automute: bool, client_email: string, client_id: string, client_x509_cert_url: string, cloud_run_revision_filters: list<string>, errors: list<string>, host_filters: string, is_cspm_enabled: bool, is_resource_change_collection_enabled: bool, is_security_command_center_enabled: bool, monitored_resource_configs: list<record>, private_key: string, private_key_id: string, project_id: string, resource_collection_enabled: bool, token_uri: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/gcp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a GCP integration
#
# POST /api/v1/integration/gcp
# DEPRECATED
# operationId: CreateGCPIntegration
# --monitored_resource_configs item shape: {filters?: list, type?: "cloud_function"|"cloud_run_revision"|"gce_instance"}
@deprecated
@deprecated --flag cloud-run-revision-filters
@deprecated --flag host-filters
export def "integration-gcp CreateGCPIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-provider-x509-cert-url: string # Should be `https://www.googleapis.com/oauth2/v1/certs`. (e.g. https://www.googleapis.com/oauth2/v1/certs)
  --auth-uri: string # Should be `https://accounts.google.com/o/oauth2/auth`. (e.g. https://accounts.google.com/o/oauth2/auth)
  --automute: string@bool-completer # Silence monitors for expected GCE instance shutdowns.
  --client-email: string # Your email found in your JSON service account key. (e.g. api-dev@datadog-sandbox.iam.gserviceaccount.com)
  --client-id: string # Your ID found in your JSON service account key. (e.g. 123456712345671234567)
  --client-x509-cert-url: string # Should be `https://www.googleapis.com/robot/v1/metadata/x509/$CLIENT_EMAIL` where `$CLIENT_EMAIL` is the email found in your JSON service account key. (e.g. https://www.googleapis.com/robot/v1/metadata/x509/$CLIENT_EMAIL)
  --cloud-run-revision-filters: list # List of filters to limit the Cloud Run revisions that are pulled into Datadog by using tags. Only Cloud Run revision resources that apply to specified filters are imported into Datadog. **Note:** This field is deprecated. Instead, use `monitored_resource_configs` with `type=cloud_run_revision` (DEPRECATED, e.g. [$KEY:$VALUE])
  --errors: list # An array of errors. (e.g. [*])
  --host-filters: string # A comma-separated list of filters to limit the VM instances that are pulled into Datadog by using tags. Only VM instance resources that apply to specified filters are imported into Datadog. **Note:** This field is deprecated. Instead, use `monitored_resource_configs` with `type=gce_instance` (DEPRECATED, e.g. $KEY1:$VALUE1,$KEY2:$VALUE2)
  --is-cspm-enabled: string@bool-completer # When enabled, Datadog will activate the Cloud Security Monitoring product for this service account. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --is-resource-change-collection-enabled: string@bool-completer # When enabled, Datadog scans for all resource change data in your Google Cloud environment. (default: false, e.g. true)
  --is-security-command-center-enabled: string@bool-completer # When enabled, Datadog will attempt to collect Security Command Center Findings. Note: This requires additional permissions on the service account. (default: false, e.g. true)
  --monitored-resource-configs: list # Configurations for GCP monitored resources. (e.g. [{filters: [$KEY:$VALUE], type: gce_instance}]) — item shape: {filters?: list, type?: "cloud_function"|"cloud_run_revision"|"gce_instance"}
  --private-key: string # Your private key name found in your JSON service account key. (e.g. private_key)
  --private-key-id: string # Your private key ID found in your JSON service account key. (e.g. 123456789abcdefghi123456789abcdefghijklm)
  --project-id: string # Your Google Cloud project ID found in your JSON service account key. (e.g. datadog-apitest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog scans for all resources in your GCP environment. (e.g. true)
  --token-uri: string # Should be `https://accounts.google.com/o/oauth2/token`. (e.g. https://accounts.google.com/o/oauth2/token)
  --type: string # The value for service_account found in your JSON service account key. (e.g. service_account)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/gcp")
  let body = {auth_provider_x509_cert_url: $auth_provider_x509_cert_url, auth_uri: $auth_uri, automute: $automute, client_email: $client_email, client_id: $client_id, client_x509_cert_url: $client_x509_cert_url, cloud_run_revision_filters: $cloud_run_revision_filters, errors: $errors, host_filters: $host_filters, is_cspm_enabled: $is_cspm_enabled, is_resource_change_collection_enabled: $is_resource_change_collection_enabled, is_security_command_center_enabled: $is_security_command_center_enabled, monitored_resource_configs: $monitored_resource_configs, private_key: $private_key, private_key_id: $private_key_id, project_id: $project_id, resource_collection_enabled: $resource_collection_enabled, token_uri: $token_uri, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a GCP integration
#
# PUT /api/v1/integration/gcp
# DEPRECATED
# operationId: UpdateGCPIntegration
# --monitored_resource_configs item shape: {filters?: list, type?: "cloud_function"|"cloud_run_revision"|"gce_instance"}
@deprecated
@deprecated --flag cloud-run-revision-filters
@deprecated --flag host-filters
export def "integration-gcp UpdateGCPIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-provider-x509-cert-url: string # Should be `https://www.googleapis.com/oauth2/v1/certs`. (e.g. https://www.googleapis.com/oauth2/v1/certs)
  --auth-uri: string # Should be `https://accounts.google.com/o/oauth2/auth`. (e.g. https://accounts.google.com/o/oauth2/auth)
  --automute: string@bool-completer # Silence monitors for expected GCE instance shutdowns.
  --client-email: string # Your email found in your JSON service account key. (e.g. api-dev@datadog-sandbox.iam.gserviceaccount.com)
  --client-id: string # Your ID found in your JSON service account key. (e.g. 123456712345671234567)
  --client-x509-cert-url: string # Should be `https://www.googleapis.com/robot/v1/metadata/x509/$CLIENT_EMAIL` where `$CLIENT_EMAIL` is the email found in your JSON service account key. (e.g. https://www.googleapis.com/robot/v1/metadata/x509/$CLIENT_EMAIL)
  --cloud-run-revision-filters: list # List of filters to limit the Cloud Run revisions that are pulled into Datadog by using tags. Only Cloud Run revision resources that apply to specified filters are imported into Datadog. **Note:** This field is deprecated. Instead, use `monitored_resource_configs` with `type=cloud_run_revision` (DEPRECATED, e.g. [$KEY:$VALUE])
  --errors: list # An array of errors. (e.g. [*])
  --host-filters: string # A comma-separated list of filters to limit the VM instances that are pulled into Datadog by using tags. Only VM instance resources that apply to specified filters are imported into Datadog. **Note:** This field is deprecated. Instead, use `monitored_resource_configs` with `type=gce_instance` (DEPRECATED, e.g. $KEY1:$VALUE1,$KEY2:$VALUE2)
  --is-cspm-enabled: string@bool-completer # When enabled, Datadog will activate the Cloud Security Monitoring product for this service account. Note: This requires resource_collection_enabled to be set to true. (e.g. true)
  --is-resource-change-collection-enabled: string@bool-completer # When enabled, Datadog scans for all resource change data in your Google Cloud environment. (default: false, e.g. true)
  --is-security-command-center-enabled: string@bool-completer # When enabled, Datadog will attempt to collect Security Command Center Findings. Note: This requires additional permissions on the service account. (default: false, e.g. true)
  --monitored-resource-configs: list # Configurations for GCP monitored resources. (e.g. [{filters: [$KEY:$VALUE], type: gce_instance}]) — item shape: {filters?: list, type?: "cloud_function"|"cloud_run_revision"|"gce_instance"}
  --private-key: string # Your private key name found in your JSON service account key. (e.g. private_key)
  --private-key-id: string # Your private key ID found in your JSON service account key. (e.g. 123456789abcdefghi123456789abcdefghijklm)
  --project-id: string # Your Google Cloud project ID found in your JSON service account key. (e.g. datadog-apitest)
  --resource-collection-enabled: string@bool-completer # When enabled, Datadog scans for all resources in your GCP environment. (e.g. true)
  --token-uri: string # Should be `https://accounts.google.com/o/oauth2/token`. (e.g. https://accounts.google.com/o/oauth2/token)
  --type: string # The value for service_account found in your JSON service account key. (e.g. service_account)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/gcp")
  let body = {auth_provider_x509_cert_url: $auth_provider_x509_cert_url, auth_uri: $auth_uri, automute: $automute, client_email: $client_email, client_id: $client_id, client_x509_cert_url: $client_x509_cert_url, cloud_run_revision_filters: $cloud_run_revision_filters, errors: $errors, host_filters: $host_filters, is_cspm_enabled: $is_cspm_enabled, is_resource_change_collection_enabled: $is_resource_change_collection_enabled, is_security_command_center_enabled: $is_security_command_center_enabled, monitored_resource_configs: $monitored_resource_configs, private_key: $private_key, private_key_id: $private_key_id, project_id: $project_id, resource_collection_enabled: $resource_collection_enabled, token_uri: $token_uri, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new service object
#
# POST /api/v1/integration/pagerduty/configuration/services
# operationId: CreatePagerDutyIntegrationService
export def "integration-pagerduty-configuration-services CreatePagerDutyIntegrationService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  service_key: string # Your service key in PagerDuty. (e.g. )
  service_name: string # Your service name associated with a service key in PagerDuty. (e.g. )
]: any -> record<service_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/pagerduty/configuration/services")
  let body = {service_key: $service_key, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a single service object
#
# DELETE /api/v1/integration/pagerduty/configuration/services/{service_name}
# operationId: DeletePagerDutyIntegrationService
export def "integration-pagerduty-configuration-services DeletePagerDutyIntegrationService" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/pagerduty/configuration/services/($service_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single service object
#
# GET /api/v1/integration/pagerduty/configuration/services/{service_name}
# operationId: GetPagerDutyIntegrationService
export def "integration-pagerduty-configuration-services GetPagerDutyIntegrationService" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<service_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/pagerduty/configuration/services/($service_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single service object
#
# PUT /api/v1/integration/pagerduty/configuration/services/{service_name}
# operationId: UpdatePagerDutyIntegrationService
export def "integration-pagerduty-configuration-services UpdatePagerDutyIntegrationService" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  service_key: string # Your service key in PagerDuty. (e.g. )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/pagerduty/configuration/services/($service_name)")
  let body = {service_key: $service_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all channels in a Slack integration
#
# GET /api/v1/integration/slack/configuration/accounts/{account_name}/channels
# operationId: GetSlackIntegrationChannels
export def "integration-slack-configuration-accounts-channels GetSlackIntegrationChannels" [
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<display: record<message: bool, mute_buttons: bool, notified: bool, snapshot: bool, tags: bool>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/slack/configuration/accounts/($account_name)/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Slack integration channel
#
# POST /api/v1/integration/slack/configuration/accounts/{account_name}/channels
# operationId: CreateSlackIntegrationChannel
# --display shape: {message?: bool, mute_buttons?: bool, notified?: bool, snapshot?: bool, tags?: bool}
export def "integration-slack-configuration-accounts-channels CreateSlackIntegrationChannel" [
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display: record # Configuration options for what is shown in an alert event message. — shape: {message?: bool, mute_buttons?: bool, notified?: bool, snapshot?: bool, tags?: bool}
  --name: string # Your channel name. (e.g. #general)
]: any -> record<display: record<message: bool, mute_buttons: bool, notified: bool, snapshot: bool, tags: bool>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/slack/configuration/accounts/($account_name)/channels")
  let body = {display: $display, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a Slack integration channel
#
# DELETE /api/v1/integration/slack/configuration/accounts/{account_name}/channels/{channel_name}
# operationId: RemoveSlackIntegrationChannel
export def "integration-slack-configuration-accounts-channels RemoveSlackIntegrationChannel" [
  account_name: string
  channel_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/slack/configuration/accounts/($account_name)/channels/($channel_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Slack integration channel
#
# GET /api/v1/integration/slack/configuration/accounts/{account_name}/channels/{channel_name}
# operationId: GetSlackIntegrationChannel
export def "integration-slack-configuration-accounts-channels GetSlackIntegrationChannel" [
  account_name: string
  channel_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<display: record<message: bool, mute_buttons: bool, notified: bool, snapshot: bool, tags: bool>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/slack/configuration/accounts/($account_name)/channels/($channel_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Slack integration channel
#
# PATCH /api/v1/integration/slack/configuration/accounts/{account_name}/channels/{channel_name}
# operationId: UpdateSlackIntegrationChannel
# --display shape: {message?: bool, mute_buttons?: bool, notified?: bool, snapshot?: bool, tags?: bool}
export def "integration-slack-configuration-accounts-channels UpdateSlackIntegrationChannel" [
  account_name: string
  channel_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display: record # Configuration options for what is shown in an alert event message. — shape: {message?: bool, mute_buttons?: bool, notified?: bool, snapshot?: bool, tags?: bool}
  --name: string # Your channel name. (e.g. #general)
]: any -> record<display: record<message: bool, mute_buttons: bool, notified: bool, snapshot: bool, tags: bool>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/slack/configuration/accounts/($account_name)/channels/($channel_name)")
  let body = {display: $display, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a custom variable
#
# POST /api/v1/integration/webhooks/configuration/custom-variables
# operationId: CreateWebhooksIntegrationCustomVariable
export def "integration-webhooks-configuration-custom-variables CreateWebhooksIntegrationCustomVariable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-secret: string@bool-completer # Make custom variable is secret or not. If the custom variable is secret, the value is not returned in the response payload. (e.g. true)
  name: string # The name of the variable. It corresponds with `<CUSTOM_VARIABLE_NAME>`. (e.g. CUSTOM_VARIABLE_NAME)
  value: string # Value of the custom variable. (e.g. CUSTOM_VARIABLE_VALUE)
]: any -> record<is_secret: bool, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/webhooks/configuration/custom-variables")
  let body = {is_secret: $is_secret, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom variable
#
# DELETE /api/v1/integration/webhooks/configuration/custom-variables/{custom_variable_name}
# operationId: DeleteWebhooksIntegrationCustomVariable
export def "integration-webhooks-configuration-custom-variables DeleteWebhooksIntegrationCustomVariable" [
  custom_variable_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/webhooks/configuration/custom-variables/($custom_variable_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a custom variable
#
# GET /api/v1/integration/webhooks/configuration/custom-variables/{custom_variable_name}
# operationId: GetWebhooksIntegrationCustomVariable
export def "integration-webhooks-configuration-custom-variables GetWebhooksIntegrationCustomVariable" [
  custom_variable_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<is_secret: bool, name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/webhooks/configuration/custom-variables/($custom_variable_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom variable
#
# PUT /api/v1/integration/webhooks/configuration/custom-variables/{custom_variable_name}
# operationId: UpdateWebhooksIntegrationCustomVariable
export def "integration-webhooks-configuration-custom-variables UpdateWebhooksIntegrationCustomVariable" [
  custom_variable_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-secret: string@bool-completer # Make custom variable is secret or not. If the custom variable is secret, the value is not returned in the response payload.
  --name: string # The name of the variable. It corresponds with `<CUSTOM_VARIABLE_NAME>`. It must only contains upper-case characters, integers or underscores. (e.g. CUSTOM_VARIABLE_NAME)
  --value: string # Value of the custom variable. (e.g. CUSTOM_VARIABLE_VALUE)
]: any -> record<is_secret: bool, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/webhooks/configuration/custom-variables/($custom_variable_name)")
  let body = {is_secret: $is_secret, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a webhooks integration
#
# POST /api/v1/integration/webhooks/configuration/webhooks
# operationId: CreateWebhooksIntegration
export def "integration-webhooks-configuration-webhooks CreateWebhooksIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-headers: string # If `null`, uses no header. If given a JSON payload, these will be headers attached to your webhook. (nullable)
  --encode-as: string@encode-as-completer # Encoding type. Can be given either `json` or `form`. (default: json)
  name: string # The name of the webhook. It corresponds with `<WEBHOOK_NAME>`. Learn more on how to use it in [monitor notifications](https://docs.datadoghq.com/monitors/notify). (e.g. WEBHOOK_NAME)
  --payload: string # If `null`, uses the default payload. If given a JSON payload, the webhook returns the payload specified by the given payload. [Webhooks variable usage](https://docs.datadoghq.com/integrations/webhooks/#usage). (nullable)
  --body-url: string # URL of the webhook. (e.g. https://example.com/webhook)
]: any -> record<custom_headers: string, encode_as: string, name: string, payload: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integration/webhooks/configuration/webhooks")
  let body = {custom_headers: $custom_headers, encode_as: $encode_as, name: $name, payload: $payload, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /api/v1/integration/webhooks/configuration/webhooks/{webhook_name}
# operationId: DeleteWebhooksIntegration
export def "integration-webhooks-configuration-webhooks DeleteWebhooksIntegration" [
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/webhooks/configuration/webhooks/($webhook_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook integration
#
# GET /api/v1/integration/webhooks/configuration/webhooks/{webhook_name}
# operationId: GetWebhooksIntegration
export def "integration-webhooks-configuration-webhooks GetWebhooksIntegration" [
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_headers: string, encode_as: string, name: string, payload: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/webhooks/configuration/webhooks/($webhook_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /api/v1/integration/webhooks/configuration/webhooks/{webhook_name}
# operationId: UpdateWebhooksIntegration
export def "integration-webhooks-configuration-webhooks UpdateWebhooksIntegration" [
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-headers: string # If `null`, uses no header. If given a JSON payload, these will be headers attached to your webhook.
  --encode-as: string@encode-as-completer # Encoding type. Can be given either `json` or `form`. (default: json)
  --name: string # The name of the webhook. It corresponds with `<WEBHOOK_NAME>`. Learn more on how to use it in [monitor notifications](https://docs.datadoghq.com/monitors/notify). (e.g. WEBHOOK_NAME)
  --payload: string # If `null`, uses the default payload. If given a JSON payload, the webhook returns the payload specified by the given payload. [Webhooks variable usage](https://docs.datadoghq.com/integrations/webhooks/#usage). (nullable)
  --body-url: string # URL of the webhook. (e.g. https://example.com/webhook)
]: any -> record<custom_headers: string, encode_as: string, name: string, payload: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integration/webhooks/configuration/webhooks/($webhook_name)")
  let body = {custom_headers: $custom_headers, encode_as: $encode_as, name: $name, payload: $payload, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search logs
#
# POST /api/v1/logs-queries/list
# operationId: ListLogs
# --time shape: {from: string, timezone?: string, to: string}
export def "logs-queries-list ListLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --index: string # The log index on which the request is performed. For multi-index organizations, the default is all live indexes. Historical indexes of rehydrated logs must be specified. (e.g. retention-3,retention-15)
  --limit: int # Number of logs return in the response. (format: int32)
  --body-query: string # The search query - following the log search syntax. (e.g. service:web* AND @http.status_code:[200 TO 299])
  --body-sort: string@sort-completer-1 # Time-ascending `asc` or time-descending `desc` results.
  --startAt: string # Hash identifier of the first log to return in the list, available in a log `id` attribute. This parameter is used for the pagination feature.  **Note**: This parameter is ignored if the corresponding log is out of the scope of the specified time window.
  time: record # Timeframe to retrieve the log from. — shape: {from: string, timezone?: string, to: string}
]: any -> record<logs: table<content: record, id: string>, nextLogId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs-queries/list")
  let body = {index: $index, limit: $limit, query: $body_query, sort: $body_sort, startAt: $startAt, time: $time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get indexes order
#
# GET /api/v1/logs/config/index-order
# operationId: GetLogsIndexOrder
export def "logs-config-index-order GetLogsIndexOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<index_names: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/index-order")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update indexes order
#
# PUT /api/v1/logs/config/index-order
# operationId: UpdateLogsIndexOrder
export def "logs-config-index-order UpdateLogsIndexOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  index_names: list # Array of strings identifying by their name(s) the index(es) of your organization. Logs are tested against the query filter of each index one by one, following the order of the array. Logs are eventually stored in the first matching index. (e.g. [main, payments, web])
]: any -> record<index_names: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/index-order")
  let body = {index_names: $index_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all indexes
#
# GET /api/v1/logs/config/indexes
# operationId: ListLogIndexes
export def "logs-config-indexes ListLogIndexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<indexes: table<daily_limit: int, daily_limit_reset: record, daily_limit_warning_threshold_percentage: float, exclusion_filters: list, filter: record, is_rate_limited: bool, name: string, num_flex_logs_retention_days: int, num_retention_days: int, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/indexes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an index
#
# POST /api/v1/logs/config/indexes
# operationId: CreateLogsIndex
# --daily_limit_reset shape: {reset_time?: string, reset_utc_offset?: string}
# --exclusion_filters item shape: {filter?: record, is_enabled?: bool, name: string}
# --filter shape: {query?: string}
export def "logs-config-indexes CreateLogsIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --daily-limit: int # The number of log events you can send in this index per day before you are rate-limited. (format: int64, e.g. 300000000)
  --daily-limit-reset: record # Object containing options to override the default daily limit reset time. — shape: {reset_time?: string, reset_utc_offset?: string}
  --daily-limit-warning-threshold-percentage: float # A percentage threshold of the daily quota at which a Datadog warning event is generated. (format: double, e.g. 70)
  --exclusion-filters: list # An array of exclusion objects. The logs are tested against the query of each filter, following the order of the array. Only the first matching active exclusion matters, others (if any) are ignored. — item shape: {filter?: record, is_enabled?: bool, name: string}
  filter: record # Filter for logs. — shape: {query?: string}
  name: string # The name of the index. (e.g. main)
  --num-flex-logs-retention-days: int # The total number of days logs are stored in Standard and Flex Tier before being deleted from the index. If Standard Tier is enabled on this index, logs are first retained in Standard Tier for the number of days specified through `num_retention_days`, and then stored in Flex Tier until the number of days specified in `num_flex_logs_retention_days` is reached. The available values depend on retention plans specified in your organization's contract/subscriptions. (format: int64, e.g. 360)
  --num-retention-days: int # The number of days logs are stored in Standard Tier before aging into the Flex Tier or being deleted from the index. The available values depend on retention plans specified in your organization's contract/subscriptions. (format: int64, e.g. 15)
  --tags: list # A list of tags associated with the index. Tags must be in `key:value` format. (e.g. [team:backend, env:production])
]: any -> record<daily_limit: int, daily_limit_reset: record<reset_time: string, reset_utc_offset: string>, daily_limit_warning_threshold_percentage: float, exclusion_filters: table<filter: record, is_enabled: bool, name: string>, filter: record<query: string>, is_rate_limited: bool, name: string, num_flex_logs_retention_days: int, num_retention_days: int, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/indexes")
  let body = {daily_limit: $daily_limit, daily_limit_reset: $daily_limit_reset, daily_limit_warning_threshold_percentage: $daily_limit_warning_threshold_percentage, exclusion_filters: $exclusion_filters, filter: $filter, name: $name, num_flex_logs_retention_days: $num_flex_logs_retention_days, num_retention_days: $num_retention_days, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an index
#
# DELETE /api/v1/logs/config/indexes/{name}
# operationId: DeleteLogsIndex
export def "logs-config-indexes DeleteLogsIndex" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/logs/config/indexes/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an index
#
# GET /api/v1/logs/config/indexes/{name}
# operationId: GetLogsIndex
export def "logs-config-indexes GetLogsIndex" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<daily_limit: int, daily_limit_reset: record<reset_time: string, reset_utc_offset: string>, daily_limit_warning_threshold_percentage: float, exclusion_filters: table<filter: record, is_enabled: bool, name: string>, filter: record<query: string>, is_rate_limited: bool, name: string, num_flex_logs_retention_days: int, num_retention_days: int, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/logs/config/indexes/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an index
#
# PUT /api/v1/logs/config/indexes/{name}
# operationId: UpdateLogsIndex
# --daily_limit_reset shape: {reset_time?: string, reset_utc_offset?: string}
# --exclusion_filters item shape: {filter?: record, is_enabled?: bool, name: string}
# --filter shape: {query?: string}
export def "logs-config-indexes UpdateLogsIndex" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --daily-limit: int # The number of log events you can send in this index per day before you are rate-limited. (format: int64, e.g. 300000000)
  --daily-limit-reset: record # Object containing options to override the default daily limit reset time. — shape: {reset_time?: string, reset_utc_offset?: string}
  --daily-limit-warning-threshold-percentage: float # A percentage threshold of the daily quota at which a Datadog warning event is generated. (format: double, e.g. 70)
  --disable-daily-limit: string@bool-completer # If true, sets the `daily_limit` value to null and the index is not limited on a daily basis (any specified `daily_limit` value in the request is ignored). If false or omitted, the index's current `daily_limit` is maintained. (e.g. false)
  --exclusion-filters: list # An array of exclusion objects. The logs are tested against the query of each filter, following the order of the array. Only the first matching active exclusion matters, others (if any) are ignored. — item shape: {filter?: record, is_enabled?: bool, name: string}
  filter: record # Filter for logs. — shape: {query?: string}
  --num-flex-logs-retention-days: int # The total number of days logs are stored in Standard and Flex Tier before being deleted from the index. If Standard Tier is enabled on this index, logs are first retained in Standard Tier for the number of days specified through `num_retention_days`, and then stored in Flex Tier until the number of days specified in `num_flex_logs_retention_days` is reached. The available values depend on retention plans specified in your organization's contract/subscriptions.  **Note**: Changing this value affects all logs already in this index. It may also affect billing. (format: int64, e.g. 360)
  --num-retention-days: int # The number of days logs are stored in Standard Tier before aging into the Flex Tier or being deleted from the index. The available values depend on retention plans specified in your organization's contract/subscriptions.  **Note**: Changing this value affects all logs already in this index. It may also affect billing. (format: int64, e.g. 15)
  --tags: list # A list of tags associated with the index. Tags must be in `key:value` format. (e.g. [team:backend, env:production])
]: any -> record<daily_limit: int, daily_limit_reset: record<reset_time: string, reset_utc_offset: string>, daily_limit_warning_threshold_percentage: float, exclusion_filters: table<filter: record, is_enabled: bool, name: string>, filter: record<query: string>, is_rate_limited: bool, name: string, num_flex_logs_retention_days: int, num_retention_days: int, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/logs/config/indexes/($name)")
  let body = {daily_limit: $daily_limit, daily_limit_reset: $daily_limit_reset, daily_limit_warning_threshold_percentage: $daily_limit_warning_threshold_percentage, disable_daily_limit: $disable_daily_limit, exclusion_filters: $exclusion_filters, filter: $filter, num_flex_logs_retention_days: $num_flex_logs_retention_days, num_retention_days: $num_retention_days, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pipeline order
#
# GET /api/v1/logs/config/pipeline-order
# operationId: GetLogsPipelineOrder
export def "logs-config-pipeline-order GetLogsPipelineOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pipeline_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/pipeline-order")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update pipeline order
#
# PUT /api/v1/logs/config/pipeline-order
# operationId: UpdateLogsPipelineOrder
export def "logs-config-pipeline-order UpdateLogsPipelineOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pipeline_ids: list # Ordered Array of `<PIPELINE_ID>` strings, the order of pipeline IDs in the array define the overall Pipelines order for Datadog. (e.g. [tags, org_ids, products])
]: any -> record<pipeline_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/pipeline-order")
  let body = {pipeline_ids: $pipeline_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all pipelines
#
# GET /api/v1/logs/config/pipelines
# operationId: ListLogsPipelines
export def "logs-config-pipelines ListLogsPipelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<description: string, filter: record<query: string>, id: string, is_enabled: bool, is_read_only: bool, name: string, processors: list<any>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/pipelines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pipeline
#
# POST /api/v1/logs/config/pipelines
# operationId: CreateLogsPipeline
# --filter shape: {query?: string}
export def "logs-config-pipelines CreateLogsPipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A description of the pipeline.
  --filter: record # Filter for logs. — shape: {query?: string}
  --is-enabled: string@bool-completer # Whether or not the pipeline is enabled.
  name: string # Name of the pipeline. (e.g. )
  --processors: list # Ordered list of processors in this pipeline.
  --tags: list # A list of tags associated with the pipeline.
]: any -> record<description: string, filter: record<query: string>, id: string, is_enabled: bool, is_read_only: bool, name: string, processors: list<any>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/config/pipelines")
  let body = {description: $description, filter: $filter, is_enabled: $is_enabled, name: $name, processors: $processors, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a pipeline
#
# DELETE /api/v1/logs/config/pipelines/{pipeline_id}
# operationId: DeleteLogsPipeline
export def "logs-config-pipelines DeleteLogsPipeline" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/logs/config/pipelines/($pipeline_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pipeline
#
# GET /api/v1/logs/config/pipelines/{pipeline_id}
# operationId: GetLogsPipeline
export def "logs-config-pipelines GetLogsPipeline" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, filter: record<query: string>, id: string, is_enabled: bool, is_read_only: bool, name: string, processors: list<any>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/logs/config/pipelines/($pipeline_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a pipeline
#
# PUT /api/v1/logs/config/pipelines/{pipeline_id}
# operationId: UpdateLogsPipeline
# --filter shape: {query?: string}
export def "logs-config-pipelines UpdateLogsPipeline" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A description of the pipeline.
  --filter: record # Filter for logs. — shape: {query?: string}
  --is-enabled: string@bool-completer # Whether or not the pipeline is enabled.
  name: string # Name of the pipeline. (e.g. )
  --processors: list # Ordered list of processors in this pipeline.
  --tags: list # A list of tags associated with the pipeline.
]: any -> record<description: string, filter: record<query: string>, id: string, is_enabled: bool, is_read_only: bool, name: string, processors: list<any>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/logs/config/pipelines/($pipeline_id)")
  let body = {description: $description, filter: $filter, is_enabled: $is_enabled, name: $name, processors: $processors, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get active metrics list
#
# GET /api/v1/metrics
# operationId: ListActiveMetrics
export def "metrics ListActiveMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # Seconds since the Unix epoch. (format: int64)
  --host: string # Hostname for filtering the list of metrics returned. If set, metrics retrieved are those with the corresponding hostname tag.
  --tag-filter: string # Filter metrics that have been submitted with the given tags. Supports boolean and wildcard expressions. Cannot be combined with other filters. (e.g. env IN (staging,test) AND service:web)
]: nothing -> record<from: string, metrics: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "tag_filter" $tag_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric metadata
#
# GET /api/v1/metrics/{metric_name}
# operationId: GetMetricMetadata
export def "metrics GetMetricMetadata" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, integration: string, per_unit: string, short_name: string, statsd_interval: int, type: string, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metrics/($metric_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit metric metadata
#
# PUT /api/v1/metrics/{metric_name}
# operationId: UpdateMetricMetadata
export def "metrics UpdateMetricMetadata" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Metric description.
  --per-unit: string # Per unit of the metric such as `second` in `bytes per second`. (e.g. second)
  --short-name: string # A more human-readable and abbreviated version of the metric name.
  --statsd-interval: int # StatsD flush interval of the metric in seconds if applicable. (format: int64)
  --type: string # Metric type such as `gauge` or `rate`. (e.g. count)
  --unit: string # Primary unit of the metric such as `byte` or `operation`. (e.g. byte)
]: any -> record<description: string, integration: string, per_unit: string, short_name: string, statsd_interval: int, type: string, unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metrics/($metric_name)")
  let body = {description: $description, per_unit: $per_unit, short_name: $short_name, statsd_interval: $statsd_interval, type: $type, unit: $unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all monitors
#
# GET /api/v1/monitor
# operationId: ListMonitors
export def "monitor ListMonitors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-states: string # When specified, shows additional information about the group states. Choose one or more from `all`, `alert`, `warn`, and `no data`. (e.g. alert)
  --name: string # A string to filter monitors by name.
  --tags: string # A comma separated list indicating what tags, if any, should be used to filter the list of monitors by scope. For example, `host:host0`. (e.g. host:host0)
  --monitor-tags: string # A comma separated list indicating what service and/or custom tags, if any, should be used to filter the list of monitors. Tags created in the Datadog UI automatically have the service key prepended. For example, `service:my-app`. (e.g. service:my-app)
  --with-downtimes: string@bool-completer # If this argument is set to true, then the returned data includes all current active downtimes for each monitor.
  --id-offset: int # Use this parameter for paginating through large sets of monitors. Start with a value of zero, make a request, set the value to the last ID of result set, and then repeat until the response is empty. (format: int64)
  --page: int # The page to start paginating from. If this argument is not specified, the request returns all monitors without pagination. (format: int64, e.g. 0)
  --page-size: int # The number of monitors to return per page. If the page argument is not specified, the default behavior returns all monitors without a `page_size` limit. However, if page is specified and `page_size` is not, the argument defaults to 100. (format: int32, default: 100, e.g. 20)
]: nothing -> table<assets: list<record>, created: string, creator: record<email: string, handle: string, name: string>, deleted: string, draft_status: string, id: int, matching_downtimes: list<record>, message: string, modified: string, multi: bool, name: string, options: record<aggregation: record, device_ids: list, enable_logs_sample: bool, enable_samples: bool, escalation_message: string, evaluation_delay: int, group_retention_duration: string, groupby_simple_monitor: bool, include_tags: bool, locked: bool, min_failure_duration: int, min_location_failed: int, new_group_delay: int, new_host_delay: int, no_data_timeframe: int, notification_preset_name: string, notify_audit: bool, notify_by: list, notify_no_data: bool, on_missing_data: string, renotify_interval: int, renotify_occurrences: int, renotify_statuses: list, require_full_window: bool, scheduling_options: record, silenced: record, synthetics_check_id: string, threshold_windows: record, thresholds: record, timeout_h: int, variables: list>, overall_state: string, priority: int, query: string, restricted_roles: list<string>, state: record<groups: record>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_states" $group_states "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "monitor_tags" $monitor_tags "scalar") (serialize-qp "with_downtimes" $with_downtimes "scalar") (serialize-qp "id_offset" $id_offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/monitor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a monitor
#
# POST /api/v1/monitor
# operationId: CreateMonitor
# --assets item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
# --creator shape: {email?: string, handle?: string, name?: string}
# --matching_downtimes item shape: {end?: int, scope?: list, start?: int}
# --options shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
# --state shape: {groups?: record}
export def "monitor CreateMonitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets: list # The list of monitor assets tied to a monitor, which represents key links for users to take action on monitor alerts (for example, runbooks). — item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
  --draft-status: string@draft-status-completer # Indicates whether the monitor is in a draft or published state.  `draft`: The monitor appears as Draft and does not send notifications. `published`: The monitor is active and evaluates conditions and notify as configured.  This field is in preview. The draft value is only available to customers with the feature enabled. (default: published)
  --matching-downtimes: list # A list of active v1 downtimes that match this monitor. — item shape: {end?: int, scope?: list, start?: int}
  --message: string # A message to include with notifications for this monitor.
  --name: string # The monitor name. (e.g. My monitor)
  --options: record # List of options associated with your monitor. — shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
  --priority: int # Integer from 1 (high) to 5 (low) indicating alert severity. (nullable, format: int64)
  --body-query: string # The monitor query. (e.g. avg(last_5m):sum:system.net.bytes_rcvd{host:host0} > 100)
  --restricted-roles: list # A list of unique role identifiers to define which roles are allowed to edit the monitor. The unique identifiers for all roles can be pulled from the [Roles API](https://docs.datadoghq.com/api/latest/roles/#list-roles) and are located in the `data.id` field. Editing a monitor includes any updates to the monitor configuration, monitor deletion, and muting of the monitor for any amount of time. You can use the [Restriction Policies API](https://docs.datadoghq.com/api/latest/restriction-policies/) to manage write authorization for individual monitors by teams and users, in addition to roles. (nullable)
  --tags: list # Tags associated to your monitor.
  type: string@type-completer # The type of the monitor. For more information about `type`, see the [monitor options](https://docs.datadoghq.com/monitors/guide/monitor_api_options/) docs. (e.g. query alert)
]: any -> record<assets: table<category: string, name: string, resource_key: string, resource_type: string, url: string>, created: string, creator: record<email: string, handle: string, name: string>, deleted: string, draft_status: string, id: int, matching_downtimes: table<end: int, id: int, scope: list, start: int>, message: string, modified: string, multi: bool, name: string, options: record<aggregation: record<group_by: string, metric: string, type: string>, device_ids: list<string>, enable_logs_sample: bool, enable_samples: bool, escalation_message: string, evaluation_delay: int, group_retention_duration: string, groupby_simple_monitor: bool, include_tags: bool, locked: bool, min_failure_duration: int, min_location_failed: int, new_group_delay: int, new_host_delay: int, no_data_timeframe: int, notification_preset_name: string, notify_audit: bool, notify_by: list<string>, notify_no_data: bool, on_missing_data: string, renotify_interval: int, renotify_occurrences: int, renotify_statuses: list<string>, require_full_window: bool, scheduling_options: record<custom_schedule: record, evaluation_window: record>, silenced: record, synthetics_check_id: string, threshold_windows: record<recovery_window: string, trigger_window: string>, thresholds: record<critical: float, critical_query: string, critical_recovery: float, critical_recovery_query: string, ok: float, unknown: float, warning: float, warning_recovery: float>, timeout_h: int, variables: list<any>>, overall_state: string, priority: int, query: string, restricted_roles: list<string>, state: record<groups: record>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/monitor")
  let body = {assets: $assets, draft_status: $draft_status, matching_downtimes: $matching_downtimes, message: $message, name: $name, options: $options, priority: $priority, query: $body_query, restricted_roles: $restricted_roles, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if a monitor can be deleted
#
# GET /api/v1/monitor/can_delete
# operationId: CheckCanDeleteMonitor
export def "monitor-can-delete CheckCanDeleteMonitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --monitor-ids: list # The IDs of the monitor to check.
]: nothing -> record<data: record<ok: list<int>>, errors: record> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitor_ids" $monitor_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/monitor/can_delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Monitors group search
#
# GET /api/v1/monitor/groups/search
# operationId: SearchMonitorGroups
export def "monitor-groups-search SearchMonitorGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # After entering a search query on the [Triggered Monitors page][1], use the query parameter value in the URL of the page as a value for this parameter. For more information, see the [Manage Monitors documentation][2].  The query can contain any number of space-separated monitor attributes, for instance: `query="type:metric group_status:alert"`.  [1]: https://app.datadoghq.com/monitors/triggered [2]: /monitors/manage/#triggered-monitors
  --page: int # Page to start paginating from. (format: int64, default: 0)
  --per-page: int # Number of monitors to return per page. (format: int64, default: 30)
  --qp-sort: string # String for sort order, composed of field and sort order separate by a comma, for example `name,asc`. Supported sort directions: `asc`, `desc`. Supported fields:  * `name` * `status` * `tags`
]: nothing -> record<counts: record<status: list<record>, type: list<record>>, groups: table<group: string, group_tags: list, last_nodata_ts: int, last_triggered_ts: int, monitor_id: int, monitor_name: string, status: string>, metadata: record<page: int, page_count: int, per_page: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/monitor/groups/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Monitors search
#
# GET /api/v1/monitor/search
# operationId: SearchMonitors
export def "monitor-search SearchMonitors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # After entering a search query in your [Manage Monitor page][1] use the query parameter value in the URL of the page as value for this parameter. Consult the dedicated [manage monitor documentation][2] page to learn more.  The query can contain any number of space-separated monitor attributes, for instance `query="type:metric status:alert"`.  [1]: https://app.datadoghq.com/monitors/manage [2]: /monitors/manage/#find-the-monitors
  --page: int # Page to start paginating from. (format: int64, default: 0)
  --per-page: int # Number of monitors to return per page. (format: int64, default: 30)
  --qp-sort: string # String for sort order, composed of field and sort order separate by a comma, for example `name,asc`. Supported sort directions: `asc`, `desc`. Supported fields:  * `name` * `status` * `tags`
]: nothing -> record<counts: record<muted: list<record>, status: list<record>, tag: list<record>, type: list<record>>, metadata: record<page: int, page_count: int, per_page: int, total_count: int>, monitors: table<classification: string, creator: record, id: int, last_triggered_ts: int, metrics: list, name: string, notifications: list, org_id: int, quality_issues: list, query: string, scopes: list, status: string, tags: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/monitor/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate a monitor
#
# POST /api/v1/monitor/validate
# operationId: ValidateMonitor
# --assets item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
# --creator shape: {email?: string, handle?: string, name?: string}
# --matching_downtimes item shape: {end?: int, scope?: list, start?: int}
# --options shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
# --state shape: {groups?: record}
export def "monitor-validate ValidateMonitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets: list # The list of monitor assets tied to a monitor, which represents key links for users to take action on monitor alerts (for example, runbooks). — item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
  --draft-status: string@draft-status-completer # Indicates whether the monitor is in a draft or published state.  `draft`: The monitor appears as Draft and does not send notifications. `published`: The monitor is active and evaluates conditions and notify as configured.  This field is in preview. The draft value is only available to customers with the feature enabled. (default: published)
  --matching-downtimes: list # A list of active v1 downtimes that match this monitor. — item shape: {end?: int, scope?: list, start?: int}
  --message: string # A message to include with notifications for this monitor.
  --name: string # The monitor name. (e.g. My monitor)
  --options: record # List of options associated with your monitor. — shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
  --priority: int # Integer from 1 (high) to 5 (low) indicating alert severity. (nullable, format: int64)
  --body-query: string # The monitor query. (e.g. avg(last_5m):sum:system.net.bytes_rcvd{host:host0} > 100)
  --restricted-roles: list # A list of unique role identifiers to define which roles are allowed to edit the monitor. The unique identifiers for all roles can be pulled from the [Roles API](https://docs.datadoghq.com/api/latest/roles/#list-roles) and are located in the `data.id` field. Editing a monitor includes any updates to the monitor configuration, monitor deletion, and muting of the monitor for any amount of time. You can use the [Restriction Policies API](https://docs.datadoghq.com/api/latest/restriction-policies/) to manage write authorization for individual monitors by teams and users, in addition to roles. (nullable)
  --tags: list # Tags associated to your monitor.
  type: string@type-completer # The type of the monitor. For more information about `type`, see the [monitor options](https://docs.datadoghq.com/monitors/guide/monitor_api_options/) docs. (e.g. query alert)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/monitor/validate")
  let body = {assets: $assets, draft_status: $draft_status, matching_downtimes: $matching_downtimes, message: $message, name: $name, options: $options, priority: $priority, query: $body_query, restricted_roles: $restricted_roles, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a monitor
#
# DELETE /api/v1/monitor/{monitor_id}
# operationId: DeleteMonitor
export def "monitor DeleteMonitor" [
  monitor_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string # Delete the monitor even if it's referenced by other resources (for example SLO, composite monitor). (e.g. false)
]: nothing -> record<deleted_monitor_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/monitor/($monitor_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a monitor's details
#
# GET /api/v1/monitor/{monitor_id}
# operationId: GetMonitor
export def "monitor GetMonitor" [
  monitor_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-states: string # When specified, shows additional information about the group states. Choose one or more from `all`, `alert`, `warn`, and `no data`.
  --with-downtimes: string@bool-completer # If this argument is set to true, then the returned data includes all current active downtimes for the monitor.
  --with-assets: string@bool-completer # If this argument is set to `true`, the returned data includes all assets tied to this monitor.
]: nothing -> record<assets: table<category: string, name: string, resource_key: string, resource_type: string, url: string>, created: string, creator: record<email: string, handle: string, name: string>, deleted: string, draft_status: string, id: int, matching_downtimes: table<end: int, id: int, scope: list, start: int>, message: string, modified: string, multi: bool, name: string, options: record<aggregation: record<group_by: string, metric: string, type: string>, device_ids: list<string>, enable_logs_sample: bool, enable_samples: bool, escalation_message: string, evaluation_delay: int, group_retention_duration: string, groupby_simple_monitor: bool, include_tags: bool, locked: bool, min_failure_duration: int, min_location_failed: int, new_group_delay: int, new_host_delay: int, no_data_timeframe: int, notification_preset_name: string, notify_audit: bool, notify_by: list<string>, notify_no_data: bool, on_missing_data: string, renotify_interval: int, renotify_occurrences: int, renotify_statuses: list<string>, require_full_window: bool, scheduling_options: record<custom_schedule: record, evaluation_window: record>, silenced: record, synthetics_check_id: string, threshold_windows: record<recovery_window: string, trigger_window: string>, thresholds: record<critical: float, critical_query: string, critical_recovery: float, critical_recovery_query: string, ok: float, unknown: float, warning: float, warning_recovery: float>, timeout_h: int, variables: list<any>>, overall_state: string, priority: int, query: string, restricted_roles: list<string>, state: record<groups: record>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_states" $group_states "scalar") (serialize-qp "with_downtimes" $with_downtimes "scalar") (serialize-qp "with_assets" $with_assets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/monitor/($monitor_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a monitor
#
# PUT /api/v1/monitor/{monitor_id}
# operationId: UpdateMonitor
# --assets item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
# --creator shape: {email?: string, handle?: string, name?: string}
# --options shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
# --state shape: {groups?: record}
export def "monitor UpdateMonitor" [
  monitor_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets: list # The list of monitor assets tied to a monitor, which represents key links for users to take action on monitor alerts (for example, runbooks). (nullable) — item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
  --draft-status: string@draft-status-completer # Indicates whether the monitor is in a draft or published state.  `draft`: The monitor appears as Draft and does not send notifications. `published`: The monitor is active and evaluates conditions and notify as configured.  This field is in preview. The draft value is only available to customers with the feature enabled. (default: published)
  --message: string # A message to include with notifications for this monitor.
  --name: string # The monitor name.
  --options: record # List of options associated with your monitor. — shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
  --priority: int # Integer from 1 (high) to 5 (low) indicating alert severity. (nullable, format: int64)
  --body-query: string # The monitor query.
  --restricted-roles: list # A list of unique role identifiers to define which roles are allowed to edit the monitor. The unique identifiers for all roles can be pulled from the [Roles API](https://docs.datadoghq.com/api/latest/roles/#list-roles) and are located in the `data.id` field. Editing a monitor includes any updates to the monitor configuration, monitor deletion, and muting of the monitor for any amount of time. You can use the [Restriction Policies API](https://docs.datadoghq.com/api/latest/restriction-policies/) to manage write authorization for individual monitors by teams and users, in addition to roles. (nullable)
  --tags: list # Tags associated to your monitor.
  --type: string@type-completer # The type of the monitor. For more information about `type`, see the [monitor options](https://docs.datadoghq.com/monitors/guide/monitor_api_options/) docs. (e.g. query alert)
]: any -> record<assets: table<category: string, name: string, resource_key: string, resource_type: string, url: string>, created: string, creator: record<email: string, handle: string, name: string>, deleted: string, draft_status: string, id: int, matching_downtimes: table<end: int, id: int, scope: list, start: int>, message: string, modified: string, multi: bool, name: string, options: record<aggregation: record<group_by: string, metric: string, type: string>, device_ids: list<string>, enable_logs_sample: bool, enable_samples: bool, escalation_message: string, evaluation_delay: int, group_retention_duration: string, groupby_simple_monitor: bool, include_tags: bool, locked: bool, min_failure_duration: int, min_location_failed: int, new_group_delay: int, new_host_delay: int, no_data_timeframe: int, notification_preset_name: string, notify_audit: bool, notify_by: list<string>, notify_no_data: bool, on_missing_data: string, renotify_interval: int, renotify_occurrences: int, renotify_statuses: list<string>, require_full_window: bool, scheduling_options: record<custom_schedule: record, evaluation_window: record>, silenced: record, synthetics_check_id: string, threshold_windows: record<recovery_window: string, trigger_window: string>, thresholds: record<critical: float, critical_query: string, critical_recovery: float, critical_recovery_query: string, ok: float, unknown: float, warning: float, warning_recovery: float>, timeout_h: int, variables: list<any>>, overall_state: string, priority: int, query: string, restricted_roles: list<string>, state: record<groups: record>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/monitor/($monitor_id)")
  let body = {assets: $assets, draft_status: $draft_status, message: $message, name: $name, options: $options, priority: $priority, query: $body_query, restricted_roles: $restricted_roles, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get active downtimes for a monitor
#
# GET /api/v1/monitor/{monitor_id}/downtimes
# DEPRECATED
# operationId: ListMonitorDowntimes
@deprecated
export def "monitor-downtimes ListMonitorDowntimes" [
  monitor_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<active: bool, active_child: record<active: bool, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list, mute_first_recovery_notification: bool, notify_end_states: list, notify_end_types: list, parent_id: int, recurrence: record, scope: list, start: int, timezone: string, updater_id: int>, canceled: int, creator_id: int, disabled: bool, downtime_type: int, end: int, id: int, message: string, monitor_id: int, monitor_tags: list<string>, mute_first_recovery_notification: bool, notify_end_states: list<string>, notify_end_types: list<string>, parent_id: int, recurrence: record<period: int, rrule: string, type: string, until_date: int, until_occurrences: int, week_days: list>, scope: list<string>, start: int, timezone: string, updater_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/monitor/($monitor_id)/downtimes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate an existing monitor
#
# POST /api/v1/monitor/{monitor_id}/validate
# operationId: ValidateExistingMonitor
# --assets item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
# --creator shape: {email?: string, handle?: string, name?: string}
# --matching_downtimes item shape: {end?: int, scope?: list, start?: int}
# --options shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
# --state shape: {groups?: record}
export def "monitor-validate ValidateExistingMonitor" [
  monitor_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets: list # The list of monitor assets tied to a monitor, which represents key links for users to take action on monitor alerts (for example, runbooks). — item shape: {category: "runbook", name: string, resource_key?: string, resource_type?: "notebook", url: string}
  --draft-status: string@draft-status-completer # Indicates whether the monitor is in a draft or published state.  `draft`: The monitor appears as Draft and does not send notifications. `published`: The monitor is active and evaluates conditions and notify as configured.  This field is in preview. The draft value is only available to customers with the feature enabled. (default: published)
  --matching-downtimes: list # A list of active v1 downtimes that match this monitor. — item shape: {end?: int, scope?: list, start?: int}
  --message: string # A message to include with notifications for this monitor.
  --name: string # The monitor name. (e.g. My monitor)
  --options: record # List of options associated with your monitor. — shape: {enable_logs_sample?: bool, enable_samples?: bool, escalation_message?: string, evaluation_delay?: int, group_retention_duration?: string, groupby_simple_monitor?: bool, include_tags?: bool, locked?: bool, min_failure_duration?: int, min_location_failed?: int, new_group_delay?: int, new_host_delay?: int, no_data_timeframe?: int, notification_preset_name?: "show_all"|"hide_query"|"hide_handles"|"hide_all"|"hide_query_and_handles"|"show_only_snapshot"|"hide_handles_and_footer", notify_audit?: bool, notify_by?: list, notify_no_data?: bool, on_missing_data?: "default"|"show_no_data"|"show_and_notify_no_data"|"resolve", renotify_interval?: int, renotify_occurrences?: int, renotify_statuses?: list, require_full_window?: bool, scheduling_options?: record, silenced?: record, synthetics_check_id?: string, threshold_windows?: record, thresholds?: record, timeout_h?: int, variables?: list}
  --priority: int # Integer from 1 (high) to 5 (low) indicating alert severity. (nullable, format: int64)
  --body-query: string # The monitor query. (e.g. avg(last_5m):sum:system.net.bytes_rcvd{host:host0} > 100)
  --restricted-roles: list # A list of unique role identifiers to define which roles are allowed to edit the monitor. The unique identifiers for all roles can be pulled from the [Roles API](https://docs.datadoghq.com/api/latest/roles/#list-roles) and are located in the `data.id` field. Editing a monitor includes any updates to the monitor configuration, monitor deletion, and muting of the monitor for any amount of time. You can use the [Restriction Policies API](https://docs.datadoghq.com/api/latest/restriction-policies/) to manage write authorization for individual monitors by teams and users, in addition to roles. (nullable)
  --tags: list # Tags associated to your monitor.
  type: string@type-completer # The type of the monitor. For more information about `type`, see the [monitor options](https://docs.datadoghq.com/monitors/guide/monitor_api_options/) docs. (e.g. query alert)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/monitor/($monitor_id)/validate")
  let body = {assets: $assets, draft_status: $draft_status, matching_downtimes: $matching_downtimes, message: $message, name: $name, options: $options, priority: $priority, query: $body_query, restricted_roles: $restricted_roles, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of available monthly custom reports
#
# GET /api/v1/monthly_custom_reports
# DEPRECATED
# operationId: GetMonthlyCustomReports
@deprecated
export def "monthly-custom-reports GetMonthlyCustomReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pagesize: int # The number of files to return in the response `[default=60].` (format: int64)
  --pagenumber: int # The identifier of the first page to return. This parameter is used for the pagination feature `[default=0]`. (format: int64)
  --sort-dir: string@sort-dir-completer # The direction to sort by: `[desc, asc]`. (default: desc)
  --qp-sort: string@sort-completer # The field to sort by: `[computed_on, size, start_date, end_date]`. (default: start_date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "page[number]" $pagenumber "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/monthly_custom_reports" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specified monthly custom reports
#
# GET /api/v1/monthly_custom_reports/{report_id}
# DEPRECATED
# operationId: GetSpecifiedMonthlyCustomReports
@deprecated
export def "monthly-custom-reports GetSpecifiedMonthlyCustomReports" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/monthly_custom_reports/($report_id)")
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all notebooks
#
# GET /api/v1/notebooks
# operationId: ListNotebooks
export def "notebooks ListNotebooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author-handle: string # Return notebooks created by the given `author_handle`. (e.g. test@datadoghq.com)
  --exclude-author-handle: string # Return notebooks not created by the given `author_handle`. (e.g. test@datadoghq.com)
  --start: int # The index of the first notebook you want returned. (format: int64, e.g. 0)
  --count: int # The number of notebooks to be returned. (format: int64, default: 100, e.g. 5)
  --sort-field: string # Sort by field `modified`, `name`, or `created`. (default: modified, e.g. modified)
  --sort-dir: string # Sort by direction `asc` or `desc`. (default: desc, e.g. desc)
  --qp-query: string # Return only notebooks with `query` string in notebook name or author handle. (e.g. postmortem)
  --include-cells: string@bool-completer # Value of `false` excludes the `cells` and global `time` for each notebook. (default: true, e.g. false)
  --is-template: string@bool-completer # True value returns only template notebooks. Default is false (returns only non-template notebooks). (default: false, e.g. false)
  --type: string # If type is provided, returns only notebooks with that metadata type. Default does not have type filtering. (e.g. investigation)
]: nothing -> record<data: table<attributes: record, id: int, type: string>, meta: record<page: record<total_count: int, total_filtered_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "author_handle" $author_handle "scalar") (serialize-qp "exclude_author_handle" $exclude_author_handle "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_dir" $sort_dir "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "include_cells" $include_cells "scalar") (serialize-qp "is_template" $is_template "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notebooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a notebook
#
# POST /api/v1/notebooks
# operationId: CreateNotebook
# --data shape: {attributes: record, type: "notebooks"}
export def "notebooks CreateNotebook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # The data for a notebook create request. — shape: {attributes: record, type: "notebooks"}
]: any -> record<data: record<attributes: record<author: record, cells: list, created: string, metadata: record, modified: string, name: string, status: string, time: any>, id: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notebooks")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a notebook
#
# DELETE /api/v1/notebooks/{notebook_id}
# operationId: DeleteNotebook
export def "notebooks DeleteNotebook" [
  notebook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notebooks/($notebook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a notebook
#
# GET /api/v1/notebooks/{notebook_id}
# operationId: GetNotebook
export def "notebooks GetNotebook" [
  notebook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<author: record, cells: list, created: string, metadata: record, modified: string, name: string, status: string, time: any>, id: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notebooks/($notebook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a notebook
#
# PUT /api/v1/notebooks/{notebook_id}
# operationId: UpdateNotebook
# --data shape: {attributes: record, type: "notebooks"}
export def "notebooks UpdateNotebook" [
  notebook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # The data for a notebook update request. — shape: {attributes: record, type: "notebooks"}
]: any -> record<data: record<attributes: record<author: record, cells: list, created: string, metadata: record, modified: string, name: string, status: string, time: any>, id: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notebooks/($notebook_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List your managed organizations
#
# GET /api/v1/org
# operationId: ListOrgs
export def "org ListOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<orgs: table<billing: record, created: string, description: string, name: string, public_id: string, settings: record, subscription: record, trial: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/org")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a child organization
#
# POST /api/v1/org
# operationId: CreateChildOrg
# --billing shape: {type?: string}
# --subscription shape: {type?: string}
@deprecated --flag billing
@deprecated --flag subscription
export def "org CreateChildOrg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billing: record # A JSON array of billing type. (DEPRECATED, e.g. {type: parent_billing}) — shape: {type?: string}
  name: string # The name of the new child-organization, limited to 32 characters. (e.g. New child org)
  --subscription: record # Subscription definition. (DEPRECATED, e.g. {type: pro}) — shape: {type?: string}
]: any -> record<api_key: record<created: string, created_by: string, key: string, name: string>, application_key: record<hash: string, name: string, owner: string>, org: record<billing: record<type: string>, created: string, description: string, name: string, public_id: string, settings: record<private_widget_share: bool, saml: record, saml_autocreate_access_role: string, saml_autocreate_users_domains: record, saml_can_be_enabled: bool, saml_idp_endpoint: string, saml_idp_initiated_login: record, saml_idp_metadata_uploaded: bool, saml_login_url: string, saml_strict_mode: record>, subscription: record<type: string>, trial: bool>, user: record<access_role: string, disabled: bool, email: string, handle: string, icon: string, name: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/org")
  let body = {billing: $billing, name: $name, subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization information
#
# GET /api/v1/org/{public_id}
# operationId: GetOrg
export def "org GetOrg" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<org: record<billing: record<type: string>, created: string, description: string, name: string, public_id: string, settings: record<private_widget_share: bool, saml: record, saml_autocreate_access_role: string, saml_autocreate_users_domains: record, saml_can_be_enabled: bool, saml_idp_endpoint: string, saml_idp_initiated_login: record, saml_idp_metadata_uploaded: bool, saml_login_url: string, saml_strict_mode: record>, subscription: record<type: string>, trial: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/org/($public_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update your organization
#
# PUT /api/v1/org/{public_id}
# operationId: UpdateOrg
# --billing shape: {type?: string}
# --settings shape: {private_widget_share?: bool, saml?: record, saml_autocreate_access_role?: "st"|"adm"|"ro"|"ERROR", saml_autocreate_users_domains?: record, saml_can_be_enabled?: bool, saml_idp_endpoint?: string, saml_idp_initiated_login?: record, saml_idp_metadata_uploaded?: bool, saml_login_url?: string, saml_strict_mode?: record}
# --subscription shape: {type?: string}
@deprecated --flag billing
@deprecated --flag subscription
export def "org UpdateOrg" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billing: record # A JSON array of billing type. (DEPRECATED, e.g. {type: parent_billing}) — shape: {type?: string}
  --description: string # Description of the organization. (e.g. some description)
  --name: string # The name of the child organization, limited to 32 characters. (e.g. New child org)
  --body-public-id: string # The `public_id` of the organization you are operating within. (e.g. abcdef12345)
  --settings: record # A JSON array of settings. — shape: {private_widget_share?: bool, saml?: record, saml_autocreate_access_role?: "st"|"adm"|"ro"|"ERROR", saml_autocreate_users_domains?: record, saml_can_be_enabled?: bool, saml_idp_endpoint?: string, saml_idp_initiated_login?: record, saml_idp_metadata_uploaded?: bool, saml_login_url?: string, saml_strict_mode?: record}
  --subscription: record # Subscription definition. (DEPRECATED, e.g. {type: pro}) — shape: {type?: string}
  --trial: string@bool-completer # Only available for MSP customers. Allows child organizations to be created on a trial plan. (e.g. false)
]: any -> record<org: record<billing: record<type: string>, created: string, description: string, name: string, public_id: string, settings: record<private_widget_share: bool, saml: record, saml_autocreate_access_role: string, saml_autocreate_users_domains: record, saml_can_be_enabled: bool, saml_idp_endpoint: string, saml_idp_initiated_login: record, saml_idp_metadata_uploaded: bool, saml_login_url: string, saml_strict_mode: record>, subscription: record<type: string>, trial: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/org/($public_id)")
  let body = {billing: $billing, description: $description, name: $name, public_id: $body_public_id, settings: $settings, subscription: $subscription, trial: $trial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Spin-off Child Organization
#
# POST /api/v1/org/{public_id}/downgrade
# operationId: DowngradeOrg
export def "org-downgrade DowngradeOrg" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/org/($public_id)/downgrade")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload IdP metadata
#
# POST /api/v1/org/{public_id}/idp_metadata
# operationId: UploadIdPForOrg
export def "org-idp-metadata UploadIdPForOrg" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idp_file: string # The path to the XML metadata file you wish to upload. (format: binary, e.g. )
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/org/($public_id)/idp_metadata")
  let body = {idp_file: $idp_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Query timeseries points
#
# GET /api/v1/query
# operationId: QueryMetrics
export def "query QueryMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # Start of the queried time period, seconds since the Unix epoch. (format: int64)
  --qp-to: int # End of the queried time period, seconds since the Unix epoch. (format: int64)
  --qp-query: string # Query string.
]: nothing -> record<error: string, from_date: int, group_by: list<string>, message: string, query: string, res_type: string, series: table<aggr: string, display_name: string, end: int, expression: string, interval: int, length: int, metric: string, pointlist: list, query_index: int, scope: string, start: int, tag_set: list, unit: list>, status: string, to_date: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search metrics
#
# GET /api/v1/search
# DEPRECATED
# operationId: ListMetrics
@deprecated
export def "search ListMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to search metrics upon. Can optionally be prefixed with `metrics:`.
]: nothing -> record<results: record<metrics: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a security signal to an incident
#
# PATCH /api/v1/security_analytics/signals/{signal_id}/add_to_incident
# operationId: AddSecurityMonitoringSignalToIncident
export def "security-analytics-signals-add-to-incident AddSecurityMonitoringSignalToIncident" [
  signal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --add-to-signal-timeline: string@bool-completer # Whether to post the signal on the incident timeline.
  incident_id: int # Public ID attribute of the incident to which the signal will be added. (format: int64, e.g. 2066)
  --version: int # Version of the updated signal. If server side version is higher, update will be rejected. (format: int64, e.g. 0)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/security_analytics/signals/($signal_id)/add_to_incident")
  let body = {add_to_signal_timeline: $add_to_signal_timeline, incident_id: $incident_id, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modify the triage assignee of a security signal
#
# PATCH /api/v1/security_analytics/signals/{signal_id}/assignee
# DEPRECATED
# operationId: EditSecurityMonitoringSignalAssignee
@deprecated
export def "security-analytics-signals-assignee EditSecurityMonitoringSignalAssignee" [
  signal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  assignee: string # The UUID of the user being assigned. Use empty string to return signal to unassigned. (e.g. 773b045d-ccf8-4808-bd3b-955ef6a8c940)
  --version: int # Version of the updated signal. If server side version is higher, update will be rejected. (format: int64, e.g. 0)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/security_analytics/signals/($signal_id)/assignee")
  let body = {assignee: $assignee, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change the triage state of a security signal
#
# PATCH /api/v1/security_analytics/signals/{signal_id}/state
# DEPRECATED
# operationId: EditSecurityMonitoringSignalState
@deprecated
export def "security-analytics-signals-state EditSecurityMonitoringSignalState" [
  signal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archiveComment: string # Optional comment to explain why a signal is being archived.
  --archiveReason: string@archiveReason-completer # Reason why a signal has been archived.
  state: string@state-completer # The new triage state of the signal. (e.g. open)
  --version: int # Version of the updated signal. If server side version is higher, update will be rejected. (format: int64, e.g. 0)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/security_analytics/signals/($signal_id)/state")
  let body = {archiveComment: $archiveComment, archiveReason: $archiveReason, state: $state, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit metrics
#
# POST /api/v1/series
# operationId: SubmitMetrics
export def "series SubmitMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Encoding: string@Content-Encoding-completer-1 # HTTP header used to compress the media-type. (e.g. deflate)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/series")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/json" $body
}

# Get all SLOs
#
# GET /api/v1/slo
# operationId: ListSLOs
export def "slo ListSLOs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of the IDs of the service level objectives objects. (e.g. id1, id2, id3)
  --qp-query: string # The query string to filter results based on SLO names. (e.g. monitor)
  --tags-query: string # The query string to filter results based on a single SLO tag. (e.g. env:prod)
  --metrics-query: string # The query string to filter results based on SLO numerator and denominator. (e.g. aws.elb.request_count)
  --limit: int # The number of SLOs to return in the response. (format: int64, default: 1000)
  --offset: int # The specific offset to use as the beginning of the returned response. (format: int64)
]: nothing -> record<data: table<created_at: int, creator: record, description: string, groups: list, id: string, modified_at: int, monitor_ids: list, monitor_tags: list, name: string, query: record, sli_specification: any, tags: list, target_threshold: float, thresholds: list, timeframe: string, type: string, warning_threshold: float>, errors: list<string>, metadata: record<page: record<total_count: int, total_filtered_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "tags_query" $tags_query "scalar") (serialize-qp "metrics_query" $metrics_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/slo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SLO object
#
# POST /api/v1/slo
# operationId: CreateSLO
# --query shape: {denominator: string, numerator: string}
# --thresholds item shape: {target: float, target_display?: string, timeframe: "7d"|"30d"|"90d"|"custom", warning?: float, warning_display?: string}
export def "slo CreateSLO" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A user-defined description of the service level objective.  Always included in service level objective responses (but may be `null`). Optional in create/update requests. (nullable)
  --groups: list # A list of (up to 100) monitor groups that narrow the scope of a monitor service level objective.  Included in service level objective responses if it is not empty. Optional in create/update requests for monitor service level objectives, but may only be used when then length of the `monitor_ids` field is one. (e.g. [env:prod, role:mysql])
  --monitor-ids: list # A list of monitor IDs that defines the scope of a monitor service level objective. **Required if type is `monitor`**.
  name: string # The name of the service level objective object. (e.g. Custom Metric SLO)
  --body-query: record # A count-based (metric) SLO query. This field is superseded by `sli_specification` but is retained for backwards compatibility. Note that Datadog only allows the sum by aggregator to be used because this will sum up all request counts instead of averaging them, or taking the max or min of all of those requests. — shape: {denominator: string, numerator: string}
  --sli-specification: any # A generic SLI specification. This is used for time-slice and count-based (metric) SLOs only.
  --tags: list # A list of tags associated with this service level objective. Always included in service level objective responses (but may be empty). Optional in create/update requests. (e.g. [env:prod, app:core])
  --target-threshold: float # The target threshold such that when the service level indicator is above this threshold over the given timeframe, the objective is being met. (format: double, e.g. 99.9)
  thresholds: list # The thresholds (timeframes and associated targets) for this service level objective object. (e.g. [{target: 95, timeframe: 7d}, {target: 95, timeframe: 30d, warning: 97}]) — item shape: {target: float, target_display?: string, timeframe: "7d"|"30d"|"90d"|"custom", warning?: float, warning_display?: string}
  --timeframe: string@timeframe-completer # The SLO time window options. Note that "custom" is not a valid option for creating or updating SLOs. It is only used when querying SLO history over custom timeframes. (e.g. 30d)
  type: string@type-completer-1 # The type of the service level objective. (e.g. metric)
  --warning-threshold: float # The optional warning threshold such that when the service level indicator is below this value for the given threshold, but above the target threshold, the objective appears in a "warning" state. This value must be greater than the target threshold. (format: double, e.g. 99.95)
]: any -> record<data: table<created_at: int, creator: record, description: string, groups: list, id: string, modified_at: int, monitor_ids: list, monitor_tags: list, name: string, query: record, sli_specification: any, tags: list, target_threshold: float, thresholds: list, timeframe: string, type: string, warning_threshold: float>, errors: list<string>, metadata: record<page: record<total_count: int, total_filtered_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/slo")
  let body = {description: $description, groups: $groups, monitor_ids: $monitor_ids, name: $name, query: $body_query, sli_specification: $sli_specification, tags: $tags, target_threshold: $target_threshold, thresholds: $thresholds, timeframe: $timeframe, type: $type, warning_threshold: $warning_threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete SLO Timeframes
#
# POST /api/v1/slo/bulk_delete
# operationId: DeleteSLOTimeframeInBulk
export def "slo-bulk-delete DeleteSLOTimeframeInBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: record<deleted: list<string>, updated: list<string>>, errors: table<id: string, message: string, timeframe: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/slo/bulk_delete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if SLOs can be safely deleted
#
# GET /api/v1/slo/can_delete
# operationId: CheckCanDeleteSLO
export def "slo-can-delete CheckCanDeleteSLO" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of the IDs of the service level objectives objects. (e.g. id1, id2, id3)
]: nothing -> record<data: record<ok: list<string>>, errors: record> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/slo/can_delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all SLO corrections
#
# GET /api/v1/slo/correction
# operationId: ListSLOCorrection
export def "slo-correction ListSLOCorrection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The specific offset to use as the beginning of the returned response. (format: int64)
  --limit: int # The number of SLO corrections to return in the response. Default is 25. (format: int64, default: 25)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, meta: record<page: record<total_count: int, total_filtered_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/slo/correction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SLO correction
#
# POST /api/v1/slo/correction
# operationId: CreateSLOCorrection
# --data shape: {attributes?: record, type: "correction"}
export def "slo-correction CreateSLOCorrection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # The data object associated with the SLO correction to be created. — shape: {attributes?: record, type: "correction"}
]: any -> record<data: record<attributes: record<category: string, created_at: int, creator: record, description: string, duration: int, end: int, modified_at: int, modifier: record, rrule: string, slo_id: string, slo_query: string, start: int, timezone: string>, id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/slo/correction")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SLO correction
#
# DELETE /api/v1/slo/correction/{slo_correction_id}
# operationId: DeleteSLOCorrection
export def "slo-correction DeleteSLOCorrection" [
  slo_correction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/slo/correction/($slo_correction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SLO correction for an SLO
#
# GET /api/v1/slo/correction/{slo_correction_id}
# operationId: GetSLOCorrection
export def "slo-correction GetSLOCorrection" [
  slo_correction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<attributes: record<category: string, created_at: int, creator: record, description: string, duration: int, end: int, modified_at: int, modifier: record, rrule: string, slo_id: string, slo_query: string, start: int, timezone: string>, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/slo/correction/($slo_correction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SLO correction
#
# PATCH /api/v1/slo/correction/{slo_correction_id}
# operationId: UpdateSLOCorrection
# --data shape: {attributes?: record, type?: "correction"}
export def "slo-correction UpdateSLOCorrection" [
  slo_correction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # The data object associated with the SLO correction to be updated. — shape: {attributes?: record, type?: "correction"}
]: any -> record<data: record<attributes: record<category: string, created_at: int, creator: record, description: string, duration: int, end: int, modified_at: int, modifier: record, rrule: string, slo_id: string, slo_query: string, start: int, timezone: string>, id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/slo/correction/($slo_correction_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for SLOs
#
# GET /api/v1/slo/search
# operationId: SearchSLO
export def "slo-search SearchSLO" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The query string to filter results based on SLO names. Some examples of queries include `service:<service-name>` and `<slo-name>`.
  --pagesize: int # The number of files to return in the response `[default=10]`. (format: int64)
  --pagenumber: int # The identifier of the first page to return. This parameter is used for the pagination feature `[default=0]`. (format: int64)
  --include-facets: string@bool-completer # Whether or not to return facet information in the response `[default=false]`.
]: nothing -> record<data: record<attributes: record<facets: record, slos: list>, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>, meta: record<pagination: record<first_number: int, last_number: int, next_number: int, number: int, prev_number: int, size: int, total: int, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "page[number]" $pagenumber "scalar") (serialize-qp "include_facets" $include_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/slo/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an SLO
#
# DELETE /api/v1/slo/{slo_id}
# operationId: DeleteSLO
export def "slo DeleteSLO" [
  slo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string # Delete the monitor even if it's referenced by other resources (for example SLO, composite monitor).
]: nothing -> record<data: list<string>, errors: record> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/slo/($slo_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SLO's details
#
# GET /api/v1/slo/{slo_id}
# operationId: GetSLO
export def "slo GetSLO" [
  slo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-configured-alert-ids: string@bool-completer # Get the IDs of SLO monitors that reference this SLO. (e.g. true)
]: nothing -> record<data: record<configured_alert_ids: list<int>, created_at: int, creator: record<email: string, handle: string, name: string>, description: string, groups: list<string>, id: string, modified_at: int, monitor_ids: list<int>, monitor_tags: list<string>, name: string, query: record<denominator: string, numerator: string>, sli_specification: any, tags: list<string>, target_threshold: float, thresholds: list<record>, timeframe: string, type: string, warning_threshold: float>, errors: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_configured_alert_ids" $with_configured_alert_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/slo/($slo_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SLO
#
# PUT /api/v1/slo/{slo_id}
# operationId: UpdateSLO
# --creator shape: {email?: string, handle?: string, name?: string}
# --query shape: {denominator: string, numerator: string}
# --thresholds item shape: {target: float, target_display?: string, timeframe: "7d"|"30d"|"90d"|"custom", warning?: float, warning_display?: string}
export def "slo UpdateSLO" [
  slo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A user-defined description of the service level objective.  Always included in service level objective responses (but may be `null`). Optional in create/update requests. (nullable)
  --groups: list # A list of (up to 100) monitor groups that narrow the scope of a monitor service level objective.  Included in service level objective responses if it is not empty. Optional in create/update requests for monitor service level objectives, but may only be used when then length of the `monitor_ids` field is one. (e.g. [env:prod, role:mysql])
  --monitor-ids: list # A list of monitor ids that defines the scope of a monitor service level objective. **Required if type is `monitor`**.
  --monitor-tags: list # The union of monitor tags for all monitors referenced by the `monitor_ids` field. Always included in service level objective responses for monitor-based service level objectives (but may be empty). Ignored in create/update requests. Does not affect which monitors are included in the service level objective (that is determined entirely by the `monitor_ids` field).
  name: string # The name of the service level objective object. (e.g. Custom Metric SLO)
  --body-query: record # A count-based (metric) SLO query. This field is superseded by `sli_specification` but is retained for backwards compatibility. Note that Datadog only allows the sum by aggregator to be used because this will sum up all request counts instead of averaging them, or taking the max or min of all of those requests. — shape: {denominator: string, numerator: string}
  --sli-specification: any # A generic SLI specification. This is used for time-slice and count-based (metric) SLOs only.
  --tags: list # A list of tags associated with this service level objective. Always included in service level objective responses (but may be empty). Optional in create/update requests. (e.g. [env:prod, app:core])
  --target-threshold: float # The target threshold such that when the service level indicator is above this threshold over the given timeframe, the objective is being met. (format: double, e.g. 99.9)
  thresholds: list # The thresholds (timeframes and associated targets) for this service level objective object. (e.g. [{target: 95, timeframe: 7d}, {target: 95, timeframe: 30d, warning: 97}]) — item shape: {target: float, target_display?: string, timeframe: "7d"|"30d"|"90d"|"custom", warning?: float, warning_display?: string}
  --timeframe: string@timeframe-completer # The SLO time window options. Note that "custom" is not a valid option for creating or updating SLOs. It is only used when querying SLO history over custom timeframes. (e.g. 30d)
  type: string@type-completer-1 # The type of the service level objective. (e.g. metric)
  --warning-threshold: float # The optional warning threshold such that when the service level indicator is below this value for the given threshold, but above the target threshold, the objective appears in a "warning" state. This value must be greater than the target threshold. (format: double, e.g. 99.95)
]: any -> record<data: table<created_at: int, creator: record, description: string, groups: list, id: string, modified_at: int, monitor_ids: list, monitor_tags: list, name: string, query: record, sli_specification: any, tags: list, target_threshold: float, thresholds: list, timeframe: string, type: string, warning_threshold: float>, errors: list<string>, metadata: record<page: record<total_count: int, total_filtered_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/slo/($slo_id)")
  let body = {description: $description, groups: $groups, monitor_ids: $monitor_ids, monitor_tags: $monitor_tags, name: $name, query: $body_query, sli_specification: $sli_specification, tags: $tags, target_threshold: $target_threshold, thresholds: $thresholds, timeframe: $timeframe, type: $type, warning_threshold: $warning_threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Corrections For an SLO
#
# GET /api/v1/slo/{slo_id}/corrections
# operationId: GetSLOCorrections
export def "slo-corrections GetSLOCorrections" [
  slo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<attributes: record, id: string, type: string>, meta: record<page: record<total_count: int, total_filtered_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/slo/($slo_id)/corrections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SLO's history
#
# GET /api/v1/slo/{slo_id}/history
# operationId: GetSLOHistory
export def "slo-history GetSLOHistory" [
  slo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --from-ts: int # The `from` timestamp for the query window in epoch seconds. (format: int64)
  --to-ts: int # The `to` timestamp for the query window in epoch seconds. (format: int64)
  --target: float # The SLO target. If `target` is passed in, the response will include the remaining error budget and a timeframe value of `custom`. (format: double)
  --apply-correction: string@bool-completer # Defaults to `true`. If any SLO corrections are applied and this parameter is set to `false`, then the corrections will not be applied and the SLI values will not be affected.
]: nothing -> record<data: record<from_ts: int, group_by: list<string>, groups: list<record>, monitors: list<record>, overall: record<error_budget_remaining: record, errors: list, group: string, history: list, monitor_modified: int, monitor_type: string, name: string, precision: record, preview: bool, sli_value: float, span_precision: float, uptime: float>, series: record<denominator: record, interval: int, message: string, numerator: record, query: string, res_type: string, resp_version: int, times: list>, thresholds: record, to_ts: int, type: string, type_id: int>, errors: table<error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_ts" $from_ts "scalar") (serialize-qp "to_ts" $to_ts "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "apply_correction" $apply_correction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/slo/($slo_id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of batch
#
# GET /api/v1/synthetics/ci/batch/{batch_id}
# operationId: GetSyntheticsCIBatch
export def "synthetics-ci-batch GetSyntheticsCIBatch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<metadata: record<ci: record, git: record>, results: list<record>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/ci/batch/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all locations (public and private)
#
# GET /api/v1/synthetics/locations
# operationId: ListLocations
export def "synthetics-locations ListLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locations: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/locations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a private location
#
# POST /api/v1/synthetics/private-locations
# operationId: CreatePrivateLocation
# --metadata shape: {restricted_roles?: list}
# --secrets shape: {authentication?: record, config_decryption?: record}
export def "synthetics-private-locations CreatePrivateLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Description of the private location. (e.g. Description of private location)
  --metadata: record # Object containing metadata about the private location. — shape: {restricted_roles?: list}
  name: string # Name of the private location. (e.g. New private location)
  tags: list # Array of tags attached to the private location. (e.g. [team:front])
]: any -> record<config: record, private_location: record<description: string, id: string, metadata: record<restricted_roles: list>, name: string, secrets: record<authentication: record, config_decryption: record>, tags: list<string>>, result_encryption: record<id: string, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/private-locations")
  let body = {description: $description, metadata: $metadata, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a private location
#
# DELETE /api/v1/synthetics/private-locations/{location_id}
# operationId: DeletePrivateLocation
export def "synthetics-private-locations DeletePrivateLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/private-locations/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a private location
#
# GET /api/v1/synthetics/private-locations/{location_id}
# operationId: GetPrivateLocation
export def "synthetics-private-locations GetPrivateLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, id: string, metadata: record<restricted_roles: list<string>>, name: string, secrets: record<authentication: record<id: string, key: string>, config_decryption: record<key: string>>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/private-locations/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a private location
#
# PUT /api/v1/synthetics/private-locations/{location_id}
# operationId: UpdatePrivateLocation
# --metadata shape: {restricted_roles?: list}
# --secrets shape: {authentication?: record, config_decryption?: record}
export def "synthetics-private-locations UpdatePrivateLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Description of the private location. (e.g. Description of private location)
  --metadata: record # Object containing metadata about the private location. — shape: {restricted_roles?: list}
  name: string # Name of the private location. (e.g. New private location)
  tags: list # Array of tags attached to the private location. (e.g. [team:front])
]: any -> record<description: string, id: string, metadata: record<restricted_roles: list<string>>, name: string, secrets: record<authentication: record<id: string, key: string>, config_decryption: record<key: string>>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/private-locations/($location_id)")
  let body = {description: $description, metadata: $metadata, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the default locations
#
# GET /api/v1/synthetics/settings/default_locations
# operationId: GetSyntheticsDefaultLocations
export def "synthetics-settings-default-locations GetSyntheticsDefaultLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/settings/default_locations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of all Synthetic tests
#
# GET /api/v1/synthetics/tests
# operationId: ListTests
export def "synthetics-tests ListTests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Used for pagination. The number of tests returned in the page. (format: int64, default: 100)
  --page-number: int # Used for pagination. Which page you want to retrieve. Starts at zero. (format: int64)
]: nothing -> record<tests: table<config: record, creator: record, locations: list, message: string, monitor_id: int, name: string, options: record, public_id: string, status: string, subtype: string, tags: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/synthetics/tests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API test
#
# POST /api/v1/synthetics/tests/api
# operationId: CreateSyntheticsAPITest
# --config shape: {assertions?: list, configVariables?: list, request?: record, steps?: list, variablesFromScript?: string}
# --options shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
export def "synthetics-tests CreateSyntheticsAPITest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # Configuration object for a Synthetic API test. (e.g. {assertions: [{operator: lessThan, target: 1000, type: responseTime}], request: {method: GET, url: https://example.com}}) — shape: {assertions?: list, configVariables?: list, request?: record, steps?: list, variablesFromScript?: string}
  locations: list # Array of locations used to run the test. (e.g. [aws:eu-west-3])
  message: string # Notification message associated with the test. (e.g. Notification message)
  name: string # Name of the test. (e.g. Example test name)
  options: record # Object describing the extra options for a Synthetic test. — shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
  --status: string@status-completer-1 # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
  --subtype: string@subtype-completer # The subtype of the Synthetic API test, `http`, `ssl`, `tcp`, `dns`, `icmp`, `udp`, `websocket`, `grpc` or `multi`. (e.g. http)
  --tags: list # Array of tags attached to the test. (e.g. [env:production])
  type: string@type-completer-2 # Type of the Synthetic test, `api`. (default: api, e.g. api)
]: any -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, steps: list<any>, variablesFromScript: string>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, subtype: string, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/api")
  let body = {config: $config, locations: $locations, message: $message, name: $name, options: $options, status: $status, subtype: $subtype, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an API test
#
# GET /api/v1/synthetics/tests/api/{public_id}
# operationId: GetAPITest
export def "synthetics-tests GetAPITest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, steps: list<any>, variablesFromScript: string>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, subtype: string, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/api/($public_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an API test
#
# PUT /api/v1/synthetics/tests/api/{public_id}
# operationId: UpdateAPITest
# --config shape: {assertions?: list, configVariables?: list, request?: record, steps?: list, variablesFromScript?: string}
# --options shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
export def "synthetics-tests UpdateAPITest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # Configuration object for a Synthetic API test. (e.g. {assertions: [{operator: lessThan, target: 1000, type: responseTime}], request: {method: GET, url: https://example.com}}) — shape: {assertions?: list, configVariables?: list, request?: record, steps?: list, variablesFromScript?: string}
  locations: list # Array of locations used to run the test. (e.g. [aws:eu-west-3])
  message: string # Notification message associated with the test. (e.g. Notification message)
  name: string # Name of the test. (e.g. Example test name)
  options: record # Object describing the extra options for a Synthetic test. — shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
  --status: string@status-completer-1 # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
  --subtype: string@subtype-completer # The subtype of the Synthetic API test, `http`, `ssl`, `tcp`, `dns`, `icmp`, `udp`, `websocket`, `grpc` or `multi`. (e.g. http)
  --tags: list # Array of tags attached to the test. (e.g. [env:production])
  type: string@type-completer-2 # Type of the Synthetic test, `api`. (default: api, e.g. api)
]: any -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, steps: list<any>, variablesFromScript: string>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, subtype: string, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/api/($public_id)")
  let body = {config: $config, locations: $locations, message: $message, name: $name, options: $options, status: $status, subtype: $subtype, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a browser test
#
# POST /api/v1/synthetics/tests/browser
# operationId: CreateSyntheticsBrowserTest
# --config shape: {assertions: list, configVariables?: list, request: record, setCookie?: string, variables?: list}
# --options shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
# --steps item shape: {allowFailure?: bool, alwaysExecute?: bool, exitIfSucceed?: bool, isCritical?: bool, name?: string, noScreenshot?: bool, params?: record, public_id?: string, timeout?: int, type?: "assertCurrentUrl"|"assertElementAttribute"|"assertElementContent"|"assertElementPresent"|"assertEmail"|"assertFileDownload"|"assertFromJavascript"|"assertPageContains"|"assertPageLacks"|"assertRequests"|"click"|"drag"|"drop"|"extractFromJavascript"|"extractFromEmailBody"|"extractVariable"|"goToEmailLink"|"goToUrl"|"goToUrlAndMeasureTti"|"hover"|"playSubTest"|"pressKey"|"refresh"|"runApiTest"|"scroll"|"selectOption"|"typeText"|"uploadFiles"|"wait"}
export def "synthetics-tests-browser CreateSyntheticsBrowserTest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # Configuration object for a Synthetic browser test. — shape: {assertions: list, configVariables?: list, request: record, setCookie?: string, variables?: list}
  locations: list # Array of locations used to run the test. (e.g. [aws:eu-west-3])
  message: string # Notification message associated with the test. Message can either be text or an empty string. (e.g. )
  name: string # Name of the test. (e.g. Example test name)
  options: record # Object describing the extra options for a Synthetic test. — shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
  --status: string@status-completer-1 # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
  --steps: list # Array of steps for the test. — item shape: {allowFailure?: bool, alwaysExecute?: bool, exitIfSucceed?: bool, isCritical?: bool, name?: string, noScreenshot?: bool, params?: record, public_id?: string, timeout?: int, type?: "assertCurrentUrl"|"assertElementAttribute"|"assertElementContent"|"assertElementPresent"|"assertEmail"|"assertFileDownload"|"assertFromJavascript"|"assertPageContains"|"assertPageLacks"|"assertRequests"|"click"|"drag"|"drop"|"extractFromJavascript"|"extractFromEmailBody"|"extractVariable"|"goToEmailLink"|"goToUrl"|"goToUrlAndMeasureTti"|"hover"|"playSubTest"|"pressKey"|"refresh"|"runApiTest"|"scroll"|"selectOption"|"typeText"|"uploadFiles"|"wait"}
  --tags: list # Array of tags attached to the test. (e.g. [env:prod])
  type: string@type-completer-3 # Type of the Synthetic test, `browser`. (default: browser, e.g. browser)
]: any -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, setCookie: string, variables: list<record>>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, steps: table<allowFailure: bool, alwaysExecute: bool, exitIfSucceed: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, public_id: string, timeout: int, type: string>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/browser")
  let body = {config: $config, locations: $locations, message: $message, name: $name, options: $options, status: $status, steps: $steps, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a browser test
#
# GET /api/v1/synthetics/tests/browser/{public_id}
# operationId: GetBrowserTest
export def "synthetics-tests-browser GetBrowserTest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, setCookie: string, variables: list<record>>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, steps: table<allowFailure: bool, alwaysExecute: bool, exitIfSucceed: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, public_id: string, timeout: int, type: string>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/browser/($public_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a browser test
#
# PUT /api/v1/synthetics/tests/browser/{public_id}
# operationId: UpdateBrowserTest
# --config shape: {assertions: list, configVariables?: list, request: record, setCookie?: string, variables?: list}
# --options shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
# --steps item shape: {allowFailure?: bool, alwaysExecute?: bool, exitIfSucceed?: bool, isCritical?: bool, name?: string, noScreenshot?: bool, params?: record, public_id?: string, timeout?: int, type?: "assertCurrentUrl"|"assertElementAttribute"|"assertElementContent"|"assertElementPresent"|"assertEmail"|"assertFileDownload"|"assertFromJavascript"|"assertPageContains"|"assertPageLacks"|"assertRequests"|"click"|"drag"|"drop"|"extractFromJavascript"|"extractFromEmailBody"|"extractVariable"|"goToEmailLink"|"goToUrl"|"goToUrlAndMeasureTti"|"hover"|"playSubTest"|"pressKey"|"refresh"|"runApiTest"|"scroll"|"selectOption"|"typeText"|"uploadFiles"|"wait"}
export def "synthetics-tests-browser UpdateBrowserTest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # Configuration object for a Synthetic browser test. — shape: {assertions: list, configVariables?: list, request: record, setCookie?: string, variables?: list}
  locations: list # Array of locations used to run the test. (e.g. [aws:eu-west-3])
  message: string # Notification message associated with the test. Message can either be text or an empty string. (e.g. )
  name: string # Name of the test. (e.g. Example test name)
  options: record # Object describing the extra options for a Synthetic test. — shape: {accept_self_signed?: bool, allow_insecure?: bool, blockedRequestPatterns?: list, checkCertificateRevocation?: bool, ci?: record, device_ids?: list, disableAiaIntermediateFetching?: bool, disableCors?: bool, disableCsp?: bool, enableProfiling?: bool, enableSecurityTesting?: bool, follow_redirects?: bool, httpVersion?: "http1"|"http2"|"any", ignoreServerCertificateError?: bool, initialNavigationTimeout?: int, min_failure_duration?: int, min_location_failed?: int, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, rumSettings?: record, scheduling?: record, tick_every?: int}
  --status: string@status-completer-1 # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
  --steps: list # Array of steps for the test. — item shape: {allowFailure?: bool, alwaysExecute?: bool, exitIfSucceed?: bool, isCritical?: bool, name?: string, noScreenshot?: bool, params?: record, public_id?: string, timeout?: int, type?: "assertCurrentUrl"|"assertElementAttribute"|"assertElementContent"|"assertElementPresent"|"assertEmail"|"assertFileDownload"|"assertFromJavascript"|"assertPageContains"|"assertPageLacks"|"assertRequests"|"click"|"drag"|"drop"|"extractFromJavascript"|"extractFromEmailBody"|"extractVariable"|"goToEmailLink"|"goToUrl"|"goToUrlAndMeasureTti"|"hover"|"playSubTest"|"pressKey"|"refresh"|"runApiTest"|"scroll"|"selectOption"|"typeText"|"uploadFiles"|"wait"}
  --tags: list # Array of tags attached to the test. (e.g. [env:prod])
  type: string@type-completer-3 # Type of the Synthetic test, `browser`. (default: browser, e.g. browser)
]: any -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, setCookie: string, variables: list<record>>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, steps: table<allowFailure: bool, alwaysExecute: bool, exitIfSucceed: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, public_id: string, timeout: int, type: string>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/browser/($public_id)")
  let body = {config: $config, locations: $locations, message: $message, name: $name, options: $options, status: $status, steps: $steps, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a browser test's latest results summaries
#
# GET /api/v1/synthetics/tests/browser/{public_id}/results
# operationId: GetBrowserTestLatestResults
export def "synthetics-tests-browser-results GetBrowserTestLatestResults" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --from-ts: int # Timestamp in milliseconds from which to start querying results. (format: int64)
  --to-ts: int # Timestamp in milliseconds up to which to query results. (format: int64)
  --probe-dc: list # Locations for which to query results.
]: nothing -> record<last_timestamp_fetched: int, results: table<check_time: float, probe_dc: string, result: record, result_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_ts" $from_ts "scalar") (serialize-qp "to_ts" $to_ts "scalar") (serialize-qp "probe_dc" $probe_dc "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/synthetics/tests/browser/($public_id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a browser test result
#
# GET /api/v1/synthetics/tests/browser/{public_id}/results/{result_id}
# operationId: GetBrowserTestResult
export def "synthetics-tests-browser-results GetBrowserTestResult" [
  public_id: string
  result_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<check: record<config: record<assertions: list, configVariables: list, request: record, variables: list>>, check_time: float, check_version: int, probe_dc: string, result: record<browserType: string, browserVersion: string, device: record<height: int, id: string, isMobile: bool, name: string, width: int>, duration: float, error: string, failure: record<code: string, message: string>, passed: bool, receivedEmailCount: int, startUrl: string, stepDetails: list<record>, thumbnailsBucketKey: bool, timeToInteractive: float>, result_id: string, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/browser/($public_id)/results/($result_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete tests
#
# POST /api/v1/synthetics/tests/delete
# operationId: DeleteTests
export def "synthetics-tests-delete DeleteTests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-delete-dependencies: string@bool-completer # Delete the Synthetic test even if it's referenced by other resources (for example, SLOs and composite monitors). (e.g. false)
  --public-ids: list # An array of Synthetic test IDs you want to delete. (e.g. [])
]: any -> record<deleted_tests: table<deleted_at: string, public_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/delete")
  let body = {force_delete_dependencies: $force_delete_dependencies, public_ids: $public_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a mobile test
#
# POST /api/v1/synthetics/tests/mobile
# operationId: CreateSyntheticsMobileTest
# --config shape: {initialApplicationArguments?: record, variables?: list}
# --options shape: {allowApplicationCrash?: bool, bindings?: list, ci?: record, defaultStepTimeout?: int, device_ids: list, disableAutoAcceptAlert?: bool, min_failure_duration?: int, mobileApplication: record, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, scheduling?: record, tick_every: int, verbosity?: int}
# --steps item shape: {allowFailure?: bool, hasNewStepElement?: bool, isCritical?: bool, name: string, noScreenshot?: bool, params: record, publicId?: string, timeout?: int, type: "assertElementContent"|"assertScreenContains"|"assertScreenLacks"|"doubleTap"|"extractVariable"|"flick"|"openDeeplink"|"playSubTest"|"pressBack"|"restartApplication"|"rotate"|"scroll"|"scrollToElement"|"tap"|"toggleWiFi"|"typeText"|"wait"}
export def "synthetics-tests-mobile CreateSyntheticsMobileTest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # Configuration object for a Synthetic mobile test. — shape: {initialApplicationArguments?: record, variables?: list}
  --device-ids: list # Array with the different device IDs used to run the test.
  message: string # Notification message associated with the test. (e.g. Notification message)
  name: string # Name of the test. (e.g. Example test name)
  options: record # Object describing the extra options for a Synthetic test. — shape: {allowApplicationCrash?: bool, bindings?: list, ci?: record, defaultStepTimeout?: int, device_ids: list, disableAutoAcceptAlert?: bool, min_failure_duration?: int, mobileApplication: record, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, scheduling?: record, tick_every: int, verbosity?: int}
  --status: string@status-completer-1 # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
  --steps: list # Array of steps for the test. — item shape: {allowFailure?: bool, hasNewStepElement?: bool, isCritical?: bool, name: string, noScreenshot?: bool, params: record, publicId?: string, timeout?: int, type: "assertElementContent"|"assertScreenContains"|"assertScreenLacks"|"doubleTap"|"extractVariable"|"flick"|"openDeeplink"|"playSubTest"|"pressBack"|"restartApplication"|"rotate"|"scroll"|"scrollToElement"|"tap"|"toggleWiFi"|"typeText"|"wait"}
  --tags: list # Array of tags attached to the test. (e.g. [env:production])
  type: string@type-completer-4 # Type of the Synthetic test, `mobile`. (default: mobile, e.g. mobile)
]: any -> record<config: record<initialApplicationArguments: record, variables: list<record>>, device_ids: list<string>, message: string, monitor_id: int, name: string, options: record<allowApplicationCrash: bool, bindings: list<record>, ci: record<executionRule: string>, defaultStepTimeout: int, device_ids: list<string>, disableAutoAcceptAlert: bool, min_failure_duration: int, mobileApplication: record<applicationId: string, referenceId: string, referenceType: string>, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, scheduling: record<timeframes: list, timezone: string>, tick_every: int, verbosity: int>, public_id: string, status: string, steps: table<allowFailure: bool, hasNewStepElement: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, publicId: string, timeout: int, type: string>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/mobile")
  let body = {config: $config, device_ids: $device_ids, message: $message, name: $name, options: $options, status: $status, steps: $steps, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a mobile test
#
# GET /api/v1/synthetics/tests/mobile/{public_id}
# operationId: GetMobileTest
export def "synthetics-tests-mobile GetMobileTest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<config: record<initialApplicationArguments: record, variables: list<record>>, device_ids: list<string>, message: string, monitor_id: int, name: string, options: record<allowApplicationCrash: bool, bindings: list<record>, ci: record<executionRule: string>, defaultStepTimeout: int, device_ids: list<string>, disableAutoAcceptAlert: bool, min_failure_duration: int, mobileApplication: record<applicationId: string, referenceId: string, referenceType: string>, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, scheduling: record<timeframes: list, timezone: string>, tick_every: int, verbosity: int>, public_id: string, status: string, steps: table<allowFailure: bool, hasNewStepElement: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, publicId: string, timeout: int, type: string>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/mobile/($public_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a mobile test
#
# PUT /api/v1/synthetics/tests/mobile/{public_id}
# operationId: UpdateMobileTest
# --config shape: {initialApplicationArguments?: record, variables?: list}
# --options shape: {allowApplicationCrash?: bool, bindings?: list, ci?: record, defaultStepTimeout?: int, device_ids: list, disableAutoAcceptAlert?: bool, min_failure_duration?: int, mobileApplication: record, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, scheduling?: record, tick_every: int, verbosity?: int}
# --steps item shape: {allowFailure?: bool, hasNewStepElement?: bool, isCritical?: bool, name: string, noScreenshot?: bool, params: record, publicId?: string, timeout?: int, type: "assertElementContent"|"assertScreenContains"|"assertScreenLacks"|"doubleTap"|"extractVariable"|"flick"|"openDeeplink"|"playSubTest"|"pressBack"|"restartApplication"|"rotate"|"scroll"|"scrollToElement"|"tap"|"toggleWiFi"|"typeText"|"wait"}
export def "synthetics-tests-mobile UpdateMobileTest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # Configuration object for a Synthetic mobile test. — shape: {initialApplicationArguments?: record, variables?: list}
  --device-ids: list # Array with the different device IDs used to run the test.
  message: string # Notification message associated with the test. (e.g. Notification message)
  name: string # Name of the test. (e.g. Example test name)
  options: record # Object describing the extra options for a Synthetic test. — shape: {allowApplicationCrash?: bool, bindings?: list, ci?: record, defaultStepTimeout?: int, device_ids: list, disableAutoAcceptAlert?: bool, min_failure_duration?: int, mobileApplication: record, monitor_name?: string, monitor_options?: record, monitor_priority?: int, noScreenshot?: bool, restricted_roles?: list, retry?: record, scheduling?: record, tick_every: int, verbosity?: int}
  --status: string@status-completer-1 # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
  --steps: list # Array of steps for the test. — item shape: {allowFailure?: bool, hasNewStepElement?: bool, isCritical?: bool, name: string, noScreenshot?: bool, params: record, publicId?: string, timeout?: int, type: "assertElementContent"|"assertScreenContains"|"assertScreenLacks"|"doubleTap"|"extractVariable"|"flick"|"openDeeplink"|"playSubTest"|"pressBack"|"restartApplication"|"rotate"|"scroll"|"scrollToElement"|"tap"|"toggleWiFi"|"typeText"|"wait"}
  --tags: list # Array of tags attached to the test. (e.g. [env:production])
  type: string@type-completer-4 # Type of the Synthetic test, `mobile`. (default: mobile, e.g. mobile)
]: any -> record<config: record<initialApplicationArguments: record, variables: list<record>>, device_ids: list<string>, message: string, monitor_id: int, name: string, options: record<allowApplicationCrash: bool, bindings: list<record>, ci: record<executionRule: string>, defaultStepTimeout: int, device_ids: list<string>, disableAutoAcceptAlert: bool, min_failure_duration: int, mobileApplication: record<applicationId: string, referenceId: string, referenceType: string>, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, scheduling: record<timeframes: list, timezone: string>, tick_every: int, verbosity: int>, public_id: string, status: string, steps: table<allowFailure: bool, hasNewStepElement: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, publicId: string, timeout: int, type: string>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/mobile/($public_id)")
  let body = {config: $config, device_ids: $device_ids, message: $message, name: $name, options: $options, status: $status, steps: $steps, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Synthetic tests
#
# GET /api/v1/synthetics/tests/search
# operationId: SearchTests
export def "synthetics-tests-search SearchTests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The search query.
  --include-full-config: string@bool-completer # If true, include the full configuration for each test in the response.
  --facets-only: string@bool-completer # If true, return only facets instead of full test details.
  --start: int # The offset from which to start returning results. (format: int64, default: 0)
  --count: int # The maximum number of results to return. (format: int64, default: 50)
  --qp-sort: string # The sort order for the results (e.g., `name,asc` or `name,desc`). (default: name,asc)
]: nothing -> record<tests: table<config: record, creator: record, locations: list, message: string, monitor_id: int, name: string, options: record, public_id: string, status: string, subtype: string, tags: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "include_full_config" $include_full_config "scalar") (serialize-qp "facets_only" $facets_only "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/synthetics/tests/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger Synthetic tests
#
# POST /api/v1/synthetics/tests/trigger
# operationId: TriggerTests
# --tests item shape: {metadata?: record, public_id: string}
export def "synthetics-tests-trigger TriggerTests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tests: list # List of Synthetic tests. — item shape: {metadata?: record, public_id: string}
]: any -> record<batch_id: string, locations: table<id: int, name: string>, results: table<device: string, location: int, public_id: string, result_id: string>, triggered_check_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/trigger")
  let body = {tests: $tests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger tests from CI/CD pipelines
#
# POST /api/v1/synthetics/tests/trigger/ci
# operationId: TriggerCITests
# --tests item shape: {allowInsecureCertificates?: bool, basicAuth?: any, body?: string, bodyType?: string, cookies?: string, deviceIds?: list, followRedirects?: bool, headers?: record, locations?: list, metadata?: record, public_id: string, retry?: record, startUrl?: string, variables?: record, version?: int}
export def "synthetics-tests-trigger-ci TriggerCITests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tests: list # List of Synthetic tests with overrides. — item shape: {allowInsecureCertificates?: bool, basicAuth?: any, body?: string, bodyType?: string, cookies?: string, deviceIds?: list, followRedirects?: bool, headers?: record, locations?: list, metadata?: record, public_id: string, retry?: record, startUrl?: string, variables?: record, version?: int}
]: any -> record<batch_id: string, locations: table<id: int, name: string>, results: table<device: string, location: int, public_id: string, result_id: string>, triggered_check_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/trigger/ci")
  let body = {tests: $tests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch uptime for multiple tests
#
# POST /api/v1/synthetics/tests/uptimes
# operationId: FetchUptimes
export def "synthetics-tests-uptimes FetchUptimes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  from_ts: int # Timestamp in seconds (Unix epoch) for the start of uptime. (format: int64, e.g. 0)
  public_ids: list # An array of Synthetic test IDs you want uptimes for. (e.g. [])
  to_ts: int # Timestamp in seconds (Unix epoch) for the end of uptime. (format: int64, e.g. 0)
]: any -> table<from_ts: int, overall: record<errors: list, group: string, history: list, span_precision: float, uptime: float>, public_id: string, to_ts: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/tests/uptimes")
  let body = {from_ts: $from_ts, public_ids: $public_ids, to_ts: $to_ts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a test configuration
#
# GET /api/v1/synthetics/tests/{public_id}
# operationId: GetTest
export def "synthetics-tests GetTest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, variables: list<record>>, creator: record<email: string, handle: string, name: string>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, subtype: string, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/($public_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a Synthetic test
#
# PATCH /api/v1/synthetics/tests/{public_id}
# operationId: PatchTest
# --data item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: any}
export def "synthetics-tests PatchTest" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: list # Array of [JSON Patch](https://jsonpatch.com) operations to perform on the test (e.g. [{op: replace, path: /name, value: New test name}, {op: remove, path: /config/assertions/0}]) — item shape: {op?: "add"|"remove"|"replace"|"move"|"copy"|"test", path?: string, value?: any}
]: any -> record<config: record<assertions: list<any>, configVariables: list<record>, request: record<allow_insecure: bool, basicAuth: any, body: string, bodyType: string, callType: string, certificate: record, certificateDomains: list, checkCertificateRevocation: bool, compressedJsonDescriptor: string, compressedProtoFile: string, disableAiaIntermediateFetching: bool, dnsServer: string, dnsServerPort: any, files: list, follow_redirects: bool, form: record, headers: record, host: string, httpVersion: string, isMessageBase64Encoded: bool, mcpProtocolVersion: string, message: string, metadata: record, method: string, noSavingResponseBody: bool, numberOfPackets: int, persistCookies: bool, port: any, proxy: record, query: record, servername: string, service: string, shouldTrackHops: bool, timeout: float, toolArgs: record, toolName: string, url: string>, variables: list<record>>, creator: record<email: string, handle: string, name: string>, locations: list<string>, message: string, monitor_id: int, name: string, options: record<accept_self_signed: bool, allow_insecure: bool, blockedRequestPatterns: list<string>, checkCertificateRevocation: bool, ci: record<executionRule: string>, device_ids: list<string>, disableAiaIntermediateFetching: bool, disableCors: bool, disableCsp: bool, enableProfiling: bool, enableSecurityTesting: bool, follow_redirects: bool, httpVersion: string, ignoreServerCertificateError: bool, initialNavigationTimeout: int, min_failure_duration: int, min_location_failed: int, monitor_name: string, monitor_options: record<escalation_message: string, notification_preset_name: string, renotify_interval: int, renotify_occurrences: int>, monitor_priority: int, noScreenshot: bool, restricted_roles: list<string>, retry: record<count: int, interval: float>, rumSettings: record<applicationId: string, clientTokenId: int, isEnabled: bool>, scheduling: record<timeframes: list, timezone: string>, tick_every: int>, public_id: string, status: string, steps: table<allowFailure: bool, alwaysExecute: bool, exitIfSucceed: bool, isCritical: bool, name: string, noScreenshot: bool, params: record, public_id: string, timeout: int, type: string>, subtype: string, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/($public_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an API test's latest results summaries
#
# GET /api/v1/synthetics/tests/{public_id}/results
# operationId: GetAPITestLatestResults
export def "synthetics-tests-results GetAPITestLatestResults" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --from-ts: int # Timestamp in milliseconds from which to start querying results. (format: int64)
  --to-ts: int # Timestamp in milliseconds up to which to query results. (format: int64)
  --probe-dc: list # Locations for which to query results.
]: nothing -> record<last_timestamp_fetched: int, results: table<check_time: float, probe_dc: string, result: record, result_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_ts" $from_ts "scalar") (serialize-qp "to_ts" $to_ts "scalar") (serialize-qp "probe_dc" $probe_dc "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/synthetics/tests/($public_id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an API test result
#
# GET /api/v1/synthetics/tests/{public_id}/results/{result_id}
# operationId: GetAPITestResult
export def "synthetics-tests-results GetAPITestResult" [
  public_id: string
  result_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<check: record<config: record<assertions: list, configVariables: list, request: record, variables: list>>, check_time: float, check_version: int, probe_dc: string, result: record<cert: record<cipher: string, exponent: float, extKeyUsage: list, fingerprint: string, fingerprint256: string, issuer: record, modulus: string, protocol: string, serialNumber: string, subject: record, validFrom: string, validTo: string>, eventType: string, failure: record<code: string, message: string>, httpStatusCode: int, requestHeaders: record, responseBody: string, responseHeaders: record, responseSize: int, timings: record<dns: float, download: float, firstByte: float, handshake: float, redirect: float, ssl: float, tcp: float, total: float, wait: float>>, result_id: string, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/($public_id)/results/($result_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause or start a test
#
# PUT /api/v1/synthetics/tests/{public_id}/status
# operationId: UpdateTestPauseStatus
export def "synthetics-tests-status UpdateTestPauseStatus" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --new-status: string@new-status-completer # Define whether you want to start (`live`) or pause (`paused`) a Synthetic test. (e.g. live)
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/tests/($public_id)/status")
  let body = {new_status: $new_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all global variables
#
# GET /api/v1/synthetics/variables
# operationId: ListGlobalVariables
export def "synthetics-variables ListGlobalVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variables: table<attributes: record, description: string, id: string, is_fido: bool, is_totp: bool, name: string, parse_test_options: record, parse_test_public_id: string, tags: list, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a global variable
#
# POST /api/v1/synthetics/variables
# operationId: CreateGlobalVariable
# --attributes shape: {restricted_roles?: list}
# --parse_test_options shape: {field?: string, localVariableName?: string, parser?: record, type: "http_body"|"http_header"|"http_status_code"|"local_variable"}
# --value shape: {options?: record, secure?: bool, value?: string}
export def "synthetics-variables CreateGlobalVariable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: record # Attributes of the global variable. — shape: {restricted_roles?: list}
  description: string # Description of the global variable. (e.g. Example description)
  --is-fido: string@bool-completer # Determines if the global variable is a FIDO variable.
  --is-totp: string@bool-completer # Determines if the global variable is a TOTP/MFA variable.
  name: string # Name of the global variable. Unique across Synthetic global variables. (e.g. MY_VARIABLE)
  --parse-test-options: record # Parser options to use for retrieving a Synthetic global variable from a Synthetic test. Used in conjunction with `parse_test_public_id`. — shape: {field?: string, localVariableName?: string, parser?: record, type: "http_body"|"http_header"|"http_status_code"|"local_variable"}
  --parse-test-public-id: string # A Synthetic test ID to use as a test to generate the variable value. (e.g. abc-def-123)
  tags: list # Tags of the global variable. (e.g. [team:front, test:workflow-1])
  --value: record # Value of the global variable. (e.g. {secure: true, value: value}) — shape: {options?: record, secure?: bool, value?: string}
]: any -> record<attributes: record<restricted_roles: list<string>>, description: string, id: string, is_fido: bool, is_totp: bool, name: string, parse_test_options: record<field: string, localVariableName: string, parser: record<type: string, value: string>, type: string>, parse_test_public_id: string, tags: list<string>, value: record<options: record<totp_parameters: record>, secure: bool, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/synthetics/variables")
  let body = {attributes: $attributes, description: $description, is_fido: $is_fido, is_totp: $is_totp, name: $name, parse_test_options: $parse_test_options, parse_test_public_id: $parse_test_public_id, tags: $tags, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a global variable
#
# DELETE /api/v1/synthetics/variables/{variable_id}
# operationId: DeleteGlobalVariable
export def "synthetics-variables DeleteGlobalVariable" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/variables/($variable_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a global variable
#
# GET /api/v1/synthetics/variables/{variable_id}
# operationId: GetGlobalVariable
export def "synthetics-variables GetGlobalVariable" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attributes: record<restricted_roles: list<string>>, description: string, id: string, is_fido: bool, is_totp: bool, name: string, parse_test_options: record<field: string, localVariableName: string, parser: record<type: string, value: string>, type: string>, parse_test_public_id: string, tags: list<string>, value: record<options: record<totp_parameters: record>, secure: bool, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/variables/($variable_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a global variable
#
# PUT /api/v1/synthetics/variables/{variable_id}
# operationId: EditGlobalVariable
# --attributes shape: {restricted_roles?: list}
# --parse_test_options shape: {field?: string, localVariableName?: string, parser?: record, type: "http_body"|"http_header"|"http_status_code"|"local_variable"}
# --value shape: {options?: record, secure?: bool, value?: string}
export def "synthetics-variables EditGlobalVariable" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: record # Attributes of the global variable. — shape: {restricted_roles?: list}
  description: string # Description of the global variable. (e.g. Example description)
  --is-fido: string@bool-completer # Determines if the global variable is a FIDO variable.
  --is-totp: string@bool-completer # Determines if the global variable is a TOTP/MFA variable.
  name: string # Name of the global variable. Unique across Synthetic global variables. (e.g. MY_VARIABLE)
  --parse-test-options: record # Parser options to use for retrieving a Synthetic global variable from a Synthetic test. Used in conjunction with `parse_test_public_id`. — shape: {field?: string, localVariableName?: string, parser?: record, type: "http_body"|"http_header"|"http_status_code"|"local_variable"}
  --parse-test-public-id: string # A Synthetic test ID to use as a test to generate the variable value. (e.g. abc-def-123)
  tags: list # Tags of the global variable. (e.g. [team:front, test:workflow-1])
  --value: record # Value of the global variable. (e.g. {secure: true, value: value}) — shape: {options?: record, secure?: bool, value?: string}
]: any -> record<attributes: record<restricted_roles: list<string>>, description: string, id: string, is_fido: bool, is_totp: bool, name: string, parse_test_options: record<field: string, localVariableName: string, parser: record<type: string, value: string>, type: string>, parse_test_public_id: string, tags: list<string>, value: record<options: record<totp_parameters: record>, secure: bool, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/synthetics/variables/($variable_id)")
  let body = {attributes: $attributes, description: $description, is_fido: $is_fido, is_totp: $is_totp, name: $name, parse_test_options: $parse_test_options, parse_test_public_id: $parse_test_public_id, tags: $tags, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Host Tags
#
# GET /api/v1/tags/hosts
# operationId: ListHostTags
export def "tags-hosts ListHostTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source to filter. [Complete list of source attribute values](https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value). Use "user" source for custom-defined tags.
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tags/hosts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove host tags
#
# DELETE /api/v1/tags/hosts/{host_name}
# operationId: DeleteHostTags
export def "tags-hosts DeleteHostTags" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source of the tags to be deleted. [Complete list of source attribute values](https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value). Use "user" source for custom-defined tags.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/tags/hosts/($host_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Host Tags
#
# GET /api/v1/tags/hosts/{host_name}
# operationId: GetHostTags
export def "tags-hosts GetHostTags" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source to filter. [Complete list of source attribute values](https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value). Use "user" source for custom-defined tags.
]: nothing -> record<host: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/tags/hosts/($host_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add tags to a host
#
# POST /api/v1/tags/hosts/{host_name}
# operationId: CreateHostTags
export def "tags-hosts CreateHostTags" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source to add tags. [Complete list of source attribute values](https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value). Use "user" source for custom-defined tags. If no source is specified, defaults to "user". (e.g. chef)
  --host: string # Your host name. (e.g. test.host)
  --tags: list # A list of tags associated with a host.
]: any -> record<host: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/tags/hosts/($host_name)" $qp)
  let body = {host: $host, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update host tags
#
# PUT /api/v1/tags/hosts/{host_name}
# operationId: UpdateHostTags
export def "tags-hosts UpdateHostTags" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source to update tags. [Complete list of source attribute values](https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value). Use "user" source for custom-defined tags. If no source specified, defaults to "user".
  --host: string # Your host name. (e.g. test.host)
  --tags: list # A list of tags associated with a host.
]: any -> record<host: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/tags/hosts/($host_name)" $qp)
  let body = {host: $host, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get hourly usage for analyzed logs
#
# GET /api/v1/usage/analyzed_logs
# DEPRECATED
# operationId: GetUsageAnalyzedLogs
@deprecated
export def "usage-analyzed-logs GetUsageAnalyzedLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/analyzed_logs" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for audit logs
#
# GET /api/v1/usage/audit_logs
# DEPRECATED
# operationId: GetUsageAuditLogs
@deprecated
export def "usage-audit-logs GetUsageAuditLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/audit_logs" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for Lambda
#
# GET /api/v1/usage/aws_lambda
# DEPRECATED
# operationId: GetUsageLambda
@deprecated
export def "usage-aws-lambda GetUsageLambda" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/aws_lambda" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get billable usage across your account
#
# GET /api/v1/usage/billable-summary
# operationId: GetUsageBillableSummary
export def "usage-billable-summary GetUsageBillableSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --month: string # Datetime in ISO-8601 format, UTC, precise to month: `[YYYY-MM]` for usage starting this month. (format: date-time)
  --include-connected-accounts: string@bool-completer # Boolean to specify whether to include accounts connected to the current account as partner customers in the Datadog partner network program. Defaults to `false`. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "month" $month "scalar") (serialize-qp "include_connected_accounts" $include_connected_accounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/billable-summary" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for CI visibility
#
# GET /api/v1/usage/ci-app
# DEPRECATED
# operationId: GetUsageCIApp
@deprecated
export def "usage-ci-app GetUsageCIApp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/ci-app" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for CSM Pro
#
# GET /api/v1/usage/cspm
# DEPRECATED
# operationId: GetUsageCloudSecurityPostureManagement
@deprecated
export def "usage-cspm GetUsageCloudSecurityPostureManagement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/cspm" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for cloud workload security
#
# GET /api/v1/usage/cws
# DEPRECATED
# operationId: GetUsageCWS
@deprecated
export def "usage-cws GetUsageCWS" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/cws" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for database monitoring
#
# GET /api/v1/usage/dbm
# DEPRECATED
# operationId: GetUsageDBM
@deprecated
export def "usage-dbm GetUsageDBM" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/dbm" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for Fargate
#
# GET /api/v1/usage/fargate
# DEPRECATED
# operationId: GetUsageFargate
@deprecated
export def "usage-fargate GetUsageFargate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/fargate" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for hosts and containers
#
# GET /api/v1/usage/hosts
# DEPRECATED
# operationId: GetUsageHosts
@deprecated
export def "usage-hosts GetUsageHosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/hosts" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage attribution
#
# GET /api/v1/usage/hourly-attribution
# operationId: GetHourlyUsageAttribution
export def "usage-hourly-attribution GetHourlyUsageAttribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
  --usage-type: string@usage-type-completer # Usage type to retrieve. Usage types are in the format `<usage_type>_usage`. Example: `infra_host_usage` To obtain the complete list of active usage types that can be used to replace `<usage_type>` in the field names, make a request to the [Get usage attribution types API](https://docs.datadoghq.com/api/latest/usage-metering/#get-usage-attribution-types).
  --next-record-id: string # List following results with a next_record_id provided in the previous query.
  --tag-breakdown-keys: string # Comma separated list of tags used to group usage. If no value is provided the usage will not be broken down by tags.  To see which tags are available, look for the value of `tag_config_source` in the API response.
  --include-descendants: string@bool-completer # Include child org usage in the response. Defaults to `true`. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar") (serialize-qp "usage_type" $usage_type "scalar") (serialize-qp "next_record_id" $next_record_id "scalar") (serialize-qp "tag_breakdown_keys" $tag_breakdown_keys "scalar") (serialize-qp "include_descendants" $include_descendants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/hourly-attribution" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for incident management
#
# GET /api/v1/usage/incident-management
# DEPRECATED
# operationId: GetIncidentManagement
@deprecated
export def "usage-incident-management GetIncidentManagement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/incident-management" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for indexed spans
#
# GET /api/v1/usage/indexed-spans
# DEPRECATED
# operationId: GetUsageIndexedSpans
@deprecated
export def "usage-indexed-spans GetUsageIndexedSpans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/indexed-spans" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for ingested spans
#
# GET /api/v1/usage/ingested-spans
# DEPRECATED
# operationId: GetIngestedSpans
@deprecated
export def "usage-ingested-spans GetIngestedSpans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/ingested-spans" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for IoT
#
# GET /api/v1/usage/iot
# DEPRECATED
# operationId: GetUsageInternetOfThings
@deprecated
export def "usage-iot GetUsageInternetOfThings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/iot" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for logs
#
# GET /api/v1/usage/logs
# DEPRECATED
# operationId: GetUsageLogs
@deprecated
export def "usage-logs GetUsageLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/logs" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly logs usage by retention
#
# GET /api/v1/usage/logs-by-retention
# DEPRECATED
# operationId: GetUsageLogsByRetention
@deprecated
export def "usage-logs-by-retention GetUsageLogsByRetention" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/logs-by-retention" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for logs by index
#
# GET /api/v1/usage/logs_by_index
# operationId: GetUsageLogsByIndex
export def "usage-logs-by-index GetUsageLogsByIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
  --index-name: list # Comma-separated list of log index names.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar") (serialize-qp "index_name" $index_name "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/logs_by_index" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get monthly usage attribution
#
# GET /api/v1/usage/monthly-attribution
# operationId: GetMonthlyUsageAttribution
export def "usage-monthly-attribution GetMonthlyUsageAttribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-month: string # Datetime in ISO-8601 format, UTC, precise to month: `[YYYY-MM]` for usage beginning in this month. Maximum of 15 months ago. (format: date-time)
  --end-month: string # Datetime in ISO-8601 format, UTC, precise to month: `[YYYY-MM]` for usage ending this month. (format: date-time)
  --qp-fields: string@fields-completer # Comma-separated list of usage types to return, or `*` for all usage types. Usage types are in the format `<usage_type>_usage` and `<usage_type>_percentage`. Example: `infra_host_usage,infra_host_percentage` To obtain the complete list of usage attribution types that can be used to replace `<usage_type>` in the field names, make a request to the [Get usage attribution types API](https://docs.datadoghq.com/api/latest/usage-metering/#get-usage-attribution-types).
  --sort-direction: string@sort-direction-completer # The direction to sort by: `[desc, asc]`. (default: desc)
  --sort-name: string@sort-name-completer # The field to sort by. Sort fields are in the format `<usage_type>_usage`. Example: `infra_host_usage` To obtain the complete list of usage attribution types that can be used to replace `<usage_type>` in the field names, make a request to the [Get usage attribution types API](https://docs.datadoghq.com/api/latest/usage-metering/#get-usage-attribution-types).
  --tag-breakdown-keys: string # Comma separated list of tag keys used to group usage. If no value is provided the usage will not be broken down by tags.  To see which tags are available, look for the value of `tag_config_source` in the API response.
  --next-record-id: string # List following results with a next_record_id provided in the previous query.
  --include-descendants: string@bool-completer # Include child org usage in the response. Defaults to `true`. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_month" $start_month "scalar") (serialize-qp "end_month" $end_month "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_name" $sort_name "scalar") (serialize-qp "tag_breakdown_keys" $tag_breakdown_keys "scalar") (serialize-qp "next_record_id" $next_record_id "scalar") (serialize-qp "include_descendants" $include_descendants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/monthly-attribution" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get hourly usage for network flows
#
# GET /api/v1/usage/network_flows
# DEPRECATED
# operationId: GetUsageNetworkFlows
@deprecated
export def "usage-network-flows GetUsageNetworkFlows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/network_flows" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for network hosts
#
# GET /api/v1/usage/network_hosts
# DEPRECATED
# operationId: GetUsageNetworkHosts
@deprecated
export def "usage-network-hosts GetUsageNetworkHosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/network_hosts" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for online archive
#
# GET /api/v1/usage/online-archive
# DEPRECATED
# operationId: GetUsageOnlineArchive
@deprecated
export def "usage-online-archive GetUsageOnlineArchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/online-archive" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for profiled hosts
#
# GET /api/v1/usage/profiling
# DEPRECATED
# operationId: GetUsageProfiling
@deprecated
export def "usage-profiling GetUsageProfiling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/profiling" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for RUM units
#
# GET /api/v1/usage/rum
# DEPRECATED
# operationId: GetUsageRumUnits
@deprecated
export def "usage-rum GetUsageRumUnits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/rum" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for RUM sessions
#
# GET /api/v1/usage/rum_sessions
# DEPRECATED
# operationId: GetUsageRumSessions
@deprecated
export def "usage-rum-sessions GetUsageRumSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
  --type: string # RUM type: `[browser, mobile]`. Defaults to `browser`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/rum_sessions" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for sensitive data scanner
#
# GET /api/v1/usage/sds
# DEPRECATED
# operationId: GetUsageSDS
@deprecated
export def "usage-sds GetUsageSDS" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/sds" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for SNMP devices
#
# GET /api/v1/usage/snmp
# DEPRECATED
# operationId: GetUsageSNMP
@deprecated
export def "usage-snmp GetUsageSNMP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: `[YYYY-MM-DDThh]` for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/snmp" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get usage across your account
#
# GET /api/v1/usage/summary
# operationId: GetUsageSummary
export def "usage-summary GetUsageSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-month: string # Datetime in ISO-8601 format, UTC, precise to month: `[YYYY-MM]` for usage beginning in this month. Maximum of 15 months ago. (format: date-time)
  --end-month: string # Datetime in ISO-8601 format, UTC, precise to month: `[YYYY-MM]` for usage ending this month. (format: date-time)
  --include-org-details: string@bool-completer # Include usage summaries for each sub-org.
  --include-connected-accounts: string@bool-completer # Boolean to specify whether to include accounts connected to the current account as partner customers in the Datadog partner network program. Defaults to `false`. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_month" $start_month "scalar") (serialize-qp "end_month" $end_month "scalar") (serialize-qp "include_org_details" $include_org_details "scalar") (serialize-qp "include_connected_accounts" $include_connected_accounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/summary" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for synthetics checks
#
# GET /api/v1/usage/synthetics
# DEPRECATED
# operationId: GetUsageSynthetics
@deprecated
export def "usage-synthetics GetUsageSynthetics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/synthetics" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for synthetics API checks
#
# GET /api/v1/usage/synthetics_api
# DEPRECATED
# operationId: GetUsageSyntheticsAPI
@deprecated
export def "usage-synthetics-api GetUsageSyntheticsAPI" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/synthetics_api" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for synthetics browser checks
#
# GET /api/v1/usage/synthetics_browser
# DEPRECATED
# operationId: GetUsageSyntheticsBrowser
@deprecated
export def "usage-synthetics-browser GetUsageSyntheticsBrowser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/synthetics_browser" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hourly usage for custom metrics
#
# GET /api/v1/usage/timeseries
# DEPRECATED
# operationId: GetUsageTimeseries
@deprecated
export def "usage-timeseries GetUsageTimeseries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage beginning at this hour. (format: date-time)
  --end-hr: string # Datetime in ISO-8601 format, UTC, precise to hour: [YYYY-MM-DDThh] for usage ending **before** this hour. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_hr" $start_hr "scalar") (serialize-qp "end_hr" $end_hr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/timeseries" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all custom metrics by hourly average
#
# GET /api/v1/usage/top_avg_metrics
# operationId: GetUsageTopAvgMetrics
export def "usage-top-avg-metrics GetUsageTopAvgMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --month: string # Datetime in ISO-8601 format, UTC, precise to month: [YYYY-MM] for usage beginning at this hour. (Either month or day should be specified, but not both) (format: date-time)
  --day: string # Datetime in ISO-8601 format, UTC, precise to day: [YYYY-MM-DD] for usage beginning at this hour. (Either month or day should be specified, but not both) (format: date-time)
  --names: list # Comma-separated list of metric names.
  --limit: int # Maximum number of results to return (between 1 and 5000) - defaults to 500 results if limit not specified. (format: int32, default: 500)
  --next-record-id: string # List following results with a next_record_id provided in the previous query.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "names" $names "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "next_record_id" $next_record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/usage/top_avg_metrics" $qp)
  let accept_val = "application/json;datetime-format=rfc3339"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users
#
# GET /api/v1/user
# operationId: ListUsers
export def "user ListUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<users: table<access_role: string, disabled: bool, email: string, handle: string, icon: string, name: string, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /api/v1/user
# operationId: CreateUser
export def "user CreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-role: string@access-role-completer # The access role of the user. Options are **st** (standard user), **adm** (admin user), or **ro** (read-only user). (nullable, e.g. ro)
  --disabled: string@bool-completer # The new disabled status of the user. (e.g. false)
  --email: string # The new email of the user. (e.g. test@datadoghq.com)
  --handle: string # The user handle, must be a valid email. (e.g. test@datadoghq.com)
  --name: string # The name of the user. (e.g. test user)
]: any -> record<user: record<access_role: string, disabled: bool, email: string, handle: string, icon: string, name: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user")
  let body = {access_role: $access_role, disabled: $disabled, email: $email, handle: $handle, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable a user
#
# DELETE /api/v1/user/{user_handle}
# operationId: DisableUser
export def "user DisableUser" [
  user_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/($user_handle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user details
#
# GET /api/v1/user/{user_handle}
# operationId: GetUser
export def "user GetUser" [
  user_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<access_role: string, disabled: bool, email: string, handle: string, icon: string, name: string, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/($user_handle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /api/v1/user/{user_handle}
# operationId: UpdateUser
export def "user UpdateUser" [
  user_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-role: string@access-role-completer # The access role of the user. Options are **st** (standard user), **adm** (admin user), or **ro** (read-only user). (nullable, e.g. ro)
  --disabled: string@bool-completer # The new disabled status of the user. (e.g. false)
  --email: string # The new email of the user. (e.g. test@datadoghq.com)
  --handle: string # The user handle, must be a valid email. (e.g. test@datadoghq.com)
  --name: string # The name of the user. (e.g. test user)
]: any -> record<user: record<access_role: string, disabled: bool, email: string, handle: string, icon: string, name: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/($user_handle)")
  let body = {access_role: $access_role, disabled: $disabled, email: $email, handle: $handle, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate API key
#
# GET /api/v1/validate
# operationId: Validate
export def "validate Validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send logs
#
# POST /v1/input
# DEPRECATED
# operationId: SubmitLog
@deprecated
export def "input SubmitLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ddtags: string # Log tags can be passed as query parameters with `text/plain` content type. (e.g. env:prod,user:my-user)
  --Content-Encoding: string@Content-Encoding-completer-1 # HTTP header used to compress the media-type.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "dd-api-key"))
  let base = ($base_url | default "https://{subdomain}.{site}")
  let qp = [(serialize-qp "ddtags" $ddtags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/input" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
