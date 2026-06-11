# Auto-generated client for Console API v20240601.0.0
# Source: https://docs.statsig.com/openapi.json
# Auth: --token flag or $env.CONSOLE_API_TOKEN

const BASE_URL = "https://statsigapi.net"
const DEFAULT_AUTH = "statsig-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONSOLE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "statsig-api-key" => { {headers: {STATSIG-API-KEY: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://statsigapi.net"] }
def auth-scheme-completer [] { ["statsig-api-key"] }

# Completers for enum parameters
def sortKey-completer [] { ["actionType" "changeLog" "date" "id" "name" "time" "updatedBy" "updatedByUserID"] }
def sortOrder-completer [] { ["asc" "desc"] }
def actionType-completer [] { ["AWS_marketplace_account_delete" "ID_list_update" "OIDC_configuration_delete" "OIDC_configuration_upsert" "SSO_disable" "accept_echidna_source_review" "active_user_definition_update" "add_dashboard_widget" "add_geo_type" "add_segments_of_interest_property" "add_session_recordings_to_playlist" "add_srm_debugger_custom_dimension" "ai_config_create" "apply_experiment_review" "archive_experiment" "archive_metric" "archive_org_project" "attach_experiment_to_power_analysis_report" "autotune_experiment_create" "autotune_experiment_delete" "autotune_experiment_edit" "autotune_experiment_snapshot_delete" "autotune_experiment_update_pulse_paused" "autotune_experiment_update_target_apps" "autotune_overrides_edit" "autotune_reviews_on" "backfill_metric_results" "batch_cancel_company_invites" "batch_user_role_update" "cancel_archive_metric" "cancel_delete_metric" "cancel_echidna_dag" "cancel_metric_backfills" "clone_ai_config" "clone_ai_config_version" "commit_echidna_source_review" "company_ID_type_add" "company_ID_type_delete" "company_ID_type_edit" "company_basic_info_edit" "company_create" "company_delete" "company_email_domain_config_delete" "company_environments_edit" "company_invite_access_update" "company_member_remove" "company_metric_delete" "company_metric_management_update" "company_snapshot_delete" "config_add_tag" "config_allowed_reviewers_update" "config_conditions_update" "config_default_value_update" "config_delete" "config_description_update" "config_display_name_update" "config_edit_tags" "config_edit_target_apps" "config_environments_update" "config_id_type_update" "config_monitoring_metrics_update" "config_remove_tag" "config_require_reviews" "config_resalt" "config_revert" "config_review_accept" "config_review_commit" "config_review_create" "config_review_delete" "config_review_info_update" "config_review_reject" "config_review_required_update" "config_review_update" "config_reviews_disable" "config_state_toggle" "config_update_owners" "create_ai_config_eval_grader" "create_ai_config_version" "create_customer_app" "create_dashboard" "create_echidna_assignment_source" "create_echidna_data_quality_checks" "create_echidna_entity_property_source" "create_echidna_metric_source" "create_echidna_source_review" "create_geotest_design" "create_guardrail_metric_alert" "create_power_analysis_custom_query" "create_power_analysis_gate_query" "create_statsig_proxy" "create_topline_alert" "custom_metric_definition_create" "custom_metric_definition_delete" "custom_metric_definition_edit" "custom_metric_edit" "custom_metric_name_edit" "custom_metric_review_accept" "custom_metric_review_delete" "custom_metric_review_reject" "custom_metric_update_owners" "custom_pulse_query_create" "custom_pulse_query_delete" "custom_pulse_query_name_edit" "custom_query_toggle_favorite" "custom_sankey_delete" "dashboard_update_owners" "delete_ai_config_eval_grader" "delete_ai_config_version" "delete_dashboard" "delete_dashboard_widget" "delete_echidna_assignment_source" "delete_echidna_entity_property_source" "delete_echidna_metric_source" "delete_echidna_source_review" "delete_geo_type" "delete_geotest_design" "delete_guardrail_metric_alert" "delete_layer_parameter" "delete_metric" "delete_payment_method" "delete_segments_of_interest_property" "delete_session_recordings_from_playlist" "delete_session_replay_playlist" "delete_srm_debugger_custom_dimension" "delete_tag" "delete_target_app" "delete_topline_alert" "delete_trigger_integration" "delete_user_role" "dismiss_runaway_entity" "dynamic_config_create" "dynamic_config_template_create" "dynamic_config_update_owners" "echidna_drop_tables" "edit_ai_config_eval_grader" "edit_ai_config_version" "edit_dashboard_description" "edit_dashboard_name" "edit_dashboard_widget" "edit_guardrail_metric_alert" "edit_target_app" "event_dimension_update" "experiment_abandon" "experiment_advanced_settings_edit" "experiment_allowed_reviewers_update" "experiment_assigned_to_layer" "experiment_create" "experiment_data_report_delete" "experiment_data_report_rename" "experiment_data_report_update_parameters" "experiment_decision_make" "experiment_delete" "experiment_description_edit" "experiment_discussion_post_create" "experiment_discussion_post_delete" "experiment_display_name_edit" "experiment_edit" "experiment_follow_toggle" "experiment_group_disable" "experiment_overrides_edit" "experiment_pause_assignment" "experiment_restart" "experiment_restart_as_new" "experiment_review_accept" "experiment_review_create" "experiment_review_delete" "experiment_review_info_update" "experiment_review_reject" "experiment_review_update_overrides" "experiment_review_update_owners" "experiment_review_update_team" "experiment_reviews_on" "experiment_rollout" "experiment_schedule_rollout" "experiment_snapshot_delete" "experiment_start" "experiment_stopped" "experiment_template_create" "experiment_update_decision_note" "experiment_update_owners" "experiment_update_subdimension_filter" "experiment_update_summary_sections" "experiment_update_target_apps" "extend_experiment_pulse_end_date" "gate_create" "gate_overrides_update" "gate_template_create" "gate_update" "gate_update_owners" "generate_integration_webhook_secret" "holdout_create" "holdout_delete" "holdout_layer_parameter_values_update" "holdout_update" "holdout_update_owners" "hypothesis_edit" "ingestion_source_delete" "integration_create" "integration_delete" "integration_set_enabled" "integration_update" "integration_update_disabled_events" "integration_update_outgoing_config" "integration_update_rate_limits" "integration_upsert" "key_experiment_metrics_edit" "layer_allowed_reviewers_update" "layer_create" "layer_delete" "layer_description_edit" "layer_edit" "layer_overrides_edit" "layer_parameter_add" "layer_parameters_edit" "layer_review_accept" "layer_review_commit" "layer_review_create" "layer_review_delete" "layer_review_info_update" "layer_review_reject" "layer_reviews_on" "layer_snapshot_delete" "layer_update_owners" "layer_update_target_apps" "load_echidna_assignment_source" "load_echidna_autotune_pulse" "load_echidna_metric" "load_echidna_pulse" "metric_add_tag" "metric_allowed_reviewers_update" "metric_disable_reviews_locally" "metric_edit_definition" "metric_edit_description" "metric_remove_tag" "metric_review_commit" "metric_review_create" "metric_review_info_update" "metric_reviews_on" "modify_override_config" "modify_overrides" "org_api_key_create" "organization_member_remove" "param_store_create" "param_store_delete" "param_store_update" "param_store_update_owners" "payment_entitlements_upsert" "pin_chart_to_summary" "pin_dashboard_for_company" "project_description_edit" "project_owner_set" "project_review_group_delete" "project_review_group_remove" "project_review_group_upsert" "pulse_results_export" "reject_echidna_source_review" "release_pipeline_completed" "release_pipeline_create" "release_pipeline_delete" "release_pipeline_trigger_create" "release_pipeline_update" "remove_override_config" "remove_template_decision_framework" "resolve_guardrail_metric_alert" "restart_experiment_pulse" "restore_dashboard" "schedule_archive_metric" "schedule_delete_metric" "schedule_experiment_start" "scheduled_custom_pulse_query_create" "scheduled_pulse_custom_query_delete" "scheduled_pulse_query_name_edit" "scheduled_pulse_rollups_update" "sdk_key_create" "sdk_key_deactivate" "sdk_key_delete" "sdk_key_update_description" "sdk_key_update_environments" "sdk_key_update_scopes" "sdk_key_update_target_app" "secret_key_regenerate" "segment_create" "segment_update_owners" "set_ai_config_baseline_version" "set_api_share_key_access" "set_automated_bot_removals" "set_bv3_plan_type" "set_company_default_user_role" "set_company_session_replay_sampling_rate" "set_company_session_replay_settings" "set_default_payment_method" "set_dynamic_config_analytics_enabled_by_default" "set_echidna_project_metric_schedule" "set_echidna_project_pulse_schedule" "set_echidna_schedule_hour" "set_enable_id_resolution_toggle" "set_gate_analytics_0_100_exposures_enabled" "set_gate_analytics_enabled_by_default" "set_geotest_design" "set_id_resolution_inferred_id" "set_id_resolution_labeled_id" "set_metric_directionality" "set_personal_api_key_access" "set_plan_type" "set_require_target_app_for_new_entity" "set_self_approvals_blocked" "set_stop_experiment_enabled" "set_stop_new_assignment_toggle" "set_suggest_cure_covariates" "set_user_sampling_rate" "set_user_sampling_rate_for_gate" "set_whn_results_export_setting" "set_whn_table_ttls" "setup_external_opt_in" "setup_stratified_sampling" "shared_report_link_delete" "shared_report_link_upsert" "source_allowed_reviewers_update" "start_ai_config_version_evaluation_job" "stop_ai_config_version_evaluation_job" "tag_configs_bulk" "tag_create" "tag_delete" "tag_edit" "tag_metrics_bulk" "tag_update_owners" "unarchive_experiment" "unarchive_metric" "unattach_experiment_to_power_analysis_report" "unsnooze_guardrail_metric_alert" "update_ai_assistance_enabled" "update_ai_business_context" "update_bv3_subscription" "update_company_auto_capture_settings" "update_company_experiment_exclusion_segment" "update_company_remove_default_gates_setting" "update_company_user_store_enabled" "update_config_analytics_enabled" "update_config_release_pipeline" "update_dashboard_settings" "update_dashboard_widgets_from_generated_tags" "update_echidna_assignment_source" "update_echidna_assignment_source_is_verified" "update_echidna_assignment_source_loading_window" "update_echidna_assignment_source_name" "update_echidna_entity_property_source" "update_echidna_entity_property_source_is_verified" "update_echidna_entity_property_source_name" "update_echidna_metric_loading_window" "update_echidna_metric_source" "update_echidna_metric_source_is_verified" "update_echidna_metric_source_name" "update_echidna_metric_tag_or_description" "update_echidna_source_is_verified" "update_echidna_source_owner" "update_echidna_source_review" "update_echidna_source_review_required" "update_echidna_subtype" "update_entities_require_teams" "update_experiment_ai_settings" "update_experiment_enabled_non_prod_environments" "update_experiment_quality_score_criteria" "update_experiment_quality_score_settings" "update_experiment_salt" "update_gate_analytics_enabled" "update_gate_display_name" "update_gate_is_permanent" "update_layer_parameter" "update_metric_is_permanent" "update_metric_is_verified" "update_metric_review_required" "update_precommit_hook" "update_precommit_webhook_key" "update_server_sdk_configuration_rollback" "update_store_0_100_exposures" "update_team" "update_team_admins" "update_team_description" "update_team_name" "update_team_settings" "update_template_decision_framework" "update_topline_alert" "upsert_ai_config_eval_groups" "upsert_ai_config_version" "upsert_experiment_settings" "upsert_gate_settings" "upsert_trigger_integration" "upsert_user_role" "upsert_user_store_client_targeting_properties" "user_data_load" "user_login" "user_role_update" "verify_dashboard"] }
def explorationWindow-completer [] { ["1" "168" "168hr" "168hrs" "1hr" "1hrs" "24" "24hr" "24hrs" "336" "336hr" "336hrs" "48" "48hr" "48hrs"] }
def attributionWindow-completer [] { ["1" "1hr" "1hrs" "2" "24" "24hr" "24hrs" "2hr" "2hrs" "4" "4hr" "4hrs"] }
def attributionWindowUnit-completer [] { ["day" "hour" "min"] }
def winnerThreshold-completer [] { ["80%" "90%" "95%" "98%" "99%"] }
def optimizationParameter-completer [] { ["occurrence" "value"] }
def identifierMappingMode-completer [] { ["firstTouchOneToMany" "lastTouchOneToMany" "strictOneToOne"] }
def defaultConfidenceInterval-completer [] { ["80" "90" "95" "98" "99"] }
def status-completer [] { ["abandoned" "active" "archived" "assignment_stopped" "decision_made" "experiment_stopped" "setup"] }
def scheduledReloadType-completer [] { ["full" "incremental"] }
def analyticsType-completer [] { ["bayesian" "frequentist" "sprt"] }
def refresh-completer [] { ["full" "incremental" "metric"] }
def sourceType-completer [] { ["query" "table"] }
def type-completer [] { ["PERMANENT" "STALE" "TEMPLATE" "TEMPORARY"] }
def typeReason-completer [] { ["NONE" "STALE_ALL_FALSE" "STALE_ALL_TRUE" "STALE_EMPTY_CHECKS" "STALE_NO_RULES" "STALE_PROBABLY_DEAD_CHECK" "STALE_PROBABLY_FORGOTTEN" "STALE_PROBABLY_LAUNCHED" "STALE_PROBABLY_UNLAUNCHED"] }
def type-completer-1 [] { ["PERMANENT" "TEMPORARY"] }
def type-completer-2 [] { ["adls" "athena" "azure-synapse" "bigquery-v2" "databricks" "redshift" "s3" "snowflake-v2"] }
def dataset-completer [] { ["Events" "Metrics" "entity_properties" "export_exposures"] }
def dataset-completer-1 [] { ["Metrics"] }
def use-delta-sharing-completer [] { ["true"] }
def status-completer-1 [] { ["%Other" "AUTHENTICATION_ERROR" "BACKFILL_REQUESTED" "BULK_LOAD_ERROR" "BULK_LOAD_SUCCESSFUL" "CONNECTION_CONFIG_ERROR" "CONNECTION_ERROR" "IMPORT_RESCHEDULED" "IMPORT_SCHEDULED" "IMPORT_STARTED" "IMPORT_SUCCESSFUL" "INTERNAL_WRITE_ERROR_EVENTS" "INTERNAL_WRITE_ERROR_EXPOSURES" "INTERNAL_WRITE_ERROR_METRICS" "LOADED_EMPTY_DATA" "QUERY_CONSTRUCTION_ERROR" "QUERY_ERROR" "SETUP_ERROR" "SSH_ERROR"] }
def type-completer-3 [] { ["CLIENT" "CONSOLE" "ORG" "SCIM" "SERVER"] }
def op-completer [] { ["add"] }
def type-completer-4 [] { ["composite" "composite_sum" "event_count_custom" "event_user" "funnel" "mean" "ratio" "sum" "undefined" "user_warehouse"] }
def directionality-completer [] { ["decrease" "increase"] }
def funnelCountDistinct-completer [] { ["events" "users"] }
def incremental-completer [] { ["false" "true"] }
def showHiddenMetrics-completer [] { ["false" "true"] }
def type-completer-5 [] { ["first_exposures" "pulse_daily" "topline_impact_daily"] }
def type-completer-6 [] { ["analysis_list" "id_list" "rule_based" "user_store_id_list"] }
def visibility-completer [] { ["CLOSED" "EXTERNAL" "OPEN"] }
def changeTeamConfigs-completer [] { ["anyone" "team_only"] }
def reviewApproval-completer [] { ["admin_only" "anyone" "team_only"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "console-alerts get" } } | get name | first)
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

# List Topline Alerts
#
# GET /console/v1/alerts
export def "console-alerts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creatorName: string # Name of the creator. (nullable)
  --creatorID: string # ID of the user who created the entity. (nullable)
  --tags: string # Filter by tags
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, alertType: string, metrics: record, metricGroupBys: record, formula: string, message: string, creatorID: string, companyID: string, priority: string, alertThreshold: float, warningThreshold: float, windowMs: float, condition: string, renotificationConditions: list, renotificationWindowMs: float, renotificationMessage: string, team: string, tags: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creatorName" $creatorName "scalar") (serialize-qp "creatorID" $creatorID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/alerts" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Audit Logs
#
# GET /console/v1/audit_logs
export def "console-audit-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --sortKey: string@sortKey-completer
  --sortOrder: string@sortOrder-completer
  --latestID: string
  --tags: string
  --actionType: string@actionType-completer
  --actionTypes: list
  --startDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --endDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, changeLog: string, actionType: record, date: string, time: string, updatedBy: string, updatedByUserID: string, modifierEmail: record, changes: record, tags: list, targetAppIDs: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "latestID" $latestID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "actionType" $actionType "scalar") (serialize-qp "actionTypes" $actionTypes "multi") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/audit_logs" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Autotune
#
# GET /console/v1/autotunes
export def "console-autotunes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<description: string, variants: list, successEvent: string, successEventValue: string, explorationWindow: string, attributionWindow: string, attributionWindowUnit: string, explorationWindowRate: float, longtermExplorationAllocation: float, winnerThreshold: string, metadataField: string, higherIsBetter: bool, isContextual: bool, metricSourceID: string, linkedExperimentName: string, goalRichText: string, optimizationParameter: string, valueColumn: string, featureList: list, id: string, name: string, idType: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: list, holdoutIDs: list, team: string, teamID: string, version: float, isStarted: bool, winner: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/autotunes" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Autotune
#
# POST /console/v1/autotunes
# --variants item shape: {name: string, json: any, size?: float}
export def "console-autotunes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string # A brief summary of what the autotune is being used for.
  variants: list # An array of Variant objects. — item shape: {name: string, json: any, size?: float}
  successEvent: string # The event you are trying to optimize for.
  --successEventValue: string # The value that should come with the event for it to be considered successful.
  explorationWindow: string@explorationWindow-completer # The initial time period where Autotune will equally split the traffic.
  attributionWindow: string@attributionWindow-completer # The maximum duration between the exposure and success event that counts as a success.
  --attributionWindowUnit: string@attributionWindowUnit-completer # Time unit of attribution window
  --explorationWindowRate: float # Exploration window rate (format: double)
  --longtermExplorationAllocation: float # Long term exploration allocation (format: double)
  winnerThreshold: string@winnerThreshold-completer # The "probability of best" threshold a variant needs to achieve for Autotune to declare it the winner, stop collecting data, and direct all traffic.
  --metadataField: string # Metadata field containing the numeric value to optimize for. If this field is null, autotune optimizes for the existence of a follow-up event. This is only used for contextual autotunes.
  --higherIsBetter: string@bool-completer # Whether to optimize for an increase or decrease in the metadata field value. Default is true. This is only used for contextual autotunes.
  --isContextual: string@bool-completer # Makes this autotune contextual
  --metricSourceID: string # Metric source to pull success event data from
  --linkedExperimentName: string # Linked experiment to measure the success of the Autotune
  --goalRichText: string # Autotune goal
  --optimizationParameter: string@optimizationParameter-completer # Optimize for event occurrence vs value
  --valueColumn: string # Metric source column to optimize for
  --featureList: list # List of features that should be included in the analysis
  name: string # The name that was originally given to the autotune on creation but formatted as an ID ("A Autotune" -> "a_autotune").
  --idType: string # idType of the autotune (userID, stableID, or a customID). Defaults to userID if not provided
]: any -> record<message: string, data: record<description: string, variants: list<record>, successEvent: string, successEventValue: string, explorationWindow: string, attributionWindow: string, attributionWindowUnit: string, explorationWindowRate: float, longtermExplorationAllocation: float, winnerThreshold: string, metadataField: string, higherIsBetter: bool, isContextual: bool, metricSourceID: string, linkedExperimentName: string, goalRichText: string, optimizationParameter: string, valueColumn: string, featureList: list<string>, id: string, name: string, idType: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isStarted: bool, winner: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/autotunes")
  let body = {description: $description, variants: $variants, successEvent: $successEvent, successEventValue: $successEventValue, explorationWindow: $explorationWindow, attributionWindow: $attributionWindow, attributionWindowUnit: $attributionWindowUnit, explorationWindowRate: $explorationWindowRate, longtermExplorationAllocation: $longtermExplorationAllocation, winnerThreshold: $winnerThreshold, metadataField: $metadataField, higherIsBetter: $higherIsBetter, isContextual: $isContextual, metricSourceID: $metricSourceID, linkedExperimentName: $linkedExperimentName, goalRichText: $goalRichText, optimizationParameter: $optimizationParameter, valueColumn: $valueColumn, featureList: $featureList, name: $name, idType: $idType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Autotune
#
# GET /console/v1/autotunes/{id}
export def "console-autotunes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<description: string, variants: list<record>, successEvent: string, successEventValue: string, explorationWindow: string, attributionWindow: string, attributionWindowUnit: string, explorationWindowRate: float, longtermExplorationAllocation: float, winnerThreshold: string, metadataField: string, higherIsBetter: bool, isContextual: bool, metricSourceID: string, linkedExperimentName: string, goalRichText: string, optimizationParameter: string, valueColumn: string, featureList: list<string>, id: string, name: string, idType: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isStarted: bool, winner: record<id: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fully Update Autotune
#
# POST /console/v1/autotunes/{id}
# --variants item shape: {name: string, json: any, size?: float}
export def "console-autotunes post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string # A brief summary of what the autotune is being used for.
  variants: list # An array of Variant objects. — item shape: {name: string, json: any, size?: float}
  successEvent: string # The event you are trying to optimize for.
  --successEventValue: string # The value that should come with the event for it to be considered successful.
  explorationWindow: string@explorationWindow-completer # The initial time period where Autotune will equally split the traffic.
  attributionWindow: string@attributionWindow-completer # The maximum duration between the exposure and success event that counts as a success.
  --attributionWindowUnit: string@attributionWindowUnit-completer # Time unit of attribution window
  --explorationWindowRate: float # Exploration window rate (format: double)
  --longtermExplorationAllocation: float # Long term exploration allocation (format: double)
  winnerThreshold: string@winnerThreshold-completer # The "probability of best" threshold a variant needs to achieve for Autotune to declare it the winner, stop collecting data, and direct all traffic.
  --metadataField: string # Metadata field containing the numeric value to optimize for. If this field is null, autotune optimizes for the existence of a follow-up event. This is only used for contextual autotunes.
  --higherIsBetter: string@bool-completer # Whether to optimize for an increase or decrease in the metadata field value. Default is true. This is only used for contextual autotunes.
  --isContextual: string@bool-completer # Whether this is a contextual autotune
  --metricSourceID: string # Metric source to pull success event data from
  --linkedExperimentName: string # Linked experiment to measure the success of the Autotune
  --goalRichText: string # Autotune goal
  --optimizationParameter: string@optimizationParameter-completer # Optimize for event occurrence vs value
  --valueColumn: string # Metric source column to optimize for
  --featureList: list # List of features that should be included in the analysis
]: any -> record<message: string, data: record<description: string, variants: list<record>, successEvent: string, successEventValue: string, explorationWindow: string, attributionWindow: string, attributionWindowUnit: string, explorationWindowRate: float, longtermExplorationAllocation: float, winnerThreshold: string, metadataField: string, higherIsBetter: bool, isContextual: bool, metricSourceID: string, linkedExperimentName: string, goalRichText: string, optimizationParameter: string, valueColumn: string, featureList: list<string>, id: string, name: string, idType: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isStarted: bool, winner: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)")
  let body = {description: $description, variants: $variants, successEvent: $successEvent, successEventValue: $successEventValue, explorationWindow: $explorationWindow, attributionWindow: $attributionWindow, attributionWindowUnit: $attributionWindowUnit, explorationWindowRate: $explorationWindowRate, longtermExplorationAllocation: $longtermExplorationAllocation, winnerThreshold: $winnerThreshold, metadataField: $metadataField, higherIsBetter: $higherIsBetter, isContextual: $isContextual, metricSourceID: $metricSourceID, linkedExperimentName: $linkedExperimentName, goalRichText: $goalRichText, optimizationParameter: $optimizationParameter, valueColumn: $valueColumn, featureList: $featureList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially Update Autotune
#
# PATCH /console/v1/autotunes/{id}
# --variants item shape: {name: string, json: any, size?: float}
export def "console-autotunes patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string # A brief summary of what the autotune is being used for.
  --variants: list # An array of Variant objects. — item shape: {name: string, json: any, size?: float}
  --successEvent: string # The event you are trying to optimize for.
  --successEventValue: string # The value that should come with the event for it to be considered successful.
  --explorationWindow: string@explorationWindow-completer # The initial time period where Autotune will equally split the traffic.
  --attributionWindow: string@attributionWindow-completer # The maximum duration between the exposure and success event that counts as a success.
  --attributionWindowUnit: string@attributionWindowUnit-completer # Time unit of attribution window
  --explorationWindowRate: float # Exploration window rate (format: double)
  --longtermExplorationAllocation: float # Long term exploration allocation (format: double)
  --winnerThreshold: string@winnerThreshold-completer # The "probability of best" threshold a variant needs to achieve for Autotune to declare it the winner, stop collecting data, and direct all traffic.
  --metadataField: string # Metadata field containing the numeric value to optimize for. If this field is null, autotune optimizes for the existence of a follow-up event. This is only used for contextual autotunes.
  --higherIsBetter: string@bool-completer # Whether to optimize for an increase or decrease in the metadata field value. Default is true. This is only used for contextual autotunes.
  --isContextual: string@bool-completer # Whether this is a contextual autotune
  --metricSourceID: string # Metric source to pull success event data from
  --linkedExperimentName: string # Linked experiment to measure the success of the Autotune
  --goalRichText: string # Autotune goal
  --optimizationParameter: string@optimizationParameter-completer # Optimize for event occurrence vs value
  --valueColumn: string # Metric source column to optimize for
  --featureList: list # List of features that should be included in the analysis
]: any -> record<message: string, data: record<description: string, variants: list<record>, successEvent: string, successEventValue: string, explorationWindow: string, attributionWindow: string, attributionWindowUnit: string, explorationWindowRate: float, longtermExplorationAllocation: float, winnerThreshold: string, metadataField: string, higherIsBetter: bool, isContextual: bool, metricSourceID: string, linkedExperimentName: string, goalRichText: string, optimizationParameter: string, valueColumn: string, featureList: list<string>, id: string, name: string, idType: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isStarted: bool, winner: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)")
  let body = {description: $description, variants: $variants, successEvent: $successEvent, successEventValue: $successEventValue, explorationWindow: $explorationWindow, attributionWindow: $attributionWindow, attributionWindowUnit: $attributionWindowUnit, explorationWindowRate: $explorationWindowRate, longtermExplorationAllocation: $longtermExplorationAllocation, winnerThreshold: $winnerThreshold, metadataField: $metadataField, higherIsBetter: $higherIsBetter, isContextual: $isContextual, metricSourceID: $metricSourceID, linkedExperimentName: $linkedExperimentName, goalRichText: $goalRichText, optimizationParameter: $optimizationParameter, valueColumn: $valueColumn, featureList: $featureList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Autotune
#
# DELETE /console/v1/autotunes/{id}
export def "console-autotunes delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finish Experiment Early
#
# PUT /console/v1/autotunes/{id}/make_decision
export def "console-autotunes-make-decision put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-id: string # The ID of the group to launch (e.g. groupid123)
  decisionReason: string # The reason for making the decision to update the experiment status (e.g. Your reason for stopping early)
  --removeTargeting: string@bool-completer # Indicates whether to remove targeting from the experiment (default: false, e.g. false)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)/make_decision")
  let body = {id: $body_id, decisionReason: $decisionReason, removeTargeting: $removeTargeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset Experiment
#
# PUT /console/v1/autotunes/{id}/reset
export def "console-autotunes-reset put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)/reset")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start Autotune Experiment
#
# PUT /console/v1/autotunes/{id}/start
export def "console-autotunes-start put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/autotunes/($id)/start")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Validation
#
# POST /console/v1/change_validation
export def "console-change-validation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  reviewID: string
  --validated: string@bool-completer
  --message: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/change_validation")
  let body = {reviewID: $reviewID, validated: $validated, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update change validation message
#
# PATCH /console/v1/change_validation/message
export def "console-change-validation-message patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  reviewID: string
  --message: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/change_validation/message")
  let body = {reviewID: $reviewID, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Company Info
#
# GET /console/v1/company
export def "console-company get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<companyID: string, companyName: string, isWarehouseNative: bool, orgID: string, orgName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/company")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Dynamic Configs
#
# GET /console/v1/dynamic_configs
export def "console-dynamic-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --releasePipelineID: string # The release pipeline ID associated with the dynamic config (nullable)
  --creatorName: string # Name of the creator. (nullable)
  --creatorID: string # ID of the user who created the entity. (nullable)
  --tags: string # Filter by tags
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, isEnabled: bool, rules: list, defaultValue: record, defaultValueJson5: string, owner: record, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "releasePipelineID" $releasePipelineID "scalar") (serialize-qp "creatorName" $creatorName "scalar") (serialize-qp "creatorID" $creatorID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/dynamic_configs" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Dynamic Config
#
# POST /console/v1/dynamic_configs
# --rules item shape: {name: string, passPercentage?: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list, returnValueJson5?: string, variants?: list}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-dynamic-configs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The dynamic config display name (e.g. my_config)
  --isEnabled: string@bool-completer # Is the dynamic config enabled (default: true)
  --description: string
  --rules: list # An array of Rule objects — item shape: {name: string, passPercentage?: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list, returnValueJson5?: string, variants?: list}
  --defaultValue: record # The fallback JSON object when no rules are triggered
  --defaultValueJson5: string # Can include comments. If provided with defaultValue, must parse to the same JSON
  --idType: string # The type of ID which the dynamic config is based on. (e.g. userID)
  --tags: list # The list of tag names attached to the dynamic config
  --creatorID: string # nullable
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --creatorEmail: string # nullable
  --schema: string # A schema using JSON Schema Draft 2020-12 to enforce return values of this dynamic config's rules. (nullable)
  --schemaJson5: string # `schema` except with Json5 comments. Optional and should parse to same json as `schema`. (nullable)
  --targetApps: any
  --team: string # The team name associated with the dynamic config, Enterprise only. (nullable)
  --teamID: string # The team ID associated with the dynamic config, Enterprise only. (nullable)
  --releasePipelineID: string # The release pipeline ID associated with the dynamic config (nullable)
  --id: string # The dynamic config name ID
  --isTemplate: string@bool-completer
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/dynamic_configs")
  let body = {name: $name, isEnabled: $isEnabled, description: $description, rules: $rules, defaultValue: $defaultValue, defaultValueJson5: $defaultValueJson5, idType: $idType, tags: $tags, creatorID: $creatorID, owner: $owner, creatorEmail: $creatorEmail, schema: $schema, schemaJson5: $schemaJson5, targetApps: $targetApps, team: $team, teamID: $teamID, releasePipelineID: $releasePipelineID, id: $id, isTemplate: $isTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Dynamic Config
#
# GET /console/v1/dynamic_configs/{id}
export def "console-dynamic-configs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fully Update Dynamic Config
#
# POST /console/v1/dynamic_configs/{id}
# --rules item shape: {name: string, passPercentage?: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list, returnValueJson5?: string, variants?: list}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-dynamic-configs post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # Optional name for the configuration. (e.g. my_config)
  --isEnabled: string@bool-completer # Is the dynamic config enabled (default: true)
  description: string # A brief summary of what the dynamic config is being used for (e.g. helpful summary of what this dynamic config does)
  rules: list # An array of Rule objects — item shape: {name: string, passPercentage?: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list, returnValueJson5?: string, variants?: list}
  --defaultValue: record # The fallback JSON object when no rules are triggered
  --defaultValueJson5: string # Can include comments. If provided with defaultValue, must parse to the same JSON
  --idType: string # The type of ID which the dynamic config is based on. (e.g. userID)
  --tags: list # The list of tag names attached to the dynamic config (e.g. [a tag])
  --creatorID: string # nullable
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --creatorEmail: string # nullable
  --schema: string # A schema using JSON Schema Draft 2020-12 to enforce return values of this dynamic config's rules. (nullable)
  --schemaJson5: string # `schema` except with Json5 comments. Optional and should parse to same json as `schema`. (nullable)
  --targetApps: any
  --team: string # The team name associated with the dynamic config, Enterprise only. (nullable)
  --teamID: string # The team ID associated with the dynamic config, Enterprise only. (nullable)
  --releasePipelineID: string # The release pipeline ID associated with the dynamic config (nullable)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)")
  let body = {name: $name, isEnabled: $isEnabled, description: $description, rules: $rules, defaultValue: $defaultValue, defaultValueJson5: $defaultValueJson5, idType: $idType, tags: $tags, creatorID: $creatorID, owner: $owner, creatorEmail: $creatorEmail, schema: $schema, schemaJson5: $schemaJson5, targetApps: $targetApps, team: $team, teamID: $teamID, releasePipelineID: $releasePipelineID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially Update Dynamic Config
#
# PATCH /console/v1/dynamic_configs/{id}
# --rules item shape: {name: string, passPercentage?: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list, returnValueJson5?: string, variants?: list}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-dynamic-configs patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # Optional name for the configuration. (e.g. my_config)
  --isEnabled: string@bool-completer # Is the dynamic config enabled (default: true)
  --description: string # A brief summary of what the dynamic config is being used for (e.g. helpful summary of what this dynamic config does)
  --rules: list # An array of Rule objects — item shape: {name: string, passPercentage?: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list, returnValueJson5?: string, variants?: list}
  --defaultValue: record # The fallback JSON object when no rules are triggered
  --defaultValueJson5: string # Can include comments. If provided with defaultValue, must parse to the same JSON
  --idType: string # The type of ID which the dynamic config is based on. (e.g. userID)
  --tags: list # The list of tag names attached to the dynamic config (e.g. [a tag])
  --creatorID: string # nullable
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --creatorEmail: string # nullable
  --schema: string # A schema using JSON Schema Draft 2020-12 to enforce return values of this dynamic config's rules. (nullable)
  --schemaJson5: string # `schema` except with Json5 comments. Optional and should parse to same json as `schema`. (nullable)
  --targetApps: any
  --team: string # The team name associated with the dynamic config, Enterprise only. (nullable)
  --teamID: string # The team ID associated with the dynamic config, Enterprise only. (nullable)
  --releasePipelineID: string # The release pipeline ID associated with the dynamic config (nullable)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)")
  let body = {name: $name, isEnabled: $isEnabled, description: $description, rules: $rules, defaultValue: $defaultValue, defaultValueJson5: $defaultValueJson5, idType: $idType, tags: $tags, creatorID: $creatorID, owner: $owner, creatorEmail: $creatorEmail, schema: $schema, schemaJson5: $schemaJson5, targetApps: $targetApps, team: $team, teamID: $teamID, releasePipelineID: $releasePipelineID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Dynamic Config
#
# DELETE /console/v1/dynamic_configs/{id}
export def "console-dynamic-configs delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Dynamic Config
#
# PUT /console/v1/dynamic_configs/{id}/archive
export def "console-dynamic-configs-archive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --forceArchive: string@bool-completer
  --archiveReason: string # The reason for archiving the gate (e.g. The gate is no longer needed)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/archive")
  let body = {forceArchive: $forceArchive, archiveReason: $archiveReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable Dynamic Config
#
# PUT /console/v1/dynamic_configs/{id}/disable
export def "console-dynamic-configs-disable put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/disable")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Dynamic Config
#
# PUT /console/v1/dynamic_configs/{id}/enable
export def "console-dynamic-configs-enable put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/enable")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Specific Dynamic Config Rule
#
# GET /console/v1/dynamic_configs/{id}/rule/{ruleId}
export def "console-dynamic-configs-rule get" [
  id: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, passPercentage: float, conditions: list<record>, environments: list<string>, id: string, baseID: string, returnValue: record, completedAutomatedRollouts: list<record>, pendingAutomatedRollouts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/rule/($ruleId)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Dynamic Config Rule By Id
#
# PATCH /console/v1/dynamic_configs/{id}/rule/{ruleId}
# --conditions item shape: {targetValue?: any, operator?: string, field?: string, customID?: string, type: "app_version"|"browser_name"|"browser_version"|"country"|"custom_field"|"email"|"environment_tier"|"fails_gate"|"fails_segment"|"ip_address"|"locale"|"os_name"|"os_version"|"passes_gate"|"passes_segment"|"public"|"time"|"unit_id"|"user_id"|"url"|"javascript"|"device_model"|"target_app"}
# --completedAutomatedRollouts item shape: {time: float, passPercent: float}
# --pendingAutomatedRollouts item shape: {time: float, passPercent: float}
# --variants item shape: {id?: string, name: string, passPercentage: float, returnValue?: record, returnValueJson5?: string}
export def "console-dynamic-configs-rule patch" [
  id: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The name of this rule.
  --passPercentage: float # Of the users that meet the conditions of this rule, what percent should return true. (format: double)
  --conditions: list # An array of Condition objects. — item shape: {targetValue?: any, operator?: string, field?: string, customID?: string, type: "app_version"|"browser_name"|"browser_version"|"country"|"custom_field"|"email"|"environment_tier"|"fails_gate"|"fails_segment"|"ip_address"|"locale"|"os_name"|"os_version"|"passes_gate"|"passes_segment"|"public"|"time"|"unit_id"|"user_id"|"url"|"javascript"|"device_model"|"target_app"}
  --environments: list # nullable
  --body-id: string # The Statsig ID of this rule.
  --baseID: string # The base ID of this rule, i.e. without any added metadata. Will remain the exact same throughout
  --returnValue: record
  --completedAutomatedRollouts: list # item shape: {time: float, passPercent: float}
  --pendingAutomatedRollouts: list # item shape: {time: float, passPercent: float}
  --returnValueJson5: string
  --variants: list # item shape: {id?: string, name: string, passPercentage: float, returnValue?: record, returnValueJson5?: string}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/rule/($ruleId)")
  let body = {name: $name, passPercentage: $passPercentage, conditions: $conditions, environments: $environments, id: $body_id, baseID: $baseID, returnValue: $returnValue, completedAutomatedRollouts: $completedAutomatedRollouts, pendingAutomatedRollouts: $pendingAutomatedRollouts, returnValueJson5: $returnValueJson5, variants: $variants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Dynamic Config Rule
#
# DELETE /console/v1/dynamic_configs/{id}/rule/{ruleId}
export def "console-dynamic-configs-rule delete" [
  id: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/rule/($ruleId)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dynamic Config Rules
#
# GET /console/v1/dynamic_configs/{id}/rules
export def "console-dynamic-configs-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<rules: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/rules")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive Dynamic Config
#
# PUT /console/v1/dynamic_configs/{id}/unarchive
export def "console-dynamic-configs-unarchive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --unarchiveReason: string # The reason for unarchiving the gate (e.g. The gate is needed again)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, rules: list<record>, defaultValue: record, defaultValueJson5: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/unarchive")
  let body = {unarchiveReason: $unarchiveReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Dynamic Config Versions
#
# GET /console/v1/dynamic_configs/{id}/versions
export def "console-dynamic-configs-versions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, isEnabled: bool, rules: list, defaultValue: record, defaultValueJson5: string, owner: record, schema: string, schemaJson5: string, releasePipelineID: string, isTemplate: bool, status: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/dynamic_configs/($id)/versions" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Environments
#
# GET /console/v1/environments
export def "console-environments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<environments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/environments")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Environments
#
# POST /console/v1/environments
# --environments item shape: {name: string, id?: string, isProduction: bool, requiresReview: bool, requiredReviewGroupID?: string, requiresReleasePipeline: bool}
export def "console-environments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  environments: list # item shape: {name: string, id?: string, isProduction: bool, requiresReview: bool, requiredReviewGroupID?: string, requiresReleasePipeline: bool}
]: any -> record<message: string, data: record<environments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/environments")
  let body = {environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Events
#
# GET /console/v1/events
export def "console-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<timestamp: string, name: string, source: string, value: string, userID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/events" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific events
#
# GET /console/v1/events/{eventName}
export def "console-events get" [
  eventName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<timestamp: string, name: string, source: string, value: string, userID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/events/($eventName)" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics using event name
#
# GET /console/v1/events/{eventName}/metrics
export def "console-events-metrics get" [
  eventName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list, metricEvents: list, metricComponentMetrics: list, description: string, directionality: string, tags: list, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list, funnelCountDistinct: string, warehouseNative: record, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/events/($eventName)/metrics" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Experiments
#
# GET /console/v1/experiments
export def "console-experiments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --layerID: string # Which layer to place the experiment into.
  --idType: string # The idType the experiment will be performed on
  --teamID: string # The team ID associated with the experiment, Enterprise only. (nullable)
  --status: string # The current status of the experiment
  --targetAppID: string
  --createdStartDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --createdEndDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --creatorName: string # Name of the creator. (nullable)
  --creatorID: string # ID of the user who created the entity. (nullable)
  --tags: string # Filter by tags
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<reviewSettings: record, activeReview: record, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list, groups: list, controlGroupID: string, allocation: float, primaryMetricTags: list, secondaryMetricTags: list, primaryMetrics: list, secondaryMetrics: list, otherMetrics: list, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list, healthCheckStatus: string, owner: record, inlineTargetingRulesJSON: string, summarySections: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "layerID" $layerID "scalar") (serialize-qp "idType" $idType "scalar") (serialize-qp "teamID" $teamID "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "targetAppID" $targetAppID "scalar") (serialize-qp "createdStartDate" $createdStartDate "scalar") (serialize-qp "createdEndDate" $createdEndDate "scalar") (serialize-qp "creatorName" $creatorName "scalar") (serialize-qp "creatorID" $creatorID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/experiments" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Experiment
#
# POST /console/v1/experiments
# --links item shape: {url: string, title?: string}
# --groups item shape: {name: string, id?: string, size: float, parameterValues: record, disabled?: bool, description?: string, foreignGroupID?: string}
# --primaryMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --secondaryMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --otherMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --manualQualityScores item shape: {criteriaName: any, status: "PASSED"|"FAILED"|"WARNING", criteriaDescription: string, score: float, weight: float}
# --assignmentSourceFilters item shape: {column?: string, condition: "in"|"not_in"|"="|">"|"<"|">="|"<="|"is_null"|"non_null"|"contains"|"not_contains"|"sql_filter"|"starts_with"|"ends_with"|"after_exposure"|"before_exposure"|"is_true"|"is_false", values?: list}
# --stratifiedSampling shape: {status: "pending"|"success"|"error", metric?: record, entityPropertySource?: record, csv?: record}
export def "console-experiments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The experiment display name
  --description: string # A description of the new experiment
  --idType: string # The idType the experiment will be performed on
  --secondaryIDType: string # The secondary ID type for the experiment used in WHN for ID resolution (nullable)
  --identifierMappingMode: string@identifierMappingMode-completer # The identifier mapping mode for the experiment used in WHN for ID resolution
  --identityResolutionSource: string # The identity resolution entity property source for the experiment used in WHN for ID resolution (nullable)
  --hypothesis: string # A statement that will be tested by this experiment
  --links: list # Links to relevant documentation or resources — item shape: {url: string, title?: string}
  --groups: list # The test groups for your experiment — item shape: {name: string, id?: string, size: float, parameterValues: record, disabled?: bool, description?: string, foreignGroupID?: string}
  --controlGroupID: string # Optional control group ID
  --allocation: float # Percent of layer allocated to this experiment (format: double)
  --primaryMetricTags: list # Primary metric tags for the experiment
  --secondaryMetricTags: list # Secondary metric tags for the experiment
  --primaryMetrics: list # Main metrics needed to evaluate your hypothesis — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --secondaryMetrics: list # Additional metrics to monitor that might impact the analysis or final decision of the experiment — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --otherMetrics: list # Additional metrics you want to investigate or learn from. The usual corrections applied to Primary and Secondary metrics are not applied to these. — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --targetApps: any # Target apps assigned to this experiment
  --tags: list # Tags associated with the experiment
  --duration: int # How long the experiment is expected to last in days (format: int64)
  --targetExposures: int # Target exposures for the experiment (format: int64)
  --targetingGateID: string # Restrict your experiment to users passing the selected feature gate (nullable)
  --sequentialTesting: string@bool-completer # Apply sequential testing?
  --bonferroniCorrection: string@bool-completer # Is Bonferroni correction applied per variant?
  --bonferroniCorrectionPerMetric: string@bool-completer # Is Bonferroni correction applied per metric?
  --benjaminiHochbergPerVariant: string@bool-completer # Is Benjamini-Hochberg procedure applied per variant?
  --benjaminiHochbergPerMetric: string@bool-completer # Is Benjamini-Hochberg procedure applied per metric?
  --benjaminiPrimaryMetricsOnly: string@bool-completer # Is Benjamini-Hochberg procedure applied for primary metrics only?
  --defaultConfidenceInterval: string@defaultConfidenceInterval-completer # Default error margin used for results
  --manualQualityScores: list # Up to 10 manually set quality scores for an experiment. The scores and weights will be added to the existing weights and scores, and then weights will be renormalized to 100. This can be set via the Statsig Console API. If targeting a default check, the weight of the check will be updated, but not the status or description. A default score can be removed by setting the weight to 0. The default score identifiers are one of: HYPOTHESIS_LENGTH, BALANCED_EXPOSURE, PRIMARY_METRICS_LENGTH, COMPARISON_CORRECTION, GUARDRAIL_METRIC_TAGS, SUFFICIENT_SAMPLE, POWER_ANALYSIS, SEQUENTIAL_TESTING — item shape: {criteriaName: any, status: "PASSED"|"FAILED"|"WARNING", criteriaDescription: string, score: float, weight: float}
  --status: string@status-completer # The current status of the experiment
  --launchedGroupID: string # ID of the launched group, null otherwise (nullable)
  --assignmentSourceName: string # Source name of the assignment
  --assignmentSourceExperimentName: string # Name of the source experiment for assignment
  --creatorID: string # The Statsig ID of the creator of this experiment (nullable)
  --creatorEmail: string # The email of the creator of this experiment (nullable)
  --isAnalysisOnly: string@bool-completer # For Warehouse Native (nullable)
  --team: string # The team name associated with the experiment, Enterprise only. (nullable)
  --teamID: string # The team ID associated with the experiment, Enterprise only. (nullable)
  --allocationDuration: int # Warehouse Native Only - Allocation duration in days (nullable, format: int64)
  --cohortedAnalysisDuration: int # Warehouse Native Only - Cohorted analysis duration in days (format: int64)
  --cohortedMetricsMatureAfterEnd: string@bool-completer # Warehouse Native Only - Allow cohort metrics to mature after experiment end
  --cohortWaitUntilEndToInclude: string@bool-completer # Warehouse Native Only - Whether to filter to units whose experiment cohort analysis duration is complete, if cohortedAnalysisDuration exists
  --fixedAnalysisDuration: int # Fixed analysis duration in days (format: int64)
  --scheduledReloadHour: int # Warehouse Native only - UTC hour at which to run scheduled pulse loads (nullable, format: int64)
  --scheduledReloadType: string@scheduledReloadType-completer # Warehouse Native only - reload type for scheduled reloads
  --analysisEndTime: string # Warehouse Native only - end time for analysis only experiments
  --assignmentSourceFilters: list # Array of criteria for filtering assignment sources. — item shape: {column?: string, condition: "in"|"not_in"|"="|">"|"<"|">="|"<="|"is_null"|"non_null"|"contains"|"not_contains"|"sql_filter"|"starts_with"|"ends_with"|"after_exposure"|"before_exposure"|"is_true"|"is_false", values?: list}
  --analyticsType: string@analyticsType-completer # The mode of analysis for the experiment, e.g frequentist, bayesian, sprt
  --isSidecar: string@bool-completer # Whether this is a Statsig Sidecar experiment.
  --decisionReason: string # Experiment notes reported after experiment completes
  --stratifiedSampling: record # The stratified sampling settings for the experiment (nullable) — shape: {status: "pending"|"success"|"error", metric?: record, entityPropertySource?: record, csv?: record}
  --id: string # The experiment name ID
  --layerID: string # Which layer to place the experiment into.
]: any -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/experiments")
  let body = {name: $name, description: $description, idType: $idType, secondaryIDType: $secondaryIDType, identifierMappingMode: $identifierMappingMode, identityResolutionSource: $identityResolutionSource, hypothesis: $hypothesis, links: $links, groups: $groups, controlGroupID: $controlGroupID, allocation: $allocation, primaryMetricTags: $primaryMetricTags, secondaryMetricTags: $secondaryMetricTags, primaryMetrics: $primaryMetrics, secondaryMetrics: $secondaryMetrics, otherMetrics: $otherMetrics, targetApps: $targetApps, tags: $tags, duration: $duration, targetExposures: $targetExposures, targetingGateID: $targetingGateID, sequentialTesting: $sequentialTesting, bonferroniCorrection: $bonferroniCorrection, bonferroniCorrectionPerMetric: $bonferroniCorrectionPerMetric, benjaminiHochbergPerVariant: $benjaminiHochbergPerVariant, benjaminiHochbergPerMetric: $benjaminiHochbergPerMetric, benjaminiPrimaryMetricsOnly: $benjaminiPrimaryMetricsOnly, defaultConfidenceInterval: $defaultConfidenceInterval, manualQualityScores: $manualQualityScores, status: $status, launchedGroupID: $launchedGroupID, assignmentSourceName: $assignmentSourceName, assignmentSourceExperimentName: $assignmentSourceExperimentName, creatorID: $creatorID, creatorEmail: $creatorEmail, isAnalysisOnly: $isAnalysisOnly, team: $team, teamID: $teamID, allocationDuration: $allocationDuration, cohortedAnalysisDuration: $cohortedAnalysisDuration, cohortedMetricsMatureAfterEnd: $cohortedMetricsMatureAfterEnd, cohortWaitUntilEndToInclude: $cohortWaitUntilEndToInclude, fixedAnalysisDuration: $fixedAnalysisDuration, scheduledReloadHour: $scheduledReloadHour, scheduledReloadType: $scheduledReloadType, analysisEndTime: $analysisEndTime, assignmentSourceFilters: $assignmentSourceFilters, analyticsType: $analyticsType, isSidecar: $isSidecar, decisionReason: $decisionReason, stratifiedSampling: $stratifiedSampling, id: $id, layerID: $layerID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Experiment
#
# GET /console/v1/experiments/{id}
export def "console-experiments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fully Update Experiment
#
# POST /console/v1/experiments/{id}
# --links item shape: {url: string, title?: string}
# --groups item shape: {name: string, id?: string, size: float, parameterValues: record, disabled?: bool, description?: string, foreignGroupID?: string}
# --primaryMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --secondaryMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --otherMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --manualQualityScores item shape: {criteriaName: any, status: "PASSED"|"FAILED"|"WARNING", criteriaDescription: string, score: float, weight: float}
# --assignmentSourceFilters item shape: {column?: string, condition: "in"|"not_in"|"="|">"|"<"|">="|"<="|"is_null"|"non_null"|"contains"|"not_contains"|"sql_filter"|"starts_with"|"ends_with"|"after_exposure"|"before_exposure"|"is_true"|"is_false", values?: list}
# --stratifiedSampling shape: {status: "pending"|"success"|"error", metric?: record, entityPropertySource?: record, csv?: record}
export def "console-experiments post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The display name of the experiment
  description: string # A helpful summary of what this experiment does
  idType: string # The type of ID which the experiment is based on
  --secondaryIDType: string # The secondary ID type for the experiment used in WHN for ID resolution (nullable)
  --identifierMappingMode: string@identifierMappingMode-completer # The identifier mapping mode for the experiment used in WHN for ID resolution
  --identityResolutionSource: string # The identity resolution entity property source for the experiment used in WHN for ID resolution (nullable)
  hypothesis: string # A statement that will be tested by this experiment
  --links: list # Links to relevant documentation or resources — item shape: {url: string, title?: string}
  groups: list # The test groups for your experiment — item shape: {name: string, id?: string, size: float, parameterValues: record, disabled?: bool, description?: string, foreignGroupID?: string}
  --controlGroupID: string # Optional control group ID
  allocation: float # Percent of layer allocated to this experiment (format: double)
  --primaryMetricTags: list # Primary metric tags for the experiment
  --secondaryMetricTags: list # Secondary metric tags for the experiment
  --primaryMetrics: list # Main metrics needed to evaluate your hypothesis — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --secondaryMetrics: list # Additional metrics to monitor that might impact the analysis or final decision of the experiment — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --otherMetrics: list # Additional metrics you want to investigate or learn from. The usual corrections applied to Primary and Secondary metrics are not applied to these. — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --targetApps: any # Target apps assigned to this experiment
  --tags: list # Tags associated with the experiment
  --duration: int # How long the experiment is expected to last in days (format: int64)
  --targetExposures: int # Target exposures for the experiment (format: int64)
  --targetingGateID: string # Restrict your experiment to users passing the selected feature gate (nullable)
  --sequentialTesting: string@bool-completer # Apply sequential testing?
  --bonferroniCorrection: string@bool-completer # Is Bonferroni correction applied per variant?
  --bonferroniCorrectionPerMetric: string@bool-completer # Is Bonferroni correction applied per metric?
  --benjaminiHochbergPerVariant: string@bool-completer # Is Benjamini-Hochberg procedure applied per variant?
  --benjaminiHochbergPerMetric: string@bool-completer # Is Benjamini-Hochberg procedure applied per metric?
  --benjaminiPrimaryMetricsOnly: string@bool-completer # Is Benjamini-Hochberg procedure applied for primary metrics only?
  defaultConfidenceInterval: string@defaultConfidenceInterval-completer # Default error margin used for results
  --manualQualityScores: list # Up to 10 manually set quality scores for an experiment. The scores and weights will be added to the existing weights and scores, and then weights will be renormalized to 100. This can be set via the Statsig Console API. If targeting a default check, the weight of the check will be updated, but not the status or description. A default score can be removed by setting the weight to 0. The default score identifiers are one of: HYPOTHESIS_LENGTH, BALANCED_EXPOSURE, PRIMARY_METRICS_LENGTH, COMPARISON_CORRECTION, GUARDRAIL_METRIC_TAGS, SUFFICIENT_SAMPLE, POWER_ANALYSIS, SEQUENTIAL_TESTING — item shape: {criteriaName: any, status: "PASSED"|"FAILED"|"WARNING", criteriaDescription: string, score: float, weight: float}
  status: string@status-completer # The current status of the experiment
  --launchedGroupID: string # ID of the launched group, null otherwise (nullable)
  --assignmentSourceName: string # Source name of the assignment
  --assignmentSourceExperimentName: string # Name of the source experiment for assignment
  --creatorID: string # The Statsig ID of the creator of this experiment (nullable)
  --creatorEmail: string # The email of the creator of this experiment (nullable)
  --isAnalysisOnly: string@bool-completer # For Warehouse Native (nullable)
  --team: string # The team name associated with the experiment, Enterprise only. (nullable)
  --teamID: string # The team ID associated with the experiment, Enterprise only. (nullable)
  --allocationDuration: int # Warehouse Native Only - Allocation duration in days (nullable, format: int64)
  --cohortedAnalysisDuration: int # Warehouse Native Only - Cohorted analysis duration in days (format: int64)
  --cohortedMetricsMatureAfterEnd: string@bool-completer # Warehouse Native Only - Allow cohort metrics to mature after experiment end
  --cohortWaitUntilEndToInclude: string@bool-completer # Warehouse Native Only - Whether to filter to units whose experiment cohort analysis duration is complete, if cohortedAnalysisDuration exists
  --fixedAnalysisDuration: int # Fixed analysis duration in days (format: int64)
  --scheduledReloadHour: int # Warehouse Native only - UTC hour at which to run scheduled pulse loads (nullable, format: int64)
  --scheduledReloadType: string@scheduledReloadType-completer # Warehouse Native only - reload type for scheduled reloads
  --analysisEndTime: string # Warehouse Native only - end time for analysis only experiments
  --assignmentSourceFilters: list # Array of criteria for filtering assignment sources. — item shape: {column?: string, condition: "in"|"not_in"|"="|">"|"<"|">="|"<="|"is_null"|"non_null"|"contains"|"not_contains"|"sql_filter"|"starts_with"|"ends_with"|"after_exposure"|"before_exposure"|"is_true"|"is_false", values?: list}
  --analyticsType: string@analyticsType-completer # The mode of analysis for the experiment, e.g frequentist, bayesian, sprt
  --isSidecar: string@bool-completer # Whether this is a Statsig Sidecar experiment.
  --decisionReason: string # Experiment notes reported after experiment completes
  --stratifiedSampling: record # The stratified sampling settings for the experiment (nullable) — shape: {status: "pending"|"success"|"error", metric?: record, entityPropertySource?: record, csv?: record}
]: any -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)")
  let body = {name: $name, description: $description, idType: $idType, secondaryIDType: $secondaryIDType, identifierMappingMode: $identifierMappingMode, identityResolutionSource: $identityResolutionSource, hypothesis: $hypothesis, links: $links, groups: $groups, controlGroupID: $controlGroupID, allocation: $allocation, primaryMetricTags: $primaryMetricTags, secondaryMetricTags: $secondaryMetricTags, primaryMetrics: $primaryMetrics, secondaryMetrics: $secondaryMetrics, otherMetrics: $otherMetrics, targetApps: $targetApps, tags: $tags, duration: $duration, targetExposures: $targetExposures, targetingGateID: $targetingGateID, sequentialTesting: $sequentialTesting, bonferroniCorrection: $bonferroniCorrection, bonferroniCorrectionPerMetric: $bonferroniCorrectionPerMetric, benjaminiHochbergPerVariant: $benjaminiHochbergPerVariant, benjaminiHochbergPerMetric: $benjaminiHochbergPerMetric, benjaminiPrimaryMetricsOnly: $benjaminiPrimaryMetricsOnly, defaultConfidenceInterval: $defaultConfidenceInterval, manualQualityScores: $manualQualityScores, status: $status, launchedGroupID: $launchedGroupID, assignmentSourceName: $assignmentSourceName, assignmentSourceExperimentName: $assignmentSourceExperimentName, creatorID: $creatorID, creatorEmail: $creatorEmail, isAnalysisOnly: $isAnalysisOnly, team: $team, teamID: $teamID, allocationDuration: $allocationDuration, cohortedAnalysisDuration: $cohortedAnalysisDuration, cohortedMetricsMatureAfterEnd: $cohortedMetricsMatureAfterEnd, cohortWaitUntilEndToInclude: $cohortWaitUntilEndToInclude, fixedAnalysisDuration: $fixedAnalysisDuration, scheduledReloadHour: $scheduledReloadHour, scheduledReloadType: $scheduledReloadType, analysisEndTime: $analysisEndTime, assignmentSourceFilters: $assignmentSourceFilters, analyticsType: $analyticsType, isSidecar: $isSidecar, decisionReason: $decisionReason, stratifiedSampling: $stratifiedSampling} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially Update Experiment
#
# PATCH /console/v1/experiments/{id}
# --links item shape: {url: string, title?: string}
# --groups item shape: {name: string, id?: string, size: float, parameterValues: record, disabled?: bool, description?: string, foreignGroupID?: string}
# --primaryMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --secondaryMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --otherMetrics item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
# --manualQualityScores item shape: {criteriaName: any, status: "PASSED"|"FAILED"|"WARNING", criteriaDescription: string, score: float, weight: float}
# --assignmentSourceFilters item shape: {column?: string, condition: "in"|"not_in"|"="|">"|"<"|">="|"<="|"is_null"|"non_null"|"contains"|"not_contains"|"sql_filter"|"starts_with"|"ends_with"|"after_exposure"|"before_exposure"|"is_true"|"is_false", values?: list}
# --stratifiedSampling shape: {status: "pending"|"success"|"error", metric?: record, entityPropertySource?: record, csv?: record}
export def "console-experiments patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The display name of the experiment
  --description: string # A helpful summary of what this experiment does
  --idType: string # The type of ID which the experiment is based on
  --secondaryIDType: string # The secondary ID type for the experiment used in WHN for ID resolution (nullable)
  --identifierMappingMode: string@identifierMappingMode-completer # The identifier mapping mode for the experiment used in WHN for ID resolution
  --identityResolutionSource: string # The identity resolution entity property source for the experiment used in WHN for ID resolution (nullable)
  --hypothesis: string # A statement that will be tested by this experiment
  --links: list # Links to relevant documentation or resources — item shape: {url: string, title?: string}
  --groups: list # The test groups for your experiment — item shape: {name: string, id?: string, size: float, parameterValues: record, disabled?: bool, description?: string, foreignGroupID?: string}
  --controlGroupID: string # Optional control group ID
  --allocation: float # Percent of layer allocated to this experiment (format: double)
  --primaryMetricTags: list # Primary metric tags for the experiment
  --secondaryMetricTags: list # Secondary metric tags for the experiment
  --primaryMetrics: list # Main metrics needed to evaluate your hypothesis — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --secondaryMetrics: list # Additional metrics to monitor that might impact the analysis or final decision of the experiment — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --otherMetrics: list # Additional metrics you want to investigate or learn from. The usual corrections applied to Primary and Secondary metrics are not applied to these. — item shape: {name: string, type: string, direction?: "increase"|"decrease", hypothesizedValue?: float}
  --targetApps: any # Target apps assigned to this experiment
  --tags: list # Tags associated with the experiment
  --duration: int # How long the experiment is expected to last in days (format: int64)
  --targetExposures: int # Target exposures for the experiment (format: int64)
  --targetingGateID: string # Restrict your experiment to users passing the selected feature gate (nullable)
  --sequentialTesting: string@bool-completer # Apply sequential testing?
  --bonferroniCorrection: string@bool-completer # Is Bonferroni correction applied per variant?
  --bonferroniCorrectionPerMetric: string@bool-completer # Is Bonferroni correction applied per metric?
  --benjaminiHochbergPerVariant: string@bool-completer # Is Benjamini-Hochberg procedure applied per variant?
  --benjaminiHochbergPerMetric: string@bool-completer # Is Benjamini-Hochberg procedure applied per metric?
  --benjaminiPrimaryMetricsOnly: string@bool-completer # Is Benjamini-Hochberg procedure applied for primary metrics only?
  --defaultConfidenceInterval: string@defaultConfidenceInterval-completer # Default error margin used for results
  --manualQualityScores: list # Up to 10 manually set quality scores for an experiment. The scores and weights will be added to the existing weights and scores, and then weights will be renormalized to 100. This can be set via the Statsig Console API. If targeting a default check, the weight of the check will be updated, but not the status or description. A default score can be removed by setting the weight to 0. The default score identifiers are one of: HYPOTHESIS_LENGTH, BALANCED_EXPOSURE, PRIMARY_METRICS_LENGTH, COMPARISON_CORRECTION, GUARDRAIL_METRIC_TAGS, SUFFICIENT_SAMPLE, POWER_ANALYSIS, SEQUENTIAL_TESTING — item shape: {criteriaName: any, status: "PASSED"|"FAILED"|"WARNING", criteriaDescription: string, score: float, weight: float}
  --status: string@status-completer # The current status of the experiment
  --launchedGroupID: string # ID of the launched group, null otherwise (nullable)
  --assignmentSourceName: string # Source name of the assignment
  --assignmentSourceExperimentName: string # Name of the source experiment for assignment
  --creatorID: string # The Statsig ID of the creator of this experiment (nullable)
  --creatorEmail: string # The email of the creator of this experiment (nullable)
  --isAnalysisOnly: string@bool-completer # For Warehouse Native (nullable)
  --team: string # The team name associated with the experiment, Enterprise only. (nullable)
  --teamID: string # The team ID associated with the experiment, Enterprise only. (nullable)
  --allocationDuration: int # Warehouse Native Only - Allocation duration in days (nullable, format: int64)
  --cohortedAnalysisDuration: int # Warehouse Native Only - Cohorted analysis duration in days (format: int64)
  --cohortedMetricsMatureAfterEnd: string@bool-completer # Warehouse Native Only - Allow cohort metrics to mature after experiment end
  --cohortWaitUntilEndToInclude: string@bool-completer # Warehouse Native Only - Whether to filter to units whose experiment cohort analysis duration is complete, if cohortedAnalysisDuration exists
  --fixedAnalysisDuration: int # Fixed analysis duration in days (format: int64)
  --scheduledReloadHour: int # Warehouse Native only - UTC hour at which to run scheduled pulse loads (nullable, format: int64)
  --scheduledReloadType: string@scheduledReloadType-completer # Warehouse Native only - reload type for scheduled reloads
  --analysisEndTime: string # Warehouse Native only - end time for analysis only experiments
  --assignmentSourceFilters: list # Array of criteria for filtering assignment sources. — item shape: {column?: string, condition: "in"|"not_in"|"="|">"|"<"|">="|"<="|"is_null"|"non_null"|"contains"|"not_contains"|"sql_filter"|"starts_with"|"ends_with"|"after_exposure"|"before_exposure"|"is_true"|"is_false", values?: list}
  --analyticsType: string@analyticsType-completer # The mode of analysis for the experiment, e.g frequentist, bayesian, sprt
  --isSidecar: string@bool-completer # Whether this is a Statsig Sidecar experiment.
  --decisionReason: string # Experiment notes reported after experiment completes
  --stratifiedSampling: record # The stratified sampling settings for the experiment (nullable) — shape: {status: "pending"|"success"|"error", metric?: record, entityPropertySource?: record, csv?: record}
]: any -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)")
  let body = {name: $name, description: $description, idType: $idType, secondaryIDType: $secondaryIDType, identifierMappingMode: $identifierMappingMode, identityResolutionSource: $identityResolutionSource, hypothesis: $hypothesis, links: $links, groups: $groups, controlGroupID: $controlGroupID, allocation: $allocation, primaryMetricTags: $primaryMetricTags, secondaryMetricTags: $secondaryMetricTags, primaryMetrics: $primaryMetrics, secondaryMetrics: $secondaryMetrics, otherMetrics: $otherMetrics, targetApps: $targetApps, tags: $tags, duration: $duration, targetExposures: $targetExposures, targetingGateID: $targetingGateID, sequentialTesting: $sequentialTesting, bonferroniCorrection: $bonferroniCorrection, bonferroniCorrectionPerMetric: $bonferroniCorrectionPerMetric, benjaminiHochbergPerVariant: $benjaminiHochbergPerVariant, benjaminiHochbergPerMetric: $benjaminiHochbergPerMetric, benjaminiPrimaryMetricsOnly: $benjaminiPrimaryMetricsOnly, defaultConfidenceInterval: $defaultConfidenceInterval, manualQualityScores: $manualQualityScores, status: $status, launchedGroupID: $launchedGroupID, assignmentSourceName: $assignmentSourceName, assignmentSourceExperimentName: $assignmentSourceExperimentName, creatorID: $creatorID, creatorEmail: $creatorEmail, isAnalysisOnly: $isAnalysisOnly, team: $team, teamID: $teamID, allocationDuration: $allocationDuration, cohortedAnalysisDuration: $cohortedAnalysisDuration, cohortedMetricsMatureAfterEnd: $cohortedMetricsMatureAfterEnd, cohortWaitUntilEndToInclude: $cohortWaitUntilEndToInclude, fixedAnalysisDuration: $fixedAnalysisDuration, scheduledReloadHour: $scheduledReloadHour, scheduledReloadType: $scheduledReloadType, analysisEndTime: $analysisEndTime, assignmentSourceFilters: $assignmentSourceFilters, analyticsType: $analyticsType, isSidecar: $isSidecar, decisionReason: $decisionReason, stratifiedSampling: $stratifiedSampling} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deleted Experiment
#
# DELETE /console/v1/experiments/{id}
export def "console-experiments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Abandon Experiment
#
# PUT /console/v1/experiments/{id}/abandon
export def "console-experiments-abandon put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  decisionReason: string # The reason for making the decision to update the experiment status (e.g. Your reason for stopping early)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/abandon")
  let body = {decisionReason: $decisionReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve Metric Rollout Alert
#
# POST /console/v1/experiments/{id}/alerts/{metricId}/resolve
export def "console-experiments-alerts-resolve post" [
  id: string
  metricId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --reasoning: string # Reason for resolving the alert (e.g. Issue has been addressed)
]: any -> record<message: string, data: record<resolvedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/alerts/($metricId)/resolve")
  let body = {reasoning: $reasoning} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive Experiment
#
# PUT /console/v1/experiments/{id}/archive
export def "console-experiments-archive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --archiveReason: string # The reason for archiving the experiment (e.g. The experiment is no longer needed)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/archive")
  let body = {archiveReason: $archiveReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve cumulative exposures
#
# GET /console/v1/experiments/{id}/cumulative_exposures
export def "console-experiments-cumulative-exposures get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<groupID: string, groupName: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/cumulative_exposures")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Experiment Groups
#
# POST /console/v1/experiments/{id}/disable_groups
export def "console-experiments-disable-groups post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  group_names: list
]: any -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/disable_groups")
  let body = {group_names: $group_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable Experiment Groups
#
# POST /console/v1/experiments/{id}/enable_groups
export def "console-experiments-enable-groups post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  group_names: list
]: any -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/enable_groups")
  let body = {group_names: $group_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Pulse (Warehouse Native)
#
# POST /console/v1/experiments/{id}/load_pulse
export def "console-experiments-load-pulse post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refresh: string@refresh-completer # default: full
  --metricIDs: list
  --ruleId: string
  --turboMode: string@bool-completer
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --refresh: string@refresh-completer # default: full
  --metricIDs: list
  --ruleId: string
  --turboMode: string@bool-completer
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refresh" $refresh "scalar") (serialize-qp "metricIDs" $metricIDs "multi") (serialize-qp "ruleId" $ruleId "scalar") (serialize-qp "turboMode" $turboMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/experiments/($id)/load_pulse" $qp)
  let body = {refresh: $refresh, metricIDs: $metricIDs, ruleId: $ruleId, turboMode: $turboMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finish Experiment Early
#
# PUT /console/v1/experiments/{id}/make_decision
export def "console-experiments-make-decision put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-id: string # The ID of the group to launch (e.g. groupid123)
  decisionReason: string # The reason for making the decision to update the experiment status (e.g. Your reason for stopping early)
  --removeTargeting: string@bool-completer # Indicates whether to remove targeting from the experiment (default: false, e.g. false)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/make_decision")
  let body = {id: $body_id, decisionReason: $decisionReason, removeTargeting: $removeTargeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Experiment Overrides
#
# GET /console/v1/experiments/{id}/overrides
export def "console-experiments-overrides get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<overrides: list<record>, userIDOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Experiment Overrides
#
# POST /console/v1/experiments/{id}/overrides
# --overrides item shape: {type: "gate"|"segment", id: string, groupID: string, environment?: string}
# --userIDOverrides item shape: {groupID: string, ids: list, environment?: string, unitType?: string}
export def "console-experiments-overrides post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  overrides: list # Array of experiment overrides, each specifying type, ID, and group ID. — item shape: {type: "gate"|"segment", id: string, groupID: string, environment?: string}
  userIDOverrides: list # Array of user ID overrides, specifying which users to force into experiment groups. — item shape: {groupID: string, ids: list, environment?: string, unitType?: string}
]: any -> record<message: string, data: record<overrides: list<record>, userIDOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/overrides")
  let body = {overrides: $overrides, userIDOverrides: $userIDOverrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially Update Experiment Overrides
#
# PATCH /console/v1/experiments/{id}/overrides
# --overrides item shape: {type: "gate"|"segment", id: string, groupID: string, environment?: string}
# --userIDOverrides item shape: {groupID: string, ids: list, environment?: string, unitType?: string}
export def "console-experiments-overrides patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  overrides: list # Array of experiment overrides, each specifying type, ID, and group ID. — item shape: {type: "gate"|"segment", id: string, groupID: string, environment?: string}
  userIDOverrides: list # Array of user ID overrides, specifying which users to force into experiment groups. — item shape: {groupID: string, ids: list, environment?: string, unitType?: string}
]: any -> record<message: string, data: record<overrides: list<record>, userIDOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/overrides")
  let body = {overrides: $overrides, userIDOverrides: $userIDOverrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Experiment Overrides
#
# DELETE /console/v1/experiments/{id}/overrides
export def "console-experiments-overrides delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<overrides: list<record>, userIDOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pulse Load History (Warehouse Native)
#
# GET /console/v1/experiments/{id}/pulse_load_history
export def "console-experiments-pulse-load-history get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<creatorName: string, createdTime: float, finishedTime: float, finishedState: string, startDs: string, endDs: string, reloadType: string, turboMode: bool>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/experiments/($id)/pulse_load_history" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Pulse Results (Beta)
#
# GET /console/v1/experiments/{id}/pulse_results
export def "console-experiments-pulse-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --control: string # Control Group ID
  --test: string # Test Group ID
  --cuped: string # Whether to apply CUPED. Allowed values are "true" or "false".
  --confidence: string # Confidence interval (0-100)
  --applyBonferroniPerVariant: string # Whether to apply Bonferroni Per Variant. Allowed values are "true" or "false".
  --applyBonferroniPerMetric: string # Whether to apply Bonferroni Per Metric. Allowed values are "true" or "false".
  --bonferroniPrimaryMetricWeight: string # α allocated to primary metrics
  --applyBenjaminiHochbergPerMetric: string # Whether to apply Benjamini-Hochberg Correction Per Metric. Allowed values are "true" or "false".
  --applyBenjaminiHochbergPerVariant: string # Whether to apply Benjamini-Hochberg Correction Per Variant. Allowed values are "true" or "false".
  --date: string # Date for pulse results. format must be YYYY-MM-DD
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<ds: string, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "control" $control "scalar") (serialize-qp "test" $test "scalar") (serialize-qp "cuped" $cuped "scalar") (serialize-qp "confidence" $confidence "scalar") (serialize-qp "applyBonferroniPerVariant" $applyBonferroniPerVariant "scalar") (serialize-qp "applyBonferroniPerMetric" $applyBonferroniPerMetric "scalar") (serialize-qp "bonferroniPrimaryMetricWeight" $bonferroniPrimaryMetricWeight "scalar") (serialize-qp "applyBenjaminiHochbergPerMetric" $applyBenjaminiHochbergPerMetric "scalar") (serialize-qp "applyBenjaminiHochbergPerVariant" $applyBenjaminiHochbergPerVariant "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/experiments/($id)/pulse_results" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset Experiment
#
# PUT /console/v1/experiments/{id}/reset
export def "console-experiments-reset put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/reset")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart As New Experiment
#
# POST /console/v1/experiments/{id}/restart_as_new
export def "console-experiments-restart-as-new post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The experiment display name
]: any -> record<message: string, data: record<reviewSettings: record<requiredReview: bool, allowedReviewers: list>, activeReview: record<reviewID: string, reviewStatus: string, description: string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list<record>, groups: list<record>, controlGroupID: string, allocation: float, primaryMetricTags: list<string>, secondaryMetricTags: list<string>, primaryMetrics: list<record>, secondaryMetrics: list<record>, otherMetrics: list<record>, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list<record>, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list<record>, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record<status: string, metric: record, entityPropertySource: record, csv: record>, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list<record>, healthCheckStatus: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, inlineTargetingRulesJSON: string, summarySections: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/restart_as_new")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule Experiment Start
#
# POST /console/v1/experiments/{id}/schedule_start
export def "console-experiments-schedule-start post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  scheduledTime: float # Unix timestamp (in milliseconds) to schedule the experiment to start (format: double)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/schedule_start")
  let body = {scheduledTime: $scheduledTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start Experiment
#
# PUT /console/v1/experiments/{id}/start
export def "console-experiments-start put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --analysisStartTime: string # For Warehouse Native analysis-only experiments; start time of experiment analysis. (e.g. 2024-10-01)
  --analysisEndTime: string # For Warehouse Native analysis-only experiments; end time of experiment analysis. (e.g. 2024-10-30)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/start")
  let body = {analysisStartTime: $analysisStartTime, analysisEndTime: $analysisEndTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unarchive Experiment
#
# PUT /console/v1/experiments/{id}/unarchive
export def "console-experiments-unarchive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/($id)/unarchive")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post Assignment Source
#
# POST /console/v1/experiments/assignment_source/{name}
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-experiments-assignment-source post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-name: string # Optional new name for the assignment source.
  --description: string # Optional updated context for the assignment source.
  --isVerified: string@bool-completer # Marks the assignment source as verified for internal trustworthiness.
  --tags: list # Optional updated tags for categorization.
  sql: string # SQL query defining the data source for assignments.
  timestampColumn: string # Column name representing the timestamp of assignments.
  experimentIDColumn: string # Column name for the experiment ID associated with the assignments.
  groupIDColumn: string # Column name for the group ID linked to the assignments.
  idTypeMapping: list # Mappings of Statsig units to their respective columns. — item shape: {statsigUnitID: string, column: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the assignment source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, isVerified: bool, tags: list<string>, sql: string, timestampColumn: string, experimentIDColumn: string, groupIDColumn: string, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/assignment_source/($name)")
  let body = {name: $body_name, description: $description, isVerified: $isVerified, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, experimentIDColumn: $experimentIDColumn, groupIDColumn: $groupIDColumn, idTypeMapping: $idTypeMapping, isReadOnly: $isReadOnly, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Assignment Source
#
# PATCH /console/v1/experiments/assignment_source/{name}
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-experiments-assignment-source patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-name: string # Unique identifier for the assignment source.
  --description: string # Detailed context and purpose of the assignment source.
  --isVerified: string@bool-completer # Marks the assignment source as verified for internal trustworthiness.
  --tags: list # Tags for categorization and search.
  --timestampColumn: string # Column name representing the timestamp of assignments.
  --experimentIDColumn: string # Column name for the experiment ID associated with the assignments.
  --groupIDColumn: string # Column name for the group ID linked to the assignments.
  --idTypeMapping: list # Mappings of Statsig units to their respective columns. — item shape: {statsigUnitID: string, column: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the assignment source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, isVerified: bool, tags: list<string>, sql: string, timestampColumn: string, experimentIDColumn: string, groupIDColumn: string, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/assignment_source/($name)")
  let body = {name: $body_name, description: $description, isVerified: $isVerified, tags: $tags, timestampColumn: $timestampColumn, experimentIDColumn: $experimentIDColumn, groupIDColumn: $groupIDColumn, idTypeMapping: $idTypeMapping, isReadOnly: $isReadOnly, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Assignment Source
#
# DELETE /console/v1/experiments/assignment_source/{name}
export def "console-experiments-assignment-source delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/assignment_source/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assignment Sources
#
# GET /console/v1/experiments/assignment_sources
export def "console-experiments-assignment-sources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, description: string, isVerified: bool, tags: list, sql: string, timestampColumn: string, experimentIDColumn: string, groupIDColumn: string, idTypeMapping: list, isReadOnly: bool, owner: record, team: string, teamID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/experiments/assignment_sources" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Assignment Source
#
# POST /console/v1/experiments/assignment_sources
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-experiments-assignment-sources post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # Unique identifier for the assignment source.
  --description: string # Optional detailed context for the assignment source.
  --isVerified: string@bool-completer # Marks the assignment source as verified for internal trustworthiness.
  --tags: list # Optional tags for categorization.
  sql: string # SQL query defining the data source for assignments.
  timestampColumn: string # Column name representing the timestamp of assignments.
  experimentIDColumn: string # Column name for the experiment ID associated with the assignments.
  groupIDColumn: string # Column name for the group ID linked to the assignments.
  idTypeMapping: list # Mappings of Statsig units to their respective columns. — item shape: {statsigUnitID: string, column: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the assignment source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, isVerified: bool, tags: list<string>, sql: string, timestampColumn: string, experimentIDColumn: string, groupIDColumn: string, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/experiments/assignment_sources")
  let body = {name: $name, description: $description, isVerified: $isVerified, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, experimentIDColumn: $experimentIDColumn, groupIDColumn: $groupIDColumn, idTypeMapping: $idTypeMapping, isReadOnly: $isReadOnly, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Entity Property Sources
#
# GET /console/v1/experiments/entity_properties
export def "console-experiments-entity-properties get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, description: string, tags: list, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list, isReadOnly: bool, owner: record, team: string, teamID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/experiments/entity_properties" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Entity Property Source
#
# POST /console/v1/experiments/entity_properties
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
export def "console-experiments-entity-properties post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # Unique identifier for the entity property source.
  --description: string # Optional detailed context for the entity property source.
  --tags: list # Optional tags for categorization.
  sql: string # SQL query defining the data source.
  --timestampColumn: string # Optional column name for timestamp.
  --timestampAsDay: string@bool-completer # Indicates if the timestamp is treated as a day.
  idTypeMapping: list # Mappings of Statsig units to their columns. — item shape: {statsigUnitID: string, column: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the entity property source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/experiments/entity_properties")
  let body = {name: $name, description: $description, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, isReadOnly: $isReadOnly, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Entity Property Source
#
# GET /console/v1/experiments/entity_property/{name}
export def "console-experiments-entity-property get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/entity_property/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post Entity Property Source
#
# POST /console/v1/experiments/entity_property/{name}
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
export def "console-experiments-entity-property post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-name: string # Optional new name for the entity property source.
  --description: string # Optional updated context for the entity property source.
  --tags: list # Optional updated tags for categorization.
  sql: string # SQL query defining the data source.
  --timestampColumn: string # Optional column name for timestamp.
  --timestampAsDay: string@bool-completer # Indicates if the timestamp is treated as a day.
  idTypeMapping: list # Mappings of Statsig units to their columns. — item shape: {statsigUnitID: string, column: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the entity property source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/entity_property/($name)")
  let body = {name: $body_name, description: $description, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, isReadOnly: $isReadOnly, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Entity Property Source
#
# PATCH /console/v1/experiments/entity_property/{name}
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
export def "console-experiments-entity-property patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-name: string # Unique identifier for the entity property source.
  --description: string # Detailed context and purpose of the entity property source.
  --tags: list # Tags for categorization and search.
  --timestampColumn: string # Optional column name for timestamp.
  --timestampAsDay: string@bool-completer # Indicates if the timestamp is treated as a day.
  --idTypeMapping: list # Mappings of Statsig units to their columns. — item shape: {statsigUnitID: string, column: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the entity property source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, isReadOnly: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/entity_property/($name)")
  let body = {name: $body_name, description: $description, tags: $tags, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, isReadOnly: $isReadOnly, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Entity Property Source
#
# DELETE /console/v1/experiments/entity_property/{name}
export def "console-experiments-entity-property delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/entity_property/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List qualifying event
#
# GET /console/v1/experiments/qualifying_events
export def "console-experiments-qualifying-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, description: string, tags: list, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list, isReadOnly: bool, isVerified: bool, owner: record, team: string, teamID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/experiments/qualifying_events" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Qualifying Event
#
# POST /console/v1/experiments/qualifying_events
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --customFieldMapping item shape: {key: string, formula: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-experiments-qualifying-events post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the source, serving as its primary identifier.
  --description: string # An optional description for the source, providing context and details about its purpose and usage.
  --tags: list # Optional array of tags to categorize the source, facilitating easier organization and retrieval.
  sql: string # The SQL query or statement used to extract data from the source.
  timestampColumn: string # The name of the column containing timestamp data for the source.
  --timestampAsDay: string@bool-completer # Indicates whether the timestamp should be treated as a day-level granularity.
  idTypeMapping: list # Array defining the mapping between Statsig unit IDs and their respective source columns. — item shape: {statsigUnitID: string, column: string}
  --sourceType: string@sourceType-completer # The type of source, indicating whether it is a database table or a custom query.
  --tableName: string # The name of the database table if the source type is "table".
  --datePartitionColumn: string # The name of the date partition column if the source type is "table". Can be undefined.
  --customFieldMapping: list # Optional array defining mappings for custom fields using specific formulas. — item shape: {key: string, formula: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --isVerified: string@bool-completer # Marks the metric source as verified, indicating trustworthiness within the organization. (e.g. false)
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list<record>, isReadOnly: bool, isVerified: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/experiments/qualifying_events")
  let body = {name: $name, description: $description, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, sourceType: $sourceType, tableName: $tableName, datePartitionColumn: $datePartitionColumn, customFieldMapping: $customFieldMapping, isReadOnly: $isReadOnly, isVerified: $isVerified, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Qualifying Event
#
# GET /console/v1/experiments/qualifying_events/{name}
export def "console-experiments-qualifying-events get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list<record>, isReadOnly: bool, isVerified: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/qualifying_events/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Qualifying Event
#
# POST /console/v1/experiments/qualifying_events/{name}
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --customFieldMapping item shape: {key: string, formula: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-experiments-qualifying-events post-by-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-name: any # The name of the source cannot be changed in this update, ensuring the identity remains consistent.
  --description: string # An optional updated description for the source, providing additional context or changes.
  --tags: list # Optional array of tags for categorizing the source, allowing for updates to its categorization.
  sql: string # The SQL query or statement used to extract data from the source.
  timestampColumn: string # The name of the column containing timestamp data for the source.
  --timestampAsDay: string@bool-completer # Indicates whether the timestamp should be treated as a day-level granularity.
  idTypeMapping: list # Array defining the mapping between Statsig unit IDs and their respective source columns. — item shape: {statsigUnitID: string, column: string}
  --sourceType: string@sourceType-completer # The type of source, indicating whether it is a database table or a custom query.
  --tableName: string # The name of the database table if the source type is "table".
  --datePartitionColumn: string # The name of the date partition column if the source type is "table". Can be undefined.
  --customFieldMapping: list # Optional array defining mappings for custom fields using specific formulas. — item shape: {key: string, formula: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --isVerified: string@bool-completer # Marks the metric source as verified, indicating trustworthiness within the organization. (e.g. false)
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting updates to the source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list<record>, isReadOnly: bool, isVerified: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/qualifying_events/($name)")
  let body = {name: $body_name, description: $description, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, sourceType: $sourceType, tableName: $tableName, datePartitionColumn: $datePartitionColumn, customFieldMapping: $customFieldMapping, isReadOnly: $isReadOnly, isVerified: $isVerified, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Qualifying Event
#
# DELETE /console/v1/experiments/qualifying_events/{name}
export def "console-experiments-qualifying-events delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/experiments/qualifying_events/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Exposure Event Count
#
# GET /console/v1/exposure_count
export def "console-exposure-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiments: string
  --gates: string
  --dynamicConfigs: string
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<gates: list<record>, experiments: list<record>, dynamicConfigs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiments" $experiments "scalar") (serialize-qp "gates" $gates "scalar") (serialize-qp "dynamicConfigs" $dynamicConfigs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/exposure_count" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Gates
#
# GET /console/v1/gates
export def "console-gates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idType: string # Filter by idType
  --type: string@type-completer # Filter by type
  --typeReason: string@typeReason-completer # Filter by typeReason
  --passRate: string # Filter by pass rate of the gates, as determined by a sampling of overall true/false values returned: 0, 100, or INBETWEEN (pass rate greater than zero but less than 100)
  --rolloutRate: string # Filter by rollout rate of the gates: 0 (all rules are set to pass 0%), 100 (all rules pass 100% including an "everyone" catch all rule), or INBETWEEN (at least one rule has a pass rate greater than 0 but less than 100)
  --releasePipelineID: string # Filter by release pipeline ID (nullable)
  --creatorName: string # Name of the creator. (nullable)
  --creatorID: string # ID of the user who created the entity. (nullable)
  --tags: string # Filter by tags
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record, isTemplate: bool, isEnabled: bool, rules: list, measureMetricLifts: bool, monitoringMetrics: list, reviewSettings: record, releasePipelineID: string, activeReview: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idType" $idType "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "typeReason" $typeReason "scalar") (serialize-qp "passRate" $passRate "scalar") (serialize-qp "rolloutRate" $rolloutRate "scalar") (serialize-qp "releasePipelineID" $releasePipelineID "scalar") (serialize-qp "creatorName" $creatorName "scalar") (serialize-qp "creatorID" $creatorID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/gates" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Gate
#
# POST /console/v1/gates
# --rules item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
# --monitoringMetrics item shape: {name: string, type: string}
# --reviewSettings shape: {requiredReview: bool}
export def "console-gates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The gate display name
  --isEnabled: string@bool-completer
  --description: string
  --rules: list # item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
  --tags: list
  --type: string@type-completer-1
  --idType: string
  --targetApps: any
  --creatorID: string # nullable
  --creatorEmail: string # nullable
  --team: string # nullable
  --teamID: string # nullable
  --measureMetricLifts: string@bool-completer
  --monitoringMetrics: list # item shape: {name: string, type: string}
  --reviewSettings: record # Whether reviews are required for this gate. If a gate has reviews required due to a project-level or team-level setting, setting this will have no effect. — shape: {requiredReview: bool}
  --releasePipelineID: string # nullable
  --id: string # The gate name ID
  --isTemplate: string@bool-completer
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/gates")
  let body = {name: $name, isEnabled: $isEnabled, description: $description, rules: $rules, tags: $tags, type: $type, idType: $idType, targetApps: $targetApps, creatorID: $creatorID, creatorEmail: $creatorEmail, team: $team, teamID: $teamID, measureMetricLifts: $measureMetricLifts, monitoringMetrics: $monitoringMetrics, reviewSettings: $reviewSettings, releasePipelineID: $releasePipelineID, id: $id, isTemplate: $isTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Gate
#
# GET /console/v1/gates/{id}
export def "console-gates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fully Update Gates
#
# POST /console/v1/gates/{id}
# --rules item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
# --monitoringMetrics item shape: {name: string, type: string}
# --reviewSettings shape: {requiredReview: bool}
export def "console-gates post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The gate display name
  --isEnabled: string@bool-completer
  description: string
  rules: list # item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
  --tags: list
  --type: string@type-completer-1
  --idType: string
  --targetApps: any
  --creatorID: string # nullable
  --creatorEmail: string # nullable
  --team: string # nullable
  --teamID: string # nullable
  --measureMetricLifts: string@bool-completer
  --monitoringMetrics: list # item shape: {name: string, type: string}
  --reviewSettings: record # Whether reviews are required for this gate. If a gate has reviews required due to a project-level or team-level setting, setting this will have no effect. — shape: {requiredReview: bool}
  --releasePipelineID: string # nullable
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)")
  let body = {name: $name, isEnabled: $isEnabled, description: $description, rules: $rules, tags: $tags, type: $type, idType: $idType, targetApps: $targetApps, creatorID: $creatorID, creatorEmail: $creatorEmail, team: $team, teamID: $teamID, measureMetricLifts: $measureMetricLifts, monitoringMetrics: $monitoringMetrics, reviewSettings: $reviewSettings, releasePipelineID: $releasePipelineID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially Update Gates
#
# PATCH /console/v1/gates/{id}
# --rules item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
# --monitoringMetrics item shape: {name: string, type: string}
# --reviewSettings shape: {requiredReview: bool}
export def "console-gates patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The gate display name
  --isEnabled: string@bool-completer
  --description: string
  --rules: list # item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
  --tags: list
  --type: string@type-completer-1
  --idType: string
  --targetApps: any
  --creatorID: string # nullable
  --creatorEmail: string # nullable
  --team: string # nullable
  --teamID: string # nullable
  --measureMetricLifts: string@bool-completer
  --monitoringMetrics: list # item shape: {name: string, type: string}
  --reviewSettings: record # Whether reviews are required for this gate. If a gate has reviews required due to a project-level or team-level setting, setting this will have no effect. — shape: {requiredReview: bool}
  --releasePipelineID: string # nullable
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)")
  let body = {name: $name, isEnabled: $isEnabled, description: $description, rules: $rules, tags: $tags, type: $type, idType: $idType, targetApps: $targetApps, creatorID: $creatorID, creatorEmail: $creatorEmail, team: $team, teamID: $teamID, measureMetricLifts: $measureMetricLifts, monitoringMetrics: $monitoringMetrics, reviewSettings: $reviewSettings, releasePipelineID: $releasePipelineID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Gates
#
# DELETE /console/v1/gates/{id}
export def "console-gates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve Metric Rollout Alert
#
# POST /console/v1/gates/{id}/alerts/{metricId}/resolve
export def "console-gates-alerts-resolve post" [
  id: string
  metricId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --reasoning: string # Reason for resolving the alert (e.g. Issue has been addressed)
]: any -> record<message: string, data: record<resolvedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/alerts/($metricId)/resolve")
  let body = {reasoning: $reasoning} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive Gate
#
# PUT /console/v1/gates/{id}/archive
export def "console-gates-archive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --forceArchive: string@bool-completer
  --archiveReason: string # The reason for archiving the gate (e.g. The gate is no longer needed)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/archive")
  let body = {forceArchive: $forceArchive, archiveReason: $archiveReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable Gate
#
# PUT /console/v1/gates/{id}/disable
export def "console-gates-disable put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/disable")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Gate
#
# PUT /console/v1/gates/{id}/enable
export def "console-gates-enable put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/enable")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Launch Gate
#
# PUT /console/v1/gates/{id}/launch
export def "console-gates-launch put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/launch")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Pulse Gate
#
# POST /console/v1/gates/{id}/load_pulse
export def "console-gates-load-pulse post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --refresh: string@refresh-completer # default: full
  --metricIDs: list
  ruleId: string
  --turboMode: string@bool-completer
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/load_pulse")
  let body = {refresh: $refresh, metricIDs: $metricIDs, ruleId: $ruleId, turboMode: $turboMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Gate Override
#
# GET /console/v1/gates/{id}/overrides
export def "console-gates-overrides get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Gate Overrides
#
# POST /console/v1/gates/{id}/overrides
# --environmentOverrides item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
export def "console-gates-overrides post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --environmentOverrides: list # item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
  --passingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --failingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --passingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
  --failingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
]: any -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/overrides")
  let body = {environmentOverrides: $environmentOverrides, passingUserIDs: $passingUserIDs, failingUserIDs: $failingUserIDs, passingCustomIDs: $passingCustomIDs, failingCustomIDs: $failingCustomIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Gate Overrides
#
# PATCH /console/v1/gates/{id}/overrides
# --environmentOverrides item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
export def "console-gates-overrides patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --environmentOverrides: list # item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
  --passingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --failingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --passingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
  --failingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
]: any -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/overrides")
  let body = {environmentOverrides: $environmentOverrides, passingUserIDs: $passingUserIDs, failingUserIDs: $failingUserIDs, passingCustomIDs: $passingCustomIDs, failingCustomIDs: $failingCustomIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Gate Overrides
#
# DELETE /console/v1/gates/{id}/overrides
export def "console-gates-overrides delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Gate Rule
#
# POST /console/v1/gates/{id}/rule
# --conditions item shape: {targetValue?: any, operator?: string, field?: string, customID?: string, type: "app_version"|"browser_name"|"browser_version"|"country"|"custom_field"|"email"|"environment_tier"|"fails_gate"|"fails_segment"|"ip_address"|"locale"|"os_name"|"os_version"|"passes_gate"|"passes_segment"|"public"|"time"|"unit_id"|"user_id"|"url"|"javascript"|"device_model"|"target_app"}
# --completedAutomatedRollouts item shape: {time: float, passPercent: float}
# --pendingAutomatedRollouts item shape: {time: float, passPercent: float}
export def "console-gates-rule post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of this rule.
  passPercentage: float # Of the users that meet the conditions of this rule, what percent should return true. (format: double)
  conditions: list # An array of Condition objects. — item shape: {targetValue?: any, operator?: string, field?: string, customID?: string, type: "app_version"|"browser_name"|"browser_version"|"country"|"custom_field"|"email"|"environment_tier"|"fails_gate"|"fails_segment"|"ip_address"|"locale"|"os_name"|"os_version"|"passes_gate"|"passes_segment"|"public"|"time"|"unit_id"|"user_id"|"url"|"javascript"|"device_model"|"target_app"}
  --environments: list # The environments this rule is enabled for. (nullable)
  --body-id: string # The Statsig ID of this rule.
  --baseID: string # The base ID of this rule, i.e. without any added metadata. Will remain the exact same throughout
  --returnValue: record # The return value of the rule.
  --completedAutomatedRollouts: list # item shape: {time: float, passPercent: float}
  --pendingAutomatedRollouts: list # item shape: {time: float, passPercent: float}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/rule")
  let body = {name: $name, passPercentage: $passPercentage, conditions: $conditions, environments: $environments, id: $body_id, baseID: $baseID, returnValue: $returnValue, completedAutomatedRollouts: $completedAutomatedRollouts, pendingAutomatedRollouts: $pendingAutomatedRollouts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Gate Rules
#
# GET /console/v1/gates/{id}/rules
export def "console-gates-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<rules: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Multiple Gate Rule
#
# POST /console/v1/gates/{id}/rules
# --rules item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
export def "console-gates-rules post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  rules: list # item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update list of current Gate Rules settings
#
# PATCH /console/v1/gates/{id}/rules
# --rules item shape: {name?: string, passPercentage?: float, conditions?: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
export def "console-gates-rules patch-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  rules: list # item shape: {name?: string, passPercentage?: float, conditions?: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Gate Rules
#
# PATCH /console/v1/gates/{id}/rules/{ruleID}
# --conditions item shape: {targetValue?: any, operator?: string, field?: string, customID?: string, type: "app_version"|"browser_name"|"browser_version"|"country"|"custom_field"|"email"|"environment_tier"|"fails_gate"|"fails_segment"|"ip_address"|"locale"|"os_name"|"os_version"|"passes_gate"|"passes_segment"|"public"|"time"|"unit_id"|"user_id"|"url"|"javascript"|"device_model"|"target_app"}
# --completedAutomatedRollouts item shape: {time: float, passPercent: float}
# --pendingAutomatedRollouts item shape: {time: float, passPercent: float}
export def "console-gates-rules patch-by-id-ruleID" [
  id: string
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The name of this rule.
  --passPercentage: float # Of the users that meet the conditions of this rule, what percent should return true. (format: double)
  --conditions: list # An array of Condition objects. — item shape: {targetValue?: any, operator?: string, field?: string, customID?: string, type: "app_version"|"browser_name"|"browser_version"|"country"|"custom_field"|"email"|"environment_tier"|"fails_gate"|"fails_segment"|"ip_address"|"locale"|"os_name"|"os_version"|"passes_gate"|"passes_segment"|"public"|"time"|"unit_id"|"user_id"|"url"|"javascript"|"device_model"|"target_app"}
  --environments: list # The environments this rule is enabled for. (nullable)
  --body-id: string # The Statsig ID of this rule.
  --baseID: string # The base ID of this rule, i.e. without any added metadata. Will remain the exact same throughout
  --returnValue: record # The return value of the rule.
  --completedAutomatedRollouts: list # item shape: {time: float, passPercent: float}
  --pendingAutomatedRollouts: list # item shape: {time: float, passPercent: float}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules/($ruleID)")
  let body = {name: $name, passPercentage: $passPercentage, conditions: $conditions, environments: $environments, id: $body_id, baseID: $baseID, returnValue: $returnValue, completedAutomatedRollouts: $completedAutomatedRollouts, pendingAutomatedRollouts: $pendingAutomatedRollouts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Gate Rule
#
# DELETE /console/v1/gates/{id}/rules/{ruleID}
export def "console-gates-rules delete" [
  id: string
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules/($ruleID)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pulse Load History (Warehouse Native)
#
# GET /console/v1/gates/{id}/rules/{ruleID}/pulse_load_history
export def "console-gates-rules-pulse-load-history get" [
  id: string
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<creatorName: string, createdTime: float, finishedTime: float, finishedState: string, startDs: string, endDs: string, reloadType: string, turboMode: bool>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules/($ruleID)/pulse_load_history" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Pulse Results
#
# GET /console/v1/gates/{id}/rules/{ruleID}/pulse_results
export def "console-gates-rules-pulse-results get" [
  id: string
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cuped: string # Whether to apply CUPED. Allowed values are "true" or "false".
  --confidence: string # Confidence interval (0-100)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<ds: string, monitoringMetrics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cuped" $cuped "scalar") (serialize-qp "confidence" $confidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/gates/($id)/rules/($ruleID)/pulse_results" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive Gate
#
# PUT /console/v1/gates/{id}/unarchive
export def "console-gates-unarchive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --unarchiveReason: string # The reason for unarchiving the gate (e.g. The gate is needed again)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, isTemplate: bool, isEnabled: bool, rules: list<record>, measureMetricLifts: bool, monitoringMetrics: list<record>, reviewSettings: record<requiredReview: bool, allowedReviewers: list>, releasePipelineID: string, activeReview: record<reviewID: string, reviewStatus: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/gates/($id)/unarchive")
  let body = {unarchiveReason: $unarchiveReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Gate Versions
#
# GET /console/v1/gates/{id}/versions
export def "console-gates-versions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, checksPerHour: float, status: string, type: string, typeReason: string, owner: record, isTemplate: bool, isEnabled: bool, rules: list, measureMetricLifts: bool, monitoringMetrics: list, reviewSettings: record, releasePipelineID: string, activeReview: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/gates/($id)/versions" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Holdouts
#
# GET /console/v1/holdouts
export def "console-holdouts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creatorName: string # Name of the creator. (nullable)
  --creatorID: string # ID of the user who created the entity. (nullable)
  --tags: string # Filter by tags
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: list, holdoutIDs: list, team: string, teamID: string, version: float, isEnabled: bool, passPercentage: float, gateIDs: list, experimentIDs: list, layerIDs: list, isGlobal: bool, targetingGateID: string, monitoringMetrics: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creatorName" $creatorName "scalar") (serialize-qp "creatorID" $creatorID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/holdouts" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create holdout
#
# POST /console/v1/holdouts
export def "console-holdouts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # name of the holdout (e.g. team holdout)
  --description: string # description of the holdout (e.g. holdout for this team)
  --idType: string # type of id (e.g. userID)
  --teamID: string # id of the team (nullable, e.g. 4pjeXYDjC2WinSgOiII7wh)
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, passPercentage: float, gateIDs: list<string>, experimentIDs: list<string>, layerIDs: list<string>, isGlobal: bool, targetingGateID: string, monitoringMetrics: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/holdouts")
  let body = {name: $name, description: $description, idType: $idType, teamID: $teamID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get holdout by id
#
# GET /console/v1/holdouts/{id}
export def "console-holdouts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, passPercentage: float, gateIDs: list<string>, experimentIDs: list<string>, layerIDs: list<string>, isGlobal: bool, targetingGateID: string, monitoringMetrics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update holdout by id
#
# POST /console/v1/holdouts/{id}
# --monitoringMetrics item shape: {name: string, type: string}
export def "console-holdouts post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --isEnabled: string@bool-completer # enable or disable the holdout (e.g. true)
  description: string # brief summary of what the holdout is being used for (e.g. example holdout description)
  passPercentage: float # percentage of users between 0-10% to pass through the holdout (format: double, e.g. 5)
  gateIDs: list # an array of gateIDs which this holdout is applied to (e.g. [4pjeXYDjC2WinSgOiII7wh])
  experimentIDs: list # an array of experimentIDs which this holdout is applied to (e.g. [70fCNphHGesdLwHdHau99q])
  layerIDs: list # an array of layerIDs which this holdout is applied to (e.g. [5O908pyGoCqw6QH1nt8v82])
  --isGlobal: string@bool-completer # whether the holdout is being applied to all new gates (e.g. false)
  --targetingGateID: string # the gateID that the holdout is targeting (nullable, e.g. 4pjeXYDjC2WinSgOiII7wh)
  --monitoringMetrics: list # item shape: {name: string, type: string}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, passPercentage: float, gateIDs: list<string>, experimentIDs: list<string>, layerIDs: list<string>, isGlobal: bool, targetingGateID: string, monitoringMetrics: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)")
  let body = {isEnabled: $isEnabled, description: $description, passPercentage: $passPercentage, gateIDs: $gateIDs, experimentIDs: $experimentIDs, layerIDs: $layerIDs, isGlobal: $isGlobal, targetingGateID: $targetingGateID, monitoringMetrics: $monitoringMetrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch holdout by id. You can pass in only the data you want to update.
#
# PATCH /console/v1/holdouts/{id}
# --monitoringMetrics item shape: {name: string, type: string}
export def "console-holdouts patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --isEnabled: string@bool-completer # enable or disable the holdout (e.g. true)
  --description: string # brief summary of what the holdout is being used for (e.g. example holdout description)
  --passPercentage: float # percentage of users between 0-10% to pass through the holdout (format: double, e.g. 5)
  --gateIDs: list # an array of gateIDs which this holdout is applied to (e.g. [4pjeXYDjC2WinSgOiII7wh])
  --experimentIDs: list # an array of experimentIDs which this holdout is applied to (e.g. [70fCNphHGesdLwHdHau99q])
  --layerIDs: list # an array of layerIDs which this holdout is applied to (e.g. [5O908pyGoCqw6QH1nt8v82])
  --isGlobal: string@bool-completer # whether the holdout is being applied to all new gates (e.g. false)
  --targetingGateID: string # the gateID that the holdout is targeting (nullable, e.g. 4pjeXYDjC2WinSgOiII7wh)
  --monitoringMetrics: list # item shape: {name: string, type: string}
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, passPercentage: float, gateIDs: list<string>, experimentIDs: list<string>, layerIDs: list<string>, isGlobal: bool, targetingGateID: string, monitoringMetrics: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)")
  let body = {isEnabled: $isEnabled, description: $description, passPercentage: $passPercentage, gateIDs: $gateIDs, experimentIDs: $experimentIDs, layerIDs: $layerIDs, isGlobal: $isGlobal, targetingGateID: $targetingGateID, monitoringMetrics: $monitoringMetrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete holdout by id
#
# DELETE /console/v1/holdouts/{id}
export def "console-holdouts delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float, isEnabled: bool, passPercentage: float, gateIDs: list<string>, experimentIDs: list<string>, layerIDs: list<string>, isGlobal: bool, targetingGateID: string, monitoringMetrics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Holdout Overrides
#
# GET /console/v1/holdouts/{id}/overrides
export def "console-holdouts-overrides get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Holdout Overrides
#
# POST /console/v1/holdouts/{id}/overrides
# --environmentOverrides item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
export def "console-holdouts-overrides post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --environmentOverrides: list # item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
  --passingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --failingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --passingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
  --failingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
]: any -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)/overrides")
  let body = {environmentOverrides: $environmentOverrides, passingUserIDs: $passingUserIDs, failingUserIDs: $failingUserIDs, passingCustomIDs: $passingCustomIDs, failingCustomIDs: $failingCustomIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Holdout Overrides
#
# PATCH /console/v1/holdouts/{id}/overrides
# --environmentOverrides item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
export def "console-holdouts-overrides patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --environmentOverrides: list # item shape: {environment?: string, unitID: string, passingIDs: list, failingIDs: list}
  --passingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --failingUserIDs: list # List of user IDs (e.g. [user123, user456, user789])
  --passingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
  --failingCustomIDs: list # Optional list of custom IDs (e.g. [custom123, custom456])
]: any -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)/overrides")
  let body = {environmentOverrides: $environmentOverrides, passingUserIDs: $passingUserIDs, failingUserIDs: $failingUserIDs, passingCustomIDs: $passingCustomIDs, failingCustomIDs: $failingCustomIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Holdout Overrides
#
# DELETE /console/v1/holdouts/{id}/overrides
export def "console-holdouts-overrides delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<passingUserIDs: list<string>, failingUserIDs: list<string>, passingCustomIDs: list<string>, failingCustomIDs: list<string>, environmentOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/holdouts/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Pulse Results
#
# GET /console/v1/holdouts/{id}/pulse_results
export def "console-holdouts-pulse-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cuped: string # Whether to apply CUPED. Allowed values are "true" or "false".
  --confidence: string # Confidence interval (0-100)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<ds: string, monitoringMetrics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cuped" $cuped "scalar") (serialize-qp "confidence" $confidence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/holdouts/($id)/pulse_results" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Ingestion
#
# GET /console/v1/ingestion
export def "console-ingestion get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2
  --dataset: string@dataset-completer
  --source-name: string
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, type: string, enabled: bool, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "source_name" $source_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ingestion Source
#
# POST /console/v1/ingestion
# --column_mapping shape: {unit_id: string, id_type: string, dateid: string, metric_name: string, metric_value?: string, numerator?: string, denominator?: string}
export def "console-ingestion post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --dataset: string@dataset-completer-1
  --column-mapping: record # shape: {unit_id: string, id_type: string, dateid: string, metric_name: string, metric_value?: string, numerator?: string, denominator?: string}
  --type: string@type-completer-2
  --source-name: string
  --body-query: string
  --use-delta-sharing: string@bool-completer
  --share: string
  --schema: string
  --table: string
  --enabled: string@bool-completer
]: any -> record<message: string, data: record<id: string, type: string, enabled: bool, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/ingestion")
  let body = {dataset: $dataset, column_mapping: $column_mapping, type: $type, source_name: $source_name, query: $body_query, use_delta_sharing: $use_delta_sharing, share: $share, schema: $schema, table: $table, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Ingestion Source
#
# PATCH /console/v1/ingestion
# --column_mapping shape: {unit_id: string, id_type: string, dateid: string, metric_name: string, metric_value?: string, numerator?: string, denominator?: string}
export def "console-ingestion patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --dataset: string@dataset-completer-1
  --column-mapping: record # shape: {unit_id: string, id_type: string, dateid: string, metric_name: string, metric_value?: string, numerator?: string, denominator?: string}
  --type: string@type-completer-2
  --source-name: string
  --body-query: string
  --share: string
  --schema: string
  --table: string
  --enabled: string@bool-completer
]: any -> record<message: string, data: record<id: string, type: string, enabled: bool, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/ingestion")
  let body = {dataset: $dataset, column_mapping: $column_mapping, type: $type, source_name: $source_name, query: $body_query, share: $share, schema: $schema, table: $table, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ingestion Source
#
# DELETE /console/v1/ingestion
export def "console-ingestion delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2
  --dataset: string@dataset-completer
  --source-name: string
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, type: string, enabled: bool, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "source_name" $source_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Backfill Ingestion
#
# POST /console/v1/ingestion/backfill
export def "console-ingestion-backfill post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  datestamp_start: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  datestamp_end: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  type: string@type-completer-2
  --body-source: any # nullable
  dataset: string@dataset-completer
]: any -> record<message: string, data: record<runID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/ingestion/backfill")
  let body = {datestamp_start: $datestamp_start, datestamp_end: $datestamp_end, type: $type, source: $body_source, dataset: $dataset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Ingestion Databricks
#
# POST /console/v1/ingestion/connection/databricks
export def "console-ingestion-connection-databricks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-token: string
  host: string
  path: string
  --deltaSharingCredentials: string
  --verified: string@bool-completer
]: any -> record<message: string, data: record<id: string, type: string, enabled: bool, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/ingestion/connection/databricks")
  let body = {token: $body_token, host: $host, path: $path, deltaSharingCredentials: $deltaSharingCredentials, verified: $verified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Ingestion Event Count
#
# GET /console/v1/ingestion/events/count
export def "console-ingestion-events-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-name: string
  --event-name: string
  --start-date: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --end-date: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: any> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_name" $source_name "scalar") (serialize-qp "event_name" $event_name "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion/events/count" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Ingestion Event Delta Ledger
#
# GET /console/v1/ingestion/events/delta
export def "console-ingestion-events-delta get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-name: string
  --event-name: string
  --start-date: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --end-date: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: any> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_name" $source_name "scalar") (serialize-qp "event_name" $event_name "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion/events/delta" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ingestion Runs
#
# GET /console/v1/ingestion/runs
export def "console-ingestion-runs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<runID: string, latestStatus: string, lastUpdatedAt: string, createdAt: string, trigger: string, sources: list, dateStamps: list, runHistory: list, granularHistory: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion/runs" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Ingestion Run
#
# GET /console/v1/ingestion/runs/{id}
export def "console-ingestion-runs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<runID: string, latestStatus: string, lastUpdatedAt: string, createdAt: string, trigger: string, sources: list<string>, dateStamps: list<string>, runHistory: list<record>, granularHistory: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/ingestion/runs/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Ingestion Schedule
#
# GET /console/v1/ingestion/schedule
export def "console-ingestion-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string@dataset-completer
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<dataset: string, scheduled_hour_pst: float>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion/schedule" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ingestion Schedule
#
# POST /console/v1/ingestion/schedule
export def "console-ingestion-schedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  dataset: string@dataset-completer
  --scheduled-hour-pst: float # format: double, default: 10
]: any -> record<message: string, data: record<dataset: string, scheduled_hour_pst: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/ingestion/schedule")
  let body = {dataset: $dataset, scheduled_hour_pst: $scheduled_hour_pst} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Ingestions Status
#
# GET /console/v1/ingestion/status
export def "console-ingestion-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --endDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --qp-source: string
  --dataset: string@dataset-completer
  --status: string@status-completer-1
  --statuses: list
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<ds: string, ingestion_dataset: string, ingestion_source: string, source_name: string, message: string, status: string, rowCount: float, metricCount: float, timestamp: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "statuses" $statuses "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/ingestion/status" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Keys
#
# GET /console/v1/keys
export def "console-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --primaryTargetApp: string
  --environment: string
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<key: string, type: string, description: string, scopes: list, environments: list, primaryTargetApp: string, secondaryTargetApps: list, status: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "primaryTargetApp" $primaryTargetApp "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/keys" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Key
#
# POST /console/v1/keys
export def "console-keys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  description: string
  type: string@type-completer-3
  --scopes: list
  --environments: list
  --targetAppID: string
  --secondaryTargetAppIDs: list
]: any -> record<message: string, data: record<key: string, type: string, description: string, scopes: list<string>, environments: list<string>, primaryTargetApp: string, secondaryTargetApps: list<string>, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/keys")
  let body = {description: $description, type: $type, scopes: $scopes, environments: $environments, targetAppID: $targetAppID, secondaryTargetAppIDs: $secondaryTargetAppIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Key
#
# GET /console/v1/keys/{id}
export def "console-keys get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<key: string, type: string, description: string, scopes: list<string>, environments: list<string>, primaryTargetApp: string, secondaryTargetApps: list<string>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/keys/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Key
#
# PATCH /console/v1/keys/{id}
export def "console-keys patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string
  --scopes: list
  --environments: list
  --targetAppID: string # nullable
  --secondaryTargetAppIDs: list # nullable
]: any -> record<message: string, data: record<key: string, type: string, description: string, scopes: list<string>, environments: list<string>, primaryTargetApp: string, secondaryTargetApps: list<string>, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/keys/($id)")
  let body = {description: $description, scopes: $scopes, environments: $environments, targetAppID: $targetAppID, secondaryTargetAppIDs: $secondaryTargetAppIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Key
#
# DELETE /console/v1/keys/{id}
export def "console-keys delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/keys/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate Key
#
# PATCH /console/v1/keys/{id}/deactivate
export def "console-keys-deactivate patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/keys/($id)/deactivate")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Key
#
# PATCH /console/v1/keys/{id}/rotate
export def "console-keys-rotate patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<key: string, type: string, description: string, scopes: list<string>, environments: list<string>, primaryTargetApp: string, secondaryTargetApps: list<string>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/keys/($id)/rotate")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Layers
#
# GET /console/v1/layers
export def "console-layers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, isImplicitLayer: bool, parameters: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/layers" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Layer
#
# POST /console/v1/layers
export def "console-layers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The unique name of the layer, formatted as an ID (e.g., "A Layer" becomes "a_layer").
  --description: string # A helpful description of what this layer does, providing context for its purpose.
  idType: string # The type of ID used for this layer, essential for validation in services.
  --targetApps: any # List of target applications that this layer is associated with.
  --team: string # Optional identifier for the team responsible for this layer.
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isImplicitLayer: bool, parameters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/layers")
  let body = {name: $name, description: $description, idType: $idType, targetApps: $targetApps, team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one layer
#
# GET /console/v1/layers/{id}
export def "console-layers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isImplicitLayer: bool, parameters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a layer
#
# POST /console/v1/layers/{id}
# --parameters item shape: {name: string, type: "string"|"number"|"boolean"|"object"|"array", defaultValue: any}
export def "console-layers post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  description: string # A detailed description of the layer, explaining its purpose and functionality.
  parameters: list # An array of parameters associated with the layer, each defining specific attributes. — item shape: {name: string, type: "string"|"number"|"boolean"|"object"|"array", defaultValue: any}
  --targetApps: any # List of target applications that this layer is intended for.
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isImplicitLayer: bool, parameters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)")
  let body = {description: $description, parameters: $parameters, targetApps: $targetApps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a layer
#
# PATCH /console/v1/layers/{id}
# --parameters item shape: {name: string, type: "string"|"number"|"boolean"|"object"|"array", defaultValue: any}
export def "console-layers patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string # A detailed description of the layer, explaining its purpose and functionality.
  --parameters: list # An array of parameters associated with the layer, each defining specific attributes. — item shape: {name: string, type: "string"|"number"|"boolean"|"object"|"array", defaultValue: any}
  --targetApps: any # List of target applications that this layer is intended for.
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: any, holdoutIDs: list<string>, team: string, teamID: string, version: float, isImplicitLayer: bool, parameters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)")
  let body = {description: $description, parameters: $parameters, targetApps: $targetApps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a layer
#
# DELETE /console/v1/layers/{id}
export def "console-layers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lineage: List Experiment related to Layer
#
# GET /console/v1/layers/{id}/experiments
export def "console-layers-experiments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<reviewSettings: record, activeReview: record, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list, groups: list, controlGroupID: string, allocation: float, primaryMetricTags: list, secondaryMetricTags: list, primaryMetrics: list, secondaryMetrics: list, otherMetrics: list, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list, healthCheckStatus: string, owner: record, inlineTargetingRulesJSON: string, summarySections: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/layers/($id)/experiments" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Layer Overrides
#
# GET /console/v1/layers/{id}/overrides
export def "console-layers-overrides get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<conditionalOverrides: list<record>, idOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Layer Overrides
#
# POST /console/v1/layers/{id}/overrides
# --conditionalOverrides item shape: {type: string, name: string, experimentName: string, groupName: string}
# --idOverrides item shape: {groupName: string, ids: list, idType?: string, environment?: string, experimentName?: string}
export def "console-layers-overrides post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  conditionalOverrides: list # item shape: {type: string, name: string, experimentName: string, groupName: string}
  idOverrides: list # item shape: {groupName: string, ids: list, idType?: string, environment?: string, experimentName?: string}
]: any -> record<message: string, data: record<conditionalOverrides: list<record>, idOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)/overrides")
  let body = {conditionalOverrides: $conditionalOverrides, idOverrides: $idOverrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Layer Overrides
#
# PATCH /console/v1/layers/{id}/overrides
# --conditionalOverrides item shape: {type: string, name: string, experimentName: string, groupName: string}
# --idOverrides item shape: {groupName: string, ids: list, idType?: string, environment?: string, experimentName?: string}
export def "console-layers-overrides patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  op: string@op-completer # Add a layer override
  conditionalOverrides: list # item shape: {type: string, name: string, experimentName: string, groupName: string}
  idOverrides: list # item shape: {groupName: string, ids: list, idType?: string, environment?: string, experimentName?: string}
]: any -> record<message: string, data: record<conditionalOverrides: list<record>, idOverrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)/overrides")
  let body = {op: $op, conditionalOverrides: $conditionalOverrides, idOverrides: $idOverrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Layer Overrides
#
# DELETE /console/v1/layers/{id}/overrides
export def "console-layers-overrides delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<conditionalOverrides: list<record>, idOverrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/layers/($id)/overrides")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Single Metric Value
#
# GET /console/v1/metrics
export def "console-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier of the metric with format <metric_id>::<type>
  --date: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<value: float, unit_type: string, row_count: float, numerator: float, denominator: float>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/metrics" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Metric
#
# POST /console/v1/metrics
# --metricEvents item shape: {name: string, type?: "count"|"count_distinct"|"value"|"metadata", metadataKey?: string, criteria?: list}
# --metricComponentMetrics item shape: {name: string, type: string}
# --funnelEventList item shape: {name: string, type: "event_dau"|"event_user"|"event_count"|"event_count_custom"}
# --warehouseNative shape: {aggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", metricSourceName?: string, criteria?: list, waitForCohortWindow?: bool, denominatorCriteria?: list, denominatorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", denominatorCustomRollupEnd?: float, denominatorCustomRollupStart?: float, denominatorMetricSourceName?: string, denominatorRollupTimeWindow?: string, denominatorValueColumn?: string, funnelCalculationWindow?: float, funnelCountDistinct?: "sessions"|"users", funnelEvents?: list, funnelStartCriteria?: "start_event"|"exposure", metricDimensionColumns?: list, metricBakeDays?: float, numeratorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", valueColumn?: string, valueThreshold?: float, allowNullRatioDenominator?: bool, funnelStrictOrdering?: bool, funnelUseExposureAsFirstEvent?: bool, funnelTimestampAllowanceMs?: float, funnelTimeToConvert?: bool, winsorizationHigh?: float, winsorizationLow?: float, winsorizationHighDenominator?: float, winsorizationLowDenominator?: float, cupedAttributionWindow?: float, rollupTimeWindow?: string, customRollUpStart?: float, customRollUpEnd?: float, onlyIncludeUsersWithConversionEvent?: bool, denominatorCustomRollupMeasureInMinutes?: bool, customRollupMeasureInMinutes?: bool, percentile?: float, useLogTransform?: bool, useSecondaryRetentionEvent?: bool, retentionEnd?: float, retentionLength?: float, logTransformBase?: float, cap?: float, surrogateMetricMSE?: float}
export def "console-metrics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the new metric, which identifies it within the system. (e.g. metricName)
  type: string@type-completer-4 # e.g. sum
  --isVerified: string@bool-completer # Marks the metric as verified for internal trustworthiness. (e.g. false)
  --isReadOnly: string@bool-completer # Set to true to make the metric definition editable only from the Console API. (e.g. false)
  --unitTypes: list # Array of unit types associated with the metric, such as stableID or userID. (e.g. [stableID, userID])
  --metricEvents: list # An array of event definitions used to compute the metric. (e.g. [{name: event1, type: value}]) — item shape: {name: string, type?: "count"|"count_distinct"|"value"|"metadata", metadataKey?: string, criteria?: list}
  --metricComponentMetrics: list # List of input metrics used to calculate the new metric for composite types. (e.g. []) — item shape: {name: string, type: string}
  --description: string # A description of the new metric, providing context and purpose.
  --directionality: string@directionality-completer # Indicates the desired change direction for the metric. Use "increase" for positive changes and "decrease" for negative changes. (default: increase, e.g. increase)
  --tags: any # Tags associated with the metric for categorization and searchability. (e.g. [tag1, tag2])
  --isPermanent: string@bool-completer # Indicates whether the metric is permanent and should not be deleted. (e.g. false)
  --rollupTimeWindow: string # Time window for the metric rollup. Specify "custom" for a customized time window. (e.g. custom)
  --customRollUpStart: float # Custom time window start date in days since exposure. (format: double, e.g. 1)
  --customRollUpEnd: float # Custom time window end date in days since exposure. (format: double, e.g. 1)
  --funnelEventList: list # List of events used to create funnel metrics. — item shape: {name: string, type: "event_dau"|"event_user"|"event_count"|"event_count_custom"}
  --funnelCountDistinct: string@funnelCountDistinct-completer # Specifies whether to count events or distinct users for the funnel metric.
  --warehouseNative: record # Defines warehouse native metrics for advanced configurations. — shape: {aggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", metricSourceName?: string, criteria?: list, waitForCohortWindow?: bool, denominatorCriteria?: list, denominatorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", denominatorCustomRollupEnd?: float, denominatorCustomRollupStart?: float, denominatorMetricSourceName?: string, denominatorRollupTimeWindow?: string, denominatorValueColumn?: string, funnelCalculationWindow?: float, funnelCountDistinct?: "sessions"|"users", funnelEvents?: list, funnelStartCriteria?: "start_event"|"exposure", metricDimensionColumns?: list, metricBakeDays?: float, numeratorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", valueColumn?: string, valueThreshold?: float, allowNullRatioDenominator?: bool, funnelStrictOrdering?: bool, funnelUseExposureAsFirstEvent?: bool, funnelTimestampAllowanceMs?: float, funnelTimeToConvert?: bool, winsorizationHigh?: float, winsorizationLow?: float, winsorizationHighDenominator?: float, winsorizationLowDenominator?: float, cupedAttributionWindow?: float, rollupTimeWindow?: string, customRollUpStart?: float, customRollUpEnd?: float, onlyIncludeUsersWithConversionEvent?: bool, denominatorCustomRollupMeasureInMinutes?: bool, customRollupMeasureInMinutes?: bool, percentile?: float, useLogTransform?: bool, useSecondaryRetentionEvent?: bool, retentionEnd?: float, retentionLength?: float, logTransformBase?: float, cap?: float, surrogateMetricMSE?: float}
  --team: string # The team associated with the metric, applicable for enterprise environments. (nullable)
  --teamID: string # The team ID associated with the metric, applicable for enterprise environments. (nullable)
  --dryRun: string@bool-completer # Skips persisting the metric (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list<string>, metricEvents: list<record>, metricComponentMetrics: list<record>, description: string, directionality: string, tags: list<string>, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list<record>, funnelCountDistinct: string, warehouseNative: record<aggregation: string, metricSourceName: string, criteria: list, waitForCohortWindow: bool, denominatorCriteria: list, denominatorAggregation: string, denominatorCustomRollupEnd: float, denominatorCustomRollupStart: float, denominatorMetricSourceName: string, denominatorRollupTimeWindow: string, denominatorValueColumn: string, funnelCalculationWindow: float, funnelCountDistinct: string, funnelEvents: list, funnelStartCriteria: string, metricDimensionColumns: list, metricBakeDays: float, numeratorAggregation: string, valueColumn: string, valueThreshold: float, allowNullRatioDenominator: bool, funnelStrictOrdering: bool, funnelUseExposureAsFirstEvent: bool, funnelTimestampAllowanceMs: float, funnelTimeToConvert: bool, winsorizationHigh: float, winsorizationLow: float, winsorizationHighDenominator: float, winsorizationLowDenominator: float, cupedAttributionWindow: float, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, onlyIncludeUsersWithConversionEvent: bool, denominatorCustomRollupMeasureInMinutes: bool, customRollupMeasureInMinutes: bool, percentile: float, useLogTransform: bool, useSecondaryRetentionEvent: bool, retentionEnd: float, retentionLength: float, logTransformBase: float, cap: float, surrogateMetricMSE: float>, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record<events: list, metrics: list>, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/metrics")
  let body = {name: $name, type: $type, isVerified: $isVerified, isReadOnly: $isReadOnly, unitTypes: $unitTypes, metricEvents: $metricEvents, metricComponentMetrics: $metricComponentMetrics, description: $description, directionality: $directionality, tags: $tags, isPermanent: $isPermanent, rollupTimeWindow: $rollupTimeWindow, customRollUpStart: $customRollUpStart, customRollUpEnd: $customRollUpEnd, funnelEventList: $funnelEventList, funnelCountDistinct: $funnelCountDistinct, warehouseNative: $warehouseNative, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Metric Definition
#
# GET /console/v1/metrics/{id}
export def "console-metrics get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list<string>, metricEvents: list<record>, metricComponentMetrics: list<record>, description: string, directionality: string, tags: list<string>, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list<record>, funnelCountDistinct: string, warehouseNative: record<aggregation: string, metricSourceName: string, criteria: list, waitForCohortWindow: bool, denominatorCriteria: list, denominatorAggregation: string, denominatorCustomRollupEnd: float, denominatorCustomRollupStart: float, denominatorMetricSourceName: string, denominatorRollupTimeWindow: string, denominatorValueColumn: string, funnelCalculationWindow: float, funnelCountDistinct: string, funnelEvents: list, funnelStartCriteria: string, metricDimensionColumns: list, metricBakeDays: float, numeratorAggregation: string, valueColumn: string, valueThreshold: float, allowNullRatioDenominator: bool, funnelStrictOrdering: bool, funnelUseExposureAsFirstEvent: bool, funnelTimestampAllowanceMs: float, funnelTimeToConvert: bool, winsorizationHigh: float, winsorizationLow: float, winsorizationHighDenominator: float, winsorizationLowDenominator: float, cupedAttributionWindow: float, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, onlyIncludeUsersWithConversionEvent: bool, denominatorCustomRollupMeasureInMinutes: bool, customRollupMeasureInMinutes: bool, percentile: float, useLogTransform: bool, useSecondaryRetentionEvent: bool, retentionEnd: float, retentionLength: float, logTransformBase: float, cap: float, surrogateMetricMSE: float>, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record<events: list, metrics: list>, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a metric
#
# POST /console/v1/metrics/{id}
# --warehouseNative shape: {aggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", metricSourceName?: string, criteria?: list, waitForCohortWindow?: bool, denominatorCriteria?: list, denominatorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", denominatorCustomRollupEnd?: float, denominatorCustomRollupStart?: float, denominatorMetricSourceName?: string, denominatorRollupTimeWindow?: string, denominatorValueColumn?: string, funnelCalculationWindow?: float, funnelCountDistinct?: "sessions"|"users", funnelEvents?: list, funnelStartCriteria?: "start_event"|"exposure", metricDimensionColumns?: list, metricBakeDays?: float, numeratorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", valueColumn?: string, valueThreshold?: float, allowNullRatioDenominator?: bool, funnelStrictOrdering?: bool, funnelUseExposureAsFirstEvent?: bool, funnelTimestampAllowanceMs?: float, funnelTimeToConvert?: bool, winsorizationHigh?: float, winsorizationLow?: float, winsorizationHighDenominator?: float, winsorizationLowDenominator?: float, cupedAttributionWindow?: float, rollupTimeWindow?: string, customRollUpStart?: float, customRollUpEnd?: float, onlyIncludeUsersWithConversionEvent?: bool, denominatorCustomRollupMeasureInMinutes?: bool, customRollupMeasureInMinutes?: bool, percentile?: float, useLogTransform?: bool, useSecondaryRetentionEvent?: bool, retentionEnd?: float, retentionLength?: float, logTransformBase?: float, cap?: float, surrogateMetricMSE?: float}
# --owner shape: {email?: string, ownerID?: string}
export def "console-metrics post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The name of the metric, serving as its primary identifier. (e.g. metricName)
  --description: string # A detailed description of the metric, providing insights into its purpose and application.
  --tags: list # An array of tags associated with the metric, used for categorization and easier retrieval.
  --isVerified: string@bool-completer # Flag to mark the metric as verified, ensuring it is deemed trustworthy within the organization.
  --isReadOnly: string@bool-completer # Specifies if the metric definition can only be edited via the Console API, enhancing control over modifications.
  --isPermanent: string@bool-completer # Determines if the metric is permanent, preventing it from being deleted or modified inadvertently.
  --warehouseNative: record # Optional configuration for metrics utilizing Warehouse Native features, defining specific behaviors and criteria. — shape: {aggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", metricSourceName?: string, criteria?: list, waitForCohortWindow?: bool, denominatorCriteria?: list, denominatorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", denominatorCustomRollupEnd?: float, denominatorCustomRollupStart?: float, denominatorMetricSourceName?: string, denominatorRollupTimeWindow?: string, denominatorValueColumn?: string, funnelCalculationWindow?: float, funnelCountDistinct?: "sessions"|"users", funnelEvents?: list, funnelStartCriteria?: "start_event"|"exposure", metricDimensionColumns?: list, metricBakeDays?: float, numeratorAggregation?: "count"|"sum"|"mean"|"daily_participation"|"ratio"|"funnel"|"count_distinct"|"percentile"|"first_value"|"latest_value"|"retention"|"max"|"min"|"", valueColumn?: string, valueThreshold?: float, allowNullRatioDenominator?: bool, funnelStrictOrdering?: bool, funnelUseExposureAsFirstEvent?: bool, funnelTimestampAllowanceMs?: float, funnelTimeToConvert?: bool, winsorizationHigh?: float, winsorizationLow?: float, winsorizationHighDenominator?: float, winsorizationLowDenominator?: float, cupedAttributionWindow?: float, rollupTimeWindow?: string, customRollUpStart?: float, customRollUpEnd?: float, onlyIncludeUsersWithConversionEvent?: bool, denominatorCustomRollupMeasureInMinutes?: bool, customRollupMeasureInMinutes?: bool, percentile?: float, useLogTransform?: bool, useSecondaryRetentionEvent?: bool, retentionEnd?: float, retentionLength?: float, logTransformBase?: float, cap?: float, surrogateMetricMSE?: float}
  --unitTypes: list # Array of unit types that the metric can utilize, such as stableID, userID, or other custom identifiers.
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --directionality: string@directionality-completer # Indicates the desired change direction for the metric. Use "increase" for positive changes and "decrease" for negative changes. (default: increase, e.g. increase)
  --dryRun: string@bool-completer # Skips persisting updates to the metric (used to validate that inputs are correct)
  --owner: record # shape: {email?: string, ownerID?: string}
]: any -> record<message: string, data: record<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list<string>, metricEvents: list<record>, metricComponentMetrics: list<record>, description: string, directionality: string, tags: list<string>, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list<record>, funnelCountDistinct: string, warehouseNative: record<aggregation: string, metricSourceName: string, criteria: list, waitForCohortWindow: bool, denominatorCriteria: list, denominatorAggregation: string, denominatorCustomRollupEnd: float, denominatorCustomRollupStart: float, denominatorMetricSourceName: string, denominatorRollupTimeWindow: string, denominatorValueColumn: string, funnelCalculationWindow: float, funnelCountDistinct: string, funnelEvents: list, funnelStartCriteria: string, metricDimensionColumns: list, metricBakeDays: float, numeratorAggregation: string, valueColumn: string, valueThreshold: float, allowNullRatioDenominator: bool, funnelStrictOrdering: bool, funnelUseExposureAsFirstEvent: bool, funnelTimestampAllowanceMs: float, funnelTimeToConvert: bool, winsorizationHigh: float, winsorizationLow: float, winsorizationHighDenominator: float, winsorizationLowDenominator: float, cupedAttributionWindow: float, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, onlyIncludeUsersWithConversionEvent: bool, denominatorCustomRollupMeasureInMinutes: bool, customRollupMeasureInMinutes: bool, percentile: float, useLogTransform: bool, useSecondaryRetentionEvent: bool, retentionEnd: float, retentionLength: float, logTransformBase: float, cap: float, surrogateMetricMSE: float>, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record<events: list, metrics: list>, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($id)")
  let body = {name: $name, description: $description, tags: $tags, isVerified: $isVerified, isReadOnly: $isReadOnly, isPermanent: $isPermanent, warehouseNative: $warehouseNative, unitTypes: $unitTypes, team: $team, teamID: $teamID, directionality: $directionality, dryRun: $dryRun, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a metric
#
# DELETE /console/v1/metrics/{id}
export def "console-metrics delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel archive a metric
#
# PUT /console/v1/metrics/{id}/cancel_archive
export def "console-metrics-cancel-archive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($id)/cancel_archive")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lineage: List experiments related to Metric
#
# GET /console/v1/metrics/{id}/experiments
export def "console-metrics-experiments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --layerID: string # Which layer to place the experiment into.
  --idType: string # The idType the experiment will be performed on
  --teamID: string # The team ID associated with the experiment, Enterprise only. (nullable)
  --status: string # The current status of the experiment
  --targetAppID: string
  --createdStartDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --createdEndDate: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --creatorName: string # Name of the creator. (nullable)
  --creatorID: string # ID of the user who created the entity. (nullable)
  --tags: string # Filter by tags
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<reviewSettings: record, activeReview: record, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: any, holdoutIDs: list, team: string, teamID: string, version: float, secondaryIDType: string, identifierMappingMode: string, identityResolutionSource: string, hypothesis: string, links: list, groups: list, controlGroupID: string, allocation: float, primaryMetricTags: list, secondaryMetricTags: list, primaryMetrics: list, secondaryMetrics: list, otherMetrics: list, duration: int, targetExposures: int, targetingGateID: string, sequentialTesting: bool, bonferroniCorrection: bool, bonferroniCorrectionPerMetric: bool, benjaminiHochbergPerVariant: bool, benjaminiHochbergPerMetric: bool, benjaminiPrimaryMetricsOnly: bool, defaultConfidenceInterval: string, manualQualityScores: list, status: string, launchedGroupID: string, assignmentSourceName: string, assignmentSourceExperimentName: string, isAnalysisOnly: bool, allocationDuration: int, cohortedAnalysisDuration: int, cohortedMetricsMatureAfterEnd: bool, cohortWaitUntilEndToInclude: bool, fixedAnalysisDuration: int, scheduledReloadHour: int, scheduledReloadType: string, analysisEndTime: string, assignmentSourceFilters: list, analyticsType: string, isSidecar: bool, decisionReason: string, stratifiedSampling: record, subtype: string, externalExperimentName: string, layerID: string, startTime: float, endTime: float, decisionTime: float, healthChecks: list, healthCheckStatus: string, owner: record, inlineTargetingRulesJSON: string, summarySections: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "layerID" $layerID "scalar") (serialize-qp "idType" $idType "scalar") (serialize-qp "teamID" $teamID "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "targetAppID" $targetAppID "scalar") (serialize-qp "createdStartDate" $createdStartDate "scalar") (serialize-qp "createdEndDate" $createdEndDate "scalar") (serialize-qp "creatorName" $creatorName "scalar") (serialize-qp "creatorID" $creatorID "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/metrics/($id)/experiments" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reload metric data
#
# POST /console/v1/metrics/{id}/reload
export def "console-metrics-reload post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incremental: string@incremental-completer # Incremental reload of the metric
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incremental" $incremental "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/metrics/($id)/reload" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a metric archive
#
# PUT /console/v1/metrics/{id}/schedule_archive
export def "console-metrics-schedule-archive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($id)/schedule_archive")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive a metric
#
# PUT /console/v1/metrics/{id}/unarchive
export def "console-metrics-unarchive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($id)/unarchive")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Metric Definition by Name
#
# GET /console/v1/metrics/{name}/{type}
export def "console-metrics get-by-name-type" [
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list<string>, metricEvents: list<record>, metricComponentMetrics: list<record>, description: string, directionality: string, tags: list<string>, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list<record>, funnelCountDistinct: string, warehouseNative: record<aggregation: string, metricSourceName: string, criteria: list, waitForCohortWindow: bool, denominatorCriteria: list, denominatorAggregation: string, denominatorCustomRollupEnd: float, denominatorCustomRollupStart: float, denominatorMetricSourceName: string, denominatorRollupTimeWindow: string, denominatorValueColumn: string, funnelCalculationWindow: float, funnelCountDistinct: string, funnelEvents: list, funnelStartCriteria: string, metricDimensionColumns: list, metricBakeDays: float, numeratorAggregation: string, valueColumn: string, valueThreshold: float, allowNullRatioDenominator: bool, funnelStrictOrdering: bool, funnelUseExposureAsFirstEvent: bool, funnelTimestampAllowanceMs: float, funnelTimeToConvert: bool, winsorizationHigh: float, winsorizationLow: float, winsorizationHighDenominator: float, winsorizationLowDenominator: float, cupedAttributionWindow: float, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, onlyIncludeUsersWithConversionEvent: bool, denominatorCustomRollupMeasureInMinutes: bool, customRollupMeasureInMinutes: bool, percentile: float, useLogTransform: bool, useSecondaryRetentionEvent: bool, retentionEnd: float, retentionLength: float, logTransformBase: float, cap: float, surrogateMetricMSE: float>, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record<events: list, metrics: list>, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/($name)/($type)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Metrics
#
# GET /console/v1/metrics/list
export def "console-metrics-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showHiddenMetrics: string@showHiddenMetrics-completer # Should hidden metrics be returned: Allowed values are "true" or "false".
  --tags: string # Filter metrics based on a given tagID, found on /tags endpoint. Can be a single string or an array of strings.
  --filters: string # Additional filters for metrics. Can be a string or an object with tags filter.
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list, metricEvents: list, metricComponentMetrics: list, description: string, directionality: string, tags: list, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list, funnelCountDistinct: string, warehouseNative: record, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showHiddenMetrics" $showHiddenMetrics "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/metrics/list" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Metric Source
#
# POST /console/v1/metrics/metric_source
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --customFieldMapping item shape: {key: string, formula: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-metrics-metric-source post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the source, serving as its primary identifier.
  --description: string # An optional description for the source, providing context and details about its purpose and usage.
  --tags: list # Optional array of tags to categorize the source, facilitating easier organization and retrieval.
  sql: string # The SQL query or statement used to extract data from the source.
  timestampColumn: string # The name of the column containing timestamp data for the source.
  --timestampAsDay: string@bool-completer # Indicates whether the timestamp should be treated as a day-level granularity.
  idTypeMapping: list # Array defining the mapping between Statsig unit IDs and their respective source columns. — item shape: {statsigUnitID: string, column: string}
  --sourceType: string@sourceType-completer # The type of source, indicating whether it is a database table or a custom query.
  --tableName: string # The name of the database table if the source type is "table".
  --datePartitionColumn: string # The name of the date partition column if the source type is "table". Can be undefined.
  --customFieldMapping: list # Optional array defining mappings for custom fields using specific formulas. — item shape: {key: string, formula: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --isVerified: string@bool-completer # Marks the metric source as verified, indicating trustworthiness within the organization. (e.g. false)
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting the source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list<record>, isReadOnly: bool, isVerified: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/metrics/metric_source")
  let body = {name: $name, description: $description, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, sourceType: $sourceType, tableName: $tableName, datePartitionColumn: $datePartitionColumn, customFieldMapping: $customFieldMapping, isReadOnly: $isReadOnly, isVerified: $isVerified, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Metric Source
#
# GET /console/v1/metrics/metric_source/{name}
export def "console-metrics-metric-source get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list<record>, isReadOnly: bool, isVerified: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/metric_source/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Metric Source
#
# POST /console/v1/metrics/metric_source/{name}
# --idTypeMapping item shape: {statsigUnitID: string, column: string}
# --customFieldMapping item shape: {key: string, formula: string}
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-metrics-metric-source post-by-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body-name: any # The name of the source cannot be changed in this update, ensuring the identity remains consistent.
  --description: string # An optional updated description for the source, providing additional context or changes.
  --tags: list # Optional array of tags for categorizing the source, allowing for updates to its categorization.
  sql: string # The SQL query or statement used to extract data from the source.
  timestampColumn: string # The name of the column containing timestamp data for the source.
  --timestampAsDay: string@bool-completer # Indicates whether the timestamp should be treated as a day-level granularity.
  idTypeMapping: list # Array defining the mapping between Statsig unit IDs and their respective source columns. — item shape: {statsigUnitID: string, column: string}
  --sourceType: string@sourceType-completer # The type of source, indicating whether it is a database table or a custom query.
  --tableName: string # The name of the database table if the source type is "table".
  --datePartitionColumn: string # The name of the date partition column if the source type is "table". Can be undefined.
  --customFieldMapping: list # Optional array defining mappings for custom fields using specific formulas. — item shape: {key: string, formula: string}
  --isReadOnly: string@bool-completer # Specifies if the source can only be edited via the Console API.
  --isVerified: string@bool-completer # Marks the metric source as verified, indicating trustworthiness within the organization. (e.g. false)
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --team: string # Optional field indicating the team name responsible for the metric, aiding in accountability and management. (nullable)
  --teamID: string # Optional field indicating the team ID responsible for the metric, aiding in accountability and management. (nullable)
  --dryRun: string@bool-completer # Skips persisting updates to the source (used to validate that inputs are correct)
]: any -> record<message: string, data: record<name: string, description: string, tags: list<string>, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list<record>, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list<record>, isReadOnly: bool, isVerified: bool, owner: record<ownerID: string, ownerType: string, ownerName: string, ownerEmail: string>, team: string, teamID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/metric_source/($name)")
  let body = {name: $body_name, description: $description, tags: $tags, sql: $sql, timestampColumn: $timestampColumn, timestampAsDay: $timestampAsDay, idTypeMapping: $idTypeMapping, sourceType: $sourceType, tableName: $tableName, datePartitionColumn: $datePartitionColumn, customFieldMapping: $customFieldMapping, isReadOnly: $isReadOnly, isVerified: $isVerified, owner: $owner, team: $team, teamID: $teamID, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Metric Source
#
# DELETE /console/v1/metrics/metric_source/{name}
export def "console-metrics-metric-source delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/metrics/metric_source/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Metric Source Metrics
#
# GET /console/v1/metrics/metric_source/{name}/metrics
export def "console-metrics-metric-source-metrics get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, type: string, isVerified: bool, isReadOnly: bool, unitTypes: list, metricEvents: list, metricComponentMetrics: list, description: string, directionality: string, tags: list, isPermanent: bool, rollupTimeWindow: string, customRollUpStart: float, customRollUpEnd: float, funnelEventList: list, funnelCountDistinct: string, warehouseNative: record, team: string, teamID: string, dryRun: bool, id: string, isHidden: bool, lineage: record, creatorName: string, creatorEmail: string, createdTime: float, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, owner: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/metrics/metric_source/($name)/metrics" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metric source
#
# GET /console/v1/metrics/metric_source/list
export def "console-metrics-metric-source-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, description: string, tags: list, sql: string, timestampColumn: string, timestampAsDay: bool, idTypeMapping: list, sourceType: string, tableName: string, datePartitionColumn: string, customFieldMapping: list, isReadOnly: bool, isVerified: bool, owner: record, team: string, teamID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/metrics/metric_source/list" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Metric Values
#
# GET /console/v1/metrics/values
export def "console-metrics-values get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Expected valid date in the form of YYYY-MM-DD (e.g. 2024-01-01)
  --metricName: string
  --metricType: string
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<value: float, unitType: string, numerator: float, denominator: float, inputRows: float, metricName: string, metricType: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "metricName" $metricName "scalar") (serialize-qp "metricType" $metricType "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/metrics/values" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Param Stores
#
# GET /console/v1/param_stores
export def "console-param-stores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, displayName: string, description: string, createdTime: float, creatorID: string, lastModifierID: string, parameters: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/param_stores" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Param Store
#
# POST /console/v1/param_stores
export def "console-param-stores post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # Param Store Name
  description: string # Param Store Description
  displayName: string # Param Store Display Name
  --targetAppIDs: list # Target App IDs
  --tags: list # Tags
  --team: string # Team
]: any -> record<message: string, data: record<id: string, name: string, displayName: string, description: string, createdTime: float, creatorID: string, lastModifierID: string, parameters: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/param_stores")
  let body = {name: $name, description: $description, displayName: $displayName, targetAppIDs: $targetAppIDs, tags: $tags, team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Param Store
#
# GET /console/v1/param_stores/{name}
export def "console-param-stores get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, displayName: string, description: string, createdTime: float, creatorID: string, lastModifierID: string, parameters: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/param_stores/($name)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Param Store
#
# POST /console/v1/param_stores/{name}
export def "console-param-stores post-by-name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string # Param Store Description
  --parameters: list # List of Parameters
]: any -> record<message: string, data: record<id: string, name: string, displayName: string, description: string, createdTime: float, creatorID: string, lastModifierID: string, parameters: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/param_stores/($name)")
  let body = {description: $description, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Project Info
#
# GET /console/v1/project
export def "console-project get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/project")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Report in CSV format
#
# GET /console/v1/project/usage_billing/report
export def "console-project-usage-billing-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Unix timestamp in ms
  --end: int # Unix timestamp in ms
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/project/usage_billing/report" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Prompts
#
# GET /console/v1/prompts
export def "console-prompts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list, targetApps: list, holdoutIDs: list, team: string, teamID: string, version: float>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/prompts" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Prompt
#
# POST /console/v1/prompts
# --owner shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
export def "console-prompts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # Name for the AI Config. (e.g. my_prompt)
  --displayName: string # Optional display name for the AI Config.
  --description: string # Description for the AI Config.
  --targetApps: any # List of target app names.
  --team: string # Team name.
  --teamID: string # Team ID.
  --tags: list # Optional tags to associate with the AI Config.
  --creatorID: string # nullable
  --owner: record # Schema for owner data including ID, type, name. Note that if Entity is created by CONSOLE API, owner will be undefined. (nullable, e.g. {ownerID: user123, ownerType: USER, ownerName: John Doe, ownerEmail: owner123@test.com}) — shape: {ownerID?: string, ownerType?: string, ownerName?: string, ownerEmail?: string}
  --creatorEmail: string # nullable
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/prompts")
  let body = {name: $name, displayName: $displayName, description: $description, targetApps: $targetApps, team: $team, teamID: $teamID, tags: $tags, creatorID: $creatorID, owner: $owner, creatorEmail: $creatorEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Prompt
#
# GET /console/v1/prompts/{id}
export def "console-prompts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/prompts/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Prompt (partial)
#
# PATCH /console/v1/prompts/{id}
export def "console-prompts patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --description: string # Updated description.
  --targetApps: any # Updated list of target app names.
  --team: string # Updated team name.
  --teamID: string # Updated team ID.
]: any -> record<message: string, data: record<id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, tags: list<string>, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/prompts/($id)")
  let body = {description: $description, targetApps: $targetApps, team: $team, teamID: $teamID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Prompt Version
#
# POST /console/v1/prompts/{id}/versions
# --prompts item shape: {content: string, role: "system"|"user"|"assistant"}
# --workflow_headers item shape: {name: string, value: string}
# --auth_workflow_headers item shape: {name: string, value: string}
export def "console-prompts-versions post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --prompts: list # item shape: {content: string, role: "system"|"user"|"assistant"}
  --temperature: float # format: double
  --model: string
  name: string # The Prompt Version display name (e.g. my_config)
  --provider: string
  --workflow-body: string
  --workflow-headers: list # item shape: {name: string, value: string}
  --auth-workflow-headers: list # item shape: {name: string, value: string}
  --eval-model: string
  --top-p: float # format: double
  --frequency-penalty: float # format: double
  --presence-penalty: float # format: double
  --max-tokens: float # format: double
  --body-id: string # The Prompt Version name ID
  --description: string
]: any -> record<message: string, data: record<prompts: list<record>, temperature: float, model: string, name: string, provider: string, workflow_body: string, workflow_headers: list<record>, auth_workflow_headers: list<record>, eval_model: string, top_p: float, frequency_penalty: float, presence_penalty: float, max_tokens: float, id: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/prompts/($id)/versions")
  let body = {prompts: $prompts, temperature: $temperature, model: $model, name: $name, provider: $provider, workflow_body: $workflow_body, workflow_headers: $workflow_headers, auth_workflow_headers: $auth_workflow_headers, eval_model: $eval_model, top_p: $top_p, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, max_tokens: $max_tokens, id: $body_id, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start Prompt Version Evaluation Job
#
# POST /console/v1/prompts/{id}/versions/{versionId}/start_evals
export def "console-prompts-versions-start-evals post" [
  versionId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/prompts/($id)/versions/($versionId)/start_evals")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Pipeline Triggers
#
# GET /console/v1/release_pipeline_triggers
export def "console-release-pipeline-triggers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --releasePipelineID: string # Filter by Release Pipeline ID
  --gateID: string # Filter by Gate ID
  --dynamicConfigID: string # Filter by Dynamic Config ID
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, releasePipelineID: string, actions: list, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "releasePipelineID" $releasePipelineID "scalar") (serialize-qp "gateID" $gateID "scalar") (serialize-qp "dynamicConfigID" $dynamicConfigID "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/release_pipeline_triggers" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pipeline Trigger
#
# GET /console/v1/release_pipeline_triggers/{id}
export def "console-release-pipeline-triggers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Abort Pipeline Trigger
#
# PUT /console/v1/release_pipeline_triggers/{id}/abort
export def "console-release-pipeline-triggers-abort put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)/abort")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve Pipeline Trigger Phase
#
# PUT /console/v1/release_pipeline_triggers/{id}/approve
export def "console-release-pipeline-triggers-approve put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  phaseID: string # Phase ID to ensure the correct state of the pipeline is updated
]: any -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)/approve")
  let body = {phaseID: $phaseID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pause Pipeline Trigger
#
# PUT /console/v1/release_pipeline_triggers/{id}/pause
export def "console-release-pipeline-triggers-pause put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  phaseID: string # Phase ID to ensure the correct state of the pipeline is updated
]: any -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)/pause")
  let body = {phaseID: $phaseID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fully Roll Out Pipeline Trigger
#
# PUT /console/v1/release_pipeline_triggers/{id}/rollout
export def "console-release-pipeline-triggers-rollout put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)/rollout")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Skip to Pipeline Trigger Phase
#
# PUT /console/v1/release_pipeline_triggers/{id}/skip
export def "console-release-pipeline-triggers-skip put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  phaseID: string # Phase ID to ensure the correct state of the pipeline is updated
]: any -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)/skip")
  let body = {phaseID: $phaseID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpause Pipeline Trigger
#
# PUT /console/v1/release_pipeline_triggers/{id}/unpause
export def "console-release-pipeline-triggers-unpause put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  phaseID: string # Phase ID to ensure the correct state of the pipeline is updated
]: any -> record<message: string, data: record<id: string, releasePipelineID: string, actions: list<record>, creatorID: string, createdTime: float, description: string, gateID: string, dynamicConfigID: string, lastModifierID: string, lastModifierName: string, status: string, currentPhase: string, currentPhaseID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipeline_triggers/($id)/unpause")
  let body = {phaseID: $phaseID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pipelines
#
# GET /console/v1/release_pipelines
export def "console-release-pipelines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, creatorID: string, createdTime: float, lastModifierID: string, phases: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/release_pipelines" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Pipeline
#
# POST /console/v1/release_pipelines
# --phases item shape: {id?: string, name: string, timeIntervalMs: float, requiredReview: bool, rules: list}
export def "console-release-pipelines post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # Pipeline Name
  --phases: list # Phases of the release pipeline that will be executed in order. — item shape: {id?: string, name: string, timeIntervalMs: float, requiredReview: bool, rules: list}
]: any -> record<message: string, data: record<id: string, name: string, creatorID: string, createdTime: float, lastModifierID: string, phases: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/release_pipelines")
  let body = {name: $name, phases: $phases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Pipeline
#
# GET /console/v1/release_pipelines/{id}
export def "console-release-pipelines get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, creatorID: string, createdTime: float, lastModifierID: string, phases: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipelines/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Pipeline
#
# POST /console/v1/release_pipelines/{id}
# --phases item shape: {id?: string, name: string, timeIntervalMs: float, requiredReview: bool, rules: list}
export def "console-release-pipelines post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # Pipeline Name
  --phases: list # Phases of the release pipeline that will be executed in order. — item shape: {id?: string, name: string, timeIntervalMs: float, requiredReview: bool, rules: list}
]: any -> record<message: string, data: record<id: string, name: string, creatorID: string, createdTime: float, lastModifierID: string, phases: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipelines/($id)")
  let body = {name: $name, phases: $phases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Pipeline
#
# DELETE /console/v1/release_pipelines/{id}
export def "console-release-pipelines delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/release_pipelines/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Reports
#
# GET /console/v1/reports
export def "console-reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-5 # report type (e.g. first_exposures)
  --date: string # date for the report (e.g. 2024-09-01)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/reports" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Roles
#
# GET /console/v1/roles
export def "console-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, permissions: record>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/roles" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Role
#
# POST /console/v1/roles
# --permissions shape: {invitation_access?: bool, create_configs?: bool, edit_or_delete_configs?: bool, launch_to_production?: bool, launch_or_disable_configs?: bool, start_experiments?: bool, create_or_edit_templates?: bool, create_or_edit_dashboards?: bool, create_teams?: bool, edit_dynamic_config_schemas?: bool, create_release_pipelines?: bool, approve_required_review_release_pipeline_phase?: bool, self_approve_review?: bool, approve_reviews?: bool, bypass_reviews_for_overrides?: bool, metric_management?: bool, event_dimensions_access?: bool, verify_metrics?: bool, use_metrics_explorer?: bool, local_metrics?: bool, manage_alerts?: bool, integrations_edit_access?: bool, source_connection_and_creation?: bool, data_warehouse_ingestion_and_exports_edit_access?: bool, edit_and_tag_configs_with_core_tag?: bool, reset_experiments?: bool, manual_whn_reload?: bool}
export def "console-roles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the role.
  permissions: record # The permissions of the role. — shape: {invitation_access?: bool, create_configs?: bool, edit_or_delete_configs?: bool, launch_to_production?: bool, launch_or_disable_configs?: bool, start_experiments?: bool, create_or_edit_templates?: bool, create_or_edit_dashboards?: bool, create_teams?: bool, edit_dynamic_config_schemas?: bool, create_release_pipelines?: bool, approve_required_review_release_pipeline_phase?: bool, self_approve_review?: bool, approve_reviews?: bool, bypass_reviews_for_overrides?: bool, metric_management?: bool, event_dimensions_access?: bool, verify_metrics?: bool, use_metrics_explorer?: bool, local_metrics?: bool, manage_alerts?: bool, integrations_edit_access?: bool, source_connection_and_creation?: bool, data_warehouse_ingestion_and_exports_edit_access?: bool, edit_and_tag_configs_with_core_tag?: bool, reset_experiments?: bool, manual_whn_reload?: bool}
]: any -> record<message: string, data: record<name: string, permissions: record<invitation_access: bool, create_configs: bool, edit_or_delete_configs: bool, launch_to_production: bool, launch_or_disable_configs: bool, start_experiments: bool, create_or_edit_templates: bool, create_or_edit_dashboards: bool, create_teams: bool, edit_dynamic_config_schemas: bool, create_release_pipelines: bool, approve_required_review_release_pipeline_phase: bool, self_approve_review: bool, approve_reviews: bool, bypass_reviews_for_overrides: bool, metric_management: bool, event_dimensions_access: bool, verify_metrics: bool, use_metrics_explorer: bool, local_metrics: bool, manage_alerts: bool, integrations_edit_access: bool, source_connection_and_creation: bool, data_warehouse_ingestion_and_exports_edit_access: bool, edit_and_tag_configs_with_core_tag: bool, reset_experiments: bool, manual_whn_reload: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/roles")
  let body = {name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Role
#
# GET /console/v1/roles/{id}
export def "console-roles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, permissions: record<invitation_access: bool, create_configs: bool, edit_or_delete_configs: bool, launch_to_production: bool, launch_or_disable_configs: bool, start_experiments: bool, create_or_edit_templates: bool, create_or_edit_dashboards: bool, create_teams: bool, edit_dynamic_config_schemas: bool, create_release_pipelines: bool, approve_required_review_release_pipeline_phase: bool, self_approve_review: bool, approve_reviews: bool, bypass_reviews_for_overrides: bool, metric_management: bool, event_dimensions_access: bool, verify_metrics: bool, use_metrics_explorer: bool, local_metrics: bool, manage_alerts: bool, integrations_edit_access: bool, source_connection_and_creation: bool, data_warehouse_ingestion_and_exports_edit_access: bool, edit_and_tag_configs_with_core_tag: bool, reset_experiments: bool, manual_whn_reload: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/roles/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Role
#
# PATCH /console/v1/roles/{id}
# --permissions shape: {invitation_access?: bool, create_configs?: bool, edit_or_delete_configs?: bool, launch_to_production?: bool, launch_or_disable_configs?: bool, start_experiments?: bool, create_or_edit_templates?: bool, create_or_edit_dashboards?: bool, create_teams?: bool, edit_dynamic_config_schemas?: bool, create_release_pipelines?: bool, approve_required_review_release_pipeline_phase?: bool, self_approve_review?: bool, approve_reviews?: bool, bypass_reviews_for_overrides?: bool, metric_management?: bool, event_dimensions_access?: bool, verify_metrics?: bool, use_metrics_explorer?: bool, local_metrics?: bool, manage_alerts?: bool, integrations_edit_access?: bool, source_connection_and_creation?: bool, data_warehouse_ingestion_and_exports_edit_access?: bool, edit_and_tag_configs_with_core_tag?: bool, reset_experiments?: bool, manual_whn_reload?: bool}
export def "console-roles patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  permissions: record # The permissions of the role. — shape: {invitation_access?: bool, create_configs?: bool, edit_or_delete_configs?: bool, launch_to_production?: bool, launch_or_disable_configs?: bool, start_experiments?: bool, create_or_edit_templates?: bool, create_or_edit_dashboards?: bool, create_teams?: bool, edit_dynamic_config_schemas?: bool, create_release_pipelines?: bool, approve_required_review_release_pipeline_phase?: bool, self_approve_review?: bool, approve_reviews?: bool, bypass_reviews_for_overrides?: bool, metric_management?: bool, event_dimensions_access?: bool, verify_metrics?: bool, use_metrics_explorer?: bool, local_metrics?: bool, manage_alerts?: bool, integrations_edit_access?: bool, source_connection_and_creation?: bool, data_warehouse_ingestion_and_exports_edit_access?: bool, edit_and_tag_configs_with_core_tag?: bool, reset_experiments?: bool, manual_whn_reload?: bool}
]: any -> record<message: string, data: record<name: string, permissions: record<invitation_access: bool, create_configs: bool, edit_or_delete_configs: bool, launch_to_production: bool, launch_or_disable_configs: bool, start_experiments: bool, create_or_edit_templates: bool, create_or_edit_dashboards: bool, create_teams: bool, edit_dynamic_config_schemas: bool, create_release_pipelines: bool, approve_required_review_release_pipeline_phase: bool, self_approve_review: bool, approve_reviews: bool, bypass_reviews_for_overrides: bool, metric_management: bool, event_dimensions_access: bool, verify_metrics: bool, use_metrics_explorer: bool, local_metrics: bool, manage_alerts: bool, integrations_edit_access: bool, source_connection_and_creation: bool, data_warehouse_ingestion_and_exports_edit_access: bool, edit_and_tag_configs_with_core_tag: bool, reset_experiments: bool, manual_whn_reload: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/roles/($id)")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Role
#
# DELETE /console/v1/roles/{id}
export def "console-roles delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/roles/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Segments
#
# GET /console/v1/segments
export def "console-segments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<isEnabled: bool, type: string, count: float, rules: list, tags: list, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, targetApps: list, holdoutIDs: list, team: string, teamID: string, version: float>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/segments" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Segment
#
# POST /console/v1/segments
# --rules item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
export def "console-segments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # name of the segment
  --id: string # optional id of the segment (defaults to name)
  --description: string # description of the segment
  type: string@type-completer-6 # type of the segment
  --idType: string # type of id (default: userID)
  --tags: list # optional tags for categorization
  --creatorID: string # the Statsig ID of the creator of this experiment (nullable)
  --creatorEmail: string # the email of the creator of this experiment (nullable)
  --team: string # optional name identifier for the responsible team (enterprise only) (nullable)
  --teamID: string # optional identifier for the responsible team (enterprise only) (nullable)
  --rules: list # Rule Object — item shape: {name: string, passPercentage: float, conditions: list, environments?: list, id?: string, baseID?: string, returnValue?: record, completedAutomatedRollouts?: list, pendingAutomatedRollouts?: list}
]: any -> record<message: string, data: record<isEnabled: bool, type: string, count: float, rules: list<record>, tags: list<string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/segments")
  let body = {name: $name, id: $id, description: $description, type: $type, idType: $idType, tags: $tags, creatorID: $creatorID, creatorEmail: $creatorEmail, team: $team, teamID: $teamID, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Segment
#
# GET /console/v1/segments/{id}
export def "console-segments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<isEnabled: bool, type: string, count: float, rules: list<record>, tags: list<string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Segment
#
# DELETE /console/v1/segments/{id}
export def "console-segments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add IDs to User Store ID List
#
# PATCH /console/v1/segments/{id}/add_ids
export def "console-segments-add-ids patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  ids: list
  --version: float # format: double
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/add_ids")
  let body = {ids: $ids, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive Segment
#
# PUT /console/v1/segments/{id}/archive
export def "console-segments-archive put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<isEnabled: bool, type: string, count: float, rules: list<record>, tags: list<string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/archive")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Segment Rules
#
# POST /console/v1/segments/{id}/conditional
export def "console-segments-conditional post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --body: record
]: any -> record<message: string, data: record<isEnabled: bool, type: string, count: float, rules: list<record>, tags: list<string>, id: string, name: string, idType: string, description: string, lastModifierID: string, lastModifiedTime: float, lastModifierEmail: string, lastModifierName: string, creatorID: string, createdTime: float, creatorName: string, creatorEmail: string, targetApps: list<string>, holdoutIDs: list<string>, team: string, teamID: string, version: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/conditional")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get IDs in a Segment
#
# GET /console/v1/segments/{id}/id_list
export def "console-segments-id-list get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, count: float, ids: list<string>>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/console/v1/segments/($id)/id_list" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add IDs to Segment
#
# PATCH /console/v1/segments/{id}/id_list
export def "console-segments-id-list patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  ids: list
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/id_list")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove IDs from Segment
#
# DELETE /console/v1/segments/{id}/id_list
export def "console-segments-id-list delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/id_list")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset ID List Segment
#
# POST /console/v1/segments/{id}/id_list/reset
export def "console-segments-id-list-reset post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  ids: list
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/id_list/reset")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ID List Metadata
#
# GET /console/v1/segments/{id}/idlist_metadata
export def "console-segments-idlist-metadata get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<currentVersion: float, isUpdating: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/idlist_metadata")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove IDs from User Store ID List
#
# PATCH /console/v1/segments/{id}/remove_ids
export def "console-segments-remove-ids patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  ids: list
  --version: float # format: double
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/segments/($id)/remove_ids")
  let body = {ids: $ids, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Project Settings
#
# GET /console/v1/settings/project
export def "console-settings-project get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, visibility: string, default_unit_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/project")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Project Settings
#
# POST /console/v1/settings/project
export def "console-settings-project post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the project.
  visibility: string@visibility-completer # The visibility type of the project.
  --default-unit-type: string # The default unit ID type of the project for newly created gates, experiments, and metrics. If not provided, there will be no default unit type.
]: any -> record<message: string, data: record<name: string, visibility: string, default_unit_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/project")
  let body = {name: $name, visibility: $visibility, default_unit_type: $default_unit_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Reviews Settings
#
# GET /console/v1/settings/reviews
export def "console-settings-reviews get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<is_config_review_required: bool, is_metric_review_required: bool, is_metric_review_required_on_verified_only: bool, is_whn_analysis_only_review_required: bool, is_whn_source_review_required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/reviews")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Reviews Settings
#
# POST /console/v1/settings/reviews
export def "console-settings-reviews post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --is-config-review-required: string@bool-completer # Whether config reviews are required.
  --is-metric-review-required: string@bool-completer # Whether metric reviews are required.
  --is-metric-review-required-on-verified-only: string@bool-completer # Whether metric reviews are only required for verified metrics.
  --is-whn-analysis-only-review-required: string@bool-completer # Whether analysis-only experiment reviews are required. Only applicable to WHN projects.
  --is-whn-source-review-required: string@bool-completer # Whether metric/assignment/entity property source reviews are required. Only applicable to WHN projects.
]: any -> record<message: string, data: record<is_config_review_required: bool, is_metric_review_required: bool, is_metric_review_required_on_verified_only: bool, is_whn_analysis_only_review_required: bool, is_whn_source_review_required: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/reviews")
  let body = {is_config_review_required: $is_config_review_required, is_metric_review_required: $is_metric_review_required, is_metric_review_required_on_verified_only: $is_metric_review_required_on_verified_only, is_whn_analysis_only_review_required: $is_whn_analysis_only_review_required, is_whn_source_review_required: $is_whn_source_review_required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Roles Settings
#
# GET /console/v1/settings/roles
export def "console-settings-roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<default_project_role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/roles")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Roles Settings
#
# POST /console/v1/settings/roles
export def "console-settings-roles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  default_project_role: string # The name of the default project role. This is the role that will be initially assigned to new users joining the project.
]: any -> record<message: string, data: record<default_project_role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/roles")
  let body = {default_project_role: $default_project_role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Teams Settings
#
# GET /console/v1/settings/teams
export def "console-settings-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<require_teams_on_configs: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/teams")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Teams Settings
#
# POST /console/v1/settings/teams
export def "console-settings-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --require-teams-on-configs: string@bool-completer # Whether a team is required on each new config.
]: any -> record<message: string, data: record<require_teams_on_configs: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/settings/teams")
  let body = {require_teams_on_configs: $require_teams_on_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Tags
#
# GET /console/v1/tags
export def "console-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string, description: string, isCore: bool>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/tags" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Tag
#
# POST /console/v1/tags
export def "console-tags post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string
  description: string
  --isCore: string@bool-completer # default: false
]: any -> record<message: string, data: record<id: string, name: string, description: string, isCore: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/tags")
  let body = {name: $name, description: $description, isCore: $isCore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Tag
#
# GET /console/v1/tags/{id}
export def "console-tags get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string, description: string, isCore: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/tags/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Tag
#
# PATCH /console/v1/tags/{id}
export def "console-tags patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string
  --description: string
  --isCore: string@bool-completer # default: false
]: any -> record<message: string, data: record<id: string, name: string, description: string, isCore: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/tags/($id)")
  let body = {name: $name, description: $description, isCore: $isCore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Tag
#
# DELETE /console/v1/tags/{id}
export def "console-tags delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/tags/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Target Apps
#
# GET /console/v1/target_app
export def "console-target-app list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<id: string, name: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/target_app" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Target App
#
# POST /console/v1/target_app
export def "console-target-app post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # name of the target app (e.g. string)
  description: string # a description of the target app (e.g. a description)
  --gates: list # Gate IDs to assign to target app(s)
  --dynamicConfigs: list # Dynamic Config IDs to assign to target app(s)
  --experiments: list # Experiment IDs to assign to target app(s)
]: any -> record<message: string, data: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/target_app")
  let body = {name: $name, description: $description, gates: $gates, dynamicConfigs: $dynamicConfigs, experiments: $experiments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Assign Target Apps
#
# PATCH /console/v1/target_app
export def "console-target-app patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  targetApps: list # target app ids
  --gates: list # Gate IDs to assign to target app(s)
  --dynamicConfigs: list # Dynamic Config IDs to assign to target app(s)
  --experiments: list # Experiment IDs to assign to target app(s)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/target_app")
  let body = {targetApps: $targetApps, gates: $gates, dynamicConfigs: $dynamicConfigs, experiments: $experiments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Target App
#
# GET /console/v1/target_app/{id}
export def "console-target-app get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/target_app/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Target App
#
# PATCH /console/v1/target_app/{id}
export def "console-target-app patch-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # name of the target app (e.g. string)
  --description: string # a description of the target app (e.g. a description)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/target_app/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Target App
#
# DELETE /console/v1/target_app/{id}
export def "console-target-app delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/target_app/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Unit ID Types
#
# GET /console/v1/unit_id_types
export def "console-unit-id-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, description: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/unit_id_types" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Unit ID Type
#
# POST /console/v1/unit_id_types
export def "console-unit-id-types post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the unit id type.
  --description: string # The description of the unit id type.
]: any -> record<message: string, data: record<name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/unit_id_types")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Unit ID Type
#
# GET /console/v1/unit_id_types/{id}
export def "console-unit-id-types get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/unit_id_types/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Unit ID Type
#
# PATCH /console/v1/unit_id_types/{id}
export def "console-unit-id-types patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  description: string # The description of the unit id type.
]: any -> record<message: string, data: record<name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/unit_id_types/($id)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Unit ID Type
#
# DELETE /console/v1/unit_id_types/{id}
export def "console-unit-id-types delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/unit_id_types/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Users
#
# GET /console/v1/users
export def "console-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<email: string, firstName: string, lastName: string, role: string>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/users" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user by email
#
# GET /console/v1/users/{email}
export def "console-users get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<email: string, firstName: string, lastName: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/users/($email)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# POST /console/v1/users/{email}
export def "console-users post" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --role: string # Update the user's role. Can be 'Admin', 'Read Only', 'Member', or any custom role name.
  --firstName: string # Update the user's first name.
  --lastName: string # Update the user's last name.
]: any -> record<message: string, data: record<email: string, firstName: string, lastName: string, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/users/($email)")
  let body = {role: $role, firstName: $firstName, lastName: $lastName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite user. To avoid spamming, invitation emails are not sent. Invitee will see invitation notification in-app after logging in.
#
# POST /console/v1/users/invite
export def "console-users-invite post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  role: string # Role assigned to the invited users. Can be 'Admin', 'Read Only', 'Member', or any custom role name.
  emails: list # List of email addresses to send invitations to. Invitee Emails must have the same domain to your company email domain.
  --teams: list # Optional list of teams that the invited users will be associated with.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/users/invite")
  let body = {role: $role, emails: $emails, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Teams
#
# GET /console/v1/users/teams
export def "console-users-teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page (e.g. 10)
  --page: int # Page number (e.g. 1)
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: table<name: string, description: string, id: string, defaultGateMetrics: list, defaultExperimentPrimaryMetrics: list, defaultExperimentSecondaryMetrics: list, defaultHoldoutMetrics: list, changeTeamConfigs: string, reviewApproval: string, defaultTargetApplications: list, defaultHoldoutID: string, requireReviews: bool, requireGateTemplates: bool, requireExperimentTemplates: bool, requireDynamicConfigTemplates: bool, members: list, admins: list>, pagination: record<itemsPerPage: float, pageNumber: float, nextPage: string, previousPage: string, totalItems: float, all: string>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/console/v1/users/teams" $qp)
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team
#
# POST /console/v1/users/teams
# --defaultGateMetrics item shape: {name: string, type: string}
# --defaultExperimentPrimaryMetrics item shape: {name: string, type: string}
# --defaultExperimentSecondaryMetrics item shape: {name: string, type: string}
# --defaultHoldoutMetrics item shape: {name: string, type: string}
export def "console-users-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  name: string # The name of the team.
  --description: string # Description of the team.
  members: list # Array of member email addresses in the team.
  admins: list # Array of admin email addresses in the team.
  defaultGateMetrics: list # Default gate metrics for the team. — item shape: {name: string, type: string}
  defaultExperimentPrimaryMetrics: list # Default primary metrics for experiments in the team. — item shape: {name: string, type: string}
  defaultExperimentSecondaryMetrics: list # Default secondary metrics for experiments in the team. — item shape: {name: string, type: string}
  defaultHoldoutMetrics: list # Default holdout metrics for the team. — item shape: {name: string, type: string}
  changeTeamConfigs: string@changeTeamConfigs-completer # Who can change team configurations: "anyone" or "team_only".
  reviewApproval: string@reviewApproval-completer # Who can review and approve changes: "anyone", "team_only", or "admin_only".
  defaultTargetApplications: list # Default target applications for the team.
  --defaultHoldoutID: string # Default holdout ID for the team, if applicable. (nullable)
  --requireReviews: string@bool-completer # Whether reviews are required for changes, if applicable. (nullable)
  --requireGateTemplates: string@bool-completer # Whether gate templates are required for the team, if applicable. (nullable)
  --requireExperimentTemplates: string@bool-completer # Whether experiment templates are required for the team, if applicable. (nullable)
  --requireDynamicConfigTemplates: string@bool-completer # Whether dynamic config templates are required for the team, if applicable. (nullable)
]: any -> record<message: string, data: record<name: string, description: string, id: string, defaultGateMetrics: list<record>, defaultExperimentPrimaryMetrics: list<record>, defaultExperimentSecondaryMetrics: list<record>, defaultHoldoutMetrics: list<record>, changeTeamConfigs: string, reviewApproval: string, defaultTargetApplications: list<string>, defaultHoldoutID: string, requireReviews: bool, requireGateTemplates: bool, requireExperimentTemplates: bool, requireDynamicConfigTemplates: bool, members: list<record>, admins: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/users/teams")
  let body = {name: $name, description: $description, members: $members, admins: $admins, defaultGateMetrics: $defaultGateMetrics, defaultExperimentPrimaryMetrics: $defaultExperimentPrimaryMetrics, defaultExperimentSecondaryMetrics: $defaultExperimentSecondaryMetrics, defaultHoldoutMetrics: $defaultHoldoutMetrics, changeTeamConfigs: $changeTeamConfigs, reviewApproval: $reviewApproval, defaultTargetApplications: $defaultTargetApplications, defaultHoldoutID: $defaultHoldoutID, requireReviews: $requireReviews, requireGateTemplates: $requireGateTemplates, requireExperimentTemplates: $requireExperimentTemplates, requireDynamicConfigTemplates: $requireDynamicConfigTemplates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Team
#
# GET /console/v1/users/teams/{id}
export def "console-users-teams get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string, data: record<name: string, description: string, id: string, defaultGateMetrics: list<record>, defaultExperimentPrimaryMetrics: list<record>, defaultExperimentSecondaryMetrics: list<record>, defaultHoldoutMetrics: list<record>, changeTeamConfigs: string, reviewApproval: string, defaultTargetApplications: list<string>, defaultHoldoutID: string, requireReviews: bool, requireGateTemplates: bool, requireExperimentTemplates: bool, requireDynamicConfigTemplates: bool, members: list<record>, admins: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/users/teams/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team. Ops: Replace. Use GET for current data if you intent to Add.
#
# PATCH /console/v1/users/teams/{id}
# --defaultGateMetrics item shape: {name: string, type: string}
# --defaultExperimentPrimaryMetrics item shape: {name: string, type: string}
# --defaultExperimentSecondaryMetrics item shape: {name: string, type: string}
# --defaultHoldoutMetrics item shape: {name: string, type: string}
export def "console-users-teams patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --name: string # The name of the team.
  --description: string # Description of the team.
  --body-id: string # The ID of the team.
  --members: list # Array of member email addresses in the team.
  --admins: list # Array of admin email addresses in the team.
  --defaultGateMetrics: list # Default gate metrics for the team. — item shape: {name: string, type: string}
  --defaultExperimentPrimaryMetrics: list # Default primary metrics for experiments in the team. — item shape: {name: string, type: string}
  --defaultExperimentSecondaryMetrics: list # Default secondary metrics for experiments in the team. — item shape: {name: string, type: string}
  --defaultHoldoutMetrics: list # Default holdout metrics for the team. — item shape: {name: string, type: string}
  --changeTeamConfigs: string@changeTeamConfigs-completer # Who can change team configurations: "anyone" or "team_only".
  --reviewApproval: string@reviewApproval-completer # Who can review and approve changes: "anyone", "team_only", or "admin_only".
  --defaultTargetApplications: list # Default target applications for the team.
  --defaultHoldoutID: string # Default holdout ID for the team, if applicable. (nullable)
  --requireReviews: string@bool-completer # Whether reviews are required for changes, if applicable. (nullable)
  --requireGateTemplates: string@bool-completer # Whether gate templates are required for the team, if applicable. (nullable)
  --requireExperimentTemplates: string@bool-completer # Whether experiment templates are required for the team, if applicable. (nullable)
  --requireDynamicConfigTemplates: string@bool-completer # Whether dynamic config templates are required for the team, if applicable. (nullable)
]: any -> record<message: string, data: record<name: string, description: string, id: string, defaultGateMetrics: list<record>, defaultExperimentPrimaryMetrics: list<record>, defaultExperimentSecondaryMetrics: list<record>, defaultHoldoutMetrics: list<record>, changeTeamConfigs: string, reviewApproval: string, defaultTargetApplications: list<string>, defaultHoldoutID: string, requireReviews: bool, requireGateTemplates: bool, requireExperimentTemplates: bool, requireDynamicConfigTemplates: bool, members: list<record>, admins: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/users/teams/($id)")
  let body = {name: $name, description: $description, id: $body_id, members: $members, admins: $admins, defaultGateMetrics: $defaultGateMetrics, defaultExperimentPrimaryMetrics: $defaultExperimentPrimaryMetrics, defaultExperimentSecondaryMetrics: $defaultExperimentSecondaryMetrics, defaultHoldoutMetrics: $defaultHoldoutMetrics, changeTeamConfigs: $changeTeamConfigs, reviewApproval: $reviewApproval, defaultTargetApplications: $defaultTargetApplications, defaultHoldoutID: $defaultHoldoutID, requireReviews: $requireReviews, requireGateTemplates: $requireGateTemplates, requireExperimentTemplates: $requireExperimentTemplates, requireDynamicConfigTemplates: $requireDynamicConfigTemplates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team
#
# DELETE /console/v1/users/teams/{id}
export def "console-users-teams delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/v1/users/teams/($id)")
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Warehouse Connection Parameters
#
# PATCH /console/v1/wh_connections
# --databricks shape: {host?: string, path?: string, accessToken?: string, stagingDatabase?: string, oauthClientID?: string, consoleComputePath?: string}
# --snowflake shape: {accountName?: string, serviceUserName?: string, serviceUserPassword?: string, privateKey?: string, keyPassPhrase?: string, stagingDatabaseName?: string, stagingSchemaName?: string, computeWarehouse?: string, consoleComputeWarehouse?: string}
# --bigquery shape: {privateKey?: string, project?: string, consoleComputeProject?: string, stagingDataset?: string}
export def "console-wh-connections patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-respect-review-settings: string # Optional header to respect review settings for mutation endpoints.
  --databricks: record # shape: {host?: string, path?: string, accessToken?: string, stagingDatabase?: string, oauthClientID?: string, consoleComputePath?: string}
  --snowflake: record # shape: {accountName?: string, serviceUserName?: string, serviceUserPassword?: string, privateKey?: string, keyPassPhrase?: string, stagingDatabaseName?: string, stagingSchemaName?: string, computeWarehouse?: string, consoleComputeWarehouse?: string}
  --bigquery: record # shape: {privateKey?: string, project?: string, consoleComputeProject?: string, stagingDataset?: string}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "statsig-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/console/v1/wh_connections")
  let body = {databricks: $databricks, snowflake: $snowflake, bigquery: $bigquery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-respect-review-settings": $x_respect_review_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
