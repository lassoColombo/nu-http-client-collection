# Auto-generated client for incident.io v1.0.0
# Source: https://docs.incident.io/openapi/latest.json
# Auth: --token flag or $env.INCIDENT_IO_TOKEN

const BASE_URL = "https://api.incident.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INCIDENT_IO_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.incident.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def incident-mode-completer [] { ["retrospective" "standard" "stream" "test" "tutorial"] }
def status-completer [] { ["firing" "resolved"] }
def source-type-completer [] { ["alertmanager" "app_optics" "azure_monitor" "big_panda" "bugsnag" "checkly" "chronosphere" "cloudflare" "cloudwatch" "coralogix" "cronitor" "crowdstrike_falcon" "datadog" "dynatrace" "elasticsearch" "email" "expel" "github_issue" "google_cloud" "grafana" "heartbeat" "honeycomb" "http" "http_custom" "incoming_calls" "jira" "jsm" "monte_carlo" "nagios" "new_relic" "opsgenie" "pager_duty" "panther" "pingdom" "prtg" "runscope" "sentry" "sentry_metric" "sns" "splunk" "status_cake" "status_page_views" "sumo_logic" "uptime" "vercel" "zendesk"] }
def color-completer [] { ["blue" "cyan" "green" "orange" "pink" "violet" "yellow"] }
def icon-completer [] { ["alert" "bolt" "box" "briefcase" "browser" "bulb" "calendar" "clock" "cog" "components" "database" "doc" "email" "escalation-path" "files" "flag" "folder" "globe" "money" "server" "severity" "star" "status-page" "store" "tag" "user" "users"] }
def field-type-completer [] { ["link" "multi_select" "numeric" "single_select" "text"] }
def resource-type-completer [] { ["atlassian_statuspage_incident" "datadog_monitor_alert" "github_pull_request" "gitlab_merge_request" "google_calendar_event" "jira_issue" "jsm_alert" "opsgenie_alert" "outlook_calendar_event" "pager_duty_incident" "salesforce_case" "scrubbed" "sentry_issue" "slack_file" "statuspage_incident" "zendesk_ticket"] }
def category-completer [] { ["closed" "learning" "live"] }
def sort-by-completer [] { ["created_at_newest_first" "created_at_oldest_first"] }
def filter-mode-completer [] { ["all" "any"] }
def mode-completer [] { ["retrospective" "standard" "test" "tutorial"] }
def visibility-completer [] { ["private" "public"] }
def status-completer-1 [] { ["active" "past" "upcoming"] }
def status-completer-2 [] { ["completed" "in_progress" "in_review"] }
def sync-type-completer [] { ["all_users" "on_call"] }
def incident-status-completer [] { ["identified" "investigating" "monitoring" "resolved"] }
def maintenance-status-completer [] { ["maintenance_complete" "maintenance_in_progress" "maintenance_scheduled"] }
def preferred-escalation-provider-completer [] { ["native" "opsgenie" "pagerduty" "splunk_on_call"] }
def runs-on-incidents-completer [] { ["newly_created" "newly_created_and_active"] }
def state-completer [] { ["active" "disabled" "draft" "error"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions List" } } | get name | first)
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

# List
#
# GET /v2/actions
# operationId: Actions V2_List
export def "actions List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --incident-id: string # Find actions related to this incident (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --incident-mode: string@incident-mode-completer # Filter to actions from incidents of the given mode. If not set, only actions from `standard` and `retrospective` incidents are returned (e.g. standard, allows empty value)
]: nothing -> record<actions: table<assignee: record, completed_at: string, created_at: string, creator: record, description: string, id: string, incident_id: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "incident_mode" $incident_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/actions/{id}
# operationId: Actions V2_Show
export def "actions Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: record<assignee: record<email: string, id: string, name: string, role: string, slack_user_id: string>, completed_at: string, created_at: string, creator: record<alert: record, api_key: record, user: record, workflow: record>, description: string, id: string, incident_id: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/alert_attributes
# operationId: Alert Attributes V2_List
export def "alert-attributes List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert_attributes: table<array: bool, emoji: string, id: string, name: string, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alert_attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/alert_attributes
# operationId: Alert Attributes V2_Create
export def "alert-attributes Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --array: oneof<nothing, bool> # Whether this attribute is an array (e.g. false)
  --emoji: string # The emoji to display alongside this attribute in chat messages, stored without colons (e.g. fire)
  name: string # Unique name of this attribute (e.g. service)
  --required: oneof<nothing, bool> # Whether this attribute is required. If this field is not set, the existing setting will be preserved. (e.g. false)
  type: string # Engine resource name for this attribute (e.g. CatalogEntry["01GW2G3V0S59R238FAHPDS1R67"])
]: any -> record<alert_attribute: record<array: bool, emoji: string, id: string, name: string, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alert_attributes")
  let body = {array: $array, emoji: $emoji, name: $name, required: $required, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/alert_attributes/{id}
# operationId: Alert Attributes V2_Destroy
export def "alert-attributes Destroy" [
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
  let full_url = (build-url $base $"/v2/alert_attributes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/alert_attributes/{id}
# operationId: Alert Attributes V2_Show
export def "alert-attributes Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert_attribute: record<array: bool, emoji: string, id: string, name: string, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alert_attributes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/alert_attributes/{id}
# operationId: Alert Attributes V2_Update
export def "alert-attributes Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --array: oneof<nothing, bool> # Whether this attribute is an array (e.g. false)
  --emoji: string # The emoji to display alongside this attribute in chat messages, stored without colons (e.g. fire)
  name: string # Unique name of this attribute (e.g. service)
  --required: oneof<nothing, bool> # Whether this attribute is required. If this field is not set, the existing setting will be preserved. (e.g. false)
  type: string # Engine resource name for this attribute (e.g. CatalogEntry["01GW2G3V0S59R238FAHPDS1R67"])
]: any -> record<alert_attribute: record<array: bool, emoji: string, id: string, name: string, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alert_attributes/($id)")
  let body = {array: $array, emoji: $emoji, name: $name, required: $required, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v2/alert_events/http/{alert_source_config_id}
# operationId: Alert Events V2_CreateHTTP
export def "alert-events-http CreateHTTP" [
  alert_source_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Token used to authenticate the request, generated when configuring the alert source. Will be consumed via a URL query string parameter (e.g. some-random-string, allows empty value)
  --authorization: string # Whatever is provided in the Authorization header. We support either Basic or Bearer authorization with the secret provided on the alert source. (e.g. some-random-string)
  --deduplication-key: string # A deduplication key which uniquely references this alert from your alert source. For newly created HTTP sources, this field is required. If you send an event with the same deduplication_key multiple times, only one alert will be created in incident.io for this alert source config. You can filter on this field to find the alert created by an event you've sent us. (e.g. 4293868629)
  --description: string # Description that optionally adds more detail to title. Supports markdown. (e.g. We've detected a number of timeouts on hello.world.com, the service may be down. To fix...)
  --metadata: record # Any additional metadata that you've configured your alert source to parse (e.g. {service: hello.world.com, team: [my-team]})
  --source-url: string # If applicable, a link to the alert in the upstream system (e.g. https://www.my-alerting-platform.com/alerts/my-alert-123)
  status: string@status-completer # Current status of this alert (e.g. firing)
  title: string # The title of the alert, parsed from the alert payload according to the alert source configuration (e.g. *errors.withMessage: PG::Error failed to connect)
]: any -> record<deduplication_key: string, message: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alert_events/http/($alert_source_config_id)" $qp)
  let body = {deduplication_key: $deduplication_key, description: $description, metadata: $metadata, source_url: $source_url, status: $status, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/alert_routes
# operationId: Alert Routes V2_List
export def "alert-routes List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Number of alert routes to return per page (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # The ID of the last alert route on the previous page (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
]: nothing -> record<alert_routes: table<enabled: bool, id: string, name: string>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/alert_routes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/alert_routes
# operationId: Alert Routes V2_Create
# --alert_sources item shape: {alert_source_id: string, condition_groups: list}
# --channel_config item shape: {condition_groups: list, ms_teams_targets?: record, slack_targets?: record}
# --condition_groups item shape: {conditions: list}
# --escalation_config shape: {auto_cancel_escalations: bool, escalation_targets: list}
# --expressions item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
# --incident_config shape: {auto_decline_enabled: bool, auto_relate_grouped_alerts?: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int}
# --incident_template shape: {custom_fields?: list, incident_mode?: record, incident_type?: record, name: record, severity?: record, start_in_triage?: record, summary?: record, workspace?: record}
# --message_template shape: {array_value?: list, value?: record}
export def "alert-routes Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alert_sources: list # Which alert sources should this alert route match? (e.g. [{alert_source_id: 01FCNDV6P870EA6S7TK1DSYDG0, condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}]) — item shape: {alert_source_id: string, condition_groups: list}
  channel_config: list # The channel configuration for this alert route (e.g. [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], ms_teams_targets: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, channel_visibility: abc123}, slack_targets: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, channel_visibility: abc123}}]) — item shape: {condition_groups: list, ms_teams_targets?: record, slack_targets?: record}
  condition_groups: list # What condition groups must be true for this alert route to fire? (e.g. [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]) — item shape: {conditions: list}
  --created-at: string # The time of creation of this alert route (format: date-time, e.g. 2021-08-17T13:28:57.801578Z)
  --enabled: oneof<nothing, bool> # Whether this alert route is enabled or not (e.g. false)
  escalation_config: record # e.g. {auto_cancel_escalations: false, escalation_targets: [{escalation_paths: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, users: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}]} — shape: {auto_cancel_escalations: bool, escalation_targets: list}
  expressions: list # The expressions used in this template (e.g. [{else_branch: {result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, label: Team Slack channel, operations: [{branches: {branches: [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}], returns: {array: true, type: IncidentStatus}}, concatenate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, filter: {condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}, navigate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, operation_type: navigate, parse: {returns: {array: true, type: IncidentStatus}, source: metadata.annotations["github.com/repo"]}}], reference: abc123, root_reference: incident.status}]) — item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
  incident_config: record # e.g. {auto_decline_enabled: false, auto_relate_grouped_alerts: false, condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], defer_time_seconds: 1, enabled: false, grouping_keys: [{reference: alert.title}], grouping_window_seconds: 1} — shape: {auto_decline_enabled: bool, auto_relate_grouped_alerts?: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int}
  incident_template: record # e.g. {custom_fields: [{binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, custom_field_id: 01FCNDV6P870EA6S7TK1DSYDG0, merge_strategy: first-wins}], incident_mode: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, incident_type: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, name: {autogenerated: false, binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, severity: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, merge_strategy: first-wins}, start_in_triage: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, summary: {autogenerated: false, binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, workspace: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}} — shape: {custom_fields?: list, incident_mode?: record, incident_type?: record, name: record, severity?: record, start_in_triage?: record, summary?: record, workspace?: record}
  --is-private: oneof<nothing, bool> # Whether this alert route is private. Private alert routes will only create private incidents from alerts. (e.g. false)
  --message-template: record # e.g. {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}} — shape: {array_value?: list, value?: record}
  name: string # The name of this alert route config, for the user's reference (e.g. Production incidents)
  --owning-team-ids: list # IDs of teams that own this alert route (e.g. [01G0J1EXE7AXZ2C93K61WBPYEH])
  --updated-at: string # The time of last update of this alert route (format: date-time, e.g. 2021-08-17T13:28:57.801578Z)
  version: int # The version of this alert route config (format: int64, e.g. 1)
]: any -> record<alert_route: record<alert_sources: list<record>, channel_config: list<record>, condition_groups: list<record>, created_at: string, enabled: bool, escalation_config: record<auto_cancel_escalations: bool, escalation_targets: list>, expressions: list<record>, id: string, incident_config: record<auto_decline_enabled: bool, auto_relate_grouped_alerts: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int>, incident_template: record<custom_fields: list, incident_mode: record, incident_type: record, name: record, severity: record, start_in_triage: record, summary: record, workspace: record>, is_private: bool, message_template: record<array_value: list, value: record>, name: string, owning_team_ids: list<string>, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alert_routes")
  let body = {alert_sources: $alert_sources, channel_config: $channel_config, condition_groups: $condition_groups, created_at: $created_at, enabled: $enabled, escalation_config: $escalation_config, expressions: $expressions, incident_config: $incident_config, incident_template: $incident_template, is_private: $is_private, message_template: $message_template, name: $name, owning_team_ids: $owning_team_ids, updated_at: $updated_at, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/alert_routes/{id}
# operationId: Alert Routes V2_Delete
export def "alert-routes Delete" [
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
  let full_url = (build-url $base $"/v2/alert_routes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/alert_routes/{id}
# operationId: Alert Routes V2_Show
export def "alert-routes Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert_route: record<alert_sources: list<record>, channel_config: list<record>, condition_groups: list<record>, created_at: string, enabled: bool, escalation_config: record<auto_cancel_escalations: bool, escalation_targets: list>, expressions: list<record>, id: string, incident_config: record<auto_decline_enabled: bool, auto_relate_grouped_alerts: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int>, incident_template: record<custom_fields: list, incident_mode: record, incident_type: record, name: record, severity: record, start_in_triage: record, summary: record, workspace: record>, is_private: bool, message_template: record<array_value: list, value: record>, name: string, owning_team_ids: list<string>, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alert_routes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/alert_routes/{id}
# operationId: Alert Routes V2_Update
# --alert_sources item shape: {alert_source_id: string, condition_groups: list}
# --channel_config item shape: {condition_groups: list, ms_teams_targets?: record, slack_targets?: record}
# --condition_groups item shape: {conditions: list}
# --escalation_config shape: {auto_cancel_escalations: bool, escalation_targets: list}
# --expressions item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
# --incident_config shape: {auto_decline_enabled: bool, auto_relate_grouped_alerts?: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int}
# --incident_template shape: {custom_fields?: list, incident_mode?: record, incident_type?: record, name: record, severity?: record, start_in_triage?: record, summary?: record, workspace?: record}
# --message_template shape: {array_value?: list, value?: record}
export def "alert-routes Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alert_sources: list # Which alert sources should this alert route match? (e.g. [{alert_source_id: 01FCNDV6P870EA6S7TK1DSYDG0, condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}]) — item shape: {alert_source_id: string, condition_groups: list}
  channel_config: list # The channel configuration for this alert route (e.g. [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], ms_teams_targets: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, channel_visibility: abc123}, slack_targets: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, channel_visibility: abc123}}]) — item shape: {condition_groups: list, ms_teams_targets?: record, slack_targets?: record}
  condition_groups: list # What condition groups must be true for this alert route to fire? (e.g. [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]) — item shape: {conditions: list}
  --created-at: string # The time of creation of this alert route (format: date-time, e.g. 2021-08-17T13:28:57.801578Z)
  --enabled: oneof<nothing, bool> # Whether this alert route is enabled or not (e.g. false)
  escalation_config: record # e.g. {auto_cancel_escalations: false, escalation_targets: [{escalation_paths: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, users: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}]} — shape: {auto_cancel_escalations: bool, escalation_targets: list}
  expressions: list # The expressions used in this template (e.g. [{else_branch: {result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, label: Team Slack channel, operations: [{branches: {branches: [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}], returns: {array: true, type: IncidentStatus}}, concatenate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, filter: {condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}, navigate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, operation_type: navigate, parse: {returns: {array: true, type: IncidentStatus}, source: metadata.annotations["github.com/repo"]}}], reference: abc123, root_reference: incident.status}]) — item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
  incident_config: record # e.g. {auto_decline_enabled: false, auto_relate_grouped_alerts: false, condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], defer_time_seconds: 1, enabled: false, grouping_keys: [{reference: alert.title}], grouping_window_seconds: 1} — shape: {auto_decline_enabled: bool, auto_relate_grouped_alerts?: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int}
  incident_template: record # e.g. {custom_fields: [{binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, custom_field_id: 01FCNDV6P870EA6S7TK1DSYDG0, merge_strategy: first-wins}], incident_mode: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, incident_type: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, name: {autogenerated: false, binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, severity: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, merge_strategy: first-wins}, start_in_triage: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, summary: {autogenerated: false, binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, workspace: {binding: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}} — shape: {custom_fields?: list, incident_mode?: record, incident_type?: record, name: record, severity?: record, start_in_triage?: record, summary?: record, workspace?: record}
  --is-private: oneof<nothing, bool> # Whether this alert route is private. Private alert routes will only create private incidents from alerts. (e.g. false)
  --message-template: record # e.g. {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}} — shape: {array_value?: list, value?: record}
  name: string # The name of this alert route config, for the user's reference (e.g. Production incidents)
  --owning-team-ids: list # IDs of teams that own this alert route (e.g. [01G0J1EXE7AXZ2C93K61WBPYEH])
  --updated-at: string # The time of last update of this alert route (format: date-time, e.g. 2021-08-17T13:28:57.801578Z)
  version: int # The version of this alert route config (format: int64, e.g. 1)
]: any -> record<alert_route: record<alert_sources: list<record>, channel_config: list<record>, condition_groups: list<record>, created_at: string, enabled: bool, escalation_config: record<auto_cancel_escalations: bool, escalation_targets: list>, expressions: list<record>, id: string, incident_config: record<auto_decline_enabled: bool, auto_relate_grouped_alerts: bool, condition_groups: list, defer_time_seconds: int, enabled: bool, grouping_keys: list, grouping_window_seconds: int>, incident_template: record<custom_fields: list, incident_mode: record, incident_type: record, name: record, severity: record, start_in_triage: record, summary: record, workspace: record>, is_private: bool, message_template: record<array_value: list, value: record>, name: string, owning_team_ids: list<string>, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alert_routes/($id)")
  let body = {alert_sources: $alert_sources, channel_config: $channel_config, condition_groups: $condition_groups, created_at: $created_at, enabled: $enabled, escalation_config: $escalation_config, expressions: $expressions, incident_config: $incident_config, incident_template: $incident_template, is_private: $is_private, message_template: $message_template, name: $name, owning_team_ids: $owning_team_ids, updated_at: $updated_at, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/alert_sources
# operationId: Alert Sources V2_List
export def "alert-sources List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert_sources: table<alert_events_url: string, auto_resolve_incident_alerts: bool, auto_resolve_timeout_minutes: int, email_options: record, heartbeat_options: record, http_custom_options: record, id: string, jira_options: record, name: string, owning_team_ids: list, secret_token: string, source_type: string, template: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alert_sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/alert_sources
# operationId: Alert Sources V2_Create
# --email_options shape: {redactions: list, transform_expression?: string}
# --heartbeat_options shape: {failure_threshold?: int, grace_period_seconds?: int, interval_seconds: int}
# --http_custom_options shape: {deduplication_key_path: string, transform_expression: string}
# --jira_options shape: {project_ids: list}
# --template shape: {attributes: list, description: record, expressions: list, is_private?: bool, title: record, visible_to_teams?: record}
export def "alert-sources Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-resolve-incident-alerts: oneof<nothing, bool> # Whether to auto-resolve incident alerts when the alert auto-resolves. Defaults to true. Only use in conjunction with auto_resolve_timeout_minutes. (e.g. false)
  --auto-resolve-timeout-minutes: int # When set, alerts from this source will automatically resolve after this many minutes. (format: int64, e.g. 1)
  --email-options: record # e.g. {redactions: [credit_card_numbers], transform_expression: return {   title: $.subject,   description: $.text,   status: $.subject.startsWith('[RESOLVED]') ? 'resolved' : 'firing',   deduplication_key: $.header_message_id, }} — shape: {redactions: list, transform_expression?: string}
  --heartbeat-options: record # e.g. {failure_threshold: 1, grace_period_seconds: 0, interval_seconds: 60} — shape: {failure_threshold?: int, grace_period_seconds?: int, interval_seconds: int}
  --http-custom-options: record # e.g. {deduplication_key_path: $.alert_id, transform_expression: return {   title: $.title || $.name || 'Unknown Alert',   status: $.status === 'resolved' ? 'resolved' : 'firing',   description: $.description || $.message || '',   sourceURL: $.url || $.link || '',   metadata: { team: $.team, severity: $.severity } }} — shape: {deduplication_key_path: string, transform_expression: string}
  --jira-options: record # e.g. {project_ids: [01GBSQF3FHF7FWZQNWGHAVQ804, 10043]} — shape: {project_ids: list}
  name: string # Unique name of the alert source (e.g. Production Web Dashboard Alerts)
  --owning-team-ids: list # IDs of teams that own this alert source (e.g. [01G0J1EXE7AXZ2C93K61WBPYEH])
  source_type: string@source-type-completer # Type of alert source (e.g. alertmanager)
  template: record # e.g. {attributes: [{alert_attribute_id: abc123, binding: {array_value: [{literal: SEV123, reference: incident.severity}], merge_strategy: first_wins, value: {literal: SEV123, reference: incident.severity}}}], description: {literal: SEV123, reference: incident.severity}, expressions: [{else_branch: {result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, label: Team Slack channel, operations: [{branches: {branches: [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}], returns: {array: true, type: IncidentStatus}}, concatenate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, filter: {condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}, navigate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, operation_type: navigate, parse: {returns: {array: true, type: IncidentStatus}, source: metadata.annotations["github.com/repo"]}}], reference: abc123, root_reference: incident.status}], is_private: false, title: {literal: SEV123, reference: incident.severity}, visible_to_teams: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}} — shape: {attributes: list, description: record, expressions: list, is_private?: bool, title: record, visible_to_teams?: record}
]: any -> record<alert_source: record<alert_events_url: string, auto_resolve_incident_alerts: bool, auto_resolve_timeout_minutes: int, email_options: record<email_address: string, redactions: list, transform_expression: string>, heartbeat_options: record<failure_threshold: int, grace_period_seconds: int, interval_seconds: int, ping_url: string>, http_custom_options: record<deduplication_key_path: string, transform_expression: string>, id: string, jira_options: record<project_ids: list>, name: string, owning_team_ids: list<string>, secret_token: string, source_type: string, template: record<attributes: list, description: record, expressions: list, is_private: bool, title: record, visible_to_teams: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alert_sources")
  let body = {auto_resolve_incident_alerts: $auto_resolve_incident_alerts, auto_resolve_timeout_minutes: $auto_resolve_timeout_minutes, email_options: $email_options, heartbeat_options: $heartbeat_options, http_custom_options: $http_custom_options, jira_options: $jira_options, name: $name, owning_team_ids: $owning_team_ids, source_type: $source_type, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/alert_sources/{id}
# operationId: Alert Sources V2_Delete
export def "alert-sources Delete" [
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
  let full_url = (build-url $base $"/v2/alert_sources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/alert_sources/{id}
# operationId: Alert Sources V2_Show
export def "alert-sources Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert_source: record<alert_events_url: string, auto_resolve_incident_alerts: bool, auto_resolve_timeout_minutes: int, email_options: record<email_address: string, redactions: list, transform_expression: string>, heartbeat_options: record<failure_threshold: int, grace_period_seconds: int, interval_seconds: int, ping_url: string>, http_custom_options: record<deduplication_key_path: string, transform_expression: string>, id: string, jira_options: record<project_ids: list>, name: string, owning_team_ids: list<string>, secret_token: string, source_type: string, template: record<attributes: list, description: record, expressions: list, is_private: bool, title: record, visible_to_teams: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alert_sources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/alert_sources/{id}
# operationId: Alert Sources V2_Update
# --email_options shape: {redactions: list, transform_expression?: string}
# --heartbeat_options shape: {failure_threshold?: int, grace_period_seconds?: int, interval_seconds: int}
# --http_custom_options shape: {deduplication_key_path: string, transform_expression: string}
# --jira_options shape: {project_ids: list}
# --template shape: {attributes: list, description: record, expressions: list, is_private?: bool, title: record, visible_to_teams?: record}
export def "alert-sources Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-resolve-incident-alerts: oneof<nothing, bool> # Whether to auto-resolve incident alerts when the alert auto-resolves. Defaults to true. Only use in conjunction with auto_resolve_timeout_minutes. (e.g. false)
  --auto-resolve-timeout-minutes: int # When set, alerts from this source will automatically resolve after this many minutes. (format: int64, e.g. 1)
  --disabled: oneof<nothing, bool> # For heartbeat sources, set to true to disable monitoring (e.g. false)
  --email-options: record # e.g. {redactions: [credit_card_numbers], transform_expression: return {   title: $.subject,   description: $.text,   status: $.subject.startsWith('[RESOLVED]') ? 'resolved' : 'firing',   deduplication_key: $.header_message_id, }} — shape: {redactions: list, transform_expression?: string}
  --heartbeat-options: record # e.g. {failure_threshold: 1, grace_period_seconds: 0, interval_seconds: 60} — shape: {failure_threshold?: int, grace_period_seconds?: int, interval_seconds: int}
  --http-custom-options: record # e.g. {deduplication_key_path: $.alert_id, transform_expression: return {   title: $.title || $.name || 'Unknown Alert',   status: $.status === 'resolved' ? 'resolved' : 'firing',   description: $.description || $.message || '',   sourceURL: $.url || $.link || '',   metadata: { team: $.team, severity: $.severity } }} — shape: {deduplication_key_path: string, transform_expression: string}
  --jira-options: record # e.g. {project_ids: [01GBSQF3FHF7FWZQNWGHAVQ804, 10043]} — shape: {project_ids: list}
  name: string # Unique name of the alert source (e.g. Production Web Dashboard Alerts)
  --owning-team-ids: list # IDs of teams that own this alert source (e.g. [01G0J1EXE7AXZ2C93K61WBPYEH])
  template: record # e.g. {attributes: [{alert_attribute_id: abc123, binding: {array_value: [{literal: SEV123, reference: incident.severity}], merge_strategy: first_wins, value: {literal: SEV123, reference: incident.severity}}}], description: {literal: SEV123, reference: incident.severity}, expressions: [{else_branch: {result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, label: Team Slack channel, operations: [{branches: {branches: [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}], returns: {array: true, type: IncidentStatus}}, concatenate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, filter: {condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}, navigate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, operation_type: navigate, parse: {returns: {array: true, type: IncidentStatus}, source: metadata.annotations["github.com/repo"]}}], reference: abc123, root_reference: incident.status}], is_private: false, title: {literal: SEV123, reference: incident.severity}, visible_to_teams: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}} — shape: {attributes: list, description: record, expressions: list, is_private?: bool, title: record, visible_to_teams?: record}
]: any -> record<alert_source: record<alert_events_url: string, auto_resolve_incident_alerts: bool, auto_resolve_timeout_minutes: int, email_options: record<email_address: string, redactions: list, transform_expression: string>, heartbeat_options: record<failure_threshold: int, grace_period_seconds: int, interval_seconds: int, ping_url: string>, http_custom_options: record<deduplication_key_path: string, transform_expression: string>, id: string, jira_options: record<project_ids: list>, name: string, owning_team_ids: list<string>, secret_token: string, source_type: string, template: record<attributes: list, description: record, expressions: list, is_private: bool, title: record, visible_to_teams: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alert_sources/($id)")
  let body = {auto_resolve_incident_alerts: $auto_resolve_incident_alerts, auto_resolve_timeout_minutes: $auto_resolve_timeout_minutes, disabled: $disabled, email_options: $email_options, heartbeat_options: $heartbeat_options, http_custom_options: $http_custom_options, jira_options: $jira_options, name: $name, owning_team_ids: $owning_team_ids, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/alerts
# operationId: Alerts V2_List
export def "alerts List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Number of alerts to return per page (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # If provided, pass this as the 'after' param to load the next page (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --deduplication-key: record # Filter on alert deduplication key. The accepted operator is 'is'. (e.g. {is: [01GBSQF3FHF7FWZQNWGHAVQ804]}, allows empty value)
  --status: record # Filter on alert status. The accepted operators are 'one_of', or 'not_in'. (e.g. {one_of: [firing]}, allows empty value)
  --alert-source: record # Filter on alert source by ID. The accepted operators are 'one_of', or 'not_in'. (e.g. {one_of: [01GBSQF3FHF7FWZQNWGHAVQ804]}, allows empty value)
  --created-at: record # Filter on alert created at timestamp. Accepted operators are 'gte', 'lte' and 'date_range'. (e.g. {gte: [2025-01-01]}, allows empty value)
  --include-maintenance-window: record # Filter on whether to include maintenance window alerts. The accepted operator is 'is'. (e.g. {is: [true]}, allows empty value)
]: nothing -> record<alerts: table<alert_source_id: string, attributes: list, created_at: string, deduplication_key: string, description: string, id: string, resolved_at: string, source_url: string, status: string, title: string, updated_at: string>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "deduplication_key" $deduplication_key "multi") (serialize-qp "status" $status "multi") (serialize-qp "alert_source" $alert_source "multi") (serialize-qp "created_at" $created_at "multi") (serialize-qp "include_maintenance_window" $include_maintenance_window "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/alerts/{id}
# operationId: Alerts V2_Show
export def "alerts Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert: record<alert_source_id: string, attributes: list<record>, created_at: string, deduplication_key: string, description: string, id: string, resolved_at: string, source_url: string, status: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alerts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve
#
# POST /v2/alerts/{id}/actions/resolve
# operationId: Alerts V2_Resolve
export def "alerts-actions-resolve Resolve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alert: record<alert_source_id: string, attributes: list<record>, created_at: string, deduplication_key: string, description: string, id: string, resolved_at: string, source_url: string, status: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alerts/($id)/actions/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/incident_alerts
# operationId: Alerts V2_ListIncidentAlerts
export def "incident-alerts ListIncidentAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Number of incident alerts to return per page (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # If provided, pass this as the 'after' param to load the next page (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --alert-id: string # Alert that this incident alert refers to (e.g. 01FCNDV6P870EA6S7TK1DSYDG1, allows empty value)
  --incident-id: string # Incident that this incident alert is attached to (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
]: nothing -> record<incident_alerts: table<alert: record, alert_route_id: string, id: string, incident: record>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "alert_id" $alert_id "scalar") (serialize-qp "incident_id" $incident_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/incident_alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v1/api_keys
# operationId: API Keys V1_List
export def "api-keys List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<api_keys: table<created_at: string, creator: record, id: string, last_used_at: string, name: string, roles: list, team_ids: list, team_roles: list, token_last_issued_at: string>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/api_keys
# operationId: API Keys V1_Create
export def "api-keys Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Human-readable name for the new API key (e.g. My test API key)
  role_names: list # Account-level roles to assign to the API key. These roles apply across the entire account, not scoped to specific teams. Pass an empty array if no account-level roles are needed. (e.g. [viewer, incident_creator])
  team_ids: list # IDs of teams to scope the `team_role_names` to. If provided, `team_role_names` must also be a non-empty array, and vice versa. Pass an empty array if the key should not be scoped to any teams. (e.g. [01FCNDV6P870EA6S7TK1DSYDG0])
  team_role_names: list # Roles to grant for the teams specified in `team_ids`. If provided, `team_ids` must also be a non-empty array, and vice versa. Pass an empty array if no team-level roles are needed. (e.g. [schedules_editor])
]: any -> record<api_key: record<created_at: string, creator: record<api_key: record, user: record>, id: string, last_used_at: string, name: string, roles: list<record>, team_ids: list<string>, team_roles: list<record>, token_last_issued_at: string>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/api_keys")
  let body = {name: $name, role_names: $role_names, team_ids: $team_ids, team_role_names: $team_role_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/api_keys/{id}
# operationId: API Keys V1_Delete
export def "api-keys Delete" [
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
  let full_url = (build-url $base $"/v1/api_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/api_keys/{id}
# operationId: API Keys V1_Show
export def "api-keys Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_key: record<created_at: string, creator: record<api_key: record, user: record>, id: string, last_used_at: string, name: string, roles: list<record>, team_ids: list<string>, team_roles: list<record>, token_last_issued_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/api_keys/{id}
# operationId: API Keys V1_Update
export def "api-keys Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Human-readable name for the API key (e.g. My test API key)
  role_names: list # Account-level roles for the API key. These roles apply across the entire account, not scoped to specific teams. Pass an empty array if no account-level roles are needed. (e.g. [viewer, incident_creator])
  team_ids: list # IDs of teams to scope the `team_role_names` to. If provided, `team_role_names` must also be a non-empty array, and vice versa. Pass an empty array if the key should not be scoped to any teams. (e.g. [01FCNDV6P870EA6S7TK1DSYDG0])
  team_role_names: list # Roles to grant for the teams specified in `team_ids`. If provided, `team_ids` must also be a non-empty array, and vice versa. Pass an empty array if no team-level roles are needed. (e.g. [schedules_editor])
]: any -> record<api_key: record<created_at: string, creator: record<api_key: record, user: record>, id: string, last_used_at: string, name: string, roles: list<record>, team_ids: list<string>, team_roles: list<record>, token_last_issued_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api_keys/($id)")
  let body = {name: $name, role_names: $role_names, team_ids: $team_ids, team_role_names: $team_role_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rotate
#
# POST /v1/api_keys/{id}/actions/rotate
# operationId: API Keys V1_Rotate
export def "api-keys-actions-rotate Rotate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  grace_period_minutes: int # How many minutes to keep the old access token alive. (format: int64, default: 30, e.g. 30)
]: any -> record<api_key: record<created_at: string, creator: record<api_key: record, user: record>, id: string, last_used_at: string, name: string, roles: list<record>, team_ids: list<string>, team_roles: list<record>, token_last_issued_at: string>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api_keys/($id)/actions/rotate")
  let body = {grace_period_minutes: $grace_period_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Entries
#
# GET /v3/catalog_entries
# operationId: Catalog V3_ListEntries
export def "catalog-entries ListEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-type-id: string # ID of this catalog type (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --page-size: int # The integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
  --identifier: string # If specified, only entries with this identifier will be returned. This will search by ID, external ID, and aliases.  If 'use name as identifier' is enabled for the catalog type, this will also match on name. (e.g. abc123, allows empty value)
]: nothing -> record<catalog_entries: table<aliases: list, archived_at: string, attribute_values: record, catalog_type_id: string, created_at: string, external_id: string, id: string, name: string, rank: int, updated_at: string>, catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>, pagination_meta: record<after: string, page_size: int, total_record_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "catalog_type_id" $catalog_type_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/catalog_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Entry
#
# POST /v3/catalog_entries
# operationId: Catalog V3_CreateEntry
export def "catalog-entries CreateEntry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: list # Optional aliases that can be used to reference this entry (e.g. [lawrence@incident.io, lawrence])
  attribute_values: record # Values of this entry (e.g. {abc123: {array_value: [{literal: SEV123}], value: {literal: SEV123}}})
  catalog_type_id: string # ID of this catalog type (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  --external-id: string # An optional alternative ID for this entry, which is ensured to be unique for the type (e.g. 761722cd-d1d7-477b-ac7e-90f9e079dc33)
  name: string # Name is the human readable name of this entry (e.g. Primary On-call)
  --rank: int # When catalog type is ranked, this is used to help order things (format: int32, e.g. 3)
]: any -> record<catalog_entry: record<aliases: list<string>, archived_at: string, attribute_values: record, catalog_type_id: string, created_at: string, external_id: string, id: string, name: string, rank: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/catalog_entries")
  let body = {aliases: $aliases, attribute_values: $attribute_values, catalog_type_id: $catalog_type_id, external_id: $external_id, name: $name, rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Entry
#
# DELETE /v3/catalog_entries/{id}
# operationId: Catalog V3_DestroyEntry
export def "catalog-entries DestroyEntry" [
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
  let full_url = (build-url $base $"/v3/catalog_entries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show Entry
#
# GET /v3/catalog_entries/{id}
# operationId: Catalog V3_ShowEntry
export def "catalog-entries ShowEntry" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: oneof<nothing, bool> # Whether to include details of all attribute links (forwards and backwards) within the response. Default behaviour (no query param) is to include only forward links. When expand is false, we only show attributes of the catalog entry itself.When expand is true, we show forward and backward links (e.g. true, allows empty value)
]: nothing -> record<catalog_entry: record<aliases: list<string>, archived_at: string, attribute_values: record, catalog_type_id: string, created_at: string, external_id: string, id: string, name: string, rank: int, updated_at: string>, catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/catalog_entries/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Entry
#
# PUT /v3/catalog_entries/{id}
# operationId: Catalog V3_UpdateEntry
export def "catalog-entries UpdateEntry" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: list # Optional aliases that can be used to reference this entry (e.g. [lawrence@incident.io, lawrence])
  attribute_values: record # Values of this entry (e.g. {abc123: {array_value: [{literal: SEV123}], value: {literal: SEV123}}})
  --external-id: string # An optional alternative ID for this entry, which is ensured to be unique for the type (e.g. 761722cd-d1d7-477b-ac7e-90f9e079dc33)
  name: string # Name is the human readable name of this entry (e.g. Primary On-call)
  --rank: int # When catalog type is ranked, this is used to help order things (format: int32, e.g. 3)
  --update-attributes: list # If provided, only update these attribute_values keys. If not provided, update all attribute values. If you specify an attribute key that's not in your payload, the associated attribute value will be cleared. (e.g. [abc123])
]: any -> record<catalog_entry: record<aliases: list<string>, archived_at: string, attribute_values: record, catalog_type_id: string, created_at: string, external_id: string, id: string, name: string, rank: int, updated_at: string>, catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/catalog_entries/($id)")
  let body = {aliases: $aliases, attribute_values: $attribute_values, external_id: $external_id, name: $name, rank: $rank, update_attributes: $update_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bulk Update Entries
#
# POST /v3/catalog_entries/actions/bulk_update
# operationId: Catalog V3_BulkUpdateEntries
# --entries item shape: {aliases?: list, attribute_values: record, entry_id: string, external_id?: string, name?: string, rank?: int}
export def "catalog-entries-actions-bulk-update BulkUpdateEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  catalog_type_id: string # The unique identifier of the catalog type containing the entries (e.g. 01GW2G3V0S59R238FAHPDS1R66)
  entries: list # A list of entries to update with their new values. Maximum 250 entries per request. (e.g. [{aliases: [abc123], attribute_values: {abc123: {array_value: [{literal: SEV123}], value: {literal: SEV123}}}, entry_id: abc123, external_id: abc123, name: abc123, rank: 1}, {aliases: [abc123], attribute_values: {abc123: {array_value: [{literal: SEV123}], value: {literal: SEV123}}}, entry_id: abc123, external_id: abc123, name: abc123, rank: 1}]) — item shape: {aliases?: list, attribute_values: record, entry_id: string, external_id?: string, name?: string, rank?: int}
  --update-attributes: list # Optional list of specific attribute IDs to update across all entries. When provided, only these attributes in attribute_values will be updated and all other attributes will be preserved. This parameter only affects attribute_values - it does not affect core entry fields like name, rank, aliases, or external_id, which follow their individual omission rules. (e.g. [01GW2G3V0S59R238FAHPDS1R66, 01GW2G3V0S59R238FAHPDS1R67])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/catalog_entries/actions/bulk_update")
  let body = {catalog_type_id: $catalog_type_id, entries: $entries, update_attributes: $update_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Resources
#
# GET /v3/catalog_resources
# operationId: Catalog V3_ListResources
export def "catalog-resources ListResources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<resources: table<category: string, description: string, label: string, type: string, value_docstring: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/catalog_resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Types
#
# GET /v3/catalog_types
# operationId: Catalog V3_ListTypes
export def "catalog-types ListTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<catalog_types: table<annotations: record, categories: list, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list, schema: record, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/catalog_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Type
#
# POST /v3/catalog_types
# operationId: Catalog V3_CreateType
export def "catalog-types CreateType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # Annotations that can track metadata about this type (e.g. {incident.io/catalog-importer/id: id-of-config})
  --categories: list # What categories is this type considered part of (e.g. [customer])
  --color: string@color-completer # Sets the display color of this type in the dashboard (e.g. yellow)
  description: string # Human readble description of this type (e.g. Represents Kubernetes clusters that we run inside of GKE.)
  --icon: string@icon-completer # Sets the display icon of this type in the dashboard (e.g. alert)
  name: string # Name is the human readable name of this type (e.g. Kubernetes Cluster)
  --ranked: oneof<nothing, bool> # If this type should be ranked (e.g. true)
  --source-repo-url: string # The url of the external repository where this type is managed (e.g. https://github.com/my-company/incident-io-catalog)
  --type-name: string # The type name of this catalog type, to be used when defining attributes. This is immutable once a CatalogType has been created. For non-externally sync types, it must follow the pattern Custom["SomeName"] (e.g. Custom["BackstageGroup"])
  --use-name-as-identifier: oneof<nothing, bool> # If enabled, you can refer to entries of this type by their name, as well as their external ID and any aliases. (e.g. true)
]: any -> record<catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/catalog_types")
  let body = {annotations: $annotations, categories: $categories, color: $color, description: $description, icon: $icon, name: $name, ranked: $ranked, source_repo_url: $source_repo_url, type_name: $type_name, use_name_as_identifier: $use_name_as_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Type
#
# DELETE /v3/catalog_types/{id}
# operationId: Catalog V3_DestroyType
export def "catalog-types DestroyType" [
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
  let full_url = (build-url $base $"/v3/catalog_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show Type
#
# GET /v3/catalog_types/{id}
# operationId: Catalog V3_ShowType
export def "catalog-types ShowType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/catalog_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Type
#
# PUT /v3/catalog_types/{id}
# operationId: Catalog V3_UpdateType
export def "catalog-types UpdateType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # Annotations that can track metadata about this type (e.g. {incident.io/catalog-importer/id: id-of-config})
  --categories: list # What categories is this type considered part of (e.g. [customer])
  --color: string@color-completer # Sets the display color of this type in the dashboard (e.g. yellow)
  description: string # Human readble description of this type (e.g. Represents Kubernetes clusters that we run inside of GKE.)
  --icon: string@icon-completer # Sets the display icon of this type in the dashboard (e.g. alert)
  name: string # Name is the human readable name of this type (e.g. Kubernetes Cluster)
  --ranked: oneof<nothing, bool> # If this type should be ranked (e.g. true)
  --source-repo-url: string # The url of the external repository where this type is managed (e.g. https://github.com/my-company/incident-io-catalog)
  --use-name-as-identifier: oneof<nothing, bool> # If enabled, you can refer to entries of this type by their name, as well as their external ID and any aliases. (e.g. true)
]: any -> record<catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/catalog_types/($id)")
  let body = {annotations: $annotations, categories: $categories, color: $color, description: $description, icon: $icon, name: $name, ranked: $ranked, source_repo_url: $source_repo_url, use_name_as_identifier: $use_name_as_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Type Schema
#
# POST /v3/catalog_types/{id}/actions/update_schema
# operationId: Catalog V3_UpdateTypeSchema
# --attributes item shape: {array: bool, backlink_attribute?: string, id?: string, mode?: ""|"api"|"dashboard"|"external"|"internal"|"dynamic"|"backlink"|"path", name: string, path?: list, type: string}
export def "catalog-types-actions-update-schema UpdateTypeSchema" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: list # e.g. [{array: false, backlink_attribute: abc123, id: 01GW2G3V0S59R238FAHPDS1R66, mode: , name: tier, path: [{attribute_id: abc123}], type: Custom["Service"]}] — item shape: {array: bool, backlink_attribute?: string, id?: string, mode?: ""|"api"|"dashboard"|"external"|"internal"|"dynamic"|"backlink"|"path", name: string, path?: list, type: string}
  version: int # format: int64, e.g. 1
]: any -> record<catalog_type: record<annotations: record, categories: list<string>, color: string, created_at: string, description: string, dynamic_resource_parameter: string, estimated_count: int, icon: string, id: string, is_editable: bool, is_team_type: bool, last_synced_at: string, name: string, ranked: bool, registry_type: string, required_integrations: list<string>, schema: record<attributes: list, version: int>, source_repo_url: string, type_name: string, updated_at: string, use_name_as_identifier: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/catalog_types/($id)/actions/update_schema")
  let body = {attributes: $attributes, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/custom_field_options
# operationId: Custom Field Options V1_List
export def "custom-field-options List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # A custom field option's ID. This endpoint will return a list of custom field options created after this option. (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH, allows empty value)
  --custom-field-id: string # The custom field to list options for. (e.g. 01FCNDV6P870EA6S7TK1DSYD5H, allows empty value)
]: nothing -> record<custom_field_options: table<custom_field_id: string, id: string, sort_key: int, value: string>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "custom_field_id" $custom_field_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/custom_field_options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/custom_field_options
# operationId: Custom Field Options V1_Create
export def "custom-field-options Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  custom_field_id: string # ID of the custom field this option belongs to (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  --sort-key: int # Sort key used to order the custom field options correctly (format: int64, default: 1000, e.g. 10)
  value: string # Human readable name for the custom field option. Values must not start or end with whitespace, or contain tabs or newlines. (e.g. Product)
]: any -> record<custom_field_option: record<custom_field_id: string, id: string, sort_key: int, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/custom_field_options")
  let body = {custom_field_id: $custom_field_id, sort_key: $sort_key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/custom_field_options/{id}
# operationId: Custom Field Options V1_Delete
export def "custom-field-options Delete" [
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
  let full_url = (build-url $base $"/v1/custom_field_options/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/custom_field_options/{id}
# operationId: Custom Field Options V1_Show
export def "custom-field-options Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_field_option: record<custom_field_id: string, id: string, sort_key: int, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_field_options/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/custom_field_options/{id}
# operationId: Custom Field Options V1_Update
export def "custom-field-options Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sort_key: int # Sort key used to order the custom field options correctly (format: int64, default: 1000, e.g. 10)
  value: string # Human readable name for the custom field option. Values must not start or end with whitespace, or contain tabs or newlines. (e.g. Product)
]: any -> record<custom_field_option: record<custom_field_id: string, id: string, sort_key: int, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_field_options/($id)")
  let body = {sort_key: $sort_key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/custom_fields
# operationId: Custom Fields V2_List
export def "custom-fields List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_fields: table<catalog_type_id: string, created_at: string, description: string, field_type: string, filter_by: record, fixed_filter: record, group_by_catalog_attribute_id: string, helptext_catalog_attribute_id: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/custom_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/custom_fields
# operationId: Custom Fields V2_Create
# --filter_by shape: {catalog_attribute_id: string, custom_field_id: string}
# --fixed_filter shape: {catalog_attribute_id: string, values: list}
export def "custom-fields Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-type-id: string # For catalog fields, the ID of the associated catalog type (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  description: string # Description of the custom field (e.g. Which team is impacted by this issue)
  field_type: string@field-type-completer # Type of custom field (e.g. single_select)
  --filter-by: record # e.g. {catalog_attribute_id: 01H2FW182TAH0NHEVBY34SCAK0, custom_field_id: 01H2FW182TAH0NHEVBY34SCAK0} — shape: {catalog_attribute_id: string, custom_field_id: string}
  --fixed-filter: record # e.g. {catalog_attribute_id: 01H2FW182TAH0NHEVBY34SCAK0, values: [01H2FW182TAH0NHEVBY34SCAK0, 01H2FW182TAH0NHEVBY34SCAK1]} — shape: {catalog_attribute_id: string, values: list}
  --group-by-catalog-attribute-id: string # For catalog fields, the ID of the attribute used to group catalog entries (if applicable) (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  --helptext-catalog-attribute-id: string # Which catalog attribute provides helptext for the options (e.g. 01H2FW182TAH0NHEVBY34SCAK0)
  name: string # Human readable name for the custom field (e.g. Affected Team)
]: any -> record<custom_field: record<catalog_type_id: string, created_at: string, description: string, field_type: string, filter_by: record<catalog_attribute_id: string, custom_field_id: string>, fixed_filter: record<catalog_attribute_id: string, values: list>, group_by_catalog_attribute_id: string, helptext_catalog_attribute_id: string, id: string, name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/custom_fields")
  let body = {catalog_type_id: $catalog_type_id, description: $description, field_type: $field_type, filter_by: $filter_by, fixed_filter: $fixed_filter, group_by_catalog_attribute_id: $group_by_catalog_attribute_id, helptext_catalog_attribute_id: $helptext_catalog_attribute_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/custom_fields/{id}
# operationId: Custom Fields V2_Delete
export def "custom-fields Delete" [
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
  let full_url = (build-url $base $"/v2/custom_fields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/custom_fields/{id}
# operationId: Custom Fields V2_Show
export def "custom-fields Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_field: record<catalog_type_id: string, created_at: string, description: string, field_type: string, filter_by: record<catalog_attribute_id: string, custom_field_id: string>, fixed_filter: record<catalog_attribute_id: string, values: list>, group_by_catalog_attribute_id: string, helptext_catalog_attribute_id: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/custom_fields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/custom_fields/{id}
# operationId: Custom Fields V2_Update
# --filter_by shape: {catalog_attribute_id: string, custom_field_id: string}
# --fixed_filter shape: {catalog_attribute_id: string, values: list}
export def "custom-fields Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Description of the custom field (e.g. Which team is impacted by this issue)
  --filter-by: record # e.g. {catalog_attribute_id: 01H2FW182TAH0NHEVBY34SCAK0, custom_field_id: 01H2FW182TAH0NHEVBY34SCAK0} — shape: {catalog_attribute_id: string, custom_field_id: string}
  --fixed-filter: record # e.g. {catalog_attribute_id: 01H2FW182TAH0NHEVBY34SCAK0, values: [01H2FW182TAH0NHEVBY34SCAK0, 01H2FW182TAH0NHEVBY34SCAK1]} — shape: {catalog_attribute_id: string, values: list}
  --group-by-catalog-attribute-id: string # For catalog fields, the ID of the attribute used to group catalog entries (if applicable) (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  --helptext-catalog-attribute-id: string # Which catalog attribute provides helptext for the options (e.g. 01H2FW182TAH0NHEVBY34SCAK0)
  name: string # Human readable name for the custom field (e.g. Affected Team)
]: any -> record<custom_field: record<catalog_type_id: string, created_at: string, description: string, field_type: string, filter_by: record<catalog_attribute_id: string, custom_field_id: string>, fixed_filter: record<catalog_attribute_id: string, values: list>, group_by_catalog_attribute_id: string, helptext_catalog_attribute_id: string, id: string, name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/custom_fields/($id)")
  let body = {description: $description, filter_by: $filter_by, fixed_filter: $fixed_filter, group_by_catalog_attribute_id: $group_by_catalog_attribute_id, helptext_catalog_attribute_id: $helptext_catalog_attribute_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/escalation_paths
# operationId: Escalations V2_ListPaths
export def "escalation-paths ListPaths" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<escalation_paths: table<current_responders: list, id: string, name: string, path: list, repeat_config: record, team_ids: list, working_hours: list>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/escalation_paths" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/escalation_paths
# operationId: Escalations V2_CreatePath
# --path item shape: {delay?: record, id: string, if_else?: record, level?: record, notify_channel?: record, repeat?: record, type: "if_else"|"repeat"|"level"|"notify_channel"|"delay"}
# --repeat_config shape: {delay_repeat_on_activity: bool, repeat_after_seconds: int}
# --working_hours item shape: {id: string, name: string, timezone: string, weekday_intervals: list}
export def "escalation-paths CreatePath" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of this escalation path, for the user's reference. (e.g. Urgent Support)
  path: list # The nodes that form the levels and branches of this escalation path. (e.g. [{delay: {delay_interval_condition: active, delay_seconds: 300, delay_weekday_interval_config_id: 01FCNDV6P870EA6S7TK1DSYDG0}, id: 01FCNDV6P870EA6S7TK1DSYDG0, if_else: {conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}], else_path: [{}], then_path: [{}]}, level: {ack_mode: all, round_robin_config: {enabled: false, rotate_after_seconds: 120}, targets: [{id: lawrencejones, schedule_mode: currently_on_call, selected_rota_id: 01FCNDV6P870EA6S7TK1DSYDG0, type: schedule, urgency: high}], time_to_ack_interval_condition: active, time_to_ack_seconds: 1800, time_to_ack_weekday_interval_config_id: 01FCNDV6P870EA6S7TK1DSYDG0}, notify_channel: {targets: [{id: lawrencejones, schedule_mode: currently_on_call, selected_rota_id: 01FCNDV6P870EA6S7TK1DSYDG0, type: schedule, urgency: high}], time_to_ack_interval_condition: active, time_to_ack_seconds: 1800, time_to_ack_weekday_interval_config_id: 01FCNDV6P870EA6S7TK1DSYDG0}, repeat: {repeat_times: 3, to_node: 01FCNDV6P870EA6S7TK1DSYDG0}, type: if_else}]) — item shape: {delay?: record, id: string, if_else?: record, level?: record, notify_channel?: record, repeat?: record, type: "if_else"|"repeat"|"level"|"notify_channel"|"delay"}
  --repeat-config: record # e.g. {delay_repeat_on_activity: false, repeat_after_seconds: 1800} — shape: {delay_repeat_on_activity: bool, repeat_after_seconds: int}
  --team-ids: list # IDs of the teams that own this escalation path. This will automatically sync escalation paths with the right teams in Catalog. If you have an escalation paths attribute on your Teams, this attribute is required. (e.g. [01JPQA75EPNEES4479P16P4XAB])
  --working-hours: list # The working hours for this escalation path. (e.g. [{id: abc123, name: abc123, timezone: abc123, weekday_intervals: [{end_time: 17:00, start_time: 09:00, weekday: monday}]}]) — item shape: {id: string, name: string, timezone: string, weekday_intervals: list}
]: any -> record<escalation_path: record<current_responders: list<record>, id: string, name: string, path: list<record>, repeat_config: record<delay_repeat_on_activity: bool, repeat_after_seconds: int>, team_ids: list<string>, working_hours: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/escalation_paths")
  let body = {name: $name, path: $path, repeat_config: $repeat_config, team_ids: $team_ids, working_hours: $working_hours} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/escalation_paths/{id}
# operationId: Escalations V2_DestroyPath
export def "escalation-paths DestroyPath" [
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
  let full_url = (build-url $base $"/v2/escalation_paths/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/escalation_paths/{id}
# operationId: Escalations V2_ShowPath
export def "escalation-paths ShowPath" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<escalation_path: record<current_responders: list<record>, id: string, name: string, path: list<record>, repeat_config: record<delay_repeat_on_activity: bool, repeat_after_seconds: int>, team_ids: list<string>, working_hours: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/escalation_paths/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/escalation_paths/{id}
# operationId: Escalations V2_UpdatePath
# --path item shape: {delay?: record, id: string, if_else?: record, level?: record, notify_channel?: record, repeat?: record, type: "if_else"|"repeat"|"level"|"notify_channel"|"delay"}
# --repeat_config shape: {delay_repeat_on_activity: bool, repeat_after_seconds: int}
# --working_hours item shape: {id: string, name: string, timezone: string, weekday_intervals: list}
export def "escalation-paths UpdatePath" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of this escalation path, for the user's reference. (e.g. Urgent Support)
  path: list # The nodes that form the levels and branches of this escalation path. (e.g. [{delay: {delay_interval_condition: active, delay_seconds: 300, delay_weekday_interval_config_id: 01FCNDV6P870EA6S7TK1DSYDG0}, id: 01FCNDV6P870EA6S7TK1DSYDG0, if_else: {conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}], else_path: [{}], then_path: [{}]}, level: {ack_mode: all, round_robin_config: {enabled: false, rotate_after_seconds: 120}, targets: [{id: lawrencejones, schedule_mode: currently_on_call, selected_rota_id: 01FCNDV6P870EA6S7TK1DSYDG0, type: schedule, urgency: high}], time_to_ack_interval_condition: active, time_to_ack_seconds: 1800, time_to_ack_weekday_interval_config_id: 01FCNDV6P870EA6S7TK1DSYDG0}, notify_channel: {targets: [{id: lawrencejones, schedule_mode: currently_on_call, selected_rota_id: 01FCNDV6P870EA6S7TK1DSYDG0, type: schedule, urgency: high}], time_to_ack_interval_condition: active, time_to_ack_seconds: 1800, time_to_ack_weekday_interval_config_id: 01FCNDV6P870EA6S7TK1DSYDG0}, repeat: {repeat_times: 3, to_node: 01FCNDV6P870EA6S7TK1DSYDG0}, type: if_else}]) — item shape: {delay?: record, id: string, if_else?: record, level?: record, notify_channel?: record, repeat?: record, type: "if_else"|"repeat"|"level"|"notify_channel"|"delay"}
  --repeat-config: record # e.g. {delay_repeat_on_activity: false, repeat_after_seconds: 1800} — shape: {delay_repeat_on_activity: bool, repeat_after_seconds: int}
  --team-ids: list # IDs of the teams that own this escalation path. This will automatically sync escalation paths with the right teams in Catalog. If you have an escalation paths attribute on your Teams, this attribute is required. (e.g. [01JPQA75EPNEES4479P16P4XAB])
  --working-hours: list # The working hours for this escalation path. (e.g. [{id: abc123, name: abc123, timezone: abc123, weekday_intervals: [{end_time: 17:00, start_time: 09:00, weekday: monday}]}]) — item shape: {id: string, name: string, timezone: string, weekday_intervals: list}
]: any -> record<escalation_path: record<current_responders: list<record>, id: string, name: string, path: list<record>, repeat_config: record<delay_repeat_on_activity: bool, repeat_after_seconds: int>, team_ids: list<string>, working_hours: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/escalation_paths/($id)")
  let body = {name: $name, path: $path, repeat_config: $repeat_config, team_ids: $team_ids, working_hours: $working_hours} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/escalations
# operationId: Escalations V2_List
export def "escalations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Number of escalations to return per page (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An escalation's ID. This endpoint will return a list of escalations after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
  --escalation-path: record # Filter on the escalation path for which the escalation was triggered. Accepted operators are 'one_of' and 'not_in'. (e.g. {one_of: [01J479052SSQAA4531ASFPR3BF]}, allows empty value)
  --status: record # Filter on the status of the escalation. Accepted operators are 'one_of' and 'not_in'. (e.g. {one_of: [triggered]}, allows empty value)
  --alert: record # Filter on the alert that created an escalation. Accepted operators are 'one_of' and 'not_in'. (e.g. {one_of: [01J479052SSQAA4531ASFPR3BF]}, allows empty value)
  --created-at: record # Filter on the created_at timestamp of the escalation. Accepted operators are 'gte', 'lte' and 'date_range'. (e.g. {gte: [2021-08-17]}, allows empty value)
  --updated-at: record # Filter on the updated_at timestamp of the escalation. Accepted operators are 'gte', 'lte' and 'date_range'. (e.g. {gte: [2021-08-17]}, allows empty value)
  --idempotency-key: record # Filter on the idempotency key of the escalation. This is the key set when creating escalations via the API, and is distinct from alert deduplication keys. Accepted operators are 'is' for exact matches and 'starts_with' for prefix matching. (e.g. {starts_with: [team-a:]}, allows empty value)
]: nothing -> record<escalations: table<created_at: string, creator: record, escalation_path_id: string, events: list, id: string, priority: record, related_alerts: list, related_incidents: list, status: string, title: string, updated_at: string>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "escalation_path" $escalation_path "multi") (serialize-qp "status" $status "multi") (serialize-qp "alert" $alert "multi") (serialize-qp "created_at" $created_at "multi") (serialize-qp "updated_at" $updated_at "multi") (serialize-qp "idempotency_key" $idempotency_key "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/escalations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/escalations
# operationId: Escalations V2_Create
export def "escalations Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Additional details about the escalation (e.g. Database CPU has been above 90% for 5 minutes)
  --escalation-path-id: string # ID of the escalation path to follow (e.g. 01H0J1EXE7AXZ2C93K61WBPYEH)
  idempotency_key: string # Unique key to prevent duplicate escalations. If this key has already been used, the existing escalation will be returned. (e.g. 2024-01-15-abc123)
  --incident-id: string # ID of an incident to associate with this escalation. The linked incident will appear in the escalation's related_incidents field. (e.g. 01H0J1EXE7AXZ2C93K61WBPYEH)
  title: string # The title of the escalation. This message will be included in all notifications about this escalation. (e.g. Production database experiencing high CPU)
  --user-ids: list # IDs of users to escalate directly to (e.g. [01H0J1EXE7AXZ2C93K61WBPYEH, 01H0J1EXE7AXZ2C93K61WBPYEI])
]: any -> record<escalation: record<created_at: string, creator: record<alert: record, user: record, workflow: record>, escalation_path_id: string, events: list<record>, id: string, priority: record<name: string>, related_alerts: list<record>, related_incidents: list<record>, status: string, title: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/escalations")
  let body = {description: $description, escalation_path_id: $escalation_path_id, idempotency_key: $idempotency_key, incident_id: $incident_id, title: $title, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show
#
# GET /v2/escalations/{id}
# operationId: Escalations V2_Show
export def "escalations Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<escalation: record<created_at: string, creator: record<alert: record, user: record, workflow: record>, escalation_path_id: string, events: list<record>, id: string, priority: record<name: string>, related_alerts: list<record>, related_incidents: list<record>, status: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/escalations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/follow_ups
# operationId: Follow-ups V2_List
export def "follow-ups List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --incident-id: string # Find follow-ups related to this incident (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --incident-mode: string@incident-mode-completer # Filter to follow-ups from incidents of the given mode. If not set, only follow-ups from `standard` and `retrospective` incidents are returned (e.g. standard, allows empty value)
  --assignee-team-id: string # Filter follow-ups that are assigned to the given team (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
]: nothing -> record<follow_ups: table<assignee: record, assignee_team: record, completed_at: string, created_at: string, creator: record, description: string, external_issue_reference: record, id: string, incident_id: string, labels: list, priority: record, status: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "incident_mode" $incident_mode "scalar") (serialize-qp "assignee_team_id" $assignee_team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/follow_ups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/follow_ups/{id}
# operationId: Follow-ups V2_Show
export def "follow-ups Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<follow_up: record<assignee: record<email: string, id: string, name: string, role: string, slack_user_id: string>, assignee_team: record<id: string, name: string>, completed_at: string, created_at: string, creator: record<alert: record, api_key: record, user: record, workflow: record>, description: string, external_issue_reference: record<issue_name: string, issue_permalink: string, provider: string>, id: string, incident_id: string, labels: list<string>, priority: record<description: string, id: string, name: string, rank: int>, status: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/follow_ups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping (GET)
#
# GET /v2/heartbeat/{alert_source_config_id}/ping
# operationId: Heartbeat V2_Ping#1
export def "heartbeat-ping Ping1" [
  alert_source_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Token provided via the token query parameter (e.g. some-random-string, allows empty value)
  --authorization: string # Bearer token provided via the Authorization header (e.g. Bearer some-random-string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/heartbeat/($alert_source_config_id)/ping" $qp)
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping (POST)
#
# POST /v2/heartbeat/{alert_source_config_id}/ping
# operationId: Heartbeat V2_Ping
export def "heartbeat-ping Ping" [
  alert_source_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Token provided via the token query parameter (e.g. some-random-string, allows empty value)
  --authorization: string # Bearer token provided via the Authorization header (e.g. Bearer some-random-string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/heartbeat/($alert_source_config_id)/ping" $qp)
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v1/incident_attachments
# operationId: Incident Attachments V1_List
export def "incident-attachments List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --incident-id: string # Incident that this attachment is against (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH, allows empty value)
  --external-id: string # ID of the resource in the external system (e.g. 123, allows empty value)
  --resource-type: string@resource-type-completer # E.g. PagerDuty: the external system that holds the resource (e.g. pager_duty_incident, allows empty value)
]: nothing -> record<incident_attachments: table<id: string, incident_id: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incident_attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/incident_attachments
# operationId: Incident Attachments V1_Create
# --resource shape: {external_id?: string, resource_type: "pager_duty_incident"|"opsgenie_alert"|"datadog_monitor_alert"|"github_pull_request"|"gitlab_merge_request"|"sentry_issue"|"jira_issue"|"jsm_alert"|"atlassian_statuspage_incident"|"zendesk_ticket"|"google_calendar_event"|"outlook_calendar_event"|"slack_file"|"salesforce_case"|"scrubbed"|"statuspage_incident", url?: string}
export def "incident-attachments Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  incident_id: string # ID of the incident to add an attachment to (e.g. 01FDAG4SAP5TYPT98WGR2N7W91)
  resource: record # e.g. {external_id: 123, resource_type: pager_duty_incident, url: https://github.com/company/repo/pull/123} — shape: {external_id?: string, resource_type: "pager_duty_incident"|"opsgenie_alert"|"datadog_monitor_alert"|"github_pull_request"|"gitlab_merge_request"|"sentry_issue"|"jira_issue"|"jsm_alert"|"atlassian_statuspage_incident"|"zendesk_ticket"|"google_calendar_event"|"outlook_calendar_event"|"slack_file"|"salesforce_case"|"scrubbed"|"statuspage_incident", url?: string}
]: any -> record<incident_attachment: record<id: string, incident_id: string, resource: record<external_id: string, permalink: string, resource_type: string, title: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_attachments")
  let body = {incident_id: $incident_id, resource: $resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/incident_attachments/{id}
# operationId: Incident Attachments V1_Delete
export def "incident-attachments Delete" [
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
  let full_url = (build-url $base $"/v1/incident_attachments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/incident_memberships
# operationId: Incident Memberships V1_Create
export def "incident-memberships Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  incident_id: string # e.g. 01ET65M7ZADYFCKD4K1AE2QNMC
  user_id: string # e.g. 01FCQSP07Z74QMMYPDDGQB9FTG
]: any -> record<incident_membership: record<created_at: string, id: string, incident_id: string, updated_at: string, user: record<email: string, id: string, name: string, role: string, slack_user_id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_memberships")
  let body = {incident_id: $incident_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke
#
# POST /v1/incident_memberships/actions/revoke
# operationId: Incident Memberships V1_Revoke
export def "incident-memberships-actions-revoke Revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  incident_id: string # Revoke memberships to incident (e.g. 01FCNDV6P870EA6S7TK1DSYD5H)
  user_id: string # e.g. 01FCQSP07Z74QMMYPDDGQB9FTG
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_memberships/actions/revoke")
  let body = {incident_id: $incident_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/incident_relationships
# operationId: Incident Relationships V1_List
export def "incident-relationships List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --incident-id: string # ID of the incident to find relationships for (e.g. 01FCNDV6P870EA6S7TK1DSYD5H, allows empty value)
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<incident_relationships: table<id: string, incident: record>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incident_relationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/incident_roles
# operationId: Incident Roles V2_List
export def "incident-roles List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_roles: table<created_at: string, description: string, id: string, instructions: string, name: string, role_type: string, shortform: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/incident_roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/incident_roles
# operationId: Incident Roles V2_Create
export def "incident-roles Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Describes the purpose of the role (e.g. The person currently coordinating the incident)
  instructions: string # Provided to whoever is nominated for the role. Note that this will be empty for the 'reporter' role. (e.g. Take point on the incident; Make sure people are clear on responsibilities)
  name: string # Human readable name of the incident role (e.g. Incident Lead)
  shortform: string # Short human readable name for Slack. Note that this will be empty for the 'reporter' role. (e.g. lead)
]: any -> record<incident_role: record<created_at: string, description: string, id: string, instructions: string, name: string, role_type: string, shortform: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/incident_roles")
  let body = {description: $description, instructions: $instructions, name: $name, shortform: $shortform} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/incident_roles/{id}
# operationId: Incident Roles V2_Delete
export def "incident-roles Delete" [
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
  let full_url = (build-url $base $"/v2/incident_roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/incident_roles/{id}
# operationId: Incident Roles V2_Show
export def "incident-roles Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_role: record<created_at: string, description: string, id: string, instructions: string, name: string, role_type: string, shortform: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/incident_roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/incident_roles/{id}
# operationId: Incident Roles V2_Update
export def "incident-roles Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Describes the purpose of the role (e.g. The person currently coordinating the incident)
  instructions: string # Provided to whoever is nominated for the role. Note that this will be empty for the 'reporter' role. (e.g. Take point on the incident; Make sure people are clear on responsibilities)
  name: string # Human readable name of the incident role (e.g. Incident Lead)
  shortform: string # Short human readable name for Slack. Note that this will be empty for the 'reporter' role. (e.g. lead)
]: any -> record<incident_role: record<created_at: string, description: string, id: string, instructions: string, name: string, role_type: string, shortform: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/incident_roles/($id)")
  let body = {description: $description, instructions: $instructions, name: $name, shortform: $shortform} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/incident_statuses
# operationId: Incident Statuses V1_List
export def "incident-statuses List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_statuses: table<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/incident_statuses
# operationId: Incident Statuses V1_Create
export def "incident-statuses Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer # Whether the status should be considered 'live' (now renamed to active), 'learning' (now renamed to post-incident) or 'closed'. The triage and declined statuses cannot be created or modified. (e.g. live)
  description: string # Rich text description of the incident status (e.g. Impact has been **fully mitigated**, and we're ready to learn from this incident.)
  name: string # Unique name of this status (e.g. Closed)
]: any -> record<incident_status: record<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_statuses")
  let body = {category: $category, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/incident_statuses/{id}
# operationId: Incident Statuses V1_Delete
export def "incident-statuses Delete" [
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
  let full_url = (build-url $base $"/v1/incident_statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/incident_statuses/{id}
# operationId: Incident Statuses V1_Show
export def "incident-statuses Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_status: record<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/incident_statuses/{id}
# operationId: Incident Statuses V1_Update
export def "incident-statuses Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Rich text description of the incident status (e.g. Impact has been **fully mitigated**, and we're ready to learn from this incident.)
  name: string # Unique name of this status (e.g. Closed)
]: any -> record<incident_status: record<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_statuses/($id)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/incident_timestamps
# operationId: Incident Timestamps V2_List
export def "incident-timestamps List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_timestamps: table<id: string, name: string, rank: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/incident_timestamps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/incident_timestamps/{id}
# operationId: Incident Timestamps V2_Show
export def "incident-timestamps Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_timestamp: record<id: string, name: string, rank: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/incident_timestamps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v1/incident_types
# operationId: Incident Types V1_List
export def "incident-types List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_types: table<create_in_triage: string, created_at: string, description: string, id: string, is_default: bool, name: string, private_incidents_only: bool, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/incident_types/{id}
# operationId: Incident Types V1_Show
export def "incident-types Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident_type: record<create_in_triage: string, created_at: string, description: string, id: string, is_default: bool, name: string, private_incidents_only: bool, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/incident_updates
# operationId: Incident Updates V2_List
export def "incident-updates List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --incident-id: string # Incident whose updates you want to list (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH, allows empty value)
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<incident_updates: table<created_at: string, id: string, incident_id: string, merged_into_incident_id: string, message: string, new_incident_status: record, new_severity: record, updater: record>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/incident_updates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/incidents
# operationId: Incidents V2_List
export def "incidents List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An incident's ID. This endpoint will return a list of incidents after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
  --sort-by: string@sort-by-completer # What order to return results in. (default: created_at_newest_first, e.g. created_at_newest_first, allows empty value)
  --filter-mode: string@filter-mode-completer # How to combine the filters: 'all' combines them with AND logic (all must match), 'any' combines them with OR logic (any can match). Defaults to 'all'. (e.g. all, allows empty value)
  --status: record # Filter on incident status. The accepted operators are 'one_of', or 'not_in'. (e.g. {one_of: [01GBSQF3FHF7FWZQNWGHAVQ804]}, allows empty value)
  --status-category: record # Filter on the category of the incidents status. The accepted operators are 'one_of', or 'not_in'. (e.g. {one_of: [active]}, allows empty value)
  --created-at: record # Filter on incident created at timestamp. The accepted operators are 'gte', 'lte' and 'date_range'. (e.g. {created_at[gte]: [2024-05-01]}, allows empty value)
  --updated-at: record # Filter on incident updated at timestamp. The accepted operators are 'gte', 'lte' and 'date_range'. (e.g. {updated_at[gte]: [2024-05-01]}, allows empty value)
  --severity: record # Filter on incident severity. The accepted operators are 'one_of', 'not_in', 'gte', 'lte'. (e.g. {one_of: [01GBSQF3FHF7FWZQNWGHAVQ804]}, allows empty value)
  --incident-type: record # Filter on incident type. The accepted operators are 'one_of, or 'not_in'. (e.g. {one_of: [01GBSQF3FHF7FWZQNWGHAVQ804]}, allows empty value)
  --incident-role: record # Filter on an incident role. Role ID should be sent, along with backlink attribute ID (if needed) followed by the operator and values. The accepted operators are 'one_of', 'is_blank'. (e.g. {01GBSQF3FHF7FWZQNWGHAVQ804: {one_of: [01GBSQF3FHF7FWZQNWGHAVQ804, 01ET65M7ZARSFZ6TFDFVQDN9AA]}}, allows empty value)
  --custom-field: record # Filter on an incident custom field. Custom field ID should be sent, followed by the operator and values. Accepted operator will depend on the custom field type. (e.g. {01GBSQF3FHF7FWZQNWGHAVQ804: {one_of: [01GBSQF3FHF7FWZQNWGHAVQ804, 01ET65M7ZARSFZ6TFDFVQDN9AA]}}, allows empty value)
  --mode: record # Filter on incident mode. The accepted operator is 'one_of'.  If this is not provided, this value defaults to `{"one_of": ["standard", "retrospective"] }`, meaning that test and tutorial incidents are not included. (e.g. {one_of: [retrospective]}, allows empty value)
]: nothing -> record<incidents: table<call_url: string, created_at: string, creator: record, custom_field_entries: list, duration_metrics: list, external_issue_reference: record, has_debrief: bool, id: string, incident_role_assignments: list, incident_status: record, incident_timestamp_values: list, incident_type: record, mode: string, name: string, permalink: string, postmortem_document_ids: list, postmortem_document_url: string, reference: string, severity: record, slack_channel_id: string, slack_channel_name: string, slack_team_id: string, summary: string, updated_at: string, visibility: string, workload_minutes_late: float, workload_minutes_sleeping: float, workload_minutes_total: float, workload_minutes_working: float>, pagination_meta: record<after: string, page_size: int, total_record_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "filter_mode" $filter_mode "scalar") (serialize-qp "status" $status "multi") (serialize-qp "status_category" $status_category "multi") (serialize-qp "created_at" $created_at "multi") (serialize-qp "updated_at" $updated_at "multi") (serialize-qp "severity" $severity "multi") (serialize-qp "incident_type" $incident_type "multi") (serialize-qp "incident_role" $incident_role "multi") (serialize-qp "custom_field" $custom_field "multi") (serialize-qp "mode" $mode "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/incidents
# operationId: Incidents V2_Create
# --custom_field_entries item shape: {custom_field_id: string, values: list}
# --incident_role_assignments item shape: {assignee?: record, incident_role_id: string}
# --incident_timestamp_values item shape: {incident_timestamp_id: string, value?: string}
# --retrospective_incident_options shape: {external_id?: int, postmortem_document_url?: string, slack_channel_id?: string}
export def "incidents Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-field-entries: list # Set the incident's custom fields to these values (e.g. [{custom_field_id: 01FCNDV6P870EA6S7TK1DSYDG0, values: [{id: 01FCNDV6P870EA6S7TK1DSYDG0, value_catalog_entry_id: 01FCNDV6P870EA6S7TK1DSYDG0, value_link: https://google.com/, value_numeric: 123.456, value_option_id: 01FCNDV6P870EA6S7TK1DSYDG0, value_text: This is my text field, I hope you like it, value_timestamp: }]}]) — item shape: {custom_field_id: string, values: list}
  idempotency_key: string # Unique string used to de-duplicate incident create requests (e.g. alert-uuid)
  --incident-role-assignments: list # Assign incident roles to these people (e.g. [{assignee: {email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123}, incident_role_id: 01FH5TZRWMNAFB0DZ23FD1TV96}]) — item shape: {assignee?: record, incident_role_id: string}
  --incident-status-id: string # Incident status to assign to the incident (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH)
  --incident-timestamp-values: list # Assign the incident's timestamps to these values (e.g. [{incident_timestamp_id: 01FCNDV6P870EA6S7TK1DSYD5H, value: 2021-08-17T13:28:57.801578Z}]) — item shape: {incident_timestamp_id: string, value?: string}
  --incident-type-id: string # Incident type to create this incident as (e.g. 01FH5TZRWMNAFB0DZ23FD1TV96)
  --mode: string@mode-completer # Whether the incident is real, a test, a tutorial, or importing as a retrospective incident (e.g. standard)
  --name: string # Explanation of the incident (e.g. Our database is sad)
  --retrospective-incident-options: record # e.g. {external_id: 123, postmortem_document_url: https://docs.google.com/my_doc_id, slack_channel_id: abc123} — shape: {external_id?: int, postmortem_document_url?: string, slack_channel_id?: string}
  --severity-id: string # Severity to create incident as (e.g. 01FH5TZRWMNAFB0DZ23FD1TV96)
  --slack-channel-name-override: string # Name of the Slack channel to create for this incident (e.g. inc-123-database-down)
  --slack-team-id: string # Slack Team to create the incident in (e.g. T02A1FSLE8J)
  --summary: string # Detailed description of the incident (e.g. Our database is really really sad, and we don't know why yet.)
  visibility: string@visibility-completer # Whether the incident should be open to anyone in your Slack workspace (public), or invite-only (private). For more information on Private Incidents see our [docs](https://docs.incident.io/incidents/sensitive-incidents). (e.g. public)
]: any -> record<incident: record<call_url: string, created_at: string, creator: record<alert: record, api_key: record, user: record, workflow: record>, custom_field_entries: list<record>, duration_metrics: list<record>, external_issue_reference: record<issue_name: string, issue_permalink: string, provider: string>, has_debrief: bool, id: string, incident_role_assignments: list<record>, incident_status: record<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>, incident_timestamp_values: list<record>, incident_type: record<create_in_triage: string, created_at: string, description: string, id: string, is_default: bool, name: string, private_incidents_only: bool, updated_at: string>, mode: string, name: string, permalink: string, postmortem_document_ids: list<string>, postmortem_document_url: string, reference: string, severity: record<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>, slack_channel_id: string, slack_channel_name: string, slack_team_id: string, summary: string, updated_at: string, visibility: string, workload_minutes_late: float, workload_minutes_sleeping: float, workload_minutes_total: float, workload_minutes_working: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/incidents")
  let body = {custom_field_entries: $custom_field_entries, idempotency_key: $idempotency_key, incident_role_assignments: $incident_role_assignments, incident_status_id: $incident_status_id, incident_timestamp_values: $incident_timestamp_values, incident_type_id: $incident_type_id, mode: $mode, name: $name, retrospective_incident_options: $retrospective_incident_options, severity_id: $severity_id, slack_channel_name_override: $slack_channel_name_override, slack_team_id: $slack_team_id, summary: $summary, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show
#
# GET /v2/incidents/{id}
# operationId: Incidents V2_Show
export def "incidents Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incident: record<call_url: string, created_at: string, creator: record<alert: record, api_key: record, user: record, workflow: record>, custom_field_entries: list<record>, duration_metrics: list<record>, external_issue_reference: record<issue_name: string, issue_permalink: string, provider: string>, has_debrief: bool, id: string, incident_role_assignments: list<record>, incident_status: record<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>, incident_timestamp_values: list<record>, incident_type: record<create_in_triage: string, created_at: string, description: string, id: string, is_default: bool, name: string, private_incidents_only: bool, updated_at: string>, mode: string, name: string, permalink: string, postmortem_document_ids: list<string>, postmortem_document_url: string, reference: string, severity: record<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>, slack_channel_id: string, slack_channel_name: string, slack_team_id: string, summary: string, updated_at: string, visibility: string, workload_minutes_late: float, workload_minutes_sleeping: float, workload_minutes_total: float, workload_minutes_working: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/incidents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit
#
# POST /v2/incidents/{id}/actions/edit
# operationId: Incidents V2_Edit
# --incident shape: {call_url?: string, custom_field_entries?: list, incident_role_assignments?: list, incident_status_id?: string, incident_timestamp_values?: list, name?: string, severity_id?: string, slack_channel_name_override?: string, summary?: string}
export def "incidents-actions-edit Edit" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  incident: record # e.g. {call_url: https://zoom.us/foo, custom_field_entries: [{custom_field_id: 01FCNDV6P870EA6S7TK1DSYDG0, values: [{id: 01FCNDV6P870EA6S7TK1DSYDG0, value_catalog_entry_id: 01FCNDV6P870EA6S7TK1DSYDG0, value_link: https://google.com/, value_numeric: 123.456, value_option_id: 01FCNDV6P870EA6S7TK1DSYDG0, value_text: This is my text field, I hope you like it, value_timestamp: }]}], incident_role_assignments: [{assignee: {email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123}, incident_role_id: 01FH5TZRWMNAFB0DZ23FD1TV96}], incident_status_id: abc123, incident_timestamp_values: [{incident_timestamp_id: 01FCNDV6P870EA6S7TK1DSYD5H, value: 2021-08-17T13:28:57.801578Z}], name: Our database is sad, severity_id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_channel_name_override: inc-123-database-down, summary: Our database is really really sad, and we don't know why yet.} — shape: {call_url?: string, custom_field_entries?: list, incident_role_assignments?: list, incident_status_id?: string, incident_timestamp_values?: list, name?: string, severity_id?: string, slack_channel_name_override?: string, summary?: string}
  --notify-incident-channel: oneof<nothing, bool> # Should we send Slack channel notifications to inform responders of this update? Note that this won't work if the Slack channel has already been archived. (e.g. true)
]: any -> record<incident: record<call_url: string, created_at: string, creator: record<alert: record, api_key: record, user: record, workflow: record>, custom_field_entries: list<record>, duration_metrics: list<record>, external_issue_reference: record<issue_name: string, issue_permalink: string, provider: string>, has_debrief: bool, id: string, incident_role_assignments: list<record>, incident_status: record<category: string, created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>, incident_timestamp_values: list<record>, incident_type: record<create_in_triage: string, created_at: string, description: string, id: string, is_default: bool, name: string, private_incidents_only: bool, updated_at: string>, mode: string, name: string, permalink: string, postmortem_document_ids: list<string>, postmortem_document_url: string, reference: string, severity: record<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>, slack_channel_id: string, slack_channel_name: string, slack_team_id: string, summary: string, updated_at: string, visibility: string, workload_minutes_late: float, workload_minutes_sleeping: float, workload_minutes_total: float, workload_minutes_working: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/incidents/($id)/actions/edit")
  let body = {incident: $incident, notify_incident_channel: $notify_incident_channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import postmortem document
#
# POST /v2/incidents/{id}/actions/import_postmortem_document
# operationId: Incidents V2_ImportPostmortemDocument
export def "incidents-actions-import-postmortem-document ImportPostmortemDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The document content as GitHub-Flavored Markdown (e.g. ## Summary  A database migration caused increased latency...)
  title: string # Title of the postmortem document (e.g. INC-123: Post-incident review)
]: any -> record<postmortem_document: record<created_at: string, document_url: string, editors: list<record>, exported_urls: list<string>, id: string, incident_id: string, status: string, title: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/incidents/($id)/actions/import_postmortem_document")
  let body = {content: $content, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show
#
# GET /v1/ip_allowlists
# operationId: IPAllowlists V1_ShowIPAllowlist
export def "ip-allowlists ShowIPAllowlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ip_allowlist: record<allowlist: list<record>, enabled: bool, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ip_allowlists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/ip_allowlists
# operationId: IPAllowlists V1_UpdateIPAllowlist
# --allowlist item shape: {label?: string, value: string}
export def "ip-allowlists UpdateIPAllowlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  allowlist: list # A list of IP addresses or CIDR prefixes to allow (e.g. [{label: London HQ, value: 192.0.2.0}]) — item shape: {label?: string, value: string}
  --enabled: oneof<nothing, bool> # Whether this IP allowlist is enabled or not (e.g. true)
  version: int # The version of this IP allowlist (format: int64, e.g. 1)
]: any -> record<ip_allowlist: record<allowlist: list<record>, enabled: bool, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ip_allowlists")
  let body = {allowlist: $allowlist, enabled: $enabled, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/maintenance_windows
# operationId: MaintenanceWindows V1_List
export def "maintenance-windows List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Number of maintenance windows to return per page (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # The ID of the last maintenance window on the previous page (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --status: string@status-completer-1 # Filter by window status: active (start_at <= now < end_at), upcoming (now < start_at), or past (end_at <= now) (e.g. active, allows empty value)
]: nothing -> record<maintenance_windows: table<alert_condition_groups: list, archived_at: string, created_at: string, end_at: string, escalation_targets: list, id: string, incident_id: string, lead: record, name: string, notification_message: string, notify_channels: list, notify_end_minutes_before: int, notify_start_minutes_before: int, reroute_on_end: bool, resolve_on_end: bool, show_in_sidebar: bool, start_at: string, updated_at: string>, pagination_meta: record<after: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/maintenance_windows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/maintenance_windows
# operationId: MaintenanceWindows V1_Create
# --alert_condition_groups item shape: {conditions: list}
# --escalation_targets item shape: {escalation_paths?: record, users?: record}
# --lead shape: {email?: string, id?: string, slack_user_id?: string}
# --notify_channels item shape: {channel_id: string, channel_name?: string, channel_type: string}
export def "maintenance-windows Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alert_condition_groups: list # Condition groups that determine which alerts this maintenance window applies to (e.g. [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]) — item shape: {conditions: list}
  end_at: string # When the maintenance window should end (format: date-time, e.g. 2021-08-17T14:28:57.801578Z)
  --escalation-targets: list # If set, alerts matching this window will be escalated to these targets (e.g. [{escalation_paths: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, users: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}]) — item shape: {escalation_paths?: record, users?: record}
  --incident-id: string # If set, alerts matching this window will be automatically attached to this incident (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  lead: record # e.g. {email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123} — shape: {email?: string, id?: string, slack_user_id?: string}
  name: string # Human readable name for the maintenance window (e.g. Planned database migration)
  --notification-message: string # Custom message included in notifications about this maintenance window (e.g. Scheduled downtime for database migration)
  --notify-channels: list # Channels to notify about the maintenance window starting and ending (e.g. [{channel_id: C0ACTHQMHS8, channel_name: general, channel_type: public}]) — item shape: {channel_id: string, channel_name?: string, channel_type: string}
  --notify-end-minutes-before: int # Minutes before the end to send a notification to the configured channels (format: int64, e.g. 5)
  --notify-start-minutes-before: int # Minutes before the start to send a notification to the configured channels (format: int64, e.g. 15)
  --reroute-on-end: oneof<nothing, bool> # Whether to retrigger firing alerts through alert routing when the window ends (e.g. false)
  --resolve-on-end: oneof<nothing, bool> # Whether to automatically resolve all firing alerts that matched this window when it ends (e.g. false)
  --show-in-sidebar: oneof<nothing, bool> # Whether to show this maintenance window in the dashboard sidebar when active (e.g. true)
  start_at: string # When the maintenance window should start (format: date-time, e.g. 2021-08-17T13:28:57.801578Z)
]: any -> record<maintenance_window: record<alert_condition_groups: list<record>, archived_at: string, created_at: string, end_at: string, escalation_targets: list<record>, id: string, incident_id: string, lead: record<alert: record, api_key: record, user: record, workflow: record>, name: string, notification_message: string, notify_channels: list<record>, notify_end_minutes_before: int, notify_start_minutes_before: int, reroute_on_end: bool, resolve_on_end: bool, show_in_sidebar: bool, start_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/maintenance_windows")
  let body = {alert_condition_groups: $alert_condition_groups, end_at: $end_at, escalation_targets: $escalation_targets, incident_id: $incident_id, lead: $lead, name: $name, notification_message: $notification_message, notify_channels: $notify_channels, notify_end_minutes_before: $notify_end_minutes_before, notify_start_minutes_before: $notify_start_minutes_before, reroute_on_end: $reroute_on_end, resolve_on_end: $resolve_on_end, show_in_sidebar: $show_in_sidebar, start_at: $start_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/maintenance_windows/{id}
# operationId: MaintenanceWindows V1_Delete
export def "maintenance-windows Delete" [
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
  let full_url = (build-url $base $"/v1/maintenance_windows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/maintenance_windows/{id}
# operationId: MaintenanceWindows V1_Show
export def "maintenance-windows Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<maintenance_window: record<alert_condition_groups: list<record>, archived_at: string, created_at: string, end_at: string, escalation_targets: list<record>, id: string, incident_id: string, lead: record<alert: record, api_key: record, user: record, workflow: record>, name: string, notification_message: string, notify_channels: list<record>, notify_end_minutes_before: int, notify_start_minutes_before: int, reroute_on_end: bool, resolve_on_end: bool, show_in_sidebar: bool, start_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance_windows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/maintenance_windows/{id}
# operationId: MaintenanceWindows V1_Update
# --alert_condition_groups item shape: {conditions: list}
# --escalation_targets item shape: {escalation_paths?: record, users?: record}
# --lead shape: {email?: string, id?: string, slack_user_id?: string}
# --notify_channels item shape: {channel_id: string, channel_name?: string, channel_type: string}
export def "maintenance-windows Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alert_condition_groups: list # Condition groups that determine which alerts this maintenance window applies to (e.g. [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]) — item shape: {conditions: list}
  end_at: string # When the maintenance window should end (format: date-time, e.g. 2021-08-17T14:28:57.801578Z)
  --escalation-targets: list # If set, alerts matching this window will be escalated to these targets (e.g. [{escalation_paths: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}, users: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}]) — item shape: {escalation_paths?: record, users?: record}
  --incident-id: string # If set, alerts matching this window will be automatically attached to this incident (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
  lead: record # e.g. {email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123} — shape: {email?: string, id?: string, slack_user_id?: string}
  name: string # Human readable name for the maintenance window (e.g. Planned database migration)
  --notification-message: string # Custom message included in notifications about this maintenance window (e.g. Scheduled downtime for database migration)
  --notify-channels: list # Channels to notify about the maintenance window starting and ending (e.g. [{channel_id: C0ACTHQMHS8, channel_name: general, channel_type: public}]) — item shape: {channel_id: string, channel_name?: string, channel_type: string}
  --notify-end-minutes-before: int # Minutes before the end to send a notification to the configured channels (format: int64, e.g. 5)
  --notify-start-minutes-before: int # Minutes before the start to send a notification to the configured channels (format: int64, e.g. 15)
  --reroute-on-end: oneof<nothing, bool> # Whether to retrigger firing alerts through alert routing when the window ends (e.g. false)
  --resolve-on-end: oneof<nothing, bool> # Whether to automatically resolve all firing alerts that matched this window when it ends (e.g. false)
  --show-in-sidebar: oneof<nothing, bool> # Whether to show this maintenance window in the dashboard sidebar when active (e.g. true)
  start_at: string # When the maintenance window should start (format: date-time, e.g. 2021-08-17T13:28:57.801578Z)
]: any -> record<maintenance_window: record<alert_condition_groups: list<record>, archived_at: string, created_at: string, end_at: string, escalation_targets: list<record>, id: string, incident_id: string, lead: record<alert: record, api_key: record, user: record, workflow: record>, name: string, notification_message: string, notify_channels: list<record>, notify_end_minutes_before: int, notify_start_minutes_before: int, reroute_on_end: bool, resolve_on_end: bool, show_in_sidebar: bool, start_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance_windows/($id)")
  let body = {alert_condition_groups: $alert_condition_groups, end_at: $end_at, escalation_targets: $escalation_targets, incident_id: $incident_id, lead: $lead, name: $name, notification_message: $notification_message, notify_channels: $notify_channels, notify_end_minutes_before: $notify_end_minutes_before, notify_start_minutes_before: $notify_start_minutes_before, reroute_on_end: $reroute_on_end, resolve_on_end: $resolve_on_end, show_in_sidebar: $show_in_sidebar, start_at: $start_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/postmortem_documents
# operationId: PostmortemDocuments V1_List
export def "postmortem-documents List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # A post-mortem document's ID. This endpoint will return a list of post-mortem documents after this ID. (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH, allows empty value)
  --incident-id: string # Filter to only return post-mortem documents for the given incident (e.g. 01GBA8J19SMXQWPJMX3P2ESCVG, allows empty value)
  --sort-by: string@sort-by-completer # Controls the order that results are returned in (default: created_at_newest_first, e.g. created_at_oldest_first, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, postmortem_documents: table<created_at: string, document_url: string, editors: list, exported_urls: list, id: string, incident_id: string, status: string, title: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/postmortem_documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/postmortem_documents/{id}
# operationId: PostmortemDocuments V1_Show
export def "postmortem-documents Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<postmortem_document: record<created_at: string, document_url: string, editors: list<record>, exported_urls: list<string>, id: string, incident_id: string, status: string, title: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/postmortem_documents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/postmortem_documents/{id}
# operationId: PostmortemDocuments V1_UpdateStatus
export def "postmortem-documents UpdateStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-2 # The new status to set the post-mortem document to (e.g. completed)
]: any -> record<postmortem_document: record<created_at: string, document_url: string, editors: list<record>, exported_urls: list<string>, id: string, incident_id: string, status: string, title: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/postmortem_documents/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show Content
#
# GET /v1/postmortem_documents/{id}/content
# operationId: PostmortemDocuments V1_ShowContent
export def "postmortem-documents-content ShowContent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<markdown: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/postmortem_documents/($id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/schedule_sync_targets
# operationId: Schedule Sync Targets V2_List
export def "schedule-sync-targets List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # A sync target's ID. This endpoint will return a list of sync targets after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, schedule_sync_targets: table<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list, slack_team_id: string, slack_user_group_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/schedule_sync_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/schedule_sync_targets
# operationId: Schedule Sync Targets V2_Create
# --schedule_sync_target shape: {add_bot_to_group: bool, annotations?: record, new_slack_user_group?: record, slack_user_group_id?: string}
export def "schedule-sync-targets Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule_sync_target: record # e.g. {add_bot_to_group: true, annotations: {incident.io/terraform/version: 3.0.0}, new_slack_user_group: {description: The team responsible for Project A, handle: project-team-a, name: Project Team A, slack_team_id: T01234567}, slack_user_group_id: S06MNNU5BMK} — shape: {add_bot_to_group: bool, annotations?: record, new_slack_user_group?: record, slack_user_group_id?: string}
]: any -> record<schedule_sync_target: record<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list<record>, slack_team_id: string, slack_user_group_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedule_sync_targets")
  let body = {schedule_sync_target: $schedule_sync_target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/schedule_sync_targets/{id}
# operationId: Schedule Sync Targets V2_Destroy
export def "schedule-sync-targets Destroy" [
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
  let full_url = (build-url $base $"/v2/schedule_sync_targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/schedule_sync_targets/{id}
# operationId: Schedule Sync Targets V2_Show
export def "schedule-sync-targets Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule_sync_target: record<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list<record>, slack_team_id: string, slack_user_group_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedule_sync_targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/schedule_sync_targets/{id}
# operationId: Schedule Sync Targets V2_Update
export def "schedule-sync-targets Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-bot-to-group: oneof<nothing, bool> # Whether the incident.io bot should be added to the group (e.g. true)
  --annotations: record # Annotations that track metadata about this resource (e.g. {incident.io/terraform/version: 3.0.0})
]: any -> record<schedule_sync_target: record<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list<record>, slack_team_id: string, slack_user_group_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedule_sync_targets/($id)")
  let body = {add_bot_to_group: $add_bot_to_group, annotations: $annotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/schedule_entries
# operationId: Schedules V2_ListScheduleEntries
export def "schedule-entries ListScheduleEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schedule-id: string # The ID of the schedule to get entries for. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
  --entry-window-start: string # The start of the window to get entries for. May also carry an opaque pagination cursor previously returned in `pagination_meta.after` — pass it back here unchanged to fetch the next page (leave `entry_window_end` unchanged from the original request). (e.g. 2021-01-01T00:00:00Z, allows empty value)
  --entry-window-end: string # The end of the window to get entries for. (format: date-time, e.g. 2021-01-01T00:00:00Z, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, after_url: string>, schedule_entries: record<final: list<record>, overrides: list<record>, scheduled: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "schedule_id" $schedule_id "scalar") (serialize-qp "entry_window_start" $entry_window_start "scalar") (serialize-qp "entry_window_end" $entry_window_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/schedule_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/schedule_overrides
# operationId: Schedules V2_CreateOverride
# --user shape: {email?: string, id?: string, slack_user_id?: string}
export def "schedule-overrides CreateOverride" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  end_at: string # End time of the override (format: date-time, e.g. 2021-08-17T14:00:00.000000Z)
  layer_id: string # The layer this override applies to (e.g. 01G0J1EXE7AXZ2C93K61WBPYNH)
  rotation_id: string # The rotation this override applies to (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH)
  schedule_id: string # The schedule this override applies to (e.g. 01G0J1EXE7AXZ2C93K61WBPYEH)
  start_at: string # Start time of the override (format: date-time, e.g. 2021-08-17T13:00:00.000000Z)
  user: record # e.g. {email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123} — shape: {email?: string, id?: string, slack_user_id?: string}
]: any -> record<override: record<created_at: string, end_at: string, id: string, layer_id: string, rotation_id: string, schedule_id: string, start_at: string, updated_at: string, user: record<email: string, id: string, name: string, role: string, slack_user_id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedule_overrides")
  let body = {end_at: $end_at, layer_id: $layer_id, rotation_id: $rotation_id, schedule_id: $schedule_id, start_at: $start_at, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/schedules
# operationId: Schedules V2_List
export def "schedules List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Note that next_shifts will only be returned when the page size is 25 or lower. (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # A schedule's ID. This endpoint will return a list of schedules after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int, total_record_count: int>, schedules: table<annotations: record, config: record, created_at: string, current_shifts: list, holidays_public_config: record, id: string, name: string, next_shifts: list, team_ids: list, timezone: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/schedules
# operationId: Schedules V2_Create
# --schedule shape: {annotations?: record, config?: record, holidays_public_config?: record, name?: string, team_ids?: list, timezone?: string}
export def "schedules Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # e.g. {annotations: {incident.io/terraform/version: version-of-terraform}, config: {rotations: [{effective_from: 2021-08-17T13:28:57.801578Z, handover_start_at: 2021-08-17T13:28:57.801578Z, handovers: [{interval: 1, interval_type: hourly}], id: 01G0J1EXE7AXZ2C93K61WBPYEH, layers: [{id: 01G0J1EXE7AXZ2C93K61WBPYEH, name: Layer 1}], name: My Rotation, scheduling_mode: fair, users: [{email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123}], working_interval: [{end_time: 17:00, start_time: 09:00, weekday: monday}], working_intervals: [{end_time: 17:00, start_time: 09:00, weekday: monday}]}]}, holidays_public_config: {country_codes: [abc123]}, name: Primary On-call Schedule, team_ids: [01JPQA75EPNEES4479P16P4XAB], timezone: America/Los_Angeles} — shape: {annotations?: record, config?: record, holidays_public_config?: record, name?: string, team_ids?: list, timezone?: string}
]: any -> record<schedule: record<annotations: record, config: record<rotations: list>, created_at: string, current_shifts: list<record>, holidays_public_config: record<country_codes: list>, id: string, name: string, next_shifts: list<record>, team_ids: list<string>, timezone: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedules")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/schedules/{id}
# operationId: Schedules V2_Destroy
export def "schedules Destroy" [
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
  let full_url = (build-url $base $"/v2/schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/schedules/{id}
# operationId: Schedules V2_Show
export def "schedules Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<annotations: record, config: record<rotations: list>, created_at: string, current_shifts: list<record>, holidays_public_config: record<country_codes: list>, id: string, name: string, next_shifts: list<record>, team_ids: list<string>, timezone: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/schedules/{id}
# operationId: Schedules V2_Update
# --schedule shape: {annotations?: record, config?: record, holidays_public_config?: record, name?: string, team_ids?: list, timezone?: string}
export def "schedules Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # e.g. {annotations: {incident.io/terraform/version: version-of-terraform}, config: {rotations: [{effective_from: 2021-08-17T13:28:57.801578Z, handover_start_at: 2021-08-17T13:28:57.801578Z, handovers: [{interval: 1, interval_type: hourly}], id: 01G0J1EXE7AXZ2C93K61WBPYEH, layers: [{id: 01G0J1EXE7AXZ2C93K61WBPYEH, name: Layer 1}], name: My Rotation, scheduling_mode: fair, users: [{email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123}], working_interval: [{end_time: 17:00, start_time: 09:00, weekday: monday}], working_intervals: [{end_time: 17:00, start_time: 09:00, weekday: monday}]}]}, holidays_public_config: {country_codes: [abc123]}, name: Primary On-call Schedule, team_ids: [01JPQA75EPNEES4479P16P4XAB], timezone: America/Los_Angeles} — shape: {annotations?: record, config?: record, holidays_public_config?: record, name?: string, team_ids?: list, timezone?: string}
]: any -> record<schedule: record<annotations: record, config: record<rotations: list>, created_at: string, current_shifts: list<record>, holidays_public_config: record<country_codes: list>, id: string, name: string, next_shifts: list<record>, team_ids: list<string>, timezone: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($id)")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview
#
# POST /v2/schedules/{id}/actions/preview_entries
# operationId: Schedules V2_PreviewScheduleEntries
# --schedule shape: {annotations?: record, config?: record, holidays_public_config?: record, name?: string, team_ids?: list, timezone?: string}
export def "schedules-actions-preview-entries PreviewScheduleEntries" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entry-window-end: string # The end of the window to preview entries for. Defaults to four weeks after entry_window_start. (format: date-time, e.g. 2021-01-08T00:00:00Z)
  --entry-window-start: string # The start of the window to preview entries for. Defaults to now. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  schedule: record # e.g. {annotations: {incident.io/terraform/version: version-of-terraform}, config: {rotations: [{effective_from: 2021-08-17T13:28:57.801578Z, handover_start_at: 2021-08-17T13:28:57.801578Z, handovers: [{interval: 1, interval_type: hourly}], id: 01G0J1EXE7AXZ2C93K61WBPYEH, layers: [{id: 01G0J1EXE7AXZ2C93K61WBPYEH, name: Layer 1}], name: My Rotation, scheduling_mode: fair, users: [{email: bob@example.com, id: 01G0J1EXE7AXZ2C93K61WBPYEH, slack_user_id: USER123}], working_interval: [{end_time: 17:00, start_time: 09:00, weekday: monday}], working_intervals: [{end_time: 17:00, start_time: 09:00, weekday: monday}]}]}, holidays_public_config: {country_codes: [abc123]}, name: Primary On-call Schedule, team_ids: [01JPQA75EPNEES4479P16P4XAB], timezone: America/Los_Angeles} — shape: {annotations?: record, config?: record, holidays_public_config?: record, name?: string, team_ids?: list, timezone?: string}
]: any -> record<schedule_entries: record<final: list<record>, overrides: list<record>, scheduled: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($id)/actions/preview_entries")
  let body = {entry_window_end: $entry_window_end, entry_window_start: $entry_window_start, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/schedules/{schedule_id}/replicas
# operationId: Schedules V2_ListScheduleReplicas
export def "schedules-replicas ListScheduleReplicas" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule_replicas: table<created_at: string, id: string, last_sync_error: string, last_synced_at: string, mirror_window_days: int, replica_fallback_user_id: string, replica_provider: string, replica_provider_id: string, schedule_id: string, sources: list, updated_at: string, user_statuses: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/replicas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/schedules/{schedule_id}/replicas
# operationId: Schedules V2_CreateScheduleReplica
# --schedule_replica shape: {mirror_window_days?: int, replica_fallback_user_id: string, replica_provider: "native"|"pagerduty"|"opsgenie"|"jira", replica_provider_id: string, sources: list}
export def "schedules-replicas CreateScheduleReplica" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule_replica: record # e.g. {mirror_window_days: 14, replica_fallback_user_id: PA7AXXN, replica_provider: pagerduty, replica_provider_id: PO8107X, sources: [{layer_id: 01G0J1EXE7AXZ2C93K61WBPYNH, rotation_id: 01G0J1EXE7AXZ2C93K61WBPYEH}]} — shape: {mirror_window_days?: int, replica_fallback_user_id: string, replica_provider: "native"|"pagerduty"|"opsgenie"|"jira", replica_provider_id: string, sources: list}
]: any -> record<schedule_replica: record<created_at: string, id: string, last_sync_error: string, last_synced_at: string, mirror_window_days: int, replica_fallback_user_id: string, replica_provider: string, replica_provider_id: string, schedule_id: string, sources: list<record>, updated_at: string, user_statuses: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/replicas")
  let body = {schedule_replica: $schedule_replica} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/schedules/{schedule_id}/replicas/{id}
# operationId: Schedules V2_DestroyScheduleReplica
export def "schedules-replicas DestroyScheduleReplica" [
  schedule_id: string
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
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/replicas/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/schedules/{schedule_id}/replicas/{id}
# operationId: Schedules V2_ShowScheduleReplica
export def "schedules-replicas ShowScheduleReplica" [
  schedule_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule_replica: record<created_at: string, id: string, last_sync_error: string, last_synced_at: string, mirror_window_days: int, replica_fallback_user_id: string, replica_provider: string, replica_provider_id: string, schedule_id: string, sources: list<record>, updated_at: string, user_statuses: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/replicas/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/schedules/{schedule_id}/sync_rules
# operationId: Schedules V2_ListScheduleSyncRules
export def "schedules-sync-rules ListScheduleSyncRules" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # A sync rule's ID. This endpoint will return a list of sync rules after this ID in relation to the API response order. (e.g. 01JXYZ000000000000000000CD, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, schedule_sync_rules: table<created_at: string, id: string, schedule_id: string, schedule_sync_target: record, schedule_sync_target_id: string, sync_type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/sync_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/schedules/{schedule_id}/sync_rules
# operationId: Schedules V2_CreateScheduleSyncRule
# --schedule_sync_rule shape: {annotations?: record, schedule_sync_target_id: string, sync_type: "on_call"|"all_users"}
export def "schedules-sync-rules CreateScheduleSyncRule" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule_sync_rule: record # e.g. {annotations: {incident.io/terraform/version: 3.0.0}, schedule_sync_target_id: 01JXYZ000000000000000000AB, sync_type: on_call} — shape: {annotations?: record, schedule_sync_target_id: string, sync_type: "on_call"|"all_users"}
]: any -> record<schedule_sync_rule: record<created_at: string, id: string, schedule_id: string, schedule_sync_target: record<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list, slack_team_id: string, slack_user_group_id: string, updated_at: string>, schedule_sync_target_id: string, sync_type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/sync_rules")
  let body = {schedule_sync_rule: $schedule_sync_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/schedules/{schedule_id}/sync_rules/{id}
# operationId: Schedules V2_DestroyScheduleSyncRule
export def "schedules-sync-rules DestroyScheduleSyncRule" [
  schedule_id: string
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
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/sync_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/schedules/{schedule_id}/sync_rules/{id}
# operationId: Schedules V2_ShowScheduleSyncRule
export def "schedules-sync-rules ShowScheduleSyncRule" [
  schedule_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule_sync_rule: record<created_at: string, id: string, schedule_id: string, schedule_sync_target: record<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list, slack_team_id: string, slack_user_group_id: string, updated_at: string>, schedule_sync_target_id: string, sync_type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/sync_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/schedules/{schedule_id}/sync_rules/{id}
# operationId: Schedules V2_UpdateScheduleSyncRule
export def "schedules-sync-rules UpdateScheduleSyncRule" [
  schedule_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # Annotations that track metadata about this resource (e.g. {incident.io/terraform/version: 3.0.0})
  sync_type: string@sync-type-completer # Which schedule members sync to the user group (e.g. on_call)
]: any -> record<schedule_sync_rule: record<created_at: string, id: string, schedule_id: string, schedule_sync_target: record<add_bot_to_group: bool, created_at: string, id: string, linked_schedules: list, slack_team_id: string, slack_user_group_id: string, updated_at: string>, schedule_sync_target_id: string, sync_type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($schedule_id)/sync_rules/($id)")
  let body = {annotations: $annotations, sync_type: $sync_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/severities
# operationId: Severities V1_List
export def "severities List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<severities: table<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/severities
# operationId: Severities V1_Create
export def "severities Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Description of the severity (e.g. Issues with **low impact**.)
  name: string # Human readable name of the severity (e.g. Minor)
  --rank: int # Rank to help sort severities (lower numbers are less severe) (format: int64, e.g. 1)
]: any -> record<severity: record<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severities")
  let body = {description: $description, name: $name, rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/severities/{id}
# operationId: Severities V1_Delete
export def "severities Delete" [
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
  let full_url = (build-url $base $"/v1/severities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v1/severities/{id}
# operationId: Severities V1_Show
export def "severities Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<severity: record<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/severities/{id}
# operationId: Severities V1_Update
export def "severities Update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Description of the severity (e.g. Issues with **low impact**.)
  name: string # Human readable name of the severity (e.g. Minor)
  --rank: int # Rank to help sort severities (lower numbers are less severe) (format: int64, e.g. 1)
]: any -> record<severity: record<created_at: string, description: string, id: string, name: string, rank: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severities/($id)")
  let body = {description: $description, name: $name, rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v1/status-pages/{id}/incidents/{incident_id}/response-incidents
# operationId: Status Pages V1_ListResponseIncidents
export def "status-pages-incidents-response-incidents ListResponseIncidents" [
  id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<incidents: table<id: string, linked_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($id)/incidents/($incident_id)/response-incidents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/status_page_incident_updates
# operationId: Status Pages V2_CreateStatusPageIncidentUpdate
# --component_statuses item shape: {component_id: string, component_status: "operational"|"degraded_performance"|"partial_outage"|"full_outage"}
export def "status-page-incident-updates CreateStatusPageIncidentUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-statuses: list # An array of mappings from component ID to component status. This must not be set if the status page incident status is being set to "resolved", as all components statuses will update to "operational". (e.g. [{component_id: 01FCNDV6P870EA6S7TK1DSYDG2, component_status: operational}]) — item shape: {component_id: string, component_status: "operational"|"degraded_performance"|"partial_outage"|"full_outage"}
  --incident-status: string@incident-status-completer # Optional new status for this status page incident. If not provided, the status will remain unchanged. Setting to "resolved" will end the incident and all component statuses will update to "operational". (e.g. investigating)
  message: string # Markdown update on what's changed about this status page incident (e.g. The fix has been deployed and we are monitoring the situation. Some users may still experience intermittent issues.)
  --notify-subscribers: oneof<nothing, bool> # Whether to notify subscribers about this incident update. This will not work if your status page has more than 1000 subscribers. (e.g. true)
  status_page_incident_id: string # ID of the status page incident (e.g. 01FCNDV6P870EA6S7TK1DSYDG1)
]: any -> record<status_page_incident_update: record<component_statuses: list<record>, id: string, incident_status: string, message: string, published_at: string, status_page_incident_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/status_page_incident_updates")
  let body = {component_statuses: $component_statuses, incident_status: $incident_status, message: $message, notify_subscribers: $notify_subscribers, status_page_incident_id: $status_page_incident_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/status_page_incidents
# operationId: Status Pages V2_ListStatusPageIncidents
export def "status-page-incidents ListStatusPageIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status-page-id: string # ID of the status page. You can find this by calling the ListStatusPages endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --component-id: string # Filter status page incidents to only those that impacted the specified component. This ID may be found by calling the ShowStatusPageStructure endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG1, allows empty value)
  --group-id: string # Filter status page incidents to only those that impacted components in the specified group. This ID may be found by calling the ShowStatusPageStructure endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG2, allows empty value)
  --sub-page-id: string # Filter status page incidents to only those that impacted the specified sub-page. This ID may be found by calling the ShowStatusPageStructure endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG3, allows empty value)
  --start-at: string # Filter status page incidents to only those that had impacts during or after this time. (format: date-time, e.g. 2021-08-17T13:28:57.801578Z, allows empty value)
  --end-at: string # Filter status page incidents to only those that had impacts during or before this time. (format: date-time, e.g. 2021-08-17T13:28:57.801578Z, allows empty value)
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, status_page_incidents: table<component_impacts: list, id: string, incident_status: string, name: string, published_at: string, status_page_id: string, updates: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status_page_id" $status_page_id "scalar") (serialize-qp "component_id" $component_id "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "sub_page_id" $sub_page_id "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/status_page_incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/status_page_incidents
# operationId: Status Pages V2_CreateStatusPageIncident
# --component_statuses item shape: {component_id: string, component_status: "operational"|"degraded_performance"|"partial_outage"|"full_outage"}
export def "status-page-incidents CreateStatusPageIncident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-statuses: list # An array of mappings from component ID to current component status (e.g. [{component_id: 01FCNDV6P870EA6S7TK1DSYDG2, component_status: operational}]) — item shape: {component_id: string, component_status: "operational"|"degraded_performance"|"partial_outage"|"full_outage"}
  idempotency_key: string # A unique key to de-duplicate requests. If you send a request with an idempotency_key that was already used, the original response will be returned. (e.g. alert-12345-abcde)
  incident_status: string@incident-status-completer # Current status for this status page incident (e.g. investigating)
  message: string # Markdown initial update on this status page incident (e.g. We are currently investigating reports of elevated error rates affecting our API.)
  name: string # A title for the incident (e.g. Elevated API latency)
  --notify-subscribers: oneof<nothing, bool> # Whether to notify subscribers about this status page incident. This will not work if your status page has more than 1000 subscribers. (e.g. true)
  status_page_id: string # ID of the status page. You can find this by calling the ListStatusPages endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
]: any -> record<status_page_incident: record<component_impacts: list<record>, id: string, incident_status: string, name: string, published_at: string, status_page_id: string, updates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/status_page_incidents")
  let body = {component_statuses: $component_statuses, idempotency_key: $idempotency_key, incident_status: $incident_status, message: $message, name: $name, notify_subscribers: $notify_subscribers, status_page_id: $status_page_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show
#
# GET /v2/status_page_incidents/{status_page_incident_id}
# operationId: Status Pages V2_ShowStatusPageIncident
export def "status-page-incidents ShowStatusPageIncident" [
  status_page_incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status_page_incident: record<component_impacts: list<record>, id: string, incident_status: string, name: string, published_at: string, status_page_id: string, updates: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/status_page_incidents/($status_page_incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/status_page_incidents/{status_page_incident_id}
# operationId: Status Pages V2_UpdateStatusPageIncident
export def "status-page-incidents UpdateStatusPageIncident" [
  status_page_incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A title for the incident (e.g. Elevated API latency)
]: any -> record<status_page_incident: record<component_impacts: list<record>, id: string, incident_status: string, name: string, published_at: string, status_page_id: string, updates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/status_page_incidents/($status_page_incident_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v2/status_page_maintenance_updates
# operationId: Status Pages V2_CreateStatusPageMaintenanceUpdate
# --component_statuses item shape: {component_id: string, component_status: "operational"|"under_maintenance"}
export def "status-page-maintenance-updates CreateStatusPageMaintenanceUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-statuses: list # An array of mappings from component ID to component status. This must not be set if the status page maintenance window status is being set to "maintenance_complete", as all components statuses will update to "operational". (e.g. [{component_id: 01FCNDV6P870EA6S7TK1DSYDG2, component_status: operational}]) — item shape: {component_id: string, component_status: "operational"|"under_maintenance"}
  --maintenance-status: string@maintenance-status-completer # Optional new status for this status page maintenance window. If not provided, the status will remain unchanged. Setting to "maintenance_complete" will end the maintenance window and all component statuses will update to "operational". (e.g. maintenance_scheduled)
  message: string # Markdown update on what's changed about this status page maintenance window (e.g. Scheduled maintenance is underway for our database infrastructure. Some services may experience brief interruptions during this window.)
  --notify-subscribers: oneof<nothing, bool> # Whether to notify subscribers about this status page maintenance update. This will not work if your status page has more than 1000 subscribers. (e.g. true)
  status_page_maintenance_id: string # ID of the status page maintenance window (e.g. 01FCNDV6P870EA6S7TK1DSYDG1)
]: any -> record<status_page_maintenance_update: record<component_statuses: list<record>, id: string, maintenance_status: string, message: string, published_at: string, status_page_maintenance_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/status_page_maintenance_updates")
  let body = {component_statuses: $component_statuses, maintenance_status: $maintenance_status, message: $message, notify_subscribers: $notify_subscribers, status_page_maintenance_id: $status_page_maintenance_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/status_page_maintenances
# operationId: Status Pages V2_ListStatusPageMaintenances
export def "status-page-maintenances ListStatusPageMaintenances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status-page-id: string # ID of the status page. You can find this by calling the ListStatusPages endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG0, allows empty value)
  --component-id: string # Filter status page maintenance windows to only those that impacted the specified component. This ID may be found by calling the ShowStatusPageStructure endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG1, allows empty value)
  --group-id: string # Filter status page maintenance windows to only those that impacted components in the specified group. This ID may be found by calling the ShowStatusPageStructure endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG2, allows empty value)
  --sub-page-id: string # Filter status page maintenance windows to only those that impacted the specified sub-page. This ID may be found by calling the ShowStatusPageStructure endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG3, allows empty value)
  --start-at: string # Filter status page maintenance windows to only those that had impacts during or after this time. (format: date-time, e.g. 2021-08-17T13:28:57.801578Z, allows empty value)
  --end-at: string # Filter status page maintenance windows to only those that had impacts during or before this time. (format: date-time, e.g. 2021-08-17T13:28:57.801578Z, allows empty value)
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, status_page_maintenances: table<component_maintenance_periods: list, id: string, maintenance_status: string, name: string, published_at: string, status_page_id: string, updates: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status_page_id" $status_page_id "scalar") (serialize-qp "component_id" $component_id "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "sub_page_id" $sub_page_id "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/status_page_maintenances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/status_page_maintenances
# operationId: Status Pages V2_CreateStatusPageMaintenance
export def "status-page-maintenances CreateStatusPageMaintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  affected_component_ids: list # An array of IDs of component affected by the maintenance window (e.g. [01FCNDV6P870EA6S7TK1DSYDG2])
  end_at: string # The time the maintenance window ends (format: date-time, e.g. 2025-01-28T12:00:00Z)
  idempotency_key: string # A unique key to de-duplicate requests. If you send a request with an idempotency_key that was already used, the original response will be returned. (e.g. maintenance-12345-abcde)
  maintenance_status: string@maintenance-status-completer # Current status for this status page maintenance window (e.g. maintenance_scheduled)
  message: string # Markdown initial update on this status page maintenance window (e.g. Planned maintenance has been scheduled to upgrade our infrastructure. We expect minimal disruption, but some features may be briefly unavailable.)
  name: string # A title for the maintenance window (e.g. Routine infrastructure upgrade)
  --notify-subscribers: oneof<nothing, bool> # Whether to notify subscribers about this status page maintenance. This will not work if your status page has more than 1000 subscribers. (e.g. true)
  start_at: string # The time the maintenance window starts (format: date-time, e.g. 2025-01-28T10:00:00Z)
  status_page_id: string # ID of the status page. You can find this by calling the ListStatusPages endpoint. (e.g. 01FCNDV6P870EA6S7TK1DSYDG0)
]: any -> record<status_page_maintenance: record<component_maintenance_periods: list<record>, id: string, maintenance_status: string, name: string, published_at: string, status_page_id: string, updates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/status_page_maintenances")
  let body = {affected_component_ids: $affected_component_ids, end_at: $end_at, idempotency_key: $idempotency_key, maintenance_status: $maintenance_status, message: $message, name: $name, notify_subscribers: $notify_subscribers, start_at: $start_at, status_page_id: $status_page_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show
#
# GET /v2/status_page_maintenances/{status_page_maintenance_id}
# operationId: Status Pages V2_ShowStatusPageMaintenance
export def "status-page-maintenances ShowStatusPageMaintenance" [
  status_page_maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status_page_maintenance: record<component_maintenance_periods: list<record>, id: string, maintenance_status: string, name: string, published_at: string, status_page_id: string, updates: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/status_page_maintenances/($status_page_maintenance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/status_page_structures/{status_page_id}
# operationId: Status Pages V2_ShowStatusPageStructure
export def "status-page-structures ShowStatusPageStructure" [
  status_page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<current_structure: record<items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/status_page_structures/($status_page_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/status_pages
# operationId: Status Pages V2_ListStatusPages
export def "status-pages ListStatusPages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, status_pages: table<description: string, id: string, name: string, public_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/status_pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v3/teams
# operationId: Teams V3_List
export def "teams List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, teams: table<catalog_entry: record, id: string, members: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v3/teams/{id}
# operationId: Teams V3_Show
export def "teams Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<team: record<catalog_entry: record<id: string, name: string>, id: string, members: list<record>, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/telemetry/data_sources/{id}
# operationId: Telemetry V2_UpdateDataSource
# --datadog_config shape: {api_key?: string, app_key?: string}
# --grafana_config shape: {api_key?: string, api_url?: string}
export def "telemetry-data-sources UpdateDataSource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datadog-config: record # Datadog-specific credential updates (e.g. {api_key: abc123, app_key: abc123}) — shape: {api_key?: string, app_key?: string}
  --grafana-config: record # Grafana-specific credential and endpoint updates (e.g. {api_key: glsa_123, api_url: grafana.example.com}) — shape: {api_key?: string, api_url?: string}
  --name: string # Updated display name (e.g. Production Grafana)
]: any -> record<data_source: record<created_at: string, enabled: bool, id: string, name: string, provider: string, source_type: string, updated_at: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/telemetry/data_sources/($id)")
  let body = {datadog_config: $datadog_config, grafana_config: $grafana_config, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List
#
# GET /v2/users
# operationId: Users V2_List
export def "users List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Filter by email address (e.g. john.doe@incident.io, allows empty value)
  --slack-user-id: string # Filter by Slack user ID (e.g. U12345678, allows empty value)
  --page-size: int # Integer number of records to return (format: int64, default: 25, e.g. 25, allows empty value)
  --after: string # An record's ID. This endpoint will return a list of records after this ID in relation to the API response order. (e.g. 01FDAG4SAP5TYPT98WGR2N7W91, allows empty value)
]: nothing -> record<pagination_meta: record<after: string, page_size: int>, users: table<base_role: record, custom_roles: list, email: string, id: string, name: string, role: string, seats: record, slack_user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "slack_user_id" $slack_user_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/users/{id}
# operationId: Users V2_Show
export def "users Show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user: record<base_role: record<description: string, id: string, name: string, slug: string>, custom_roles: list<record>, email: string, id: string, name: string, role: string, seats: record<on_call: string, response: string>, slack_user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/users/{user_id}/notification_methods
# operationId: Users V2_ListNotificationMethods
export def "users-notification-methods ListNotificationMethods" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<notification_methods: table<address: string, id: string, is_usable: bool, method_type: string, phone_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($user_id)/notification_methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/users/{user_id}/notification_rules
# operationId: Users V2_ListNotificationRules
export def "users-notification-rules ListNotificationRules" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<notification_rules: table<app: record, delay_seconds: int, id: string, method_target: record, method_type: string, phone: record, rule_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($user_id)/notification_rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ShowPagingProvider
#
# GET /v2/users/{user_id}/paging_provider
# operationId: Users V2_ShowPagingProvider
export def "users-paging-provider ShowPagingProvider" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<preferred_escalation_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($user_id)/paging_provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# UpdatePagingProvider
#
# POST /v2/users/{user_id}/paging_provider
# operationId: Users V2_UpdatePagingProvider
export def "users-paging-provider UpdatePagingProvider" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  preferred_escalation_provider: string@preferred-escalation-provider-completer # The preferred escalation provider for the user. (e.g. native)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($user_id)/paging_provider")
  let body = {preferred_escalation_provider: $preferred_escalation_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show Identity
#
# GET /v1/identity
# operationId: Utilities V1_Identity
export def "identity Identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<identity: record<dashboard_url: string, name: string, roles: list<string>, team_roles: list<string>, teams: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/identity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show OpenAPI V2 Spec
#
# GET /v1/openapi.json
# DEPRECATED
# operationId: Utilities V1_OpenAPI
@deprecated
export def "openapijson OpenAPI" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/openapi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show OpenAPI V3 Spec
#
# GET /v1/openapiV3.json
# operationId: Utilities V1_OpenAPIV3
export def "openapi-v3json OpenAPIV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/openapiV3.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /v2/workflows
# operationId: Workflows V2_ListWorkflows
export def "workflows ListWorkflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflows: table<condition_groups: list, continue_on_step_error: bool, delay: record, expressions: list, folder: string, id: string, include_private_escalations: bool, include_private_incidents: bool, name: string, once_for: list, runs_from: string, runs_on_incident_modes: list, runs_on_incidents: string, shortform: string, state: string, steps: list, trigger: record, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/workflows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /v2/workflows
# operationId: Workflows V2_CreateWorkflow
# --condition_groups item shape: {conditions: list}
# --delay shape: {conditions_apply_over_delay: bool, for_seconds: int}
# --expressions item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
# --steps item shape: {for_each?: string, id: string, name: string, param_bindings: list}
export def "workflows CreateWorkflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # Annotations that track metadata about this resource (e.g. {incident.io/terraform/version: 3.0.0})
  condition_groups: list # Conditions that apply to the workflow trigger (e.g. [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]) — item shape: {conditions: list}
  --continue-on-step-error: oneof<nothing, bool> # Whether to continue executing the workflow if a step fails (e.g. true)
  --delay: record # e.g. {conditions_apply_over_delay: false, for_seconds: 60} — shape: {conditions_apply_over_delay: bool, for_seconds: int}
  expressions: list # The expressions to use in the workflow (e.g. [{else_branch: {result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, label: Team Slack channel, operations: [{branches: {branches: [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}], returns: {array: true, type: IncidentStatus}}, concatenate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, filter: {condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}, navigate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, operation_type: navigate, parse: {returns: {array: true, type: IncidentStatus}, source: metadata.annotations["github.com/repo"]}}], reference: abc123, root_reference: incident.status}]) — item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
  --folder: string # Folder to display the workflow in (e.g. My folder 01)
  --include-private-escalations: oneof<nothing, bool> # Whether to include private escalations (e.g. true)
  --include-private-incidents: oneof<nothing, bool> # Whether to include private incidents (e.g. true)
  name: string # Name provided by the user when creating the workflow (e.g. My little workflow)
  once_for: list # This workflow will run 'once for' a list of references (e.g. [incident.url])
  runs_on_incident_modes: list # Which incident modes should this workflow run on? By default, workflows only run on standard incidents, but can also be configured to run on test and retrospective incidents. (e.g. [standard, test, retrospective])
  runs_on_incidents: string@runs-on-incidents-completer # Which incidents should the workflow be applied to? (e.g. newly_created)
  --shortform: string # The shortform used to trigger this workflow (only applicable for manual triggers) (e.g. page-the-ceo)
  --state: string@state-completer # What state this workflow is in (e.g. active)
  steps: list # Steps that are executed as part of the workflow (e.g. [{for_each: abc123, id: abc123, name: pagerduty.escalate, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}]}]) — item shape: {for_each?: string, id: string, name: string, param_bindings: list}
  trigger: string # Trigger to set on the workflow (e.g. incident.updated)
]: any -> record<management_meta: record<annotations: record, managed_by: string, source_url: string>, workflow: record<condition_groups: list<record>, continue_on_step_error: bool, delay: record<conditions_apply_over_delay: bool, for_seconds: int>, expressions: list<record>, folder: string, id: string, include_private_escalations: bool, include_private_incidents: bool, name: string, once_for: list<record>, runs_from: string, runs_on_incident_modes: list<string>, runs_on_incidents: string, shortform: string, state: string, steps: list<record>, trigger: record<label: string, name: string>, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/workflows")
  let body = {annotations: $annotations, condition_groups: $condition_groups, continue_on_step_error: $continue_on_step_error, delay: $delay, expressions: $expressions, folder: $folder, include_private_escalations: $include_private_escalations, include_private_incidents: $include_private_incidents, name: $name, once_for: $once_for, runs_on_incident_modes: $runs_on_incident_modes, runs_on_incidents: $runs_on_incidents, shortform: $shortform, state: $state, steps: $steps, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v2/workflows/{id}
# operationId: Workflows V2_DestroyWorkflow
export def "workflows DestroyWorkflow" [
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
  let full_url = (build-url $base $"/v2/workflows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show
#
# GET /v2/workflows/{id}
# operationId: Workflows V2_ShowWorkflow
export def "workflows ShowWorkflow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-step-upgrades: oneof<nothing, bool> # Skips workflow step upgrades, when the parameters for an existing workflow step change (e.g. false, allows empty value)
]: nothing -> record<management_meta: record<annotations: record, managed_by: string, source_url: string>, workflow: record<condition_groups: list<record>, continue_on_step_error: bool, delay: record<conditions_apply_over_delay: bool, for_seconds: int>, expressions: list<record>, folder: string, id: string, include_private_escalations: bool, include_private_incidents: bool, name: string, once_for: list<record>, runs_from: string, runs_on_incident_modes: list<string>, runs_on_incidents: string, shortform: string, state: string, steps: list<record>, trigger: record<label: string, name: string>, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_step_upgrades" $skip_step_upgrades "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/workflows/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v2/workflows/{id}
# operationId: Workflows V2_UpdateWorkflow
# --condition_groups item shape: {conditions: list}
# --delay shape: {conditions_apply_over_delay: bool, for_seconds: int}
# --expressions item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
# --steps item shape: {for_each?: string, id: string, name: string, param_bindings: list}
export def "workflows UpdateWorkflow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # Annotations that track metadata about this resource (e.g. {incident.io/terraform/version: 3.0.0})
  condition_groups: list # Conditions that apply to the workflow trigger (e.g. [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]) — item shape: {conditions: list}
  --continue-on-step-error: oneof<nothing, bool> # Whether to continue executing the workflow if a step fails (e.g. true)
  --delay: record # e.g. {conditions_apply_over_delay: false, for_seconds: 60} — shape: {conditions_apply_over_delay: bool, for_seconds: int}
  expressions: list # The expressions to use in the workflow (e.g. [{else_branch: {result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}, label: Team Slack channel, operations: [{branches: {branches: [{condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}], result: {array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}}], returns: {array: true, type: IncidentStatus}}, concatenate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, filter: {condition_groups: [{conditions: [{operation: one_of, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}], subject: incident.severity}]}]}, navigate: {reference: catalog_attribute["01FCNDV6P870EA6S7TK1DSYD5H"]}, operation_type: navigate, parse: {returns: {array: true, type: IncidentStatus}, source: metadata.annotations["github.com/repo"]}}], reference: abc123, root_reference: incident.status}]) — item shape: {else_branch?: record, label: string, operations: list, reference: string, root_reference: string}
  --folder: string # Folder to display the workflow in (e.g. My folder 01)
  --include-private-escalations: oneof<nothing, bool> # Whether to include private escalations (e.g. true)
  --include-private-incidents: oneof<nothing, bool> # Whether to include private incidents (e.g. true)
  name: string # Name provided by the user when creating the workflow (e.g. My little workflow)
  once_for: list # This workflow will run 'once for' a list of references (e.g. [incident.url])
  runs_on_incident_modes: list # Which incident modes should this workflow run on? By default, workflows only run on standard incidents, but can also be configured to run on test and retrospective incidents. (e.g. [standard, test, retrospective])
  runs_on_incidents: string@runs-on-incidents-completer # Which incidents should the workflow be applied to? (e.g. newly_created)
  --shortform: string # The shortform used to trigger this workflow (only applicable for manual triggers) (e.g. page-the-ceo)
  --skip-step-upgrades: oneof<nothing, bool> # Skips workflow step upgrades, when the parameters for an existing workflow step change (e.g. false)
  --state: string@state-completer # What state this workflow is in (e.g. active)
  steps: list # Steps that are executed as part of the workflow (e.g. [{for_each: abc123, id: abc123, name: pagerduty.escalate, param_bindings: [{array_value: [{literal: SEV123, reference: incident.severity}], value: {literal: SEV123, reference: incident.severity}}]}]) — item shape: {for_each?: string, id: string, name: string, param_bindings: list}
]: any -> record<management_meta: record<annotations: record, managed_by: string, source_url: string>, workflow: record<condition_groups: list<record>, continue_on_step_error: bool, delay: record<conditions_apply_over_delay: bool, for_seconds: int>, expressions: list<record>, folder: string, id: string, include_private_escalations: bool, include_private_incidents: bool, name: string, once_for: list<record>, runs_from: string, runs_on_incident_modes: list<string>, runs_on_incidents: string, shortform: string, state: string, steps: list<record>, trigger: record<label: string, name: string>, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workflows/($id)")
  let body = {annotations: $annotations, condition_groups: $condition_groups, continue_on_step_error: $continue_on_step_error, delay: $delay, expressions: $expressions, folder: $folder, include_private_escalations: $include_private_escalations, include_private_incidents: $include_private_incidents, name: $name, once_for: $once_for, runs_on_incident_modes: $runs_on_incident_modes, runs_on_incidents: $runs_on_incidents, shortform: $shortform, skip_step_upgrades: $skip_step_upgrades, state: $state, steps: $steps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
