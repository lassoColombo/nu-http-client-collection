# Auto-generated client for BugSnag - Data Access API v2
# Source: https://api.swaggerhub.com/apis/smartbear-public/bugsnag-data-access-api/2/swagger.json
# Auth: --token flag or $env.BUGSNAG_AUTH_TOKEN

const BASE_URL = "https://api.bugsnag.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUGSNAG_AUTH_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.bugsnag.com" "https://virtserver.swaggerhub.com/smartbear-public/bugsnag-data-access-api/2" "https://api.bugsnag.smartbear.com" "https://virtserver.swaggerhub.com/smartbear/bugsnag-data-access-api/2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["events" "first_seen" "last_seen" "users"] }
def sort-completer-1 [] { ["created_at" "favorite" "name"] }
def direction-completer [] { ["asc" "desc"] }
def type-completer [] { ["android" "angular" "asgi" "aspnet" "aspnet_core" "backbone" "bottle" "cocos2dx" "connect" "django" "dotnet" "dotnet_desktop" "dotnet_mvc" "electron" "ember" "eventmachine" "expo" "express" "flask" "flutter" "gin" "go" "go_net_http" "heroku" "ios" "java" "java_desktop" "js" "koa" "laravel" "lumen" "magento" "martini" "minidump" "ndk" "negroni" "nintendo_switch" "node" "osx" "other" "other_desktop" "other_mobile" "other_tv" "php" "python" "rack" "rails" "react" "reactnative" "restify" "revel" "ruby" "silex" "sinatra" "spring" "symfony" "tornado" "tvos" "unity" "unrealengine" "vega" "vue" "watchos" "webapi" "wordpress" "wpf" "wsgi"] }
def sort-completer-2 [] { ["events" "first_seen" "last_seen" "unsorted" "users"] }
def filter-groups-join-completer [] { ["and" "or"] }
def histogram-completer [] { ["dynamic" "two_week"] }
def severity-completer [] { ["error" "info" "warning"] }
def operation-completer [] { ["assign" "create_issue" "delete" "discard" "fix" "ignore" "link_issue" "open" "override_severity" "snooze" "undiscard" "unlink_issue"] }
def sort-completer-3 [] { ["timestamp"] }
def resolution-completer [] { ["12h" "1m" "2h" "30m" "5m"] }
def sort-completer-4 [] { ["unsorted"] }
def type-completer-1 [] { ["jira"] }
def sort-completer-5 [] { ["created_at"] }
def project-role-completer [] { ["project_member" "project_owner"] }
def report-type-completer [] { ["gdpr"] }
def op-completer [] { ["add" "remove" "replace"] }
def sort-completer-6 [] { ["percent_of_sessions" "timestamp"] }
def first-seen-completer [] { ["all" "this_week" "today"] }
def sort-completer-7 [] { ["first_seen" "name"] }
def sort-completer-8 [] { ["display_name" "duration_p50" "duration_p75" "duration_p90" "duration_p95" "duration_p99" "http_response_4xx_percentage" "http_response_5xx_percentage" "last_seen" "name" "network_http_method" "rendering_frozen_frame_span_percentage" "rendering_metrics_fps_mean_p50" "rendering_metrics_fps_mean_p75" "rendering_metrics_fps_mean_p90" "rendering_metrics_fps_mean_p95" "rendering_metrics_fps_mean_p99" "rendering_slow_frame_span_percentage" "system_metrics_cpu_total_mean_p50" "system_metrics_cpu_total_mean_p75" "system_metrics_cpu_total_mean_p90" "system_metrics_cpu_total_mean_p95" "system_metrics_cpu_total_mean_p99" "system_metrics_memory_device_mean_p50" "system_metrics_memory_device_mean_p75" "system_metrics_memory_device_mean_p90" "system_metrics_memory_device_mean_p95" "system_metrics_memory_device_mean_p99" "total_spans"] }
def sort-completer-9 [] { ["duration" "full_page_load_cls" "full_page_load_fcp" "full_page_load_fid" "full_page_load_lcp" "full_page_load_ttfb" "http_response_code" "rendering_frozen_frame_percentage" "rendering_metrics_fps_maximum" "rendering_metrics_fps_mean" "rendering_metrics_fps_minimum" "rendering_slow_frame_percentage" "system_metrics_cpu_total_mean" "system_metrics_memory_device_mean" "timestamp"] }
def sort-completer-10 [] { ["cls" "fcp" "fid" "full_page_load_duration_p50" "full_page_load_duration_p75" "full_page_load_duration_p90" "full_page_load_duration_p95" "full_page_load_duration_p99" "full_page_load_total_spans" "lcp" "name" "route_change_duration_p50" "route_change_duration_p75" "route_change_duration_p90" "route_change_duration_p95" "route_change_duration_p99" "route_change_load_total_spans" "route_change_total_spans" "total_spans" "ttfb"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "user-organizations listUserOrganizations" } } | get name | first)
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

# List the Current User's Organizations
#
# GET /user/organizations
# operationId: listUserOrganizations
export def "user-organizations listUserOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool> # `true` if only Organizations the Current User is an admin of should be returned
  --per-page: float # Number of results per page (default: 30, e.g. 10)
]: nothing -> table<name: string, billing_emails: list<string>, auto_upgrade: bool, id: string, slug: string, api_key: string, creator: record<email: string, id: string, name: string>, collaborators_url: string, projects_url: string, created_at: string, updated_at: string, upgrade_url: string, managed_by_platform_services: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "admin" $admin "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Saved Searches on a Project
#
# GET /projects/{project_id}/saved_searches
# operationId: listProjectSavedSearches
export def "projects-saved-searches listProjectSavedSearches" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shared: string # Limit Saved Searches returned to only those with this `shared` property (e.g. true)
]: nothing -> table<id: string, user_id: string, project_id: string, name: string, filters: record<user_id: list, user_email: list, user_name: list, error_id: list, error_status: list, error_assigned_to: list, error_has_issue: bool, app_release_stage: list, app_context: list, app_type: list, version_introduced_in: list, version_seen_in: list, version_code_introduced_in: list, version_code_seen_in: list, release_introduced_in: list, release_seen_in: list, feature_flag_seen_in: list, feature_flag_exclusive_to: list, event_class: list, event_message: list, event_file: list, event_method: list, event_severity: list, event_since: list, event_before: list, browser_name: list, browser_version: list, os_name: list, os_version: list, device_hostname: list, device_manufacturer: list, device_model: list, request_url: list, request_ip: list, device_jailbroken: list, app_in_foreground: list>, sort: string, shared: bool, project_default: bool, updated_by_id: string, created_at: string, updated_at: string, has_assigned_to_me: bool, has_assigned_to: bool, has_created_issue_filter: bool, has_status_filter: bool, new_error_inclusion: string, open_error_inclusion: string, for_review_error_inclusion: string, snoozed_error_inclusion: string, fixed_error_inclusion: string, ignored_error_inclusion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shared" $shared "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/saved_searches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Saved Search
#
# POST /saved_searches
# operationId: createSavedSearch
# --filters shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
export def "saved-searches createSavedSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_id: string # ID of project this saved search is for (e.g. 515fb9337c1074f6fd000003)
  name: string # name of the saved search (e.g. most events)
  filters: record # shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
  --body-sort: string@sort-completer
  --shared: oneof<nothing, bool> # whether this saved search is shared among collaborators (default: false, e.g. false)
  --project-default: oneof<nothing, bool> # whether this saved search is the project default for the current user (e.g. false)
]: any -> record<id: string, user_id: string, project_id: string, name: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, sort: string, shared: bool, project_default: bool, updated_by_id: string, created_at: string, updated_at: string, has_assigned_to_me: bool, has_assigned_to: bool, has_created_issue_filter: bool, has_status_filter: bool, new_error_inclusion: string, open_error_inclusion: string, for_review_error_inclusion: string, snoozed_error_inclusion: string, fixed_error_inclusion: string, ignored_error_inclusion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_searches")
  let body = {project_id: $project_id, name: $name, filters: $filters, sort: $body_sort, shared: $shared, project_default: $project_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Saved Search
#
# GET /saved_searches/{id}
# operationId: getSavedSearchById
export def "saved-searches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, user_id: string, project_id: string, name: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, sort: string, shared: bool, project_default: bool, updated_by_id: string, created_at: string, updated_at: string, has_assigned_to_me: bool, has_assigned_to: bool, has_created_issue_filter: bool, has_status_filter: bool, new_error_inclusion: string, open_error_inclusion: string, for_review_error_inclusion: string, snoozed_error_inclusion: string, fixed_error_inclusion: string, ignored_error_inclusion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_searches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Saved Search
#
# PATCH /saved_searches/{id}
# operationId: updateSavedSearchById
# --filters shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
export def "saved-searches updateSavedSearchById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # name of the saved search (e.g. most events)
  --filters: record # shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
  --body-sort: string@sort-completer
  --shared: oneof<nothing, bool> # whether this saved search is shared among collaborators (default: false, e.g. false)
  --project-default: oneof<nothing, bool> # whether this saved search is the project default for the current user (e.g. false)
]: any -> record<id: string, user_id: string, project_id: string, name: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, sort: string, shared: bool, project_default: bool, updated_by_id: string, created_at: string, updated_at: string, has_assigned_to_me: bool, has_assigned_to: bool, has_created_issue_filter: bool, has_status_filter: bool, new_error_inclusion: string, open_error_inclusion: string, for_review_error_inclusion: string, snoozed_error_inclusion: string, fixed_error_inclusion: string, ignored_error_inclusion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_searches/($id)")
  let body = {name: $name, filters: $filters, sort: $body_sort, shared: $shared, project_default: $project_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Saved Search
#
# DELETE /saved_searches/{id}
# operationId: deleteSavedSearchById
export def "saved-searches delete" [
  id: string
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
  let full_url = (build-url $base $"/saved_searches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Usage Summary for a Saved Search
#
# GET /saved_searches/{id}/usage_summary
# operationId: getSavedSearchUsageSummary
export def "saved-searches-usage-summary get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_notifications_count: float, current_user_using_for_email_notification: bool, collaborator_email_notifications_count: float, performance_monitor_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_searches/($id)/usage_summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List an Organization's Projects
#
# GET /organizations/{organization_id}/projects
# operationId: getOrganizationProjects
export def "organizations-projects get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search projects with names matching parameter (e.g. MyProject)
  --qp-sort: string@sort-completer-1 # Which field to sort the results by (default: created_at)
  --direction: string@direction-completer # Which direction to sort the results by. Defaults to `desc` for all sorts except `favorite`. Defaults to `asc` if sorting by `favorite` (cannot sort `favorite`s `desc`). (default: desc)
  --per-page: float # How many results to return per page (default: 30)
]: nothing -> table<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project in an Organization
#
# POST /organizations/{organization_id}/projects
# operationId: createOrganizationProject
export def "organizations-projects createOrganizationProject" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The new Project's name. Note that the first character should not start with a '$'. (e.g. Example Project)
  type: string@type-completer # used for Projects that use a framework other than those listed above
  --ignore-old-browsers: oneof<nothing, bool> # For javascript projects this will filter errors from older browsers (e.g. true)
]: any -> record<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/projects")
  let body = {name: $name, type: $type, ignore_old_browsers: $ignore_old_browsers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the Errors on a Project
#
# GET /projects/{project_id}/errors
# operationId: listProjectErrors
export def "projects-errors listProjectErrors" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-base: string # format: date-time, e.g. 2017-04-12T22:50:04Z
  --qp-sort: string@sort-completer-2 # default: last_seen
  --direction: string@direction-completer # default: desc
  --per-page: int # default: 30
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --histogram: string@histogram-completer # The type of histogram to include in the response. Only specific values are accepted. When provided, adds trend data to each error in the response. (e.g. two_week)
]: nothing -> table<severity: string, assigned_collaborator_id: string, assigned_team_id: string, id: string, project_id: string, url: string, project_url: string, error_class: string, message: string, context: string, original_severity: string, overridden_severity: string, events: float, events_url: string, unthrottled_occurrence_count: float, users: float, first_seen: string, last_seen: string, first_seen_unfiltered: string, last_seen_unfiltered: string, trend: list<list>, reopen_rules: record<reopen_if: string, additional_users: float, reopen_after: string, seconds: float, occurrences: float, hours: float, occurrence_threshold: float, additional_occurrences: float>, status: string, linked_issues: list<record>, created_issue: record<id: string, key: string, number: float, type: string, url: string>, comment_count: float, missing_dsyms: list<string>, release_stages: list<string>, grouping_reason: string, grouping_fields: record, discarded: bool, introduced_in_releases: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "histogram" $histogram "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Update Errors
#
# PATCH /projects/{project_id}/errors
# operationId: bulkUpdateErrors
# --reopen_rules shape: {reopen_if: "occurs_after"|"n_occurrences_in_m_hours"|"n_additional_occurrences"|"n_additional_users", additional_users?: float, seconds?: float, occurrences?: float, hours?: float, additional_occurrences?: float}
export def "projects-errors bulkUpdateErrors" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-ids: list # e.g. [515fb9337c1074f6fd000001]
  --severity: string@severity-completer # - info - can be used in manual Bugsnag.notify calls - warning - the default severity when Bugsnag.notify is called manually - error - the default severity for uncaught exceptions and crashes
  operation: string@operation-completer # The type of update operation to perform. The can be used to change the Error's workflow state (e.g. marking the Error as `fixed`). It must be one of the following: * `override_severity`   Set the Error's severity to the newly supplied `severity` parameter. * `assign`   Assign the Error to the Collaborator specified by the `assigned_collaborator_id` parameter. The error will be unassigned if `assigned_collaborator_id` is blank, the identified Collaborator has not accepted their invitation, or they do not have access to the Error's Project. * `create_issue`   Create an issue for the Error. If the `issue_title` parameter is set, the new issue will be created with this title. * `link_issue`   Link the Error to an existing issue. The url should be provided in the `issue_url` parameter. `verify_issue_url` can be set to control whether Bugsnag should attempt to verify the issue URL with any configured issue tracker integration. This is the default behavior if `verify_issue_url` is not supplied. * `unlink_issue`   Remove the link between the Error and its current linked issue.  * `open`   Set the Error's status to open. * `snooze`   Snooze the error per the `reopen_rules` parameter. * `fix`   Set the Error's status to fixed. * `ignore`   Ignore the Error. Errors that are ignored and can only be reopened manually. Events are collected, but no notifications are sent. * `delete`   Delete the Error. The Error and all related Events will be removed from Bugsnag. If the error occurs again, it will appear as a new Error with status `Open`. * `discard`   Discard future Events for this Error. The Error and all existing Events will remain in Bugsnag, but future occurrences of the Error will not be stored by Bugsnag or count toward Event usage limits. * `undiscard`   Undiscard the Error. Future Events will be stored for this Error. This undoes the `discard` option.
  --assigned-collaborator-id: string # The Collaborator to assign to the Error. Errors may be assigned only to users who have accepted their Bugsnag invitation and have access to the project.   (e.g. 515fb9337c1074f6fd000002)
  --assigned-team-id: string # The Team to assign to the Error. Mutually exclusive with `assigned_collaborator_id`. (e.g. 515fb9337c1074f6fd000003)
  --issue-url: string # Specifies the HTTP link to an external issue when adding or updating a link. 
  --verify-issue-url: oneof<nothing, bool> # Setting `false` will prevent Bugsnag from attempting to verify the `issue_url` with the configured issue tracker when linking an issue. Defaults to `true` if the parameter is not supplied. If no configured issue tracker the parameter is ignored.
  --issue-title: string # If the Error has a `created_issue`, the `issue_title` request field can be set to update the issue's title.
  --notification-id: string # ID of the issue tracker to use for `create_issue` and `link_issue` operations. The most recent issue tracker is used if the parameter is omitted, and no issue tracker is used even if `notification_id` is set for `link_issue` operations if `verify_issue_url` is `false`.   (e.g. 337515fb9c1074f6fd000001)
  --reopen-rules: record # shape: {reopen_if: "occurs_after"|"n_occurrences_in_m_hours"|"n_additional_occurrences"|"n_additional_users", additional_users?: float, seconds?: float, occurrences?: float, hours?: float, additional_occurrences?: float}
]: any -> record<operation: string, 515fb9337c1074f6fd000001: record<assigned_collaborator_id: string, assigned_team_id: string, linked_issues: list<record>, created_issue: record<id: string, key: string, number: float, type: string, url: string>, reopen_rules: record<reopen_if: string, additional_users: float, reopen_after: string, seconds: float, occurrences: float, hours: float, occurrence_threshold: float, additional_occurrences: float>, status: string, discarded: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "error_ids" $error_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors" $qp)
  let body = {severity: $severity, operation: $operation, assigned_collaborator_id: $assigned_collaborator_id, assigned_team_id: $assigned_team_id, issue_url: $issue_url, verify_issue_url: $verify_issue_url, issue_title: $issue_title, notification_id: $notification_id, reopen_rules: $reopen_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all Errors in a Project
#
# DELETE /projects/{project_id}/errors
# operationId: deleteAllErrorsInProject
export def "projects-errors delete-by-project_id" [
  project_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/errors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View an Error
#
# GET /projects/{project_id}/errors/{error_id}
# operationId: viewErrorOnProject
export def "projects-errors viewErrorOnProject" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
]: nothing -> record<severity: string, assigned_collaborator_id: string, assigned_team_id: string, id: string, project_id: string, url: string, project_url: string, error_class: string, message: string, context: string, original_severity: string, overridden_severity: string, events: float, events_url: string, unthrottled_occurrence_count: float, users: float, first_seen: string, last_seen: string, first_seen_unfiltered: string, last_seen_unfiltered: string, trend: list<list<any>>, reopen_rules: record<reopen_if: string, additional_users: float, reopen_after: string, seconds: float, occurrences: float, hours: float, occurrence_threshold: float, additional_occurrences: float>, status: string, linked_issues: table<id: string, key: string, number: float, type: string, url: string>, created_issue: record<id: string, key: string, number: float, type: string, url: string>, comment_count: float, missing_dsyms: list<string>, release_stages: list<string>, grouping_reason: string, grouping_fields: record, discarded: bool, introduced_in_releases: table<release_stage: string, release_id: string, build_label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Error
#
# PATCH /projects/{project_id}/errors/{error_id}
# operationId: updateErrorOnProject
# --reopen_rules shape: {reopen_if: "occurs_after"|"n_occurrences_in_m_hours"|"n_additional_occurrences"|"n_additional_users", additional_users?: float, seconds?: float, occurrences?: float, hours?: float, additional_occurrences?: float}
export def "projects-errors updateErrorOnProject" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --severity: string@severity-completer # - info - can be used in manual Bugsnag.notify calls - warning - the default severity when Bugsnag.notify is called manually - error - the default severity for uncaught exceptions and crashes
  operation: string@operation-completer # The type of update operation to perform. The can be used to change the Error's workflow state (e.g. marking the Error as `fixed`). It must be one of the following: * `override_severity`   Set the Error's severity to the newly supplied `severity` parameter. * `assign`   Assign the Error to the Collaborator specified by the `assigned_collaborator_id` parameter. The error will be unassigned if `assigned_collaborator_id` is blank, the identified Collaborator has not accepted their invitation, or they do not have access to the Error's Project. * `create_issue`   Create an issue for the Error. If the `issue_title` parameter is set, the new issue will be created with this title. * `link_issue`   Link the Error to an existing issue. The url should be provided in the `issue_url` parameter. `verify_issue_url` can be set to control whether Bugsnag should attempt to verify the issue URL with any configured issue tracker integration. This is the default behavior if `verify_issue_url` is not supplied. * `unlink_issue`   Remove the link between the Error and its current linked issue.  * `open`   Set the Error's status to open. * `snooze`   Snooze the error per the `reopen_rules` parameter. * `fix`   Set the Error's status to fixed. * `ignore`   Ignore the Error. Errors that are ignored and can only be reopened manually. Events are collected, but no notifications are sent. * `delete`   Delete the Error. The Error and all related Events will be removed from Bugsnag. If the error occurs again, it will appear as a new Error with status `Open`. * `discard`   Discard future Events for this Error. The Error and all existing Events will remain in Bugsnag, but future occurrences of the Error will not be stored by Bugsnag or count toward Event usage limits. * `undiscard`   Undiscard the Error. Future Events will be stored for this Error. This undoes the `discard` option.
  --assigned-collaborator-id: string # The Collaborator to assign to the Error. Errors may be assigned only to users who have accepted their Bugsnag invitation and have access to the project.   (e.g. 515fb9337c1074f6fd000002)
  --assigned-team-id: string # The Team to assign to the Error. Mutually exclusive with `assigned_collaborator_id`. (e.g. 515fb9337c1074f6fd000003)
  --issue-url: string # Specifies the HTTP link to an external issue when adding or updating a link. 
  --verify-issue-url: oneof<nothing, bool> # Setting `false` will prevent Bugsnag from attempting to verify the `issue_url` with the configured issue tracker when linking an issue. Defaults to `true` if the parameter is not supplied. If no configured issue tracker the parameter is ignored.
  --issue-title: string # If the Error has a `created_issue`, the `issue_title` request field can be set to update the issue's title.
  --notification-id: string # ID of the issue tracker to use for `create_issue` and `link_issue` operations. The most recent issue tracker is used if the parameter is omitted, and no issue tracker is used even if `notification_id` is set for `link_issue` operations if `verify_issue_url` is `false`.   (e.g. 337515fb9c1074f6fd000001)
  --reopen-rules: record # shape: {reopen_if: "occurs_after"|"n_occurrences_in_m_hours"|"n_additional_occurrences"|"n_additional_users", additional_users?: float, seconds?: float, occurrences?: float, hours?: float, additional_occurrences?: float}
]: any -> record<severity: string, assigned_collaborator_id: string, assigned_team_id: string, id: string, project_id: string, url: string, project_url: string, error_class: string, message: string, context: string, original_severity: string, overridden_severity: string, events: float, events_url: string, unthrottled_occurrence_count: float, users: float, first_seen: string, last_seen: string, first_seen_unfiltered: string, last_seen_unfiltered: string, trend: list<list<any>>, reopen_rules: record<reopen_if: string, additional_users: float, reopen_after: string, seconds: float, occurrences: float, hours: float, occurrence_threshold: float, additional_occurrences: float>, status: string, linked_issues: table<id: string, key: string, number: float, type: string, url: string>, created_issue: record<id: string, key: string, number: float, type: string, url: string>, comment_count: float, missing_dsyms: list<string>, release_stages: list<string>, grouping_reason: string, grouping_fields: record, discarded: bool, introduced_in_releases: table<release_stage: string, release_id: string, build_label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)")
  let body = {severity: $severity, operation: $operation, assigned_collaborator_id: $assigned_collaborator_id, assigned_team_id: $assigned_team_id, issue_url: $issue_url, verify_issue_url: $verify_issue_url, issue_title: $issue_title, notification_id: $notification_id, reopen_rules: $reopen_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Error
#
# DELETE /projects/{project_id}/errors/{error_id}
# operationId: deleteErrorOnProject
export def "projects-errors delete-by-project_id-error_id" [
  project_id: string
  error_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View an Event
#
# GET /projects/{project_id}/events/{event_id}
# operationId: viewEventById
export def "projects-events viewEventById" [
  project_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, project_url: string, is_full_report: bool, error_id: string, received_at: string, exceptions: table<errorClass: string, message: string, type: string, stacktrace: list, registers: list>, threads: table<id: float, name: string, type: string, stacktrace: list, error_reporting_thread: bool, state: string>, metaData: record, request: record<url: string, clientIp: string, httpMethod: string, referer: string, headers: record, params: record>, app: record<id: string, version: string, versionCode: float, bundleVersion: string, codeBundleId: string, buildUUID: string, releaseStage: string, type: string, dsymUUIDs: list<string>, duration: float, durationInForeground: float, inForeground: bool, isLaunching: bool, binaryArch: string, runningOnRosetta: bool>, device: record<id: string, hostname: string, manufacturer: string, model: string, modelNumber: string, osName: string, osVersion: string, freeMemory: float, totalMemory: float, freeDisk: float, browserName: string, browserVersion: string, jailbroken: bool, orientation: string, locale: string, charging: bool, batteryLevel: float, time: string, timezone: string, cpuAbi: list<string>, runtimeVersions: record, macCatalystIosVersion: string>, user: record<id: string, name: string, email: string>, breadcrumbs: table<name: string, type: string, timestamp: string, metaData: record>, context: string, severity: string, unhandled: bool, missing_dsym: bool, correlation: record<traceId: string, spanId: string>, feature_flags: table<feature_flag_name: string, feature_flag_id: string, variant_name: string, variant_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Event
#
# DELETE /projects/{project_id}/events/{event_id}
# operationId: deleteEventById
export def "projects-events delete" [
  project_id: string
  event_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Events on an Error
#
# GET /projects/{project_id}/errors/{error_id}/events
# operationId: listEventsOnError
export def "projects-errors-events listEventsOnError" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-base: string # format: date-time, e.g. 2017-04-12T22:50:04Z
  --qp-sort: string@sort-completer-3 # default: timestamp
  --direction: string@direction-completer # default: desc
  --per-page: float # default: 30
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --full-reports: oneof<nothing, bool> # default: false
]: nothing -> table<id: string, is_full_report: bool, url: string, project_url: string, error_id: string, received_at: string, exceptions: list<record>, error_class: string, message: string, severity: string, unhandled: bool, context: string, app: record<releaseStage: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "full_reports" $full_reports "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the latest Event on an Error
#
# GET /errors/{error_id}/latest_event
# operationId: viewLatestEventOnError
export def "errors-latest-event viewLatestEventOnError" [
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, project_url: string, is_full_report: bool, error_id: string, received_at: string, exceptions: table<errorClass: string, message: string, type: string, stacktrace: list, registers: list>, threads: table<id: float, name: string, type: string, stacktrace: list, error_reporting_thread: bool, state: string>, metaData: record, request: record<url: string, clientIp: string, httpMethod: string, referer: string, headers: record, params: record>, app: record<id: string, version: string, versionCode: float, bundleVersion: string, codeBundleId: string, buildUUID: string, releaseStage: string, type: string, dsymUUIDs: list<string>, duration: float, durationInForeground: float, inForeground: bool, isLaunching: bool, binaryArch: string, runningOnRosetta: bool>, device: record<id: string, hostname: string, manufacturer: string, model: string, modelNumber: string, osName: string, osVersion: string, freeMemory: float, totalMemory: float, freeDisk: float, browserName: string, browserVersion: string, jailbroken: bool, orientation: string, locale: string, charging: bool, batteryLevel: float, time: string, timezone: string, cpuAbi: list<string>, runtimeVersions: record, macCatalystIosVersion: string>, user: record<id: string, name: string, email: string>, breadcrumbs: table<name: string, type: string, timestamp: string, metaData: record>, context: string, severity: string, unhandled: bool, missing_dsym: bool, correlation: record<traceId: string, spanId: string>, feature_flags: table<feature_flag_name: string, feature_flag_id: string, variant_name: string, variant_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/errors/($error_id)/latest_event")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Events on a Project
#
# GET /projects/{project_id}/events
# operationId: listEventsOnProject
export def "projects-events listEventsOnProject" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-base: string # format: date-time, e.g. 2017-04-12T22:50:04Z
  --qp-sort: string@sort-completer-3 # default: timestamp
  --direction: string@direction-completer # default: desc
  --per-page: float # default: 30
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --full-reports: oneof<nothing, bool> # default: false
]: nothing -> table<id: string, is_full_report: bool, url: string, project_url: string, error_id: string, received_at: string, exceptions: list<record>, error_class: string, message: string, severity: string, unhandled: bool, context: string, app: record<releaseStage: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "full_reports" $full_reports "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Trends for an Error
#
# GET /projects/{project_id}/errors/{error_id}/trends
# operationId: getBucketedAndUnbucketedTrendsOnError
export def "projects-errors-trends get" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer # Search filters to restrict the events reported in the trend
  --buckets-count: float # Number of buckets to group trend data into (max 50)
  --resolution: string@resolution-completer # The trend data will be grouped so that each bucket spans the given time period
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "buckets_count" $buckets_count "scalar") (serialize-qp "resolution" $resolution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)/trends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Trends for a Project
#
# GET /projects/{project_id}/trends
# operationId: getBucketedAndUnbucketedTrendsOnProject
export def "projects-trends get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # Search filters to restrict the events reported in the trend
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --buckets-count: float # Number of buckets to group trend data into (max 50)
  --resolution: string@resolution-completer # The trend data will be grouped so that each bucket spans the given time period
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "buckets_count" $buckets_count "scalar") (serialize-qp "resolution" $resolution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/trends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Pivots on an Error
#
# GET /projects/{project_id}/errors/{error_id}/pivots
# operationId: listPivotsOnAnError
export def "projects-errors-pivots listPivotsOnAnError" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --summary-size: float # e.g. 10
  --pivots: list
  --per-page: float # default: 30, e.g. 30
]: nothing -> table<event_field_display_id: string, name: string, cardinality: float, summary: any, list: list<record>, no_value: float, other: float, average: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "summary_size" $summary_size "scalar") (serialize-qp "pivots" $pivots "multi") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)/pivots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List values of a Pivot on an Error
#
# GET /projects/{project_id}/errors/{error_id}/pivots/{event_field_display_id}/values
# operationId: getPivotValuesOnAnError
export def "projects-errors-pivots-values get" [
  project_id: string
  error_id: string
  event_field_display_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --qp-sort: string@sort-completer-4 # e.g. unsorted
  --qp-base: string # format: date-time, e.g. 2017-04-12T22:50:04Z
  --per-page: float # default: 30, e.g. 30
]: nothing -> table<event_field_value: string, events: float, proportion: float, first_seen: string, last_seen: string, fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "base" $qp_base "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)/pivots/($event_field_display_id)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Pivots on a Project
#
# GET /projects/{project_id}/pivots
# operationId: getPivotsOnAProject
export def "projects-pivots get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --summary-size: float # e.g. 10
  --pivots: list
]: nothing -> table<event_field_display_id: string, name: string, cardinality: float, summary: any, list: list<record>, no_value: float, other: float, average: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "summary_size" $summary_size "scalar") (serialize-qp "pivots" $pivots "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/pivots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List values of a Pivot on a Project
#
# GET /projects/{project_id}/pivots/{event_field_display_id}/values
# operationId: getPivotValuesOnAProject
export def "projects-pivots-values get" [
  project_id: string
  event_field_display_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record
  --filter-groups: record
  --filter-groups-join: string@filter-groups-join-completer
  --qp-sort: string@sort-completer-4 # e.g. unsorted
  --qp-base: string # format: date-time, e.g. 2017-04-12T22:50:04Z
  --per-page: float # default: 30, e.g. 30
]: nothing -> table<event_field_value: string, events: float, proportion: float, first_seen: string, last_seen: string, fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "filter_groups" $filter_groups "multi") (serialize-qp "filter_groups_join" $filter_groups_join "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "base" $qp_base "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/pivots/($event_field_display_id)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Comment
#
# PATCH /comments/{comment_id}
# operationId: updateComment
export def "comments updateComment" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The updated content of the Comment (e.g. Updated comment)
]: any -> record<id: string, created_at: string, updated_at: string, message: string, url: string, collaborator: record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, favorite_project_ids: list<string>, managed_by_smartbear_id: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($comment_id)")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Comment
#
# DELETE /comments/{comment_id}
# operationId: deleteComment
export def "comments delete" [
  comment_id: string
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
  let full_url = (build-url $base $"/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Comments on an Error
#
# GET /projects/{project_id}/errors/{error_id}/comments
# operationId: listCommentsOnError
export def "projects-errors-comments listCommentsOnError" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Comments are only sortable by creation time (e.g. created_at)
  --direction: string@direction-completer # Which direction to sort the results by (default: desc)
  --per-page: float # How many results to return per page (default: 30)
  --offset: float # The pagination offset. This will not typically need to be set manually, as the `link` header will contain the full url to the next page of results. (default: 0, e.g. 0)
]: nothing -> table<id: string, created_at: string, updated_at: string, message: string, url: string, collaborator: record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, favorite_project_ids: list, managed_by_smartbear_id: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Comment on an Error
#
# POST /projects/{project_id}/errors/{error_id}/comments
# operationId: createCommentOnError
export def "projects-errors-comments createCommentOnError" [
  project_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string
]: any -> record<id: string, created_at: string, updated_at: string, message: string, url: string, collaborator: record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, favorite_project_ids: list<string>, managed_by_smartbear_id: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/errors/($error_id)/comments")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the supported Integrations
#
# GET /integrations
# operationId: getIntegrations
export def "integrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, url: string, type: string, two_way_sync: bool, description: string, actions: record<create: string, view: string, object: string, new: string>, fields: list<record>, icon_url: string, created_entity_name: string, issue_automation_options: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test an Integration
#
# POST /integrations/test
# operationId: integrationsTest
# --configuration shape: {user_name?: string, project_id?: string, password?: string}
export def "integrations-test integrationsTest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The key of the integration service to test. The supported keys can be obtained from [/integrations](https://developer.smartbear.com/bugsnag/docs/bugsnag-data-access-api#/Integrations/getIntegrations) (e.g. jira)
  configuration: record # shape: {user_name?: string, project_id?: string, password?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/test")
  let body = {key: $key, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Configured Integration
#
# GET /configured_integrations/{id}
# operationId: configuredIntegrations
export def "configured-integrations configuredIntegrations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, integration_key: string, project_id: string, configuration: record<user_name: string, project_id: string, password: string>, description: string, disable_release_stages: list<string>, disable_severities: list<string>, disable_unhandled_states: list<string>, issue_automation: record<automation_style_type: string, error_fixed: record<active: bool, state: string, states: list>, error_reopened: record<active: bool, state: string, states: list>, issue_resolved: record<active: bool, state: string, states: list>, issue_unresolved: record<active: bool, state: string, states: list>>, last_failure_message: string, total_rate_limits: float, last_successful_usage_at: string, status: string, additional_setup_required: string, label: string, integration_connection_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/configured_integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Configured Integration
#
# PATCH /configured_integrations/{id}
# operationId: configuredIntegrationsUpdate
# --configuration shape: {user_name?: string, project_id?: string, password?: string}
# --issue_automation shape: {automation_style_type?: string, error_fixed?: record, error_reopened?: record, issue_resolved?: record, issue_unresolved?: record}
export def "configured-integrations configuredIntegrationsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  configuration: record # shape: {user_name?: string, project_id?: string, password?: string}
  --disable-release-stages: list # The release stages that this notification should not be triggered for. Example: { "disable_release_stages": ["development", "staging"] }
  --disable-severities: list # The severities that this notification should not be triggered for.
  --disable-unhandled-states: list # The kinds of exceptions that this notification should not be triggered for.
  --issue-automation: record # shape: {automation_style_type?: string, error_fixed?: record, error_reopened?: record, issue_resolved?: record, issue_unresolved?: record}
  --label: string # A label for use in identifying the issue tracker. (nullable, e.g. My Issue Tracker)
  --integration-connection-id: string # The id of the integration connection to base this configured integration off of. (e.g. 515fb9337c1074f6fd000007)
]: any -> record<id: string, integration_key: string, project_id: string, configuration: record<user_name: string, project_id: string, password: string>, description: string, disable_release_stages: list<string>, disable_severities: list<string>, disable_unhandled_states: list<string>, issue_automation: record<automation_style_type: string, error_fixed: record<active: bool, state: string, states: list>, error_reopened: record<active: bool, state: string, states: list>, issue_resolved: record<active: bool, state: string, states: list>, issue_unresolved: record<active: bool, state: string, states: list>>, last_failure_message: string, total_rate_limits: float, last_successful_usage_at: string, status: string, additional_setup_required: string, label: string, integration_connection_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/configured_integrations/($id)")
  let body = {configuration: $configuration, disable_release_stages: $disable_release_stages, disable_severities: $disable_severities, disable_unhandled_states: $disable_unhandled_states, issue_automation: $issue_automation, label: $label, integration_connection_id: $integration_connection_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Configured Integration
#
# DELETE /configured_integrations/{id}
# operationId: configuredIntegrationsDelete
export def "configured-integrations configuredIntegrationsDelete" [
  id: string
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
  let full_url = (build-url $base $"/configured_integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Configured Integration's Trigger Config
#
# PATCH /configured_integrations/{id}/trigger_configs/{trigger_config_key}
# operationId: updateConfiguredIntegrationsTriggerConfig
# --settings item shape: {saved_search_id?: string, basic_filter?: record, include_all_states?: bool, release_stages?: list, threshold?: float, condition?: "always"|"when_degraded", period?: string}
export def "configured-integrations-trigger-configs updateConfiguredIntegrationsTriggerConfig" [
  id: string
  trigger_config_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # e.g. true
  --settings: list # settings for the trigger — item shape: {saved_search_id?: string, basic_filter?: record, include_all_states?: bool, release_stages?: list, threshold?: float, condition?: "always"|"when_degraded", period?: string}
]: any -> record<active: bool, settings: table<saved_search_id: string, basic_filter: record, include_all_states: bool, release_stages: list, threshold: float, condition: string, period: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/configured_integrations/($id)/trigger_configs/($trigger_config_key)")
  let body = {active: $active, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Test a Configured Integration
#
# POST /configured_integrations/{id}/test
# operationId: configuredIntegrationTest
export def "configured-integrations-test configuredIntegrationTest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --component: string # Comma separated list of components to create the issue in (e.g. Ticket, Action)
  --customFields: string # Additional JSON-encoded Jira fields (e.g. {"customfield_10024": {"value": "Engineering"}})
  --host: string # URL of your Jira instance (e.g. https://example.atlassian.net)
  --ignore-tls-validation: oneof<nothing, bool> # Whether to ignore TLS validation when making API calls (e.g. false)
  --issueType: string # The type of issue to be created (e.g. Task)
  --password: string # API token generated for your Jira account (use your password for Jira Server) (e.g. e112Fq0cc5)
  --project-key: string # The project key for the Jira project (e.g. jira)
  --user-name: string # Your Jira email (e.g. example@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/configured_integrations/($id)/test")
  let body = {component: $component, customFields: $customFields, host: $host, ignore_tls_validation: $ignore_tls_validation, issueType: $issueType, password: $password, project_key: $project_key, user_name: $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure an Integration
#
# POST /projects/{project_id}/configured_integrations
# operationId: projectConfiguredIntegrations
# --configuration shape: {user_name?: string, project_id?: string, password?: string}
# --issue_automation shape: {automation_style_type?: string, error_fixed?: record, error_reopened?: record, issue_resolved?: record, issue_unresolved?: record}
export def "projects-configured-integrations projectConfiguredIntegrations" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  integration_key: string # Key to identify the integration service. (e.g. jira)
  configuration: record # shape: {user_name?: string, project_id?: string, password?: string}
  --disable-release-stages: list # The release stages that this notification should not be triggered for. Example: { "disable_release_stages": ["development", "staging"] }
  --disable-severities: list # The severities that this notification should not be triggered for.
  --disable-unhandled-states: list # The kinds of exceptions that this notification should not be triggered for.
  --issue-automation: record # shape: {automation_style_type?: string, error_fixed?: record, error_reopened?: record, issue_resolved?: record, issue_unresolved?: record}
  --label: string # A label for use in identifying the issue tracker. (nullable, e.g. My Issue Tracker)
  --integration-connection-id: string # The id of the integration connection to base this configured integration off of. (e.g. 515fb9337c1074f6fd000007)
]: any -> record<id: string, integration_key: string, project_id: string, configuration: record<user_name: string, project_id: string, password: string>, description: string, disable_release_stages: list<string>, disable_severities: list<string>, disable_unhandled_states: list<string>, issue_automation: record<automation_style_type: string, error_fixed: record<active: bool, state: string, states: list>, error_reopened: record<active: bool, state: string, states: list>, issue_resolved: record<active: bool, state: string, states: list>, issue_unresolved: record<active: bool, state: string, states: list>>, last_failure_message: string, total_rate_limits: float, last_successful_usage_at: string, status: string, additional_setup_required: string, label: string, integration_connection_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/configured_integrations")
  let body = {integration_key: $integration_key, configuration: $configuration, disable_release_stages: $disable_release_stages, disable_severities: $disable_severities, disable_unhandled_states: $disable_unhandled_states, issue_automation: $issue_automation, label: $label, integration_connection_id: $integration_connection_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Summaries of the Configured Integrations for a Project
#
# GET /projects/{project_id}/configured_integration_summaries
# operationId: projectConfiguredIntegrationSummaries
export def "projects-configured-integration-summaries projectConfiguredIntegrationSummaries" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float
  --page-token: float
  --category: string # e.g. issue-tracker
]: nothing -> table<notification_id: string, description: string, project_identifier: string, integration_key: string, category: string, enabled_trigger_count: float, status: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/configured_integration_summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Integration Connections for an Organization
#
# GET /organizations/{organization_id}/integration_connections
# operationId: listOrganizationIntegrationConnections
export def "organizations-integration-connections listOrganizationIntegrationConnections" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The external software to communicate with. Currently this can only be 'jira' or nil.
]: nothing -> table<id: string, organization_id: string, external_identifier: string, type: string, configuration_type: string, configuration: record<jira: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/integration_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Organization
#
# POST /organizations
# operationId: createOrganization
export def "organizations createOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the company or organization to create (e.g. Acme Co.)
]: any -> record<name: string, billing_emails: list<string>, auto_upgrade: bool, id: string, slug: string, api_key: string, creator: record<email: string, id: string, name: string>, collaborators_url: string, projects_url: string, created_at: string, updated_at: string, upgrade_url: string, managed_by_platform_services: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View an Organization
#
# GET /organizations/{id}
# operationId: getOrganizationById
export def "organizations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, billing_emails: list<string>, auto_upgrade: bool, id: string, slug: string, api_key: string, creator: record<email: string, id: string, name: string>, collaborators_url: string, projects_url: string, created_at: string, updated_at: string, upgrade_url: string, managed_by_platform_services: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Organization
#
# PATCH /organizations/{id}
# operationId: updateOrganizationById
export def "organizations updateOrganizationById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # e.g. Acme Co.
  --billing-emails: list # e.g. [emily@example.com]
  --auto-upgrade: oneof<nothing, bool> # whether we should upgrade your plan in response to the organization reaching its plan limit of events. If this value is `false` your events will be throttled when you reach your plan limit. (e.g. true)
  --invoice-address: string # Additional information to print on your invoice (e.g. Vendor ID number 4567)
  --invoice-info: string # Deprecated field. Use `invoice_address` (e.g. Vendor ID number 4567)
]: any -> record<name: string, billing_emails: list<string>, auto_upgrade: bool, id: string, slug: string, api_key: string, creator: record<email: string, id: string, name: string>, collaborators_url: string, projects_url: string, created_at: string, updated_at: string, upgrade_url: string, managed_by_platform_services: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let body = {name: $name, billing_emails: $billing_emails, auto_upgrade: $auto_upgrade, invoice_address: $invoice_address, invoice_info: $invoice_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Organization
#
# DELETE /organizations/{id}
# operationId: deleteOrganization
export def "organizations delete" [
  id: string
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
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate an Organization's API key
#
# DELETE /organizations/{id}/api_key
# operationId: revokeOrganizationApiKey
export def "organizations-api-key revokeOrganizationApiKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, billing_emails: list<string>, auto_upgrade: bool, id: string, slug: string, api_key: string, creator: record<email: string, id: string, name: string>, collaborators_url: string, projects_url: string, created_at: string, updated_at: string, upgrade_url: string, managed_by_platform_services: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate an Organization's auth token
#
# DELETE /organizations/{id}/auth_token
# operationId: revokeOrganizationAuthToken
export def "organizations-auth-token revokeOrganizationAuthToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, billing_emails: list<string>, auto_upgrade: bool, id: string, slug: string, api_key: string, creator: record<email: string, id: string, name: string>, collaborators_url: string, projects_url: string, created_at: string, updated_at: string, upgrade_url: string, managed_by_platform_services: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/auth_token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all collaborators that are members of your organization
#
# GET /organizations/{organization_id}/collaborators
# operationId: listOrganizationCollaborators
export def "organizations-collaborators listOrganizationCollaborators" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # Number of results per page (default: 30)
  --q: string # Search collaborators with names or emails matching parameter
]: nothing -> table<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite a collaborator to your organization
#
# POST /organizations/{organization_id}/collaborators
# operationId: inviteOrganizationCollaborator
export def "organizations-collaborators inviteOrganizationCollaborator" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the person to invite
  --name: string # A name for the invited user
  --password: string # A password for the invited user
  --project-ids: list # The ids of projects in the current organization that the invited user should have access to.
  --project-roles: record # The IDs of the projects to which the user should have access, and the roles they should have, either 'project_owner' or 'project_member'.
  --admin: oneof<nothing, bool> # Whether to give admin permissions to the invited user.
]: any -> record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators")
  let body = {email: $email, name: $name, password: $password, project_ids: $project_ids, project_roles: $project_roles, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show a Collaborator on an Organization
#
# GET /organizations/{organization_id}/collaborators/{id}
# operationId: getOrganizationCollaborator
export def "organizations-collaborators get" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Collaborator's permissions
#
# PATCH /organizations/{organization_id}/collaborators/{id}
# operationId: updateOrganizationCollaborator
export def "organizations-collaborators updateOrganizationCollaborator" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-ids: list # The ids of projects in the current organization that the invited user should have access to.
  --project-roles: record # The IDs of the projects to which the user should have access, and the roles they should have, either 'project_owner' or 'project_member'.
  --admin: oneof<nothing, bool> # Whether to give admin permissions to the user.
]: any -> record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)")
  let body = {project_ids: $project_ids, project_roles: $project_roles, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Collaborator
#
# DELETE /organizations/{organization_id}/collaborators/{id}
# operationId: deleteOrganizationCollaborator
export def "organizations-collaborators delete" [
  organization_id: string
  id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk invite collaborators to your organization
#
# POST /organizations/{organization_id}/collaborators/bulk_invite
# operationId: bulkInviteOrganizationCollaborators
export def "organizations-collaborators-bulk-invite bulkInviteOrganizationCollaborators" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emails: list # A list of emails to invite
  --project-ids: list # The ids of projects in the current organization that the invited user should have access to. Leave blank if the admin field is set to true. Admins have access to all projects. Only one of project_roles and project_ids may be supplied.
  --project-roles: record # The IDs of the projects to which the user should have access, and the roles they should have, either 'project_owner' or 'project_member'. Leave blank if the admin field is set to true. Admins have access to all projects. Only one of project_roles and project_ids may be supplied. This field may only be supplied if the enterprise-roles feature is enabled for the account.
  --admin: oneof<nothing, bool> # Whether to give admin permissions to the invited user(s).
]: any -> table<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/bulk_invite")
  let body = {emails: $emails, project_ids: $project_ids, project_roles: $project_roles, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Collaborators on a Project
#
# GET /projects/{project_id}/collaborators
# operationId: listProjectCollaborators
export def "projects-collaborators listProjectCollaborators" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # Number of results per page (default: 30)
]: nothing -> table<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a collaborator in a project.
#
# GET /projects/{project_id}/collaborators/{id}
# operationId: getProjectCollaborator
export def "projects-collaborators get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/collaborators/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the project count of a collaborator
#
# GET /organizations/{organization_id}/collaborators/project_access_counts
# operationId: getOrganizationCollaboratorProjectAccessCounts
export def "organizations-collaborators-project-access-counts get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collaborator-ids: list # IDs of collaborators to view the project count of
]: nothing -> table<collaborator_id: string, project_count: float, is_admin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collaborator_ids" $collaborator_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/project_access_counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Projects a Collaborator has access to
#
# GET /organizations/{organization_id}/collaborators/{collaborator_id}/projects
# operationId: getOrganizationCollaboratorProjects
export def "organizations-collaborators-projects get" [
  organization_id: string
  collaborator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search projects with names matching parameter
  --qp-sort: string@sort-completer-5 # Which field to sort the results by (default: created_at)
  --direction: string@direction-completer # Which direction to sort the results by (default: desc)
  --per-page: float # How many results to return per page (default: 30)
]: nothing -> table<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($collaborator_id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project accesses for a collaborator
#
# GET /organizations/{organization_id}/collaborators/{collaborator_id}/project_accesses
# operationId: listOrganizationCollaboratorProjectAccesses
export def "organizations-collaborators-project-accesses listOrganizationCollaboratorProjectAccesses" [
  organization_id: string
  collaborator_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # Number of results per page (default: 30)
]: nothing -> table<team: list<record>, collaborators: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($collaborator_id)/project_accesses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a Collaborator's Access Details for a Project
#
# GET /organizations/{organization_id}/collaborators/{collaborator_id}/project_accesses/{project_id}
# operationId: getOrganizationCollaboratorProjectAccessById
export def "organizations-collaborators-project-accesses get" [
  organization_id: string
  collaborator_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_summary: record<id: string, name: string, type: string, slug: string>, team_count: float, is_admin: bool, project_role: string, individual_project_role: string, team_project_role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($collaborator_id)/project_accesses/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a collaborator to a group of Teams
#
# POST /organizations/{organization_id}/collaborators/{id}/team_memberships
# operationId: addOrganizationCollaboratorTeamMemberships
export def "organizations-collaborators-team-memberships addOrganizationCollaboratorTeamMemberships" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-ids: list # IDs of the teams to assign the collaborator to. This variable is optional, but required if add_all_teams is false
  --add-all-teams: oneof<nothing, bool> # Whether to assign the collaborator to all teams in the organization
]: any -> record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)/team_memberships")
  let body = {team_ids: $team_ids, add_all_teams: $add_all_teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Collaborator from a group of Teams
#
# DELETE /organizations/{organization_id}/collaborators/{id}/team_memberships
# operationId: deleteOrganizationCollaboratorTeamMemberships
export def "organizations-collaborators-team-memberships delete" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)/team_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Teams from a query
#
# GET /organizations/{organization_id}/teams
# operationId: listOrganizationTeams
export def "organizations-teams listOrganizationTeams" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A partial or full team name to filter the results by.
  --per-page: float # default: 30, e.g. 10
  --offset: string # Token to retrieve next page of results
]: nothing -> table<id: string, name: string, collaborator_count: float, project_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Team
#
# POST /organizations/{organization_id}/teams
# operationId: createOrganizationTeam
export def "organizations-teams createOrganizationTeam" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, name: string, collaborator_count: float, project_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show the details of a team
#
# GET /organizations/{organization_id}/teams/{id}
# operationId: getOrganizationTeam
export def "organizations-teams get" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, collaborator_count: float, project_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a team name
#
# PATCH /organizations/{organization_id}/teams/{id}
# operationId: updateOrganizationTeam
export def "organizations-teams updateOrganizationTeam" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, name: string, collaborator_count: float, project_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a team
#
# DELETE /organizations/{organization_id}/teams/{id}
# operationId: deleteOrganizationTeam
export def "organizations-teams delete" [
  organization_id: string
  id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Suggested Collaborators to Add to a Team
#
# GET /organizations/{organization_id}/teams/{id}/suggested_collaborators
# operationId: listOrganizationTeamSuggestedCollaborators
export def "organizations-teams-suggested-collaborators listOrganizationTeamSuggestedCollaborators" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A partial or full user name or email to filter the results by.
  --include-has-access: oneof<nothing, bool> # Request all collaborators in the organization, including those that are not members of the team. By default only collaborators who are not members of the team will be returned.
  --per-page: float # default: 30, e.g. 10
  --offset: string # token to retrieve next page of results
]: nothing -> table<id: string, name: string, email: string, has_access: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "include_has_access" $include_has_access "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/suggested_collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Teams for a Collaborator
#
# GET /organizations/{organization_id}/collaborators/{id}/teams
# operationId: listOrganizationCollaboratorTeams
export def "organizations-collaborators-teams listOrganizationCollaboratorTeams" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A partial or full team name to filter the results by
  --per-page: float # default: 30, e.g. 10
  --offset: string # token to retrieve next page of results
]: nothing -> table<id: string, name: string, collaborator_count: float, project_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Suggested Teams for a Collaborator
#
# GET /organizations/{organization_id}/collaborators/{id}/suggested_teams
# operationId: listOrganizationCollaboratorSuggestedTeams
export def "organizations-collaborators-suggested-teams listOrganizationCollaboratorSuggestedTeams" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A partial or full team name to filter the results by
  --include-is-member: oneof<nothing, bool> # Request all teams in the organization, including those that the collaborator is already on. By default only teams the collaborator is not a member of will be returned
  --per-page: float # default: 30, e.g. 10
  --offset: string # token to retrieve next page of results
]: nothing -> table<project_id: string, project_name: string, is_member: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "include_is_member" $include_is_member "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/collaborators/($id)/suggested_teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Collaborators in a Team
#
# GET /organizations/{organization_id}/teams/{id}/collaborators
# operationId: listOrganizationTeamCollaborators
export def "organizations-teams-collaborators listOrganizationTeamCollaborators" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A partial or full user name or email to filter the results by.
  --per-page: float # default: 30, e.g. 10
  --offset: string # token to retrieve next page of results
]: nothing -> table<id: string, name: string, email: string, two_factor_enabled: bool, two_factor_enabled_on: string, recovery_codes_remaining: float, password_updated_on: string, show_time_in_utc: bool, heroku: bool, created_at: string, is_admin: bool, pending_invitation: bool, last_request_at: string, project_ids: list<string>, paid_for: bool, project_roles: record<515fb9337c1074f6fd000001: string>, managed_by_smartbear_id: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Collaborators to a Team
#
# POST /organizations/{organization_id}/teams/{id}/team_memberships
# operationId: addOrganizationTeamMemberships
export def "organizations-teams-team-memberships addOrganizationTeamMemberships" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collaborator-ids: list # Collaborators to add to the team.
  --add-all-collaborators: oneof<nothing, bool> # Add all organization collaborators to the team. This should not be set if `collaborator_ids` is specified.
]: any -> record<id: string, name: string, collaborator_count: float, project_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/team_memberships")
  let body = {collaborator_ids: $collaborator_ids, add_all_collaborators: $add_all_collaborators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Collaborators from a Team
#
# DELETE /organizations/{organization_id}/teams/{id}/team_memberships
# operationId: deleteOrganizationTeamMemberships
export def "organizations-teams-team-memberships delete" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, collaborator_count: float, project_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/team_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Access for a Team
#
# GET /organizations/{organization_id}/teams/{id}/project_accesses
# operationId: listOrganizationTeamProjectAccesses
export def "organizations-teams-project-accesses listOrganizationTeamProjectAccesses" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A partial or full project name to filter the results by.
  --per-page: float # default: 30, e.g. 10
  --offset: string # A token for pagination
]: nothing -> table<project_summary: record<id: string, name: string, type: string, slug: string>, project_role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/project_accesses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Project Access to a Team
#
# PATCH /organizations/{organization_id}/teams/{id}/project_accesses
# operationId: updateOrganizationTeamProjectAccesses
# --project_roles shape: {515fb9337c1074f6fd000002: "project_owner"|"project_member"}
export def "organizations-teams-project-accesses updateOrganizationTeamProjectAccesses" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-all-projects: oneof<nothing, bool> # Whether to add all remaining projects to the team. If `true`, `project_role` must also be supplied. User making the request must be an organization administrator if using `true`. (e.g. true)
  --project-role: string@project-role-completer
  --project-roles: record # A map of project IDs to the roles to be assigned to them. Must be `project_owner` unless the organization has access to the `enterprise-roles` feature. Cannot be supplied if `add_all_projects` is `true`. — shape: {515fb9337c1074f6fd000002: "project_owner"|"project_member"}
]: any -> table<id: string, name: string, collaborator_count: float, project_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/project_accesses")
  let body = {add_all_projects: $add_all_projects, project_role: $project_role, project_roles: $project_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Project Access from a Team
#
# DELETE /organizations/{organization_id}/teams/{id}/project_accesses
# operationId: deleteOrganizationTeamProjectAccesses
export def "organizations-teams-project-accesses delete" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, collaborator_count: float, project_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/project_accesses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suggest Projects to Add to a Team
#
# GET /organizations/{organization_id}/teams/{id}/suggested_projects
# operationId: listOrganizationTeamSuggestedProjects
export def "organizations-teams-suggested-projects listOrganizationTeamSuggestedProjects" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-has-access: oneof<nothing, bool> # should projects the team already has access to be included?
  --q: string # A partial or full project name to filter the results by.
  --per-page: float # default: 30, e.g. 10
  --offset: string # token to retrieve next page of results
]: nothing -> table<project_id: string, project_name: string, type: string, has_access: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_has_access" $include_has_access "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/teams/($id)/suggested_projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an event data request
#
# POST /organizations/{organization_id}/event_data_requests
# operationId: organizationEventDataRequests
# --filters shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
export def "organizations-event-data-requests organizationEventDataRequests" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # only include event fields that pertain to the user such as event.user, event.device, and event.request; you may need to remove/redact some fields before giving this data to your users that request it
  filters: record # shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
  --filter-groups: record # A map of filter groups, where each group is keyed with a unique identifier for the group e.g: ``` {  "0": { ... },  "1": { ... } } ``` See the [Advanced Filters documentation](https://developer.smartbear.com/bugsnag/docs/data-access-filtering#advanced-filters) for more details.
  --filter-groups-join: string@filter-groups-join-completer # The join operator to apply between filter groups. - and - All conditions must be satisfied - or (default) - At least one condition must be satisfied
]: any -> record<id: string, url: string, status: string, total: float, report_type: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/event_data_requests")
  let body = {report_type: $report_type, filters: $filters, filter_groups: $filter_groups, filter_groups_join: $filter_groups_join} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check the status of an event data request
#
# GET /organizations/{organization_id}/event_data_requests/{id}
# operationId: organizationEventDataRequestsById
export def "organizations-event-data-requests organizationEventDataRequestsById" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, status: string, total: float, report_type: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/event_data_requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an event deletion request
#
# POST /organizations/{organization_id}/event_data_deletions
# operationId: organizationEventDataDeletions
# --filters shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
export def "organizations-event-data-deletions organizationEventDataDeletions" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-confirmation: oneof<nothing, bool> # whether to skip requiring another request to confirm the deletion (default: false)
  filters: record # shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
  --filter-groups: record # A map of filter groups, where each group is keyed with a unique identifier for the group e.g: ``` {  "0": { ... },  "1": { ... } } ``` See the [Advanced Filters documentation](https://developer.smartbear.com/bugsnag/docs/data-access-filtering#advanced-filters) for more details.
  --filter-groups-join: string@filter-groups-join-completer # The join operator to apply between filter groups. - and - All conditions must be satisfied - or (default) - At least one condition must be satisfied
]: any -> record<id: string, status: string, total: float, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/event_data_deletions")
  let body = {skip_confirmation: $skip_confirmation, filters: $filters, filter_groups: $filter_groups, filter_groups_join: $filter_groups_join} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Confirm an event deletion request
#
# POST /organizations/{organization_id}/event_data_deletions/{id}/confirm
# operationId: organizationEventDataDeletionsConfirm
export def "organizations-event-data-deletions-confirm organizationEventDataDeletionsConfirm" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, total: float, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/event_data_deletions/($id)/confirm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the status of an event deletion request
#
# GET /organizations/{organization_id}/event_data_deletions/{id}
# operationId: organizationEventDataDeletionsById
export def "organizations-event-data-deletions organizationEventDataDeletionsById" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, total: float, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/event_data_deletions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Collaborators on an Organization
#
# GET /organizations/{organization_id}/scim/v2/Users
# operationId: listScimCollaborators
export def "organizations-scim-users listScimCollaborators" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # filter the results by userName (e.g. userName eq "james@example.com")
  --startIndex: float # the pagination offset, 1-indexed, defaults to 1 (e.g. 15)
  --itemsPerPage: float # the number of results returned in this response, defaults to 30, maximum of 100 (e.g. 10)
]: nothing -> record<startIndex: float, itemsPerPage: float, totalResults: float, Resources: table<id: string, userName: string, name: record, emails: list, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Collaborator
#
# POST /organizations/{organization_id}/scim/v2/Users
# operationId: createScimCollaborator
export def "organizations-scim-users createScimCollaborator" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, userName: string, name: record<formatted: string, givenName: string, familyName: string>, emails: table<value: string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a Collaborator on an Organization
#
# GET /organizations/{organization_id}/scim/v2/Users/{id}
# operationId: getScimCollaborator
export def "organizations-scim-users get" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, userName: string, name: record<formatted: string, givenName: string, familyName: string>, emails: table<value: string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Collaborator
#
# PUT /organizations/{organization_id}/scim/v2/Users/{id}
# operationId: updateScimCollaborator
# --name shape: {formatted?: string, givenName: string, familyName: string}
# --emails item shape: {value: string}
export def "organizations-scim-users updateScimCollaborator" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # e.g. 515fb9337c1074f6fd000007
  userName: string # e.g. james.smith@example.com
  name: record # shape: {formatted?: string, givenName: string, familyName: string}
  emails: list # item shape: {value: string}
  --active: oneof<nothing, bool> # Whether the user is part of the organization.
]: any -> record<id: string, userName: string, name: record<formatted: string, givenName: string, familyName: string>, emails: table<value: string>, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Users/($id)")
  let body = {id: $body_id, userName: $userName, name: $name, emails: $emails, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or Remove Previously Added Collaborators
#
# PATCH /organizations/{organization_id}/scim/v2/Users/{id}
# operationId: patchScimCollaborator
# --Operations item shape: {op: string, path: string, value: bool}
export def "organizations-scim-users patch" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Operations: list # item shape: {op: string, path: string, value: bool}
]: any -> record<id: string, userName: string, name: record<formatted: string, givenName: string, familyName: string>, emails: table<value: string>, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Users/($id)")
  let body = {Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Collaborator
#
# DELETE /organizations/{organization_id}/scim/v2/Users/{id}
# operationId: deleteScimCollaborator
export def "organizations-scim-users delete" [
  organization_id: string
  id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Groups on an Organization
#
# GET /organizations/{organization_id}/scim/v2/Groups
# operationId: listScimGroups
export def "organizations-scim-groups listScimGroups" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # filter the results by userName (e.g. userName eq "james@example.com")
  --startIndex: float # the pagination offset, 1-indexed, defaults to 1 (e.g. 15)
  --itemsPerPage: float # the number of results returned in this response, defaults to 30, maximum of 100 (e.g. 10)
]: nothing -> record<total_results: float, Resources: table<id: string, displayName: string, members: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "itemsPerPage" $itemsPerPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Group on an Organization
#
# POST /organizations/{organization_id}/scim/v2/Groups
# operationId: createScimGroup
export def "organizations-scim-groups createScimGroup" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayName: string # e.g. Development Group
]: any -> record<id: string, displayName: string, members: table<value: string, display: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Groups")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show Group on an Organization
#
# GET /organizations/{organization_id}/scim/v2/Groups/{id}
# operationId: getScimGroup
export def "organizations-scim-groups get" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, displayName: string, members: table<value: string, display: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Group on an Organization
#
# PATCH /organizations/{organization_id}/scim/v2/Groups/{id}
# operationId: updateScimGroup
# --value item shape: {value: string}
export def "organizations-scim-groups updateScimGroup" [
  organization_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  op: string@op-completer
  --path: string # the target to update. Optional for `add` or `replace` operations and required for `remove` operations. (e.g. members)
  value: list # if updating the group's name, provide an object with a `displayName` attribute instead — item shape: {value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Groups/($id)")
  let body = {op: $op, path: $path, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Group on an Organization
#
# DELETE /organizations/{organization_id}/scim/v2/Groups/{id}
# operationId: deleteScimGroup
export def "organizations-scim-groups delete" [
  organization_id: string
  id: string
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
  let full_url = (build-url $base $"/organizations/($organization_id)/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Spans for a Trace
#
# GET /organizations/{organization_id}/traces/{trace_id}/spans
# operationId: listOrganizationSpans
export def "organizations-traces-spans listOrganizationSpans" [
  organization_id: string
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Beginning of window to return spans from. (e.g. 2023-04-11T13:14:25.123Z)
  --qp-to: string # End of window to return spans from. (e.g. 2023-04-11T13:14:26.123Z)
  --target-span-id: string # The ID of a Span within the Trace to focus on. If provided the target Span and its direct children will be returned ahead of other Spans in the Trace. (e.g. 6368f07a518fa064ce036bdb)
  --per-page: float # The number of results to return per page. Defaults to 20. (e.g. 20)
]: nothing -> table<id: string, parent_span_id: string, trace_id: string, category: string, name: string, display_name: string, duration: float, timestamp: string, time_adjustment_type: string, start_time: string, is_first_class: bool, build_id: string, project_id: string, span_group_id: string, virtual_span_group_id: string, statistics: record<category_statistics: record, system_metric_statistics: record, rendering_statistics: record, http_statistics: record>, metadata: record<key: string, value: string, level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "target_span_id" $target_span_id "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/traces/($trace_id)/spans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a Project
#
# GET /projects/{project_id}
# operationId: getProject
export def "projects get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Project
#
# PATCH /projects/{project_id}
# operationId: updateProject
export def "projects updateProject" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # e.g. Example Project
  --global-grouping: list # A list of error classes. Events with these classes will be grouped by their class, regardless of the location that they occur in the Project's source code. Altering a Project's `global_grouping` will not cause existing errors to be regrouped.  Note: In the UI this is referred to as grouping by error class.  Example:  ``` ["foo", "bar"] ```
  --location-grouping: list # A list of error classes. Events with these classes will be grouped by their `context`. Altering a Project's `location_grouping` will not cause existing errors to be regrouped.  Note: In the UI this is referred to as grouping by error context.
  --discarded-app-versions: list # A list of app versions whose events will be [discarded](https://docs.bugsnag.com/product/event-usage/#discard-by-app-version) if received for the Project. Supports [regular expressions](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/RegExp#Special_characters_meaning_in_regular_expressions) and [semver ranges](https://github.com/npm/node-semver#ranges). Errors matching these versions won't be processed by Bugsnag, and you won't receive notifications about them.
  --discarded-errors: list # A list of Error classes whose events will be [discarded](https://docs.bugsnag.com/product/event-usage/#discard-by-error-class) if received for the Project. Errors with these classes won't be processed by Bugsnag, and you won't receive notifications about them.
  --url-whitelist: list # When configured, the script source of each error's innermost stack trace's top frame is checked. If the script was not served from a matching domain the error will not be processed by BugSnag and will be discarded.  Provide a list of newline separated domain names. To match example.com and its subdomains specify *.example.com.  Relevant to JavaScript Projects only.
  --ignore-old-browsers: oneof<nothing, bool> # Whether the Events in the Project will be ignored if they originate from old web browsers.  Relevant to JavaScript Projects only.  (e.g. true)
  --ignored-browser-versions: record # Relevant to JavaScript Projects only.  A mapping a of browser name to browser version. If set, Events in the Project will be ignored if they originate from a browser specified here whose version is earlier than the given version.  Keys must be one of the following strings: chrome, ie, firefox, safari, android, uc, opera, opera_mini, samsung, blackberry, sogou, other.  Values must be a number indicating which which version to ignore up to (but not including), or one of the strings: `ignore_all`, `ignore_none`  Example:  ``` { "chrome": "ignore_none", "safari": 6, "other": "ignore_all" } ```
  --resolve-on-deploy: oneof<nothing, bool> # If true, every error in the Project will be marked as 'fixed' after using the Deploy Tracking API to notify Bugsnag of a new production deploy.  Applies to non-JavaScript Projects only.  (e.g. true)
  --collaborator-ids: list # If provided in the request, the Project will be updated so that its set of Collaborators will reflect those indicated by this list of ids. Existing Collaborators whose ids do not appear in the list will be removed from the Project.
]: any -> record<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let body = {name: $name, global_grouping: $global_grouping, location_grouping: $location_grouping, discarded_app_versions: $discarded_app_versions, discarded_errors: $discarded_errors, url_whitelist: $url_whitelist, ignore_old_browsers: $ignore_old_browsers, ignored_browser_versions: $ignored_browser_versions, resolve_on_deploy: $resolve_on_deploy, collaborator_ids: $collaborator_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Project
#
# DELETE /projects/{project_id}
# operationId: deleteProject
export def "projects delete" [
  project_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate a Project's notifier API key
#
# DELETE /projects/{project_id}/api_key
# operationId: regenerateProjectApiKey
export def "projects-api-key regenerateProjectApiKey" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate a Project's upload API key
#
# DELETE /projects/{project_id}/upload_api_key
# operationId: regenerateProjectUploadApiKey
export def "projects-upload-api-key regenerateProjectUploadApiKey" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, global_grouping: list<any>, location_grouping: list<any>, discarded_app_versions: list<any>, discarded_errors: list<any>, url_whitelist: list<any>, ignore_old_browsers: bool, ignored_browser_versions: record, resolve_on_deploy: bool, id: string, organization_id: string, type: string, performance_display_type: string, slug: string, api_key: string, upload_api_key: string, must_use_upload_api_key: bool, is_full_view: bool, release_stages: list<any>, language: string, created_at: string, updated_at: string, url: string, html_url: string, errors_url: string, events_url: string, open_error_count: float, for_review_error_count: float, collaborators_count: float, teams_count: float, custom_event_fields_used: float, ecmascript_parse_version: record, stability_target_type: string, target_stability: record<value: float, updated_at: string, updated_by_id: string>, critical_stability: record<value: float, updated_at: string, updated_by_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/upload_api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Event Fields for a Project
#
# GET /projects/{project_id}/event_fields
# operationId: listProjectEventFields
export def "projects-event-fields listProjectEventFields" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<custom: bool, display_id: string, filter_options: record<name: string, description: string, aliases: list, hint_text: string, hint_url: string>, values: list<record>, match_types: list<string>, pivot_options: record<name: string, fields: list, summary: bool, values: bool, cardinality: bool, average: bool>, reindex_in_progress: bool, reindex_percentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a custom Event Field
#
# POST /projects/{project_id}/event_fields
# operationId: createProjectEventField
# --filter_options shape: {name?: string}
# --pivot_options shape: {name?: string, fields?: list, summary?: bool, values?: bool, cardinality?: bool, average?: bool}
export def "projects-event-fields createProjectEventField" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  path: string # [Path](https://docs.bugsnag.com/product/custom-filters/advanced-custom-filters/#custom-filter-path) to locate the relevant data inside an Event data structure (e.g. metaData.plan.tier)
  --reindex: oneof<nothing, bool> # Whether to reindex historical events for this field (e.g. false)
  filter_options: record # shape: {name?: string}
  --pivot-options: record # shape: {name?: string, fields?: list, summary?: bool, values?: bool, cardinality?: bool, average?: bool}
]: any -> record<custom: bool, display_id: string, filter_options: record<name: string, description: string, aliases: list<string>, hint_text: string, hint_url: string>, values: table<id: string, name: string>, match_types: list<string>, pivot_options: record<name: string, fields: list<record>, summary: bool, values: bool, cardinality: bool, average: bool>, reindex_in_progress: bool, reindex_percentage: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_fields")
  let body = {path: $path, reindex: $reindex, filter_options: $filter_options, pivot_options: $pivot_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a custom Event Field
#
# PATCH /projects/{project_id}/event_fields/{display_id}
# operationId: updateProjectEventFieldByDisplayId
# --filter_options shape: {name?: string}
# --pivot_options shape: {name?: string, fields?: list, summary?: bool, values?: bool, cardinality?: bool, average?: bool}
export def "projects-event-fields updateProjectEventFieldByDisplayId" [
  project_id: string
  display_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  path: string # [Path](https://docs.bugsnag.com/product/custom-filters/advanced-custom-filters/#custom-filter-path) to locate the relevant data inside an Event data structure (e.g. metaData.plan.tier)
  --reindex: oneof<nothing, bool> # Whether to reindex historical events for this field (e.g. false)
  filter_options: record # shape: {name?: string}
  --pivot-options: record # shape: {name?: string, fields?: list, summary?: bool, values?: bool, cardinality?: bool, average?: bool}
]: any -> record<custom: bool, display_id: string, filter_options: record<name: string, description: string, aliases: list<string>, hint_text: string, hint_url: string>, values: table<id: string, name: string>, match_types: list<string>, pivot_options: record<name: string, fields: list<record>, summary: bool, values: bool, cardinality: bool, average: bool>, reindex_in_progress: bool, reindex_percentage: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_fields/($display_id)")
  let body = {path: $path, reindex: $reindex, filter_options: $filter_options, pivot_options: $pivot_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a custom Event Field
#
# DELETE /projects/{project_id}/event_fields/{display_id}
# operationId: deleteProjectEventFieldByDisplayId
export def "projects-event-fields delete" [
  project_id: string
  display_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/event_fields/($display_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Release Groups on a Project
#
# GET /projects/{project_id}/release_groups
# operationId: listProjectReleaseGroups
export def "projects-release-groups listProjectReleaseGroups" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # name of release stage to list release groups for (e.g. production)
  --top-only: oneof<nothing, bool> # return only the top release groups (default false) (e.g. true)
  --visible-only: oneof<nothing, bool> # return only visible release groups (default false) (e.g. true)
  --per-page: float # how many results to return per page (e.g. 30)
  --page-token: string # value from the next relation in the Link response header to obtain the next page of results
]: nothing -> table<id: string, project_id: string, release_stage_name: string, app_version: string, first_released_at: string, first_release_id: string, releases_count: float, has_secondary_versions: bool, build_tool: string, builder_name: string, source_control: record<service: string, commit_url: string, revision: string, diff_url_to_previous: string, previous_app_version: string>, total_sessions_count: float, unhandled_sessions_count: float, sessions_count_in_last_24h: float, accumulative_daily_users_seen: float, accumulative_daily_users_with_unhandled: float, top_release_group: bool, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar") (serialize-qp "top_only" $top_only "scalar") (serialize-qp "visible_only" $visible_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/release_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Release Group
#
# GET /release_groups/{id}
# operationId: getReleaseGroup
export def "release-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, release_stage_name: string, app_version: string, first_released_at: string, first_release_id: string, releases_count: float, has_secondary_versions: bool, build_tool: string, builder_name: string, source_control: record<service: string, commit_url: string, revision: string, diff_url_to_previous: string, previous_app_version: string>, total_sessions_count: float, unhandled_sessions_count: float, sessions_count_in_last_24h: float, accumulative_daily_users_seen: float, accumulative_daily_users_with_unhandled: float, top_release_group: bool, visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/release_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Release Group
#
# PATCH /release_groups/{id}
# operationId: updateReleaseGroup
export def "release-groups updateReleaseGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --visible: oneof<nothing, bool> # the updated visibility (e.g. false)
]: any -> record<id: string, project_id: string, release_stage_name: string, app_version: string, first_released_at: string, first_release_id: string, releases_count: float, has_secondary_versions: bool, build_tool: string, builder_name: string, source_control: record<service: string, commit_url: string, revision: string, diff_url_to_previous: string, previous_app_version: string>, total_sessions_count: float, unhandled_sessions_count: float, sessions_count_in_last_24h: float, accumulative_daily_users_seen: float, accumulative_daily_users_with_unhandled: float, top_release_group: bool, visible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/release_groups/($id)")
  let body = {visible: $visible} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Releases on a Project
#
# GET /projects/{project_id}/releases
# operationId: listProjectReleases
export def "projects-releases listProjectReleases" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage: string # release stage to filter by (e.g. production)
  --qp-base: string # date and time (in ISO 8601 format) to search for releases before (e.g. 2018-02-22T12:00:00Z)
  --qp-sort: string@sort-completer-6 # How to sort the results (default: timestamp)
  --offset: float # The pagination offset (default: 0)
  --per-page: float # How many results (between 1 and 10) to return per page (default: 5, e.g. 5)
]: nothing -> table<id: string, project_id: string, release_time: string, release_source: string, app_version: string, app_version_code: string, app_bundle_version: string, build_label: string, builder_name: string, build_tool: string, errors_introduced_count: float, errors_seen_count: float, sessions_count_in_last_24h: float, total_sessions_count: float, unhandled_sessions_count: float, accumulative_daily_users_seen: float, accumulative_daily_users_with_unhandled: float, metadata: record, release_stage: record<name: string>, source_control: record<service: string, commit_url: string, revision: string, diff_url_to_previous: string>, release_group_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage" $release_stage "scalar") (serialize-qp "base" $qp_base "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a Release
#
# GET /projects/{project_id}/releases/{release_id}
# operationId: getProjectReleaseById
export def "projects-releases get" [
  project_id: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, release_time: string, release_source: string, app_version: string, app_version_code: string, app_bundle_version: string, build_label: string, builder_name: string, build_tool: string, errors_introduced_count: float, errors_seen_count: float, sessions_count_in_last_24h: float, total_sessions_count: float, unhandled_sessions_count: float, accumulative_daily_users_seen: float, accumulative_daily_users_with_unhandled: float, metadata: record, release_stage: record<name: string>, source_control: record<service: string, commit_url: string, revision: string, diff_url_to_previous: string>, release_group_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/releases/($release_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Releases on a Release Group
#
# GET /release_groups/{release_group_id}/releases
# operationId: listReleaseGroupReleases
export def "release-groups-releases listReleaseGroupReleases" [
  release_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # how many results to return per page (e.g. 30)
  --page-token: string # value from the next relation in the Link response header to obtain the next page of results
]: nothing -> table<id: string, project_id: string, release_time: string, release_source: string, app_version: string, app_version_code: string, app_bundle_version: string, build_label: string, builder_name: string, build_tool: string, errors_introduced_count: float, errors_seen_count: float, sessions_count_in_last_24h: float, total_sessions_count: float, unhandled_sessions_count: float, accumulative_daily_users_seen: float, accumulative_daily_users_with_unhandled: float, metadata: record, release_stage: record<name: string>, source_control: record<service: string, commit_url: string, revision: string, diff_url_to_previous: string>, release_group_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/release_groups/($release_group_id)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the stability trend for a project
#
# GET /projects/{project_id}/stability_trend
# operationId: getProjectStabilityTrend
export def "projects-stability-trend get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_id: string, release_stage_name: string, timeline_points: table<bucket_start: string, bucket_end: string, total_sessions_count: float, unhandled_sessions_count: float, users_seen: float, users_with_unhandled: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/stability_trend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an event data request
#
# POST /projects/{project_id}/event_data_requests
# operationId: createProjectEventDataRequest
# --filters shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
export def "projects-event-data-requests createProjectEventDataRequest" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # only include event fields that pertain to the user such as event.user, event.device, and event.request; you may need to remove/redact some fields before giving this data to your users that request it
  filters: record # shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
  --filter-groups: record # A map of filter groups, where each group is keyed with a unique identifier for the group e.g: ``` {  "0": { ... },  "1": { ... } } ``` See the [Advanced Filters documentation](https://developer.smartbear.com/bugsnag/docs/data-access-filtering#advanced-filters) for more details.
  --filter-groups-join: string@filter-groups-join-completer # The join operator to apply between filter groups. - and - All conditions must be satisfied - or (default) - At least one condition must be satisfied
]: any -> record<id: string, url: string, status: string, total: float, report_type: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_data_requests")
  let body = {report_type: $report_type, filters: $filters, filter_groups: $filter_groups, filter_groups_join: $filter_groups_join} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check the status of an event data request
#
# GET /projects/{project_id}/event_data_requests/{id}
# operationId: getProjectEventDataRequestById
export def "projects-event-data-requests get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, status: string, total: float, report_type: string, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_data_requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an event deletion request
#
# POST /projects/{project_id}/event_data_deletions
# operationId: createProjectEventDataDeletion
# --filters shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
export def "projects-event-data-deletions createProjectEventDataDeletion" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-confirmation: oneof<nothing, bool> # whether to skip requiring another request to confirm the deletion (default: false)
  filters: record # shape: {user.id?: list, user.email?: list, user.name?: list, error.id?: list, error.status?: list, error.assigned_to?: list, error.has_issue?: bool, app.release_stage?: list, app.context?: list, app.type?: list, version.introduced_in?: list, version.seen_in?: list, version_code.introduced_in?: list, version_code.seen_in?: list, release.introduced_in?: list, release.seen_in?: list, feature_flag.seen_in?: list, feature_flag.exclusive_to?: list, event.class?: list, event.message?: list, event.file?: list, event.method?: list, event.severity?: list, event.since?: list, event.before?: list, browser.name?: list, browser.version?: list, os.name?: list, os.version?: list, device.hostname?: list, device.manufacturer?: list, device.model?: list, request.url?: list, request.ip?: list, device.jailbroken?: list, app.in_foreground?: list}
  --filter-groups: record # A map of filter groups, where each group is keyed with a unique identifier for the group e.g: ``` {  "0": { ... },  "1": { ... } } ``` See the [Advanced Filters documentation](https://developer.smartbear.com/bugsnag/docs/data-access-filtering#advanced-filters) for more details.
  --filter-groups-join: string@filter-groups-join-completer # The join operator to apply between filter groups. - and - All conditions must be satisfied - or (default) - At least one condition must be satisfied
]: any -> record<id: string, status: string, total: float, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_data_deletions")
  let body = {skip_confirmation: $skip_confirmation, filters: $filters, filter_groups: $filter_groups, filter_groups_join: $filter_groups_join} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Confirm an event deletion request
#
# POST /projects/{project_id}/event_data_deletions/{id}/confirm
# operationId: confirmProjectEventDataDeletion
export def "projects-event-data-deletions-confirm confirmProjectEventDataDeletion" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, total: float, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_data_deletions/($id)/confirm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the status of an event deletion request
#
# GET /projects/{project_id}/event_data_deletions/{id}
# operationId: getProjectEventDataDeletionById
export def "projects-event-data-deletions get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, total: float, filters: record<user_id: list<record>, user_email: list<record>, user_name: list<record>, error_id: list<record>, error_status: list<record>, error_assigned_to: list<record>, error_has_issue: bool, app_release_stage: list<record>, app_context: list<record>, app_type: list<record>, version_introduced_in: list<record>, version_seen_in: list<record>, version_code_introduced_in: list<record>, version_code_seen_in: list<record>, release_introduced_in: list<record>, release_seen_in: list<record>, feature_flag_seen_in: list<record>, feature_flag_exclusive_to: list<record>, event_class: list<record>, event_message: list<record>, event_file: list<record>, event_method: list<record>, event_severity: list<record>, event_since: list<record>, event_before: list<record>, browser_name: list<record>, browser_version: list<record>, os_name: list<record>, os_version: list<record>, device_hostname: list<record>, device_manufacturer: list<record>, device_model: list<record>, request_url: list<record>, request_ip: list<record>, device_jailbroken: list<record>, app_in_foreground: list<record>>, filter_groups: list<record<join: string, filters: record>>, filter_groups_join: string, created_at: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/event_data_deletions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Feature Flags on a Project
#
# GET /projects/{project_id}/feature_flags
# operationId: listProjectFeatureFlags
export def "projects-feature-flags listProjectFeatureFlags" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # Release stage name to get the feature flags for. (e.g. production)
  --starred-at-top: oneof<nothing, bool> # Whether to return starred Feature Flags at the top of the Feature Flags list. (default: false, e.g. false)
  --include-variant-summary: oneof<nothing, bool> # Whether to include a summary of the Variants for each Feature Flag. (default: false, e.g. false)
  --q: string # Search for feature flags with a name matching this query parameter. Supports case-insensitive substring matching. (e.g. name)
  --first-seen: string@first-seen-completer # Filter to Feature Flags that were first seen in the release stage within the specified time frame. (default: all)
  --include-inactive: oneof<nothing, bool> # Whether to include inactive Feature Flags. (default: false, e.g. false)
  --qp-sort: string@sort-completer-7 # Which field to sort on. (default: name)
  --direction: string@direction-completer # Which direction to sort the results by. (default: asc)
  --per-page: float # How many results to return per page. (default: 30)
]: nothing -> table<id: string, name: string, first_seen: string, is_starred: bool, is_active: bool, variant_summary: record<variant_count: float, first_variant_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar") (serialize-qp "starred_at_top" $starred_at_top "scalar") (serialize-qp "include_variant_summary" $include_variant_summary "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "first_seen" $first_seen "scalar") (serialize-qp "include_inactive" $include_inactive "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Feature Flag Summaries for a Project
#
# GET /projects/{project_id}/feature_flag_summaries
# operationId: listProjectFeatureFlagSummaries
export def "projects-feature-flag-summaries listProjectFeatureFlagSummaries" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search for feature flags with a name matching this query parameter. Supports case-insensitive substring matching. (e.g. name)
  --per-page: float # How many results to return per page. (default: 30)
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flag_summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Feature Flag
#
# GET /projects/{project_id}/feature_flags/{id}
# operationId: getProjectFeatureFlag
export def "projects-feature-flags get" [
  id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # Release stage name to get the feature flags for. (e.g. production)
  --include-variant-summary: oneof<nothing, bool> # Whether to include a summary of the Variants for the Feature Flag. (default: false, e.g. false)
]: nothing -> record<id: string, name: string, first_seen: string, is_starred: bool, is_active: bool, variant_summary: record<variant_count: float, first_variant_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar") (serialize-qp "include_variant_summary" $include_variant_summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Feature Flag
#
# DELETE /projects/{project_id}/feature_flags/{id}
# operationId: deleteProjectFeatureFlag
export def "projects-feature-flags delete" [
  project_id: string
  id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Feature Flag's Error Overview
#
# GET /projects/{project_id}/feature_flags/{id}/error_overview
# operationId: getProjectFeatureFlagErrorOverview
export def "projects-feature-flags-error-overview get" [
  id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # Release stage name to get the feature flags for. (e.g. production)
]: nothing -> record<errors_seen: float, exclusive_errors: float, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags/($id)/error_overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Feature Flag Variant's Error Overview
#
# GET /projects/{project_id}/feature_flags/{id}/variants/error_overview
# operationId: getProjectFeatureFlagVariantsErrorOverview
export def "projects-feature-flags-variants-error-overview get" [
  id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --variant-ids: list # IDs for the FeatureFlag variants.
  --release-stage-name: string # Release stage name to get the feature flags for. (e.g. production)
]: nothing -> table<variant_id: string, errors_seen: float, exclusive_errors: float, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variant_ids" $variant_ids "multi") (serialize-qp "release_stage_name" $release_stage_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags/($id)/variants/error_overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Variants on a Feature Flag by ID
#
# GET /projects/{project_id}/feature_flags/{id}/variants
# operationId: getProjectFeatureFlagVariants
export def "projects-feature-flags-variants get" [
  id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # Release stage name to get the variants for. (e.g. production)
  --q: string # Search for feature flags with a name matching this query parameter. Supports case-insensitive substring matching. (e.g. name)
  --per-page: float # How many results to return per page. (default: 30)
]: nothing -> table<id: string, name: string, first_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags/($id)/variants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Variants on a Feature Flag by name
#
# GET /projects/{project_id}/feature_flags/by_name/{name}/variants
# operationId: getProjectFeatureFlagVariantsByName
export def "projects-feature-flags-by-name-variants get" [
  name: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # Release stage name to get the variants for. (e.g. production)
  --q: string # Search for feature flag variants with a name matching this query parameter. Supports case-insensitive substring matching. (e.g. name)
  --per-page: float # How many results to return per page. (default: 30)
]: nothing -> table<id: string, name: string, first_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/feature_flags/by_name/($name)/variants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Star a Feature Flag
#
# POST /user/projects/{project_id}/starred_feature_flags
# operationId: createUserStarredFeatureFlag
export def "user-projects-starred-feature-flags createUserStarredFeatureFlag" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature_flag_id: string # ID of the Feature Flag to star. (e.g. fb59337c511074f6fd000002)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/projects/($project_id)/starred_feature_flags")
  let body = {feature_flag_id: $feature_flag_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unstar a Feature Flag
#
# DELETE /user/projects/{project_id}/starred_feature_flags/{id}
# operationId: deleteUserProjectStarredFeatureFlag
export def "user-projects-starred-feature-flags delete" [
  project_id: string
  id: string
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
  let full_url = (build-url $base $"/user/projects/($project_id)/starred_feature_flags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace the ErrorAssignmentRules on a project
#
# PUT /projects/{project_id}/error_assignment_rules
# operationId: replaceProjectErrorAssignmentRules
# --assignment_rules item shape: {assignee: record, pattern: record, comment?: string}
export def "projects-error-assignment-rules replaceProjectErrorAssignmentRules" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment-rules: list # item shape: {assignee: record, pattern: record, comment?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/error_assignment_rules")
  let body = {assignment_rules: $assignment_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Span Groups on a Project
#
# GET /projects/{project_id}/span_groups
# operationId: listProjectSpanGroups
export def "projects-span-groups listProjectSpanGroups" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer-8 # The field to sort the span groups by (e.g. total_spans)
  --direction: string@direction-completer # The direction to sort the span groups by (e.g. desc)
  --per-page: int # the number of results per page (e.g. 1)
  --offset: int # the offset for the next page of results (e.g. 10)
  --filters: list # The current filters that are being applied.
  --starred-only: oneof<nothing, bool> # Whether to only return Span Groups the requesting user has starred. (e.g. false)
]: nothing -> table<id: string, category: string, name: string, display_name: string, is_starred: bool, statistics: record<duration_statistics: record, total_spans: float, estimated_spans: float, last_seen: string, category_statistics: record, rendering_statistics: record, system_metrics_statistics: record, http_statistics: record>, performance_target: record<id: string, project_id: string, type: string, span_group: record, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "starred_only" $starred_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/span_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a Span Group
#
# GET /projects/{project_id}/span_groups/{id}
# operationId: getProjectSpanGroup
export def "projects-span-groups get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # The current filters that are being applied.
]: nothing -> record<id: string, category: string, name: string, display_name: string, is_starred: bool, statistics: record<duration_statistics: record<p50: float, p75: float, p90: float, p95: float, p99: float>, total_spans: float, estimated_spans: float, last_seen: string, category_statistics: record<full_page_load: record>, rendering_statistics: record<slow_frames: record, frozen_frames: record, total_frames: record, frame_rate_statistics: record>, system_metrics_statistics: record<cpu: record, memory: record>, http_statistics: record<response_codes: record>>, performance_target: record<id: string, project_id: string, type: string, span_group: record<category: string, id: string, display_name: string>, config: record<state: string, warning_performance: record, critical_performance: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/span_groups/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Span Group
#
# PATCH /projects/{project_id}/span_groups/{id}
# operationId: updateProjectSpanGroup
export def "projects-span-groups updateProjectSpanGroup" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-starred: oneof<nothing, bool> # whether or not the Span Group is starred by the user. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/span_groups/($id)")
  let body = {is_starred: $is_starred} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Span Group Summaries for a Project
#
# GET /projects/{project_id}/span_group_summaries
# operationId: listProjectSpanGroupSummaries
export def "projects-span-group-summaries listProjectSpanGroupSummaries" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # the number of results per page (e.g. 1)
  --offset: int # the offset for the next page of results (e.g. 10)
  --filters: list # The current filters that are being applied.
]: nothing -> table<id: string, category: string, name: string, display_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/span_group_summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Span Group's timeline
#
# GET /projects/{project_id}/span_groups/{id}/timeline
# operationId: getProjectSpanGroupTimeline
export def "projects-span-groups-timeline get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # The current filters that are being applied.
]: nothing -> table<bucket_start: string, bucket_end: string, statistics: record<duration_statistics: record, total_spans: float, estimated_spans: float, last_seen: string, category_statistics: record, rendering_statistics: record, system_metrics_statistics: record, http_statistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/span_groups/($id)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Span Group's distribution
#
# GET /projects/{project_id}/span_groups/{id}/distribution
# operationId: getProjectSpanGroupDistribution
export def "projects-span-groups-distribution get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # The current filters that are being applied.
]: nothing -> table<bucket_min: float, bucket_max: float, total_spans: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/span_groups/($id)/distribution" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the starred Span Group descriptions
#
# GET /projects/{project_id}/starred_span_groups
# operationId: listProjectStarredSpanGroups
export def "projects-starred-span-groups listProjectStarredSpanGroups" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # The performance categories of the Span Groups.
  --per-page: int # the number of results per page (e.g. 1)
  --offset: int # the offset for the next page of results (e.g. 10)
]: nothing -> table<id: string, name: string, display_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categories" $categories "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/starred_span_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Performance Targets for a Span Group by ID
#
# GET /projects/{project_id}/span_groups/{id}/performance_targets
# operationId: listProjectSpanGroupPerformanceTargets
export def "projects-span-groups-performance-targets listProjectSpanGroupPerformanceTargets" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, project_id: string, type: string, span_group: record<category: string, id: string, display_name: string>, config: record<state: string, warning_performance: record, critical_performance: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/span_groups/($id)/performance_targets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Spans for a Span Group
#
# GET /projects/{project_id}/span_group_categories/{category}/span_groups/{name}/spans
# operationId: getSpansByCategoryAndName
export def "projects-span-group-categories-span-groups-spans get" [
  project_id: string
  category: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, parent_span_id: string, trace_id: string, category: string, name: string, display_name: string, duration: float, timestamp: string, time_adjustment_type: string, start_time: string, is_first_class: bool, build_id: string, project_id: string, span_group_id: string, virtual_span_group_id: string, statistics: record<category_statistics: record, system_metric_statistics: record, rendering_statistics: record, http_statistics: record>, metadata: record<key: string, value: string, level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/span_group_categories/($category)/span_groups/($name)/spans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Spans for a Span Group by ID
#
# GET /projects/{project_id}/span_groups/{id}/spans
# operationId: listSpansBySpanGroupId
export def "projects-span-groups-spans listSpansBySpanGroupId" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # The current filters that are being applied.
  --qp-sort: string@sort-completer-9 # The field to sort the results by.
  --direction: string@direction-completer # The direction to sort the results by.
  --per-page: int # The number of results to return per page. Defaults to 20. (e.g. 20)
]: nothing -> table<id: string, parent_span_id: string, trace_id: string, category: string, name: string, display_name: string, duration: float, timestamp: string, time_adjustment_type: string, start_time: string, is_first_class: bool, build_id: string, project_id: string, span_group_id: string, virtual_span_group_id: string, statistics: record<category_statistics: record, system_metric_statistics: record, rendering_statistics: record, http_statistics: record>, metadata: record<key: string, value: string, level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/span_groups/($id)/spans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Spans for a Trace
#
# GET /projects/{project_id}/traces/{trace_id}/spans
# operationId: listSpansByTraceId
export def "projects-traces-spans listSpansByTraceId" [
  project_id: string
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Beginning of window to return spans from. (e.g. 2023-04-11T13:14:25.123Z)
  --qp-to: string # End of window to return spans from. (e.g. 2023-04-11T13:14:26.123Z)
  --target-span-id: string # The ID of a Span within the Trace to focus on. If provided the target Span and its direct children will be returned ahead of other Spans in the Trace. (e.g. 6368f07a518fa064ce036bdb)
  --per-page: int # The number of results to return per page. Defaults to 20. (e.g. 20)
]: nothing -> table<id: string, parent_span_id: string, trace_id: string, category: string, name: string, display_name: string, duration: float, timestamp: string, time_adjustment_type: string, start_time: string, is_first_class: bool, build_id: string, project_id: string, span_group_id: string, virtual_span_group_id: string, statistics: record<category_statistics: record, system_metric_statistics: record, rendering_statistics: record, http_statistics: record>, metadata: record<key: string, value: string, level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "target_span_id" $target_span_id "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/traces/($trace_id)/spans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Page Load Span Groups
#
# GET /projects/{project_id}/page_load_span_groups
# operationId: listProjectPageLoadSpanGroups
export def "projects-page-load-span-groups listProjectPageLoadSpanGroups" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer-10 # The field to sort the page load span groups by (e.g. total_spans)
  --direction: string@direction-completer # The direction to sort the page load span groups by (e.g. desc)
  --per-page: float # the number of results per page (e.g. 1)
  --offset: float # the offset for the next page of results (e.g. 10)
  --filters: list # The current filters that are being applied.
  --starred-only: oneof<nothing, bool> # Whether to only return Page Load Span Groups the requesting user has starred. (e.g. false)
]: nothing -> table<id: string, display_name: string, is_starred: bool, full_page_load_span_group: record<id: string, category: string, name: string, display_name: string, is_starred: bool, statistics: record, performance_target: record>, route_change_span_group: record<id: string, category: string, name: string, display_name: string, is_starred: bool, statistics: record, performance_target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "starred_only" $starred_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/page_load_span_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a Page Load Span Group by ID
#
# GET /projects/{project_id}/page_load_span_groups/{id}
# operationId: getProjectPageLoadSpanGroupById
export def "projects-page-load-span-groups get" [
  project_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # The current filters that are being applied.
]: nothing -> record<id: string, display_name: string, is_starred: bool, full_page_load_span_group: record<id: string, category: string, name: string, display_name: string, is_starred: bool, statistics: record<duration_statistics: record, total_spans: float, estimated_spans: float, last_seen: string, category_statistics: record, rendering_statistics: record, system_metrics_statistics: record, http_statistics: record>, performance_target: record<id: string, project_id: string, type: string, span_group: record, config: record>>, route_change_span_group: record<id: string, category: string, name: string, display_name: string, is_starred: bool, statistics: record<duration_statistics: record, total_spans: float, estimated_spans: float, last_seen: string, category_statistics: record, rendering_statistics: record, system_metrics_statistics: record, http_statistics: record>, performance_target: record<id: string, project_id: string, type: string, span_group: record, config: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/page_load_span_groups/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the Trace Fields on a project
#
# GET /projects/{project_id}/trace_fields
# operationId: listProjectTraceFields
export def "projects-trace-fields listProjectTraceFields" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_id: string, filter_options: record<name: string, description: string, values: list, match_types: list, searchable: bool>, custom: bool, metadata_key: string, metadata_location: string, field_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/trace_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a Project's Network Grouping Ruleset
#
# GET /projects/{project_id}/network_endpoint_grouping
# operationId: getProjectNetworkGroupingRuleset
export def "projects-network-endpoint-grouping get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_id: string, endpoints: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/network_endpoint_grouping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Project's Network Grouping Ruleset
#
# PUT /projects/{project_id}/network_endpoint_grouping
# operationId: updateProjectNetworkGroupingRuleset
export def "projects-network-endpoint-grouping updateProjectNetworkGroupingRuleset" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoints: list # The URL patterns by which network spans are grouped.
]: any -> record<project_id: string, endpoints: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/network_endpoint_grouping")
  let body = {endpoints: $endpoints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Performance Score Overview for Project
#
# GET /projects/{project_id}/performance_overview
# operationId: getProjectPerformanceScoreOverview
export def "projects-performance-overview get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-stage-name: string # The name of the release stage to filter the performance score.
]: nothing -> record<performance_score: float, span_count: float, performance_score_timeline: table<bucket_start: string, bucket_end: string, performance_score: float, span_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "release_stage_name" $release_stage_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/performance_overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
