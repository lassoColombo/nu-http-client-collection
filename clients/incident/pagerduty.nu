# Auto-generated client for PagerDuty API v2.0.0
# Source: https://raw.githubusercontent.com/PagerDuty/api-schema/main/reference/REST/openapiv3.json
# Auth: --token flag or $env.PAGERDUTY_API_TOKEN

const BASE_URL = "https://api.pagerduty.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAGERDUTY_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.pagerduty.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Content-Type-completer [] { ["application/json"] }
def include-completer [] { ["services"] }
def filter-completer [] { ["full_page_addon" "incident_show_addon"] }
def order-completer [] { ["asc" "desc"] }
def aggregate-unit-completer [] { ["day" "month" "week"] }
def order-by-completer [] { ["created_at" "seconds_to_resolve"] }
def order-by-completer-1 [] { ["requested_at"] }
def order-by-completer-2 [] { ["incident_created_at"] }
def root-resource-types-completer [] { ["escalation_policies" "ip_allow_lists" "schedules" "services" "teams" "users"] }
def actor-type-completer [] { ["api_key_reference" "app_reference" "user_reference"] }
def method-type-completer [] { ["api_token" "browser" "identity_provider" "oauth" "other"] }
def actions-completer [] { ["create" "delete" "update"] }
def classification-completer [] { ["diagnostic" "remediation"] }
def action-type-completer [] { ["process_automation" "script"] }
def invocation-state-completer [] { ["aborted" "completed" "created" "error" "prepared" "queued" "running" "sent" "unknown"] }
def additional-fields-completer [] { ["services.highest_impacting_priority" "total_impacted_count"] }
def include-completer-1 [] { ["escalation_rule_assignment_strategies" "services" "targets" "teams"] }
def sort-by-completer [] { ["name" "name:asc" "name:desc"] }
def sort-by-completer-1 [] { ["created_at:asc" "created_at:desc" "name:asc" "name:desc" "routes:asc" "routes:desc"] }
def source-type-completer [] { ["orchestration"] }
def include-completer-2 [] { ["migrated_metadata"] }
def include-completer-3 [] { ["extension_objects" "extension_schemas"] }
def include-completer-4 [] { ["extension_objects" "extension_schemas" "temporarily_disabled"] }
def include-completer-5 [] { ["steps" "team"] }
def trigger-type-completer [] { ["conditional" "incident_type" "manual"] }
def sort-by-completer-2 [] { ["workflow_id" "workflow_id asc" "workflow_id desc" "workflow_name" "workflow_name asc" "workflow_name desc"] }
def date-range-completer [] { ["all"] }
def urgencies-completer [] { ["high" "low"] }
def statuses-completer [] { ["acknowledged" "resolved" "triggered"] }
def include-completer-6 [] { ["acknowledgers" "agents" "assignees" "conference_bridge" "escalation_policies" "first_trigger_log_entries" "priorities" "services" "teams" "users"] }
def include-completer-7 [] { ["acknowledgers" "agents" "assignees" "conference_bridge" "custom_fields" "escalation_policies" "first_trigger_log_entries" "priorities" "services" "teams" "users"] }
def statuses-completer-1 [] { ["resolved" "triggered"] }
def sort-by-completer-3 [] { ["created_at" "created_at:asc" "created_at:desc" "resolved_at" "resolved_at:asc" "resolved_at:desc"] }
def include-completer-8 [] { ["first_trigger_log_entries" "incidents" "services"] }
def relation-completer [] { ["impacted" "not_impacted"] }
def include-completer-9 [] { ["channels" "incidents" "services" "teams"] }
def additional-details-completer [] { ["incident"] }
def filter-completer-1 [] { ["all" "disabled" "enabled"] }
def include-completer-10 [] { ["field_options"] }
def X-EARLY-ACCESS-completer [] { ["ip-allow-lists"] }
def include-completer-11 [] { ["services" "teams" "users"] }
def filter-completer-2 [] { ["all" "future" "ongoing" "open" "past"] }
def filter-completer-3 [] { ["email_notification" "phone_notification" "push_notification" "sms_notification"] }
def include-completer-12 [] { ["users"] }
def type-completer [] { ["mobile" "web"] }
def include-completer-13 [] { ["escalation_policies" "schedules" "users"] }
def suspended-by-completer [] { ["auto_pause" "rules"] }
def include-completer-14 [] { ["final_schedule" "overrides_subschedule" "schedule_layers"] }
def include-completer-15 [] { ["auto_pause_notifications_parameters" "escalation_policies" "integrations" "teams"] }
def include-completer-16 [] { ["services" "vendors"] }
def resource-type-completer [] { ["technical_service"] }
def status-page-type-completer [] { ["private" "public"] }
def post-type-completer [] { ["incident" "maintenance"] }
def reviewed-status-completer [] { ["approved" "not_reviewed"] }
def status-completer [] { ["active" "pending"] }
def channel-completer [] { ["email" "slack" "webhook"] }
def type-completer-1 [] { ["incident_playbook" "runbook" "service_profile"] }
def include-completer-17 [] { ["privileges"] }
def role-completer [] { ["manager" "observer" "responder"] }
def sort-by-completer-4 [] { ["created_at" "created_at:asc" "created_at:desc" "name" "name:asc" "name:desc"] }
def include-completer-18 [] { ["contact_methods" "notification_rules" "subdomains" "teams"] }
def delegation-type-completer [] { ["integration" "mobile" "web"] }
def status-completer-1 [] { ["issued" "revoked"] }
def include-completer-19 [] { ["contact_methods"] }
def urgency-completer [] { ["all" "high" "low"] }
def filter-type-completer [] { ["account" "service" "team"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "change-tags createEntityTypeByIdChangeTags" } } | get name | first)
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

# Assign tags
#
# POST /{entity_type}/{id}/change_tags
# operationId: createEntityTypeByIdChangeTags
# --add item shape: {type: "tag"|"tag_reference", label?: string}
# --remove item shape: {type: "tag_reference"}
export def "change-tags createEntityTypeByIdChangeTags" [
  entity_type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --add: list # Array of tags and/or tag references to add to the entity. For elements with type `tag_reference`, the tag with the corresponding `id` is added to the entity. For elements with type `tag`, if there is an existing tag with the given label that tag is added to the entity. If there is no existing tag with that label and the user has permission to create tags, a new tag is created with that label and assigned to the entity. — item shape: {type: "tag"|"tag_reference", label?: string}
  --remove: list # Array of tag references to remove from the entity. — item shape: {type: "tag_reference"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($entity_type)/($id)/change_tags")
  let body = {add: $add, remove: $remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tags for entities
#
# GET /{entity_type}/{id}/tags
# operationId: getEntityTypeByIdTags
export def "tags get-by-entity_type-id" [
  entity_type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, tags: table<id: string, summary: string, type: string, self: string, html_url: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($entity_type)/($id)/tags" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List abilities
#
# GET /abilities
# operationId: listAbilities
export def "abilities listAbilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<abilities: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/abilities")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test an ability
#
# GET /abilities/{id}
# operationId: getAbility
export def "abilities get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/abilities/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List installed Add-ons
#
# GET /addons
# operationId: listAddon
export def "addons listAddon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --include: string@include-completer # Array of additional Models to include in response.
  --service-ids: list # Filters the results, showing only Add-ons for the given services
  --filter: string@filter-completer # Filters the results, showing only Add-ons of the given type
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, addons: table<src: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "include[]" $include "scalar") (serialize-qp "service_ids[]" $service_ids "multi") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addons" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install an Add-on
#
# POST /addons
# operationId: createAddon
export def "addons createAddon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  addon: any
]: any -> record<addon: record<src: string, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addons")
  let body = {addon: $addon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Add-on
#
# GET /addons/{id}
# operationId: getAddon
export def "addons get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<addon: record<type: string, name: string, src: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addons/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Add-on
#
# DELETE /addons/{id}
# operationId: deleteAddon
export def "addons delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addons/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Add-on
#
# PUT /addons/{id}
# operationId: updateAddon
export def "addons updateAddon" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  addon: any
]: any -> record<addon: record<type: string, name: string, src: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addons/($id)")
  let body = {addon: $addon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List alert grouping settings
#
# GET /alert_grouping_settings
# operationId: listAlertGroupingSettings
export def "alert-grouping-settings listAlertGroupingSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor to retrieve next page; only present if next page exists.
  --before: string # Cursor to retrieve previous page; only present if not on first page.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --limit: int # The number of results per page.
  --service-ids: list # An array of service IDs. Only results related to these services will be returned.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<alert_grouping_settings: table<id: string, name: string, description: string, type: string, config: any, services: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "service_ids[]" $service_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/alert_grouping_settings" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Alert Grouping Setting
#
# POST /alert_grouping_settings
# operationId: postAlertGroupingSettings
# --alert_grouping_setting shape: {name?: string, description?: string, type?: "content_based"|"content_based_intelligent"|"intelligent"|"time", config?: any, services?: list}
export def "alert-grouping-settings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  alert_grouping_setting: record # Defines how alerts will be automatically grouped into incidents based on the configurations defined. Note that the Alert Grouping Setting features are available only on certain plans. — shape: {name?: string, description?: string, type?: "content_based"|"content_based_intelligent"|"intelligent"|"time", config?: any, services?: list}
]: any -> record<alert_grouping_setting: record<id: string, name: string, description: string, type: string, config: any, services: list<record>, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alert_grouping_settings")
  let body = {alert_grouping_setting: $alert_grouping_setting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Alert Grouping Setting
#
# GET /alert_grouping_settings/{id}
# operationId: getAlertGroupingSetting
export def "alert-grouping-settings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<alert_grouping_setting: record<id: string, name: string, description: string, type: string, config: any, services: list<record>, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert_grouping_settings/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Alert Grouping Setting
#
# DELETE /alert_grouping_settings/{id}
# operationId: deleteAlertGroupingSetting
export def "alert-grouping-settings delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert_grouping_settings/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Alert Grouping Setting
#
# PUT /alert_grouping_settings/{id}
# operationId: putAlertGroupingSetting
# --alert_grouping_setting shape: {name?: string, description?: string, type?: "content_based"|"content_based_intelligent"|"intelligent"|"time", config?: any, services?: list}
export def "alert-grouping-settings put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  alert_grouping_setting: record # Defines how alerts will be automatically grouped into incidents based on the configurations defined. Note that the Alert Grouping Setting features are available only on certain plans. — shape: {name?: string, description?: string, type?: "content_based"|"content_based_intelligent"|"intelligent"|"time", config?: any, services?: list}
]: any -> record<alert_grouping_setting: record<id: string, name: string, description: string, type: string, config: any, services: list<record>, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert_grouping_settings/($id)")
  let body = {alert_grouping_setting: $alert_grouping_setting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated incident data
#
# POST /analytics/metrics/incidents/all
# operationId: getAnalyticsMetricsIncidentsAll
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, p50_seconds_to_first_ack: int, p50_seconds_to_resolve: int, p75_seconds_to_first_ack: int, p75_seconds_to_resolve: int, p90_seconds_to_first_ack: int, p90_seconds_to_resolve: int, p95_seconds_to_first_ack: int, p95_seconds_to_resolve: int, range_start: string, service_id: string, service_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/all")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated escalation policy data
#
# POST /analytics/metrics/incidents/escalation_policies
# operationId: getAnalyticsMetricsIncidentsEscalationPolicy
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-escalation-policies post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<distinct_responder_count: int, escalation_policy_id: string, escalation_policy_name: string, mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, range_start: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/escalation_policies")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated metrics for all escalation policies
#
# POST /analytics/metrics/incidents/escalation_policies/all
# operationId: getAnalyticsMetricsIncidentsEscalationPolicyAll
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-escalation-policies-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<distinct_responder_count: int, escalation_policy_id: string, escalation_policy_name: string, mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, range_start: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/escalation_policies/all")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated service data
#
# POST /analytics/metrics/incidents/services
# operationId: getAnalyticsMetricsIncidentsService
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-services post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, range_start: string, service_id: string, service_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/services")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated metrics for all services
#
# POST /analytics/metrics/incidents/services/all
# operationId: getAnalyticsMetricsIncidentsServiceAll
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-services-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, range_start: string, service_id: string, service_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/services/all")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated team data
#
# POST /analytics/metrics/incidents/teams
# operationId: getAnalyticsMetricsIncidentsTeam
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, range_start: string, service_id: string, service_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/teams")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated metrics for all teams
#
# POST /analytics/metrics/incidents/teams/all
# operationId: getAnalyticsMetricsIncidentsTeamAll
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
export def "analytics-metrics-incidents-teams-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list, pd_advance_used?: bool}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. created_at)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by.  If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
]: any -> record<data: table<mean_assignment_count: int, mean_engaged_seconds: int, mean_engaged_user_count: int, mean_seconds_to_engage: int, mean_seconds_to_first_ack: int, mean_seconds_to_mobilize: int, mean_seconds_to_resolve: int, mean_user_defined_engaged_seconds: int, range_start: string, service_id: string, service_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_escalation_count: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_auto_resolved: any, total_incidents_manual_escalated: int, total_incidents_reassigned: int, total_incidents_timeout_escalated: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_sleep_hour_interruptions: int, total_snoozed_seconds: int, total_user_defined_engaged_seconds: int, up_time_pct: float>, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, pd_advance_used: bool>, time_zone: string, order: string, order_by: string, aggregate_unit: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/incidents/teams/all")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated PD Advance usage data
#
# POST /analytics/metrics/pd_advance_usage/features
# operationId: getAnalyticsMetricsPdAdvanceUsageFeatures
# --filters shape: {created_at_start?: string, created_at_end?: string, incident_created_at_start?: string, incident_created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list}
export def "analytics-metrics-pd-advance-usage-features post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results. — shape: {created_at_start?: string, created_at_end?: string, incident_created_at_start?: string, incident_created_at_end?: string, urgency?: "high"|"low", major?: bool, min_ackowledgements?: int, min_timeout_escalations?: int, min_manual_escalations?: int, team_ids?: list, service_ids?: list, escalation_policy_ids?: list, priority_ids?: list, priority_names?: list}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
]: any -> record<data: table<feature_id: string, total_credits_used: int, total_use_count: int, total_proactive_credits_used: int, total_proactive_use_count: int>, filters: record<created_at_start: string, created_at_end: string, incident_created_at_start: string, incident_created_at_end: string, urgency: string, major: bool, min_ackowledgements: int, min_timeout_escalations: int, min_manual_escalations: int, team_ids: list<string>, service_ids: list<string>, escalation_policy_ids: list<string>, priority_ids: list<string>, priority_names: list<string>>, time_zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/pd_advance_usage/features")
  let body = {filters: $filters, time_zone: $time_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated metrics for all responders
#
# POST /analytics/metrics/responders/all
# operationId: getAnalyticsMetricsRespondersAll
# --filters shape: {date_range_start?: string, date_range_end?: string, urgency?: "high"|"low", team_ids?: list, responder_ids?: list, priority_ids?: list, priority_names?: list}
export def "analytics-metrics-responders-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results — shape: {date_range_start?: string, date_range_end?: string, urgency?: "high"|"low", team_ids?: list, responder_ids?: list, priority_ids?: list, priority_names?: list}
  --time-zone: string # The time zone to use for the results and grouping. (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. user_id)
]: any -> record<data: table<mean_engaged_seconds: int, mean_time_to_acknowledge_seconds: int, responder_id: int, responder_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_manual_escalated_from: int, total_incidents_manual_escalated_to: int, total_incidents_reassigned_from: int, total_incidents_reassigned_to: int, total_incidents_timeout_escalated_from: int, total_incidents_timeout_escalated_to: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_seconds_on_call: int, total_seconds_on_call_level_1: int, total_seconds_on_call_level_2_plus: int, total_sleep_hour_interruptions: int>, filters: record<date_range_start: string, date_range_end: string, urgency: string, team_ids: list<string>, responder_ids: list<string>, priority_ids: list<string>, priority_names: list<string>>, time_zone: string, order: string, order_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/responders/all")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get responder data aggregated by team
#
# POST /analytics/metrics/responders/teams
# operationId: getAnalyticsMetricsRespondersTeam
# --filters shape: {date_range_start?: string, date_range_end?: string, urgency?: "high"|"low", team_ids?: list, responder_ids?: list, priority_ids?: list, priority_names?: list}
export def "analytics-metrics-responders-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Accepts a set of filters to apply to the Incidents before aggregating.  Any incidents that do not match the included filters will be omitted from the results — shape: {date_range_start?: string, date_range_end?: string, urgency?: "high"|"low", team_ids?: list, responder_ids?: list, priority_ids?: list, priority_names?: list}
  --time-zone: string # The time zone to use for the results and grouping. (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending.
  --order-by: string # The column that was used for ordering the results. (e.g. user_id)
]: any -> record<data: table<mean_engaged_seconds: int, mean_time_to_acknowledge_seconds: int, responder_id: int, responder_name: string, team_id: string, team_name: string, total_business_hour_interruptions: int, total_engaged_seconds: int, total_incident_count: int, total_incidents_acknowledged: int, total_incidents_manual_escalated_from: int, total_incidents_manual_escalated_to: int, total_incidents_reassigned_from: int, total_incidents_reassigned_to: int, total_incidents_timeout_escalated_from: int, total_incidents_timeout_escalated_to: int, total_interruptions: int, total_notifications: int, total_off_hour_interruptions: int, total_seconds_on_call: int, total_seconds_on_call_level_1: int, total_seconds_on_call_level_2_plus: int, total_sleep_hour_interruptions: int>, filters: record<date_range_start: string, date_range_end: string, urgency: string, team_ids: list<string>, responder_ids: list<string>, priority_ids: list<string>, priority_names: list<string>>, time_zone: string, order: string, order_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/responders/teams")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregated metrics for all users
#
# POST /analytics/metrics/users/all
# operationId: getAnalyticsMetricsUsersAll
# --filters shape: {created_at_start?: string, created_at_end?: string, team_ids?: list, user_ids?: list, role_ids?: list}
export def "analytics-metrics-users-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # shape: {created_at_start?: string, created_at_end?: string, team_ids?: list, user_ids?: list, role_ids?: list}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending. (default: desc)
  --order-by: string # The column that was used for ordering the results. (default: user_id, e.g. user_id)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by. If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
  --limit: int # The maximum number of results to return per page. The default (and maximum allowed value) is 1000. (default: 1000)
  --starting-after: string # A cursor used for pagination. Starting after cursor provides the next set of results in forward pagination order. (nullable)
  --ending-before: string # A cursor used for pagination. Ending before cursor provides the previous set of results in reverse pagination order. (nullable)
]: any -> record<data: table<total_downloaded_mobile_app_count: int, total_downloaded_mobile_app_percentage: float, total_on_escalation_policy_count: int, total_on_escalation_policy_percentage: float, total_signed_up_count: int, total_signed_up_percentage: float, total_user_count: int, total_with_notification_methods_count: int, total_with_notification_methods_percentage: float>, filters: record<created_at_start: string, created_at_end: string, team_ids: list<string>>, time_zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/metrics/users/all")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit, limit: $limit, starting_after: $starting_after, ending_before: $ending_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get raw data - multiple incidents
#
# POST /analytics/raw/incidents
# operationId: getAnalyticsIncidents
# --filters shape: {created_at_start?: string, created_at_end?: string, updated_after?: string, urgency?: string, major?: bool, team_ids?: list, service_ids?: list, priority_ids?: list, priority_names?: list, incident_type_ids?: list}
export def "analytics-raw-incidents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Filters the result, only show incidents that match the conditions passed in the filter. — shape: {created_at_start?: string, created_at_end?: string, updated_after?: string, urgency?: string, major?: bool, team_ids?: list, service_ids?: list, priority_ids?: list, priority_names?: list, incident_type_ids?: list}
  --starting-after: string # A cursor to indicate the reference point that the results should follow
  --ending-before: string # A cursor to indicate the reference point that the results should precede
  --order: string@order-completer # The order the results;  asc for ascending, desc for descending. Defaults to 'desc'.
  --order-by: string@order-by-completer # The column to use for ordering the results. Defaults to 'created_at'.
  --limit: int # Number of results to include in each batch. Limits between 1 to 1000 are accepted. (e.g. 20)
  --time-zone: string # The time zone to use for the results. (e.g. Etc/UTC)
]: any -> record<first: string, last: string, limit: int, more: bool, order: string, order_by: string, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, team_ids: list<string>, service_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, incident_type_ids: list<string>>, time_zone: string, data: table<acknowledged_user_ids: list, acknowledged_user_names: list, acknowledgement_count: int, active_user_count: int, assigned_user_ids: list, assigned_user_names: list, assignment_count: int, auto_resolved: bool, business_hour_interruptions: int, created_at: string, updated_at: string, description: string, engaged_seconds: int, engaged_user_count: int, escalation_count: int, escalation_policy_id: string, escalation_policy_name: string, id: string, incident_number: int, incident_type_id: string, incident_type_name: string, joined_user_ids: list, joined_user_names: list, major: bool, manual_escalation_count: int, off_hour_interruptions: int, priority_id: string, priority_name: string, priority_order: int, reassignment_count: int, resolved_at: string, resolved_by_user_id: string, resolved_by_user_name: string, seconds_to_engage: int, seconds_to_first_ack: int, seconds_to_mobilize: int, seconds_to_resolve: int, service_id: string, service_name: string, sleep_hour_interruptions: int, snoozed_seconds: int, status: string, team_id: string, team_name: string, timeout_escalation_count: int, total_interruptions: int, total_notifications: int, urgency: string, user_defined_effort_seconds: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/raw/incidents")
  let body = {filters: $filters, starting_after: $starting_after, ending_before: $ending_before, order: $order, order_by: $order_by, limit: $limit, time_zone: $time_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get raw data - single incident
#
# GET /analytics/raw/incidents/{id}
# operationId: getAnalyticsIncidentsById
export def "analytics-raw-incidents get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<acknowledged_user_ids: list<string>, acknowledged_user_names: list<string>, acknowledgement_count: int, active_user_count: int, assigned_user_ids: list<string>, assigned_user_names: list<string>, assignment_count: int, auto_resolved: bool, business_hour_interruptions: int, created_at: string, updated_at: string, description: string, engaged_seconds: int, engaged_user_count: int, escalation_count: int, escalation_policy_id: string, escalation_policy_name: string, id: string, incident_number: int, incident_type_id: string, incident_type_name: string, joined_user_ids: list<string>, joined_user_names: list<string>, major: bool, manual_escalation_count: int, off_hour_interruptions: int, priority_id: string, priority_name: string, priority_order: int, reassignment_count: int, resolved_at: string, resolved_by_user_id: string, resolved_by_user_name: string, seconds_to_engage: int, seconds_to_first_ack: int, seconds_to_mobilize: int, seconds_to_resolve: int, service_id: string, service_name: string, sleep_hour_interruptions: int, snoozed_seconds: int, status: string, team_id: string, team_name: string, timeout_escalation_count: int, total_interruptions: int, total_notifications: int, urgency: string, user_defined_effort_seconds: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analytics/raw/incidents/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get raw responses from a single incident
#
# GET /analytics/raw/incidents/{id}/responses
# operationId: getAnalyticsIncidentResponsesById
export def "analytics-raw-incidents-responses get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --limit: int # Number of results to include in each batch. Limits between 1 to 1000 are accepted. (e.g. 20)
  --order: string@order-completer # The order in which to display the results; asc for ascending, desc for descending. Defaults to `desc`.
  --order-by: string@order-by-completer-1 # The column to use for ordering the results.
  --time-zone: string # The time zone to use for the results. (e.g. Etc/UTC)
]: any -> record<incident_id: string, limit: int, order: string, order_by: string, time_zone: string, responses: table<responder_name: string, responder_id: string, response_status: string, responder_type: string, requested_at: string, responded_at: string, time_to_respond_seconds: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analytics/raw/incidents/($id)/responses")
  let body = {limit: $limit, order: $order, order_by: $order_by, time_zone: $time_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get raw incidents for a single responder_id
#
# POST /analytics/raw/responders/{responder_id}/incidents
# operationId: getAnalyticsResponderIncidents
# --filters shape: {created_at_start?: string, created_at_end?: string, urgency?: string, major?: bool, team_ids?: list, service_ids?: list, priority_ids?: list, priority_names?: list, incident_type_ids?: list}
export def "analytics-raw-responders-incidents post" [
  responder_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # Filters the result, only show incidents that match the conditions passed in the filter. — shape: {created_at_start?: string, created_at_end?: string, urgency?: string, major?: bool, team_ids?: list, service_ids?: list, priority_ids?: list, priority_names?: list, incident_type_ids?: list}
  --starting-after: string # A cursor to indicate the reference point that the results should follow
  --ending-before: string # A cursor to indicate the reference point that the results should precede
  --order: string@order-completer # The order in which to display the results; asc for ascending, desc for descending. Defaults to `desc`.
  --order-by: string@order-by-completer-2 # The column to use for ordering the results. Defaults to `incident_created_at`.
  --limit: int # Number of results to include in each batch. Limits between 1 to 1000 are accepted. (e.g. 20)
  --time-zone: string # The time zone to use for the results. (e.g. Etc/UTC)
]: any -> record<first: string, last: string, responder_id: string, limit: int, order: string, order_by: string, time_zone: string, filters: record<created_at_start: string, created_at_end: string, urgency: string, major: bool, team_ids: list<string>, service_ids: list<string>, priority_ids: list<string>, priority_names: list<string>, incident_type_ids: list<string>>, data: table<incident_created_at: string, incident_description: string, incident_id: string, incident_number: int, incident_priority_id: string, incident_priority_name: string, incident_priority_order: int, incident_urgency: string, mean_time_to_acknowledge_seconds: int, responder_id: string, responder_name: string, service_id: string, service_name: string, service_team_id: string, service_team_name: string, total_acknowledgements: int, total_business_hour_interruptions: int, total_engaged_seconds: int, total_interruptions: int, total_manual_escalations_from: int, total_manual_escalations_to: int, total_off_hour_interruptions: string, total_reassignments_from: int, total_reassignments_to: int, total_sleep_hour_interruptions: int, total_timeout_escalations_from: int, total_timeout_escalations_to: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analytics/raw/responders/($responder_id)/incidents")
  let body = {filters: $filters, starting_after: $starting_after, ending_before: $ending_before, order: $order, order_by: $order_by, limit: $limit, time_zone: $time_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get raw user analytics data
#
# POST /analytics/raw/users
# operationId: getAnalyticsUsers
# --filters shape: {created_at_start?: string, created_at_end?: string, team_ids?: list, user_ids?: list, role_ids?: list}
export def "analytics-raw-users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --filters: record # shape: {created_at_start?: string, created_at_end?: string, team_ids?: list, user_ids?: list, role_ids?: list}
  --time-zone: string # The time zone to use for the results and grouping. Must be in tzdata format. See list of accepted values [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). (e.g. Etc/UTC)
  --order: string@order-completer # The order in which the results were sorted; asc for ascending, desc for descending. (default: desc)
  --order-by: string # The column that was used for ordering the results. (default: user_id, e.g. user_id)
  --aggregate-unit: string@aggregate-unit-completer # The time unit to aggregate metrics by. If no value is provided, the metrics will be aggregated for the entire period. (nullable, e.g. day)
  --limit: int # The maximum number of results to return per page. The default (and maximum allowed value) is 1000. (default: 1000)
  --starting-after: string # A cursor used for pagination. Starting after cursor provides the next set of results in forward pagination order. (nullable)
  --ending-before: string # A cursor used for pagination. Ending before cursor provides the previous set of results in reverse pagination order. (nullable)
]: any -> record<first: string, last: string, limit: int, more: bool, order: string, order_by: string, filters: record<created_at_start: string, created_at_end: string, team_ids: list<string>, roles: list<string>>, time_zone: string, data: table<id: string, user_name: string, email: string, account_id: int, description: string, time_zone: string, role: string, team_id: string, team_name: string, created_at: string, last_sign_in_at: string, default_notification_channel_count: int, escalation_policies_count: int, schedules_count: int, channel_types_configured: list, team_count: int, downloaded_mobile_app: bool, notification_methods: bool, on_escalation_policy: bool, on_schedule: bool, signed_up: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/raw/users")
  let body = {filters: $filters, time_zone: $time_zone, order: $order, order_by: $order_by, aggregate_unit: $aggregate_unit, limit: $limit, starting_after: $starting_after, ending_before: $ending_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit records
#
# GET /audit/records
# operationId: listAuditRecords
export def "audit-records listAuditRecords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --root-resource-types: string@root-resource-types-completer # Resource type filter for the root_resource. (e.g. users)
  --actor-type: string@actor-type-completer # Actor type filter. (e.g. user_reference)
  --actor-id: string # Actor Id filter. Must be qualified by providing the `actor_type` param. (e.g. P123456)
  --method-type: string@method-type-completer # Method type filter.
  --method-truncated-token: string # Method truncated_token filter. Must be qualified by providing the `method_type` param. (e.g. 3xyz)
  --actions: string@actions-completer # Action filter
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "root_resource_types[]" $root_resource_types "scalar") (serialize-qp "actor_type" $actor_type "scalar") (serialize-qp "actor_id" $actor_id "scalar") (serialize-qp "method_type" $method_type "scalar") (serialize-qp "method_truncated_token" $method_truncated_token "scalar") (serialize-qp "actions[]" $actions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Automation Action
#
# POST /automation_actions/actions
# operationId: createAutomationAction
export def "automation-actions-actions createAutomationAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  action: any
]: any -> record<action: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automation_actions/actions")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Automation Actions
#
# GET /automation_actions/actions
# operationId: getAllAutomationActions
export def "automation-actions-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --name: string # Filters results to include the ones matching the name (case insensitive substring matching)
  --runner-id: string # Filters results to include the ones linked to the specified runner. Specifying the value `any` filters results to include the ones linked to runners only, thus omitting the results not linked to runners.
  --classification: string@classification-completer # Filters results to include the ones matching the specified classification (aka category) (nullable)
  --team-id: string # Filters results to include the ones associated with the specified team.
  --service-id: string # Filters results to include the ones associated with the specified service
  --action-type: string@action-type-completer # Filters results to include the ones matching the specified action type (e.g. process_automation)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<actions: list<any>, privileges: record<permissions: list<string>>, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "runner_id" $runner_id "scalar") (serialize-qp "classification" $classification "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "action_type" $action_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/automation_actions/actions" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Automation Action
#
# GET /automation_actions/actions/{id}
# operationId: getAutomationAction
export def "automation-actions-actions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<action: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Automation Action
#
# DELETE /automation_actions/actions/{id}
# operationId: deleteAutomationAction
export def "automation-actions-actions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Automation Action
#
# PUT /automation_actions/actions/{id}
# operationId: updateAutomationAction
export def "automation-actions-actions updateAutomationAction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  action: any
]: any -> record<action: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an Invocation
#
# POST /automation_actions/actions/{id}/invocations
# operationId: createAutomationActionInvocation
# --invocation shape: {metadata: record}
export def "automation-actions-actions-invocations createAutomationActionInvocation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  invocation: record # shape: {metadata: record}
]: any -> record<invocation: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/invocations")
  let body = {invocation: $invocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all service references associated with an Automation Action
#
# GET /automation_actions/actions/{id}/services
# operationId: getAutomationActionsActionServiceAssociations
export def "automation-actions-actions-services list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<services: table<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/services")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate an Automation Action with a service
#
# POST /automation_actions/actions/{id}/services
# operationId: createAutomationActionServiceAssocation
export def "automation-actions-actions-services createAutomationActionServiceAssocation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  service: any
]: any -> record<service: record<type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/services")
  let body = {service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the details of an Automation Action / service relation
#
# GET /automation_actions/actions/{id}/services/{service_id}
# operationId: getAutomationActionsActionServiceAssociation
export def "automation-actions-actions-services get" [
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<service: record<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/services/($service_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociate an Automation Action from a service
#
# DELETE /automation_actions/actions/{id}/services/{service_id}
# operationId: deleteAutomationActionServiceAssociation
export def "automation-actions-actions-services delete" [
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/services/($service_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate an Automation Action with a team
#
# POST /automation_actions/actions/{id}/teams
# operationId: createAutomationActionTeamAssociation
export def "automation-actions-actions-teams createAutomationActionTeamAssociation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  team: any
]: any -> record<team: record<type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/teams")
  let body = {team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all team references associated with an Automation Action
#
# GET /automation_actions/actions/{id}/teams
# operationId: getAutomationActionsActionTeamAssociations
export def "automation-actions-actions-teams list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<teams: table<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/teams")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociate an Automation Action from a team
#
# DELETE /automation_actions/actions/{id}/teams/{team_id}
# operationId: deleteAutomationActionTeamAssociation
export def "automation-actions-actions-teams delete" [
  id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/teams/($team_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of an Automation Action / team relation
#
# GET /automation_actions/actions/{id}/teams/{team_id}
# operationId: getAutomationActionsActionTeamAssociation
export def "automation-actions-actions-teams get" [
  id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<team: record<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/actions/($id)/teams/($team_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Invocations
#
# GET /automation_actions/invocations
# operationId: listAutomationActionInvocations
export def "automation-actions-invocations listAutomationActionInvocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invocation-state: string@invocation-state-completer # Invocation state (e.g. sent)
  --not-invocation-state: string # Invocation state inverse filter (matches invocations NOT in the specified state)
  --incident-id: string # Incident ID (e.g. Q2LAR4ADCXC8IB)
  --action-id: string # Action ID (e.g. 01DAW70HK24JZORNE0P9C2V1L9)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<invocations: table<action_snapshot: record, runner_id: string, timing: list, duration: int, state: any, action_id: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invocation_state" $invocation_state "scalar") (serialize-qp "not_invocation_state" $not_invocation_state "scalar") (serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "action_id" $action_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/automation_actions/invocations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Invocation
#
# GET /automation_actions/invocations/{id}
# operationId: getAutomationActionsInvocation
export def "automation-actions-invocations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<invocation: record<action_snapshot: record<name: string, action_type: any, action_data_reference: any>, runner_id: string, timing: list<record>, duration: int, state: any, action_id: string, metadata: record<agent: any, incident: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/invocations/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Automation Action runner.
#
# POST /automation_actions/runners
# operationId: createAutomationActionsRunner
export def "automation-actions-runners createAutomationActionsRunner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  runner: any
]: any -> record<runner: record<secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automation_actions/runners")
  let body = {runner: $runner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Automation Action runners
#
# GET /automation_actions/runners
# operationId: getAutomationActionsRunners
export def "automation-actions-runners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --name: string # Filters results to include the ones matching the name (case insensitive substring matching)
  --include: list # Includes additional data elements into the response
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<runners: table<runner_type: string, name: string, description: string, last_seen: string, status: string, creation_time: string, runbook_base_uri: string, teams: list, privileges: record, associated_actions: record, metadata: record>, privileges: record<permissions: list<string>>, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/automation_actions/runners" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Automation Action runner
#
# GET /automation_actions/runners/{id}
# operationId: getAutomationActionsRunner
export def "automation-actions-runners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<runner: record<runner_type: string, name: string, description: string, last_seen: string, status: string, creation_time: string, runbook_base_uri: string, teams: list<record>, privileges: record<permissions: list>, associated_actions: record<actions: list, more: bool>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Automation Action runner
#
# PUT /automation_actions/runners/{id}
# operationId: updateAutomationActionsRunner
export def "automation-actions-runners updateAutomationActionsRunner" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  runner: any
]: any -> record<runner: record<runner_type: string, name: string, description: string, last_seen: string, status: string, creation_time: string, runbook_base_uri: string, teams: list<record>, privileges: record<permissions: list>, associated_actions: record<actions: list, more: bool>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)")
  let body = {runner: $runner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Automation Action runner
#
# DELETE /automation_actions/runners/{id}
# operationId: deleteAutomationActionsRunner
export def "automation-actions-runners delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a runner with a team
#
# POST /automation_actions/runners/{id}/teams
# operationId: createAutomationActionsRunnerTeamAssociation
export def "automation-actions-runners-teams createAutomationActionsRunnerTeamAssociation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  team: any
]: any -> record<team: record<type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)/teams")
  let body = {team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all team references associated with a runner
#
# GET /automation_actions/runners/{id}/teams
# operationId: getAutomationActionsRunnerTeamAssociations
export def "automation-actions-runners-teams list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<teams: table<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)/teams")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociate a runner from a team
#
# DELETE /automation_actions/runners/{id}/teams/{team_id}
# operationId: deleteAutomationActionsRunnerTeamAssociation
export def "automation-actions-runners-teams delete" [
  id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)/teams/($team_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of a runner / team relation
#
# GET /automation_actions/runners/{id}/teams/{team_id}
# operationId: getAutomationActionsRunnerTeamAssociation
export def "automation-actions-runners-teams get" [
  id: string
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<team: record<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation_actions/runners/($id)/teams/($team_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Business Services
#
# GET /business_services
# operationId: listBusinessServices
export def "business-services listBusinessServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, business_services: table<name: string, description: string, point_of_contact: string, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business_services" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Business Service
#
# POST /business_services
# operationId: createBusinessService
# --business_service shape: {name?: string, description?: string, point_of_contact?: string, team?: record}
export def "business-services createBusinessService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --business-service: record # The Business Service to be created — shape: {name?: string, description?: string, point_of_contact?: string, team?: record}
]: any -> record<business_service: record<name: string, description: string, point_of_contact: string, team: record<id: string, type: string, self: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_services")
  let body = {business_service: $business_service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Business Service
#
# GET /business_services/{id}
# operationId: getBusinessService
export def "business-services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<business_service: record<name: string, description: string, point_of_contact: string, team: record<id: string, type: string, self: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Business Service
#
# DELETE /business_services/{id}
# operationId: deleteBusinessService
export def "business-services delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Business Service
#
# PUT /business_services/{id}
# operationId: updateBusinessService
# --business_service shape: {name?: string, description?: string, point_of_contact?: string, team?: record}
export def "business-services updateBusinessService" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --business-service: record # The Business Service to be created — shape: {name?: string, description?: string, point_of_contact?: string, team?: record}
]: any -> record<business_service: record<name: string, description: string, point_of_contact: string, team: record<id: string, type: string, self: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)")
  let body = {business_service: $business_service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Business Service Account Subscription
#
# POST /business_services/{id}/account_subscription
# operationId: createBusinessServiceAccountSubscription
export def "business-services-account-subscription createBusinessServiceAccountSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<account_is_subscribed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)/account_subscription")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Business Service Account Subscription
#
# DELETE /business_services/{id}/account_subscription
# operationId: removeBusinessServiceAccountSubscription
export def "business-services-account-subscription removeBusinessServiceAccountSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)/account_subscription")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Business Service Subscribers
#
# GET /business_services/{id}/subscribers
# operationId: getBusinessServiceSubscribers
export def "business-services-subscribers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, subscribers: table<subscriber_id: string, subscriber_type: string>, account_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)/subscribers")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Business Service Subscribers
#
# POST /business_services/{id}/subscribers
# operationId: createBusinessServiceNotificationSubscribers
# --subscribers item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
export def "business-services-subscribers createBusinessServiceNotificationSubscribers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribers: list # item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
]: any -> record<subscriptions: table<subscriber_id: string, subscriber_type: string, subscribable_id: string, subscribable_type: string, account_id: string, result: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)/subscribers")
  let body = {subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the supporting Business Services for the given Business Service Id, sorted by impacted status.
#
# GET /business_services/{id}/supporting_services/impacts
# operationId: getBusinessServiceSupportingServiceImpacts
export def "business-services-supporting-services-impacts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-fields: string@additional-fields-completer # Provides access to additional fields such as highest priority per business service and total impacted count
  --ids: string # The IDs of the resources.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, more: bool, services: table<id: string, name: string, type: string, status: string, additional_fields: record>, additional_fields: record<total_impacted_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional_fields[]" $additional_fields "scalar") (serialize-qp "ids[]" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/business_services/($id)/supporting_services/impacts" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Business Service Subscribers
#
# POST /business_services/{id}/unsubscribe
# operationId: removeBusinessServiceNotificationSubscriber
# --subscribers item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
export def "business-services-unsubscribe removeBusinessServiceNotificationSubscriber" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribers: list # item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
]: any -> record<deleted_count: float, unauthorized_count: float, non_existent_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business_services/($id)/unsubscribe")
  let body = {subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Impactors affecting Business Services
#
# GET /business_services/impactors
# operationId: getBusinessServiceTopLevelImpactors
export def "business-services-impactors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The IDs of the resources.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, more: bool, impactors: table<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business_services/impactors" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Business Services sorted by impacted status
#
# GET /business_services/impacts
# operationId: getBusinessServiceImpacts
export def "business-services-impacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-fields: string@additional-fields-completer # Provides access to additional fields such as highest priority per business service and total impacted count
  --ids: string # The IDs of the resources.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, more: bool, services: table<id: string, name: string, type: string, status: string, additional_fields: record>, additional_fields: record<total_impacted_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional_fields[]" $additional_fields "scalar") (serialize-qp "ids[]" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business_services/impacts" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the global priority threshold for a Business Service to be considered impacted by an Incident
#
# GET /business_services/priority_thresholds
# operationId: getBusinessServicePriorityThresholds
export def "business-services-priority-thresholds get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<global_threshold: record<id: string, order: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_services/priority_thresholds")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the account-level priority threshold for Business Service impact
#
# DELETE /business_services/priority_thresholds
# operationId: deleteBusinessServicePriorityThresholds
export def "business-services-priority-thresholds delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_services/priority_thresholds")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the Account-level priority threshold for Business Service impact.
#
# PUT /business_services/priority_thresholds
# operationId: putBusinessServicePriorityThresholds
# --global_threshold shape: {id: string, order: float}
export def "business-services-priority-thresholds put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  global_threshold: record # shape: {id: string, order: float}
]: any -> record<global_threshold: record<id: string, order: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_services/priority_thresholds")
  let body = {global_threshold: $global_threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Change Events
#
# GET /change_events
# operationId: listChangeEvents
export def "change-events listChangeEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --integration-ids: list # An array of integration IDs. Only results related to these integrations will be returned.
  --since: string # The start of the date range over which you want to search, as a UTC ISO 8601 datetime string. Will return an HTTP 400 for non-UTC datetimes. (format: date-time)
  --until: string # The end of the date range over which you want to search, as a UTC ISO 8601 datetime string. Will return an HTTP 400 for non-UTC datetimes. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<change_events: table<timestamp: string, type: string, services: list, integration: record, routing_key: string, summary: string, source: string, links: list, images: list, custom_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "integration_ids[]" $integration_ids "multi") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/change_events" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Change Event
#
# POST /change_events
# operationId: createChangeEvent
export def "change-events createChangeEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/change_events")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Change Event
#
# GET /change_events/{id}
# operationId: getChangeEvent
export def "change-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<change_event: record<timestamp: string, type: string, services: list<record>, integration: record, routing_key: string, summary: string, source: string, links: list<record>, images: list<record>, custom_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/change_events/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Change Event
#
# PUT /change_events/{id}
# operationId: updateChangeEvent
export def "change-events updateChangeEvent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  change_event: any
]: any -> record<change_event: record<timestamp: string, type: string, services: list<record>, integration: record, routing_key: string, summary: string, source: string, links: list<record>, images: list<record>, custom_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/change_events/($id)")
  let body = {change_event: $change_event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List escalation policies
#
# GET /escalation_policies
# operationId: listEscalationPolicies
export def "escalation-policies listEscalationPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --user-ids: list # Filters the results, showing only escalation policies on which any of the users is a target.
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --include: string@include-completer-1 # Array of additional Models to include in response.
  --sort-by: string@sort-by-completer # Used to specify the field you wish to sort the results on. (default: name)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, escalation_policies: table<type: string, name: string, description: string, num_loops: int, on_call_handoff_notifications: string, escalation_rules: list, services: list, teams: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "user_ids[]" $user_ids "multi") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "include[]" $include "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/escalation_policies" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an escalation policy
#
# POST /escalation_policies
# operationId: createEscalationPolicy
export def "escalation-policies createEscalationPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request. This is optional, and is only used for change tracking.
  escalation_policy: any
]: any -> record<escalation_policy: record<type: string, name: string, description: string, num_loops: int, on_call_handoff_notifications: string, escalation_rules: list<record>, services: list<record>, teams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/escalation_policies")
  let body = {escalation_policy: $escalation_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an escalation policy
#
# GET /escalation_policies/{id}
# operationId: getEscalationPolicy
export def "escalation-policies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-1 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<escalation_policy: record<type: string, name: string, description: string, num_loops: int, on_call_handoff_notifications: string, escalation_rules: list<record>, services: list<record>, teams: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/escalation_policies/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an escalation policy
#
# DELETE /escalation_policies/{id}
# operationId: deleteEscalationPolicy
export def "escalation-policies delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation_policies/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an escalation policy
#
# PUT /escalation_policies/{id}
# operationId: updateEscalationPolicy
export def "escalation-policies updateEscalationPolicy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  escalation_policy: any
]: any -> record<escalation_policy: record<type: string, name: string, description: string, num_loops: int, on_call_handoff_notifications: string, escalation_rules: list<record>, services: list<record>, teams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation_policies/($id)")
  let body = {escalation_policy: $escalation_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit records for an escalation policy
#
# GET /escalation_policies/{id}/audit/records
# operationId: listEscalationPolicyAuditRecords
export def "escalation-policies-audit-records listEscalationPolicyAuditRecords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/escalation_policies/($id)/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Event Orchestrations
#
# GET /event_orchestrations
# operationId: listEventOrchestrations
export def "event-orchestrations listEventOrchestrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --sort-by: string@sort-by-completer-1 # Used to specify the field you wish to sort the results on. (default: name:asc)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, orchestrations: table<id: string, self: string, name: string, description: string, team: record, routes: int, created_at: string, created_by: record, updated_at: string, updated_by: record, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event_orchestrations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Orchestration
#
# POST /event_orchestrations
# operationId: postOrchestration
# --orchestration shape: {name?: string, description?: string, team?: record}
export def "event-orchestrations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  orchestration: record # shape: {name?: string, description?: string, team?: record}
]: any -> record<orchestration: record<id: string, self: string, name: string, description: string, team: record<id: string, type: string, self: string>, integrations: list<record>, routes: int, created_at: string, created_by: record<id: string, type: string, self: string>, updated_at: string, updated_by: record<id: string, type: string, self: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event_orchestrations")
  let body = {orchestration: $orchestration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Orchestration
#
# GET /event_orchestrations/{id}
# operationId: getOrchestration
export def "event-orchestrations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<orchestration: record<id: string, self: string, name: string, description: string, team: record<id: string, type: string, self: string>, integrations: list<record>, routes: int, created_at: string, created_by: record<id: string, type: string, self: string>, updated_at: string, updated_by: record<id: string, type: string, self: string>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Orchestration
#
# PUT /event_orchestrations/{id}
# operationId: updateOrchestration
# --orchestration shape: {name?: string, description?: string, team?: record}
export def "event-orchestrations updateOrchestration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  orchestration: record # shape: {name?: string, description?: string, team?: record}
]: any -> record<orchestration: record<id: string, self: string, name: string, description: string, team: record<id: string, type: string, self: string>, integrations: list<record>, routes: int, created_at: string, created_by: record<id: string, type: string, self: string>, updated_at: string, updated_by: record<id: string, type: string, self: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)")
  let body = {orchestration: $orchestration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Orchestration
#
# DELETE /event_orchestrations/{id}
# operationId: deleteOrchestration
export def "event-orchestrations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Integrations for an Event Orchestration
#
# GET /event_orchestrations/{id}/integrations
# operationId: listOrchestrationIntegrations
export def "event-orchestrations-integrations listOrchestrationIntegrations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<integrations: table<id: string, label: string, parameters: record>, total: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/integrations")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Integration for an Event Orchestration
#
# POST /event_orchestrations/{id}/integrations
# operationId: postOrchestrationIntegration
# --integration shape: {label: string}
export def "event-orchestrations-integrations post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  integration: record # shape: {label: string}
]: any -> record<integration: record<id: string, label: string, parameters: record<routing_key: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/integrations")
  let body = {integration: $integration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Integration for an Event Orchestration
#
# GET /event_orchestrations/{id}/integrations/{integration_id}
# operationId: getOrchestrationIntegration
export def "event-orchestrations-integrations get" [
  id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<integration: record<id: string, label: string, parameters: record<routing_key: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/integrations/($integration_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Integration for an Event Orchestration
#
# PUT /event_orchestrations/{id}/integrations/{integration_id}
# operationId: updateOrchestrationIntegration
# --integration shape: {label: string}
export def "event-orchestrations-integrations updateOrchestrationIntegration" [
  id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  integration: record # shape: {label: string}
]: any -> record<integration: record<id: string, label: string, parameters: record<routing_key: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/integrations/($integration_id)")
  let body = {integration: $integration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Integration for an Event Orchestration
#
# DELETE /event_orchestrations/{id}/integrations/{integration_id}
# operationId: deleteOrchestrationIntegration
export def "event-orchestrations-integrations delete" [
  id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/integrations/($integration_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate an Integration from one Event Orchestration to another
#
# POST /event_orchestrations/{id}/integrations/migration
# operationId: migrateOrchestrationIntegration
export def "event-orchestrations-integrations-migration migrateOrchestrationIntegration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  source_id: string # The ID of the Event Orchestration you'll be moving the Integration away from
  source_type: string@source-type-completer # The type of of the `source_id` object
  integration_id: string # The ID of the Integration you'll be moving
]: any -> record<integrations: table<id: string, label: string, parameters: record>, total: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/integrations/migration")
  let body = {source_id: $source_id, source_type: $source_type, integration_id: $integration_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Global Orchestration for an Event Orchestration
#
# GET /event_orchestrations/{id}/global
# operationId: getOrchPathGlobal
export def "event-orchestrations-global get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<orchestration_path: record<type: any, parent: record<id: any, type: any>, sets: list<record>, catch_all: record<actions: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/global")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Global Orchestration for an Event Orchestration
#
# PUT /event_orchestrations/{id}/global
# operationId: updateOrchPathGlobal
# --orchestration_path shape: {type?: any, parent?: any, sets?: any, catch_all?: any}
export def "event-orchestrations-global updateOrchPathGlobal" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  orchestration_path: any # shape: {type?: any, parent?: any, sets?: any, catch_all?: any}
]: any -> record<warnings: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/global")
  let body = {orchestration_path: $orchestration_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Router for an Event Orchestration
#
# GET /event_orchestrations/{id}/router
# operationId: getOrchPathRouter
export def "event-orchestrations-router get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/router")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Router for an Event Orchestration
#
# PUT /event_orchestrations/{id}/router
# operationId: updateOrchPathRouter
# --orchestration_path shape: {type?: any, parent?: any, sets?: any, catch_all?: any}
export def "event-orchestrations-router updateOrchPathRouter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --orchestration-path: any # shape: {type?: any, parent?: any, sets?: any, catch_all?: any}
]: any -> record<warnings: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/router")
  let body = {orchestration_path: $orchestration_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Unrouted Orchestration for an Event Orchestration
#
# GET /event_orchestrations/{id}/unrouted
# operationId: getOrchPathUnrouted
export def "event-orchestrations-unrouted get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/unrouted")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Unrouted Orchestration for an Event Orchestration
#
# PUT /event_orchestrations/{id}/unrouted
# operationId: updateOrchPathUnrouted
# --orchestration_path shape: {type?: any, parent?: any, sets?: any, catch_all?: any}
export def "event-orchestrations-unrouted updateOrchPathUnrouted" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --orchestration-path: any # shape: {type?: any, parent?: any, sets?: any, catch_all?: any}
]: any -> record<warnings: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/unrouted")
  let body = {orchestration_path: $orchestration_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Service Orchestration for a Service
#
# GET /event_orchestrations/services/{service_id}
# operationId: getOrchPathService
export def "event-orchestrations-services get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-2 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Service Orchestration for a Service
#
# PUT /event_orchestrations/services/{service_id}
# operationId: updateOrchPathService
export def "event-orchestrations-services updateOrchPathService" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --orchestration-path: any
]: any -> record<warnings: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)")
  let body = {orchestration_path: $orchestration_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Service Orchestration active status for a Service
#
# GET /event_orchestrations/services/{service_id}/active
# operationId: getOrchActiveStatus
export def "event-orchestrations-services-active get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/active")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Service Orchestration active status for a Service
#
# PUT /event_orchestrations/services/{service_id}/active
# operationId: updateOrchActiveStatus
export def "event-orchestrations-services-active updateOrchActiveStatus" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/active")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Cache Variables for a Global Event Orchestration
#
# GET /event_orchestrations/{id}/cache_variables
# operationId: listCacheVarOnGlobalOrch
export def "event-orchestrations-cache-variables listCacheVarOnGlobalOrch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Cache Variable for a Global Event Orchestration
#
# POST /event_orchestrations/{id}/cache_variables
# operationId: createCacheVarOnGlobalOrch
export def "event-orchestrations-cache-variables createCacheVarOnGlobalOrch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  cache_variable: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables")
  let body = {cache_variable: $cache_variable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Cache Variable for a Global Event Orchestration
#
# GET /event_orchestrations/{id}/cache_variables/{cache_variable_id}
# operationId: getCacheVarOnGlobalOrch
export def "event-orchestrations-cache-variables get" [
  id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables/($cache_variable_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Cache Variable for a Global Event Orchestration
#
# PUT /event_orchestrations/{id}/cache_variables/{cache_variable_id}
# operationId: updateCacheVarOnGlobalOrch
export def "event-orchestrations-cache-variables updateCacheVarOnGlobalOrch" [
  id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  cache_variable: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables/($cache_variable_id)")
  let body = {cache_variable: $cache_variable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Cache Variable for a Global Event Orchestration
#
# DELETE /event_orchestrations/{id}/cache_variables/{cache_variable_id}
# operationId: deleteCacheVarOnGlobalOrch
export def "event-orchestrations-cache-variables delete" [
  id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables/($cache_variable_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Data for an External Data Cache Variable on a Global Event Orchestration
#
# GET /event_orchestrations/{id}/cache_variables/{cache_variable_id}/data
# operationId: getExternalDataCacheVarDataOnGlobalOrch
export def "event-orchestrations-cache-variables-data get" [
  id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables/($cache_variable_id)/data")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Data for an External Data Cache Variable on a Global Event Orchestration
#
# PUT /event_orchestrations/{id}/cache_variables/{cache_variable_id}/data
# operationId: updateExternalDataCacheVarDataOnGlobalOrch
export def "event-orchestrations-cache-variables-data updateExternalDataCacheVarDataOnGlobalOrch" [
  id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables/($cache_variable_id)/data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Data for an External Data Cache Variable on a Global Event Orchestration
#
# DELETE /event_orchestrations/{id}/cache_variables/{cache_variable_id}/data
# operationId: deleteExternalDataCacheVarDataOnGlobalOrch
export def "event-orchestrations-cache-variables-data delete" [
  id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/cache_variables/($cache_variable_id)/data")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Cache Variables for a Service Event Orchestration
#
# GET /event_orchestrations/services/{service_id}/cache_variables
# operationId: listCacheVarOnServiceOrch
export def "event-orchestrations-services-cache-variables listCacheVarOnServiceOrch" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Cache Variable for a Service Event Orchestration
#
# POST /event_orchestrations/services/{service_id}/cache_variables
# operationId: createCacheVarOnServiceOrch
export def "event-orchestrations-services-cache-variables createCacheVarOnServiceOrch" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  cache_variable: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables")
  let body = {cache_variable: $cache_variable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Cache Variable for a Service Event Orchestration
#
# GET /event_orchestrations/services/{service_id}/cache_variables/{cache_variable_id}
# operationId: getCacheVarOnServiceOrch
export def "event-orchestrations-services-cache-variables get" [
  service_id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables/($cache_variable_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Cache Variable for a Service Event Orchestration
#
# PUT /event_orchestrations/services/{service_id}/cache_variables/{cache_variable_id}
# operationId: updateCacheVarOnServiceOrch
export def "event-orchestrations-services-cache-variables updateCacheVarOnServiceOrch" [
  service_id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  cache_variable: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables/($cache_variable_id)")
  let body = {cache_variable: $cache_variable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Cache Variable for a Service Event Orchestration
#
# DELETE /event_orchestrations/services/{service_id}/cache_variables/{cache_variable_id}
# operationId: deleteCacheVarOnServiceOrch
export def "event-orchestrations-services-cache-variables delete" [
  service_id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables/($cache_variable_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Data for an External Data Cache Variable on a Service Event Orchestration
#
# GET /event_orchestrations/services/{service_id}/cache_variables/{cache_variable_id}/data
# operationId: getExternalDataCacheVarDataOnServiceOrch
export def "event-orchestrations-services-cache-variables-data get" [
  service_id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables/($cache_variable_id)/data")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Data for an External Data Cache Variable on a Service Event Orchestration
#
# PUT /event_orchestrations/services/{service_id}/cache_variables/{cache_variable_id}/data
# operationId: updateExternalDataCacheVarDataOnServiceOrch
export def "event-orchestrations-services-cache-variables-data updateExternalDataCacheVarDataOnServiceOrch" [
  service_id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables/($cache_variable_id)/data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Data for an External Data Cache Variable on a Service Event Orchestration
#
# DELETE /event_orchestrations/services/{service_id}/cache_variables/{cache_variable_id}/data
# operationId: deleteExternalDataCacheVarDataOnServiceOrch
export def "event-orchestrations-services-cache-variables-data delete" [
  service_id: string
  cache_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/services/($service_id)/cache_variables/($cache_variable_id)/data")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Enablements for an Event Orchestration
#
# GET /event_orchestrations/{id}/enablements
# operationId: listEventOrchestrationFeatureEnablements
export def "event-orchestrations-enablements listEventOrchestrationFeatureEnablements" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<enablements: table<feature: string, enabled: bool, updated_at: string, warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/enablements")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Enablement for an Event Orchestration
#
# PUT /event_orchestrations/{id}/enablements/{feature_name}
# operationId: updateEventOrchestrationFeatureEnablements
# --enablement shape: {enabled: bool}
export def "event-orchestrations-enablements updateEventOrchestrationFeatureEnablements" [
  id: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  enablement: record # shape: {enabled: bool}
]: any -> record<enablement: record<feature: string, enabled: bool, updated_at: string, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_orchestrations/($id)/enablements/($feature_name)")
  let body = {enablement: $enablement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List extension schemas
#
# GET /extension_schemas
# operationId: listExtensionSchemas
export def "extension-schemas listExtensionSchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, extension_schemas: table<icon_url: string, logo_url: string, label: string, key: string, description: string, guide_url: string, send_types: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extension_schemas" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an extension vendor
#
# GET /extension_schemas/{id}
# operationId: getExtensionSchema
export def "extension-schemas get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<extension_schema: record<icon_url: string, logo_url: string, label: string, key: string, description: string, guide_url: string, send_types: list<string>, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extension_schemas/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List extensions
#
# GET /extensions
# operationId: listExtensions
export def "extensions listExtensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --extension-object-id: string # The id of the extension object you want to filter by.
  --extension-schema-id: string # Filter the extensions by extension vendor id.
  --include: string@include-completer-3 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, extensions: table<name: string, type: string, endpoint_url: string, extension_objects: list, extension_schema: record, temporarily_disabled: bool, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "extension_object_id" $extension_object_id "scalar") (serialize-qp "extension_schema_id" $extension_schema_id "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an extension
#
# POST /extensions
# operationId: createExtension
export def "extensions createExtension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  extension: any
]: any -> record<extension: record<name: string, type: string, endpoint_url: string, extension_objects: list<record>, extension_schema: record<type: string>, temporarily_disabled: bool, config: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extensions")
  let body = {extension: $extension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an extension
#
# GET /extensions/{id}
# operationId: getExtension
export def "extensions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-4 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<extension: record<name: string, type: string, endpoint_url: string, extension_objects: list<record>, extension_schema: record<type: string>, temporarily_disabled: bool, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/extensions/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an extension
#
# DELETE /extensions/{id}
# operationId: deleteExtension
export def "extensions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extensions/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an extension
#
# PUT /extensions/{id}
# operationId: updateExtension
export def "extensions updateExtension" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  extension: any
]: any -> record<extension: record<name: string, type: string, endpoint_url: string, extension_objects: list<record>, extension_schema: record<type: string>, temporarily_disabled: bool, config: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extensions/($id)")
  let body = {extension: $extension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable an extension
#
# POST /extensions/{id}/enable
# operationId: enableExtension
export def "extensions-enable enableExtension" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<extension: record<name: string, type: string, endpoint_url: string, extension_objects: list<record>, extension_schema: record<type: string>, temporarily_disabled: bool, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extensions/($id)/enable")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Incident Workflows
#
# GET /incident_workflows
# operationId: listIncidentWorkflows
export def "incident-workflows listIncidentWorkflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --include: string@include-completer-5 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, incident_workflows: table<type: string, name: string, description: string, created_at: string, team: record, is_enabled: bool, steps: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incident_workflows" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Incident Workflow
#
# POST /incident_workflows
# operationId: postIncidentWorkflow
export def "incident-workflows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  incident_workflow: any
]: any -> record<incident_workflow: record<type: string, name: string, description: string, created_at: string, team: record<type: string, id: string>, is_enabled: bool, steps: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incident_workflows")
  let body = {incident_workflow: $incident_workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Incident Workflow
#
# GET /incident_workflows/{id}
# operationId: getIncidentWorkflow
export def "incident-workflows get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<incident_workflow: record<type: string, name: string, description: string, created_at: string, team: record<type: string, id: string>, is_enabled: bool, steps: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Incident Workflow
#
# DELETE /incident_workflows/{id}
# operationId: deleteIncidentWorkflow
export def "incident-workflows delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Incident Workflow
#
# PUT /incident_workflows/{id}
# operationId: putIncidentWorkflow
export def "incident-workflows put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  incident_workflow: any
]: any -> record<incident_workflow: record<type: string, name: string, description: string, created_at: string, team: record<type: string, id: string>, is_enabled: bool, steps: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/($id)")
  let body = {incident_workflow: $incident_workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start an Incident Workflow Instance
#
# POST /incident_workflows/{id}/instances
# operationId: createIncidentWorkflowInstance
# --incident_workflow_instance shape: {id?: string, incident?: record}
export def "incident-workflows-instances createIncidentWorkflowInstance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  incident_workflow_instance: record # shape: {id?: string, incident?: record}
]: any -> record<incident_workflow_instance: record<id: string, type: string, incident: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/($id)/instances")
  let body = {incident_workflow_instance: $incident_workflow_instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Actions
#
# GET /incident_workflows/actions
# operationId: listIncidentWorkflowActions
export def "incident-workflows-actions listIncidentWorkflowActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --keyword: string # If provided, only show actions tagged with the specified keyword (e.g. slack)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<limit: int, next_cursor: string, more: bool, actions: table<type: string, domain_name: string, package_name: string, function_name: string, version: float, name: string, description: string, action_type: string, action_tier: string, trigger_type: string, tags: list, search_keywords: list, metadata: string, created_at: string, created_by_user_id: string, inputs: list, outputs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "keyword" $keyword "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incident_workflows/actions" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Action
#
# GET /incident_workflows/actions/{id}
# operationId: getIncidentWorkflowAction
export def "incident-workflows-actions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<action: record<type: string, domain_name: string, package_name: string, function_name: string, version: float, name: string, description: string, action_type: string, action_tier: string, trigger_type: string, tags: list<string>, search_keywords: list<string>, metadata: string, created_at: string, created_by_user_id: string, inputs: list<record>, outputs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/actions/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Triggers
#
# GET /incident_workflows/triggers
# operationId: listIncidentWorkflowTriggers
@deprecated --flag is-disabled
export def "incident-workflows-triggers listIncidentWorkflowTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workflow-id: string # If provided, only show triggers configured to start the given workflow. Useful for listing all services associated with the given workflow (e.g. P4RG7YW)
  --incident-id: string # If provided, only show triggers configured on the service of the given incident. Useful for finding manual triggers that are configured on the service for a specific incident. Cannot be specified if `service_id` is provided. (e.g. Q2LAR4ADCXC8IB)
  --service-id: string # If provided, only show triggers configured for incidents in the given service. Useful for listing all workflows associated with the given service. Cannot be specified if `incident_id` is provided. (e.g. P4RG7YW)
  --trigger-type: string@trigger-type-completer # If provided, only show triggers of the given type. For example “manual” to search for manual triggers
  --workflow-name-contains: string # If provided, only show triggers configured to start workflows whose name contain the provided value. (e.g. High Priority)
  --is-disabled: string@bool-completer # If provided, filters between disabled and enabled Triggers. This query parameter is deprecated, and will be removed in a future version of this API.  (DEPRECATED)
  --sort-by: string@sort-by-completer-2 # If provided, returns triggers sorted by the specified property.
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<limit: int, next_cursor: string, more: bool, triggers: table<type: string, trigger_type_name: string, trigger_type: string, condition: string, trigger_url: string, incident_types: list, workflow: record, services: list, is_subscribed_to_all_services: bool, permissions: record, is_disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_id" $workflow_id "scalar") (serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "trigger_type" $trigger_type "scalar") (serialize-qp "workflow_name_contains" $workflow_name_contains "scalar") (serialize-qp "is_disabled" $is_disabled "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incident_workflows/triggers" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Trigger
#
# POST /incident_workflows/triggers
# operationId: createIncidentWorkflowTrigger
export def "incident-workflows-triggers createIncidentWorkflowTrigger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  trigger: any
]: any -> record<trigger: record<type: string, trigger_type_name: string, trigger_type: string, condition: string, trigger_url: string, incident_types: list<string>, workflow: record<id: string, type: string, name: string, self: string, html_url: string>, services: list<record>, is_subscribed_to_all_services: bool, permissions: record<restricted: bool, team_id: string>, is_disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incident_workflows/triggers")
  let body = {trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Trigger
#
# GET /incident_workflows/triggers/{id}
# operationId: getIncidentWorkflowTrigger
export def "incident-workflows-triggers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<trigger: record<type: string, trigger_type_name: string, trigger_type: string, condition: string, trigger_url: string, incident_types: list<string>, workflow: record<id: string, type: string, name: string, self: string, html_url: string>, services: list<record>, is_subscribed_to_all_services: bool, permissions: record<restricted: bool, team_id: string>, is_disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/triggers/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Trigger
#
# PUT /incident_workflows/triggers/{id}
# operationId: updateIncidentWorkflowTrigger
export def "incident-workflows-triggers updateIncidentWorkflowTrigger" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  trigger: any
]: any -> record<trigger: record<type: string, trigger_type_name: string, trigger_type: string, condition: string, trigger_url: string, incident_types: list<string>, workflow: record<id: string, type: string, name: string, self: string, html_url: string>, services: list<record>, is_subscribed_to_all_services: bool, permissions: record<restricted: bool, team_id: string>, is_disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/triggers/($id)")
  let body = {trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Trigger
#
# DELETE /incident_workflows/triggers/{id}
# operationId: deleteIncidentWorkflowTrigger
export def "incident-workflows-triggers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/triggers/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a Trigger and Service
#
# POST /incident_workflows/triggers/{id}/services
# operationId: associateServiceToIncidentWorkflowTrigger
# --service shape: {id?: string}
export def "incident-workflows-triggers-services associateServiceToIncidentWorkflowTrigger" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  service: record # shape: {id?: string}
]: any -> record<trigger: record<type: string, trigger_type_name: string, trigger_type: string, condition: string, trigger_url: string, incident_types: list<string>, workflow: record<id: string, type: string, name: string, self: string, html_url: string>, services: list<record>, is_subscribed_to_all_services: bool, permissions: record<restricted: bool, team_id: string>, is_disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/triggers/($id)/services")
  let body = {service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dissociate a Trigger and Service
#
# DELETE /incident_workflows/triggers/{trigger_id}/services/{service_id}
# operationId: deleteServiceFromIncidentWorkflowTrigger
export def "incident-workflows-triggers-services delete" [
  trigger_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<trigger: record<type: string, trigger_type_name: string, trigger_type: string, condition: string, trigger_url: string, incident_types: list<string>, workflow: record<id: string, type: string, name: string, self: string, html_url: string>, services: list<record>, is_subscribed_to_all_services: bool, permissions: record<restricted: bool, team_id: string>, is_disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident_workflows/triggers/($trigger_id)/services/($service_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List incidents
#
# GET /incidents
# operationId: listIncidents
export def "incidents listIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page. Maximum of 100.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --date-range: string@date-range-completer # When set to all, the since and until parameters and defaults are ignored.
  --incident-key: string # Incident de-duplication key. Incidents with child alerts do not have an incident key; querying by incident key will return incidents whose alerts have alert_key matching the given incident key.
  --service-ids: list # Returns only the incidents associated with the passed service(s). This expects one or more service IDs.
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --user-ids: list # Returns only the incidents currently assigned to the passed user(s). This expects one or more user IDs. Note: When using the assigned_to_user filter, you will only receive incidents with statuses of triggered or acknowledged. This is because resolved incidents are not assigned to any user.
  --urgencies: string@urgencies-completer # Array of the urgencies of the incidents to be returned. Defaults to all urgencies. Account must have the `urgencies` ability to do this.
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --statuses: string@statuses-completer # Return only incidents with the given statuses. To query multiple statuses, pass `statuses[]` more than once, for example: `https://api.pagerduty.com/incidents?statuses[]=triggered&statuses[]=acknowledged`. (More status codes may be introduced in the future.)
  --sort-by: list # Used to specify both the field you wish to sort the results on (incident_number/created_at/resolved_at/urgency), as well as the direction (asc/desc) of the results. The sort_by field and direction should be separated by a colon. A maximum of two fields can be included, separated by a comma. Sort direction defaults to ascending. The account must have the `urgencies` ability to sort by the urgency.
  --include: string@include-completer-6 # Array of additional details to include.
  --since: string # The start of the date range over which you want to search. Maximum range is 6 months and default is 1 month.
  --until: string # The end of the date range over which you want to search. Maximum range is 6 months and default is 1 month.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, incidents: table<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record, is_mergeable: bool, incident_type: record, escalation_policy: any, teams: list, pending_actions: list, acknowledgements: list, alert_grouping: record, last_status_change_by: any, priority: record, resolve_reason: record, conference_bridge: record, incidents_responders: list, responder_requests: list, urgency: string, body: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "incident_key" $incident_key "scalar") (serialize-qp "service_ids[]" $service_ids "multi") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "user_ids[]" $user_ids "multi") (serialize-qp "urgencies[]" $urgencies "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "statuses[]" $statuses "scalar") (serialize-qp "sort_by" $sort_by "csv") (serialize-qp "include[]" $include "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage incidents
#
# PUT /incidents
# operationId: updateIncidents
# --incidents item shape: {id: string, type: "incident"|"incident_reference", status?: "resolved"|"acknowledged"|"triggered", resolution?: string, title?: string, priority?: any, escalation_level?: int, assignments?: list, incident_type?: record, escalation_policy?: any, urgency?: "high"|"low", conference_bridge?: record}
export def "incidents updateIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  incidents: list # An array of incidents, including the parameters to update. — item shape: {id: string, type: "incident"|"incident_reference", status?: "resolved"|"acknowledged"|"triggered", resolution?: string, title?: string, priority?: any, escalation_level?: int, assignments?: list, incident_type?: record, escalation_policy?: any, urgency?: "high"|"low", conference_bridge?: record}
]: any -> record<offset: int, limit: int, more: bool, total: int, incidents: table<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record, is_mergeable: bool, incident_type: record, escalation_policy: any, teams: list, pending_actions: list, acknowledgements: list, alert_grouping: record, last_status_change_by: any, priority: record, resolve_reason: record, conference_bridge: record, incidents_responders: list, responder_requests: list, urgency: string, body: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents" $qp)
  let body = {incidents: $incidents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an Incident
#
# POST /incidents
# operationId: createIncident
# --incident shape: {type: "incident", title: string, service: any, priority?: any, urgency?: "high"|"low", body?: record, incident_key?: string, assignments?: list, incident_type?: record, escalation_policy?: any, conference_bridge?: record}
export def "incidents createIncident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  incident: record # Details of the incident to be created. — shape: {type: "incident", title: string, service: any, priority?: any, urgency?: "high"|"low", body?: record, incident_key?: string, assignments?: list, incident_type?: record, escalation_policy?: any, conference_bridge?: record}
]: any -> record<incident: record<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list<record>, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record<triggered: int, resolved: int, all: int>, is_mergeable: bool, incident_type: record<name: string>, escalation_policy: any, teams: list<any>, pending_actions: list<record>, acknowledgements: list<record>, alert_grouping: record<grouping_type: string, started_at: string, ended_at: string, alert_grouping_active: bool>, last_status_change_by: any, priority: record<name: string, description: string>, resolve_reason: record<type: string, incident: record>, conference_bridge: record<conference_number: string, conference_url: string>, incidents_responders: list<record>, responder_requests: list<record>, urgency: string, body: record<details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incidents")
  let body = {incident: $incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an incident
#
# GET /incidents/{id}
# operationId: getIncident
export def "incidents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-7 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<incident: record<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list<record>, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record<triggered: int, resolved: int, all: int>, is_mergeable: bool, incident_type: record<name: string>, escalation_policy: any, teams: list<any>, pending_actions: list<record>, acknowledgements: list<record>, alert_grouping: record<grouping_type: string, started_at: string, ended_at: string, alert_grouping_active: bool>, last_status_change_by: any, priority: record<name: string, description: string>, resolve_reason: record<type: string, incident: record>, conference_bridge: record<conference_number: string, conference_url: string>, incidents_responders: list<record>, responder_requests: list<record>, urgency: string, body: record<details: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an incident
#
# PUT /incidents/{id}
# operationId: updateIncident
# --incident shape: {type: "incident"|"incident_reference", status?: "resolved"|"acknowledged"|"triggered", priority?: any, resolution?: string, title?: string, escalation_level?: int, assignments?: list, incident_type?: record, escalation_policy?: any, urgency?: "high"|"low", conference_bridge?: record, service?: record}
export def "incidents updateIncident" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  incident: record # The parameters of the incident to update. — shape: {type: "incident"|"incident_reference", status?: "resolved"|"acknowledged"|"triggered", priority?: any, resolution?: string, title?: string, escalation_level?: int, assignments?: list, incident_type?: record, escalation_policy?: any, urgency?: "high"|"low", conference_bridge?: record, service?: record}
]: any -> record<incident: record<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list<record>, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record<triggered: int, resolved: int, all: int>, is_mergeable: bool, incident_type: record<name: string>, escalation_policy: any, teams: list<any>, pending_actions: list<record>, acknowledgements: list<record>, alert_grouping: record<grouping_type: string, started_at: string, ended_at: string, alert_grouping_active: bool>, last_status_change_by: any, priority: record<name: string, description: string>, resolve_reason: record<type: string, incident: record>, conference_bridge: record<conference_number: string, conference_url: string>, incidents_responders: list<record>, responder_requests: list<record>, urgency: string, body: record<details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)")
  let body = {incident: $incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List alerts for an incident
#
# GET /incidents/{id}/alerts
# operationId: listIncidentAlerts
export def "incidents-alerts listIncidentAlerts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --alert-key: string # Alert de-duplication key.
  --statuses: string@statuses-completer-1 # Return only alerts with the given statuses. (More status codes may be introduced in the future.)
  --sort-by: string@sort-by-completer-3 # Used to specify both the field you wish to sort the results on (created_at/resolved_at), as well as the direction (asc/desc) of the results. The sort_by field and direction should be separated by a colon. A maximum of two fields can be included, separated by a comma. Sort direction defaults to ascending.
  --include: string@include-completer-8 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, alerts: table<created_at: string, type: string, status: string, alert_key: string, service: record, first_trigger_log_entry: record, incident: record, suppressed: bool, severity: string, integration: record, body: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "alert_key" $alert_key "scalar") (serialize-qp "statuses[]" $statuses "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/alerts" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage alerts
#
# PUT /incidents/{id}/alerts
# operationId: updateIncidentAlerts
# --alerts item shape: {status?: "resolved"|"triggered", incident?: record}
export def "incidents-alerts updateIncidentAlerts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  alerts: list # An array of alerts, including the parameters to update for each alert. — item shape: {status?: "resolved"|"triggered", incident?: record}
]: any -> record<offset: int, limit: int, more: bool, total: int, alerts: table<created_at: string, type: string, status: string, alert_key: string, service: record, first_trigger_log_entry: record, incident: record, suppressed: bool, severity: string, integration: record, body: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/alerts" $qp)
  let body = {alerts: $alerts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an alert
#
# GET /incidents/{id}/alerts/{alert_id}
# operationId: getIncidentAlert
export def "incidents-alerts get" [
  id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<alert: record<created_at: string, type: string, status: string, alert_key: string, service: record<type: string>, first_trigger_log_entry: record<type: string>, incident: record<type: string>, suppressed: bool, severity: string, integration: record<type: string>, body: record<type: string, contexts: list, details: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/alerts/($alert_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an alert
#
# PUT /incidents/{id}/alerts/{alert_id}
# operationId: updateIncidentAlert
# --alert shape: {status?: "resolved"|"triggered", incident?: record}
export def "incidents-alerts updateIncidentAlert" [
  id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  alert: record # shape: {status?: "resolved"|"triggered", incident?: record}
]: any -> record<alert: record<created_at: string, type: string, status: string, alert_key: string, service: record<type: string>, first_trigger_log_entry: record<type: string>, incident: record<type: string>, suppressed: bool, severity: string, integration: record<type: string>, body: record<type: string, contexts: list, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/alerts/($alert_id)")
  let body = {alert: $alert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually change an Incident's Impact on a Business Service.
#
# PUT /incidents/{id}/business_services/{business_service_id}/impacts
# operationId: putIncidentManualBusinessServiceAssociation
export def "incidents-business-services-impacts put" [
  id: string
  business_service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  relation: string@relation-completer
]: any -> record<relation: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/business_services/($business_service_id)/impacts")
  let body = {relation: $relation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Business Services impacted by the given Incident
#
# GET /incidents/{id}/business_services/impacts
# operationId: getIncidentImpactedBusinessServices
export def "incidents-business-services-impacts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, next_cursor: string, services: table<id: string, name: string, type: string, status: string, additional_fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/business_services/impacts")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Field Values
#
# GET /incidents/{id}/custom_fields/values
# operationId: getIncidentFieldValues
export def "incidents-custom-fields-values get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_fields: table<id: string, name: string, type: string, display_name: string, field_type: string, data_type: string, description: string, value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/custom_fields/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Field Values
#
# PUT /incidents/{id}/custom_fields/values
# operationId: setIncidentFieldValues
export def "incidents-custom-fields-values setIncidentFieldValues" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_fields: list
]: any -> record<custom_fields: table<id: string, name: string, type: string, display_name: string, field_type: string, data_type: string, description: string, value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/custom_fields/values")
  let body = {custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List log entries for an incident
#
# GET /incidents/{id}/log_entries
# operationId: listIncidentLogEntries
export def "incidents-log-entries listIncidentLogEntries" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --until: string # The end of the date range over which you want to search. (format: date-time)
  --is-overview: string@bool-completer # If `true`, will return a subset of log entries that show only the most important changes to the incident. (default: false)
  --include: string@include-completer-9 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, log_entries: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "is_overview" $is_overview "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/log_entries" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge incidents
#
# PUT /incidents/{id}/merge
# operationId: mergeIncidents
# --source_incidents item shape: {type?: "incident_reference"}
export def "incidents-merge mergeIncidents" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  source_incidents: list # The source incidents that will be merged into the target incident and resolved. — item shape: {type?: "incident_reference"}
]: any -> record<incident: record<type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/merge")
  let body = {source_incidents: $source_incidents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List notes for an incident
#
# GET /incidents/{id}/notes
# operationId: listIncidentNotes
export def "incidents-notes listIncidentNotes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<notes: table<id: string, user: record, channel: record, content: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/notes")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a note on an incident
#
# POST /incidents/{id}/notes
# operationId: createIncidentNote
# --note shape: {content: string}
export def "incidents-notes createIncidentNote" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  note: record # shape: {content: string}
]: any -> record<note: record<id: string, user: record<type: string>, channel: record<summary: string, id: string, type: string, self: string, html_url: string>, content: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/notes")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a note on an incident
#
# PUT /incidents/{id}/notes/{note_id}
# operationId: updateIncidentNote
# --note shape: {content: string}
export def "incidents-notes updateIncidentNote" [
  id: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  note: record # shape: {content: string}
]: any -> record<note: record<id: string, user: record<type: string>, channel: record<summary: string, id: string, type: string, self: string, html_url: string>, content: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/notes/($note_id)")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a note on an incident
#
# DELETE /incidents/{id}/notes/{note_id}
# operationId: deleteIncidentNote
export def "incidents-notes delete" [
  id: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/notes/($note_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Outlier Incident
#
# GET /incidents/{id}/outlier_incident
# operationId: getOutlierIncident
export def "incidents-outlier-incident get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --additional-details: string@additional-details-completer # Array of additional attributes to any of the returned incidents for related incidents.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<outlier_incident: record<incident: record<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record, is_mergeable: bool, incident_type: record, escalation_policy: any, teams: list, pending_actions: list, acknowledgements: list, alert_grouping: record, last_status_change_by: any, priority: record, resolve_reason: record, conference_bridge: record, incidents_responders: list, responder_requests: list, urgency: string, body: record>, incident_template: record<id: string, cluster_id: string, mined_text: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "additional_details[]" $additional_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/outlier_incident" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Past Incidents
#
# GET /incidents/{id}/past_incidents
# operationId: getPastIncidents
export def "incidents-past-incidents get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results to be returned in the response. (default: 5)
  --total: string@bool-completer # By default the `total` field in the response body is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated with the total number of Past Incidents.  (default: false)
]: nothing -> record<past_incidents: table<incident: record, score: float>, total: float, limit: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/past_incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List related Change Events for an Incident
#
# GET /incidents/{id}/related_change_events
# operationId: listIncidentRelatedChangeEvents
export def "incidents-related-change-events listIncidentRelatedChangeEvents" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<change_events: table<correlation_reason: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/related_change_events" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Related Incidents
#
# GET /incidents/{id}/related_incidents
# operationId: getRelatedIncidents
export def "incidents-related-incidents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-details: string@additional-details-completer # Array of additional attributes to any of the returned incidents for related incidents.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<related_incidents: table<incident: record, relationships: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional_details[]" $additional_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)/related_incidents" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a responder request for an incident
#
# POST /incidents/{id}/responder_requests
# operationId: createIncidentResponderRequest
export def "incidents-responder-requests createIncidentResponderRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  requester_id: string # The user id of the requester.
  message: string # The message sent with the responder request.
  responder_request_targets: any # The array of targets the responder request is sent to.
]: any -> record<responder_request: record<id: string, incident: record<type: string>, requester: record<type: string>, requested_at: string, message: string, responder_request_targets: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/responder_requests")
  let body = {requester_id: $requester_id, message: $message, responder_request_targets: $responder_request_targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel responder requests for an incident
#
# PUT /incidents/{id}/responder_requests/cancel
# operationId: cancelIncidentResponderRequest
# --responder_request_targets item shape: {type: "user_reference"|"escalation_policy_reference", id: string}
export def "incidents-responder-requests-cancel cancelIncidentResponderRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  requester_id: string # The user id of the requester.
  responder_request_targets: list # The array of targets to cancel. — item shape: {type: "user_reference"|"escalation_policy_reference", id: string}
]: any -> record<responder_request_targets: table<type: string, id: string, result: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/responder_requests/cancel")
  let body = {requester_id: $requester_id, responder_request_targets: $responder_request_targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Snooze an incident
#
# POST /incidents/{id}/snooze
# operationId: createIncidentSnooze
export def "incidents-snooze createIncidentSnooze" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  duration: int # The number of seconds to snooze the incident for. After this number of seconds has elapsed, the incident will return to the "triggered" state.
]: any -> record<incident: record<incident_number: int, title: string, created_at: string, updated_at: string, status: string, incident_key: string, service: any, assignments: list<record>, assigned_via: string, last_status_change_at: string, resolved_at: string, first_trigger_log_entry: any, alert_counts: record<triggered: int, resolved: int, all: int>, is_mergeable: bool, incident_type: record<name: string>, escalation_policy: any, teams: list<any>, pending_actions: list<record>, acknowledgements: list<record>, alert_grouping: record<grouping_type: string, started_at: string, ended_at: string, alert_grouping_active: bool>, last_status_change_by: any, priority: record<name: string, description: string>, resolve_reason: record<type: string, incident: record>, conference_bridge: record<conference_number: string, conference_url: string>, incidents_responders: list<record>, responder_requests: list<record>, urgency: string, body: record<details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/snooze")
  let body = {duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a status update on an incident
#
# POST /incidents/{id}/status_updates
# operationId: createIncidentStatusUpdate
export def "incidents-status-updates createIncidentStatusUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  message: string # The message to be posted as a status update.
  --subject: string # The subject to be sent for the custom html email status update. Required if sending custom html email.
  --html-message: string # The html content to be sent for the custom html email status update. Required if sending custom html email.
]: any -> record<status_update: record<id: string, message: string, created_at: string, sender: record<type: string>, subject: string, html_message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/status_updates")
  let body = {message: $message, subject: $subject, html_message: $html_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Notification Subscribers
#
# GET /incidents/{id}/status_updates/subscribers
# operationId: getIncidentNotificationSubscribers
export def "incidents-status-updates-subscribers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, subscribers: table<subscriber_id: string, subscriber_type: string, has_indirect_subscription: bool, subscribed_via: list>, account_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/status_updates/subscribers")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Notification Subscribers
#
# POST /incidents/{id}/status_updates/subscribers
# operationId: createIncidentNotificationSubscribers
# --subscribers item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
export def "incidents-status-updates-subscribers createIncidentNotificationSubscribers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribers: list # item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
]: any -> record<subscriptions: table<subscriber_id: string, subscriber_type: string, subscribable_id: string, subscribable_type: string, account_id: string, result: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/status_updates/subscribers")
  let body = {subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Notification Subscriber
#
# POST /incidents/{id}/status_updates/unsubscribe
# operationId: removeIncidentNotificationSubscribers
# --subscribers item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
export def "incidents-status-updates-unsubscribe removeIncidentNotificationSubscribers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribers: list # item shape: {subscriber_id?: string, subscriber_type?: "user"|"team"}
]: any -> record<deleted_count: float, unauthorized_count: float, non_existent_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/status_updates/unsubscribe")
  let body = {subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List incident types
#
# GET /incidents/types
# operationId: listIncidentTypes
export def "incidents-types listIncidentTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string@filter-completer-1 # Filters the list of incident types based on their `enabled` state. (default: enabled)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<incident_types: table<enabled: bool, id: string, name: string, parent: record, type: string, description: string, created_at: string, updated_at: string, display_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/types" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Incident Type
#
# POST /incidents/types
# operationId: createIncidentType
# --incident_type shape: {name: string, display_name: string, parent_type: string, enabled?: bool, description?: string}
export def "incidents-types createIncidentType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  incident_type: record # Details of the incident type to be created. — shape: {name: string, display_name: string, parent_type: string, enabled?: bool, description?: string}
]: any -> record<incident_type: record<enabled: bool, id: string, name: string, parent: record<id: string, type: string>, type: string, description: string, created_at: string, updated_at: string, display_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incidents/types")
  let body = {incident_type: $incident_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Incident Type
#
# GET /incidents/types/{type_id_or_name}
# operationId: getIncidentType
export def "incidents-types get" [
  type_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<incident_type: record<enabled: bool, id: string, name: string, parent: record<id: string, type: string>, type: string, description: string, created_at: string, updated_at: string, display_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Incident Type
#
# PUT /incidents/types/{type_id_or_name}
# operationId: updateIncidentType
# --incident_type shape: {display_name?: string, enabled?: bool, description?: string}
export def "incidents-types updateIncidentType" [
  type_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  incident_type: record # Details of the incident type to be created. — shape: {display_name?: string, enabled?: bool, description?: string}
]: any -> record<incident_type: record<enabled: bool, id: string, name: string, parent: record<id: string, type: string>, type: string, description: string, created_at: string, updated_at: string, display_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)")
  let body = {incident_type: $incident_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Incident Type Custom Fields
#
# GET /incidents/types/{type_id_or_name}/custom_fields
# operationId: listIncidentTypeCustomFields
export def "incidents-types-custom-fields listIncidentTypeCustomFields" [
  type_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-10 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<fields: table<enabled: bool, id: string, name: any, type: string, self: string, description: any, field_type: any, data_type: any, updated_at: string, created_at: string, display_name: any, default_value: any, incident_type: string, summary: string, field_options: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Custom Field for an Incident Type
#
# POST /incidents/types/{type_id_or_name}/custom_fields
# operationId: createIncidentTypeCustomField
# --field shape: {name: string, display_name: string, data_type: string, field_type: "single_value"|"single_value_fixed"|"multi_value"|"multi_value_fixed", description?: string, enabled?: bool, default_value?: string, field_options?: list}
export def "incidents-types-custom-fields createIncidentTypeCustomField" [
  type_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field: record # Details of the custom field to be created. — shape: {name: string, display_name: string, data_type: string, field_type: "single_value"|"single_value_fixed"|"multi_value"|"multi_value_fixed", description?: string, enabled?: bool, default_value?: string, field_options?: list}
]: any -> record<field: record<enabled: bool, id: string, name: any, type: string, self: string, description: any, field_type: any, data_type: any, updated_at: string, created_at: string, display_name: any, default_value: any, incident_type: string, summary: string, field_options: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Incident Type Custom Field
#
# GET /incidents/types/{type_id_or_name}/custom_fields/{field_id}
# operationId: getIncidentTypeCustomField
export def "incidents-types-custom-fields get" [
  type_id_or_name: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-10 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<field: record<enabled: bool, id: string, name: any, type: string, self: string, description: any, field_type: any, data_type: any, updated_at: string, created_at: string, display_name: any, default_value: any, incident_type: string, summary: string, field_options: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Custom Field for an Incident Type
#
# PUT /incidents/types/{type_id_or_name}/custom_fields/{field_id}
# operationId: updateIncidentTypeCustomField
# --field shape: {display_name?: string, enabled?: bool, default_value?: string, description?: string, field_options?: list}
export def "incidents-types-custom-fields updateIncidentTypeCustomField" [
  type_id_or_name: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field: record # Details of the custom field to be updated. — shape: {display_name?: string, enabled?: bool, default_value?: string, description?: string, field_options?: list}
]: any -> record<field: record<enabled: bool, id: string, name: any, type: string, self: string, description: any, field_type: any, data_type: any, updated_at: string, created_at: string, display_name: any, default_value: any, incident_type: string, summary: string, field_options: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Field for an Incident Type
#
# DELETE /incidents/types/{type_id_or_name}/custom_fields/{field_id}
# operationId: deleteIncidentTypeCustomField
export def "incidents-types-custom-fields delete" [
  type_id_or_name: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Field Options on a Custom Field
#
# GET /incidents/types/{type_id_or_name}/custom_fields/{field_id}/field_options
# operationId: listIncidentTypeCustomField
export def "incidents-types-custom-fields-field-options listIncidentTypeCustomField" [
  type_id_or_name: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<field_options: table<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)/field_options")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Field Option for a Custom Field
#
# POST /incidents/types/{type_id_or_name}/custom_fields/{field_id}/field_options
# operationId: createIncidentTypeCustomFieldFieldOptions
# --field_option shape: {data: record}
export def "incidents-types-custom-fields-field-options createIncidentTypeCustomFieldFieldOptions" [
  type_id_or_name: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field_option: record # Details of the field option to be created. — shape: {data: record}
]: any -> record<field_option: record<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)/field_options")
  let body = {field_option: $field_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Field Option on a Custom Field
#
# GET /incidents/types/{type_id_or_name}/custom_fields/{field_id}/field_options/{field_option_id}
# operationId: getIncidentTypeCustomFieldFieldOptions
export def "incidents-types-custom-fields-field-options get" [
  type_id_or_name: string
  field_option_id: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<field_option: record<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)/field_options/($field_option_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Field Option for a Custom Field
#
# PUT /incidents/types/{type_id_or_name}/custom_fields/{field_id}/field_options/{field_option_id}
# operationId: updateIncidentTypeCustomFieldFieldOption
# --field_option shape: {data: record}
export def "incidents-types-custom-fields-field-options updateIncidentTypeCustomFieldFieldOption" [
  type_id_or_name: string
  field_option_id: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field_option: record # Details of the field option on a custom field to be updated. — shape: {data: record}
]: any -> record<field_option: record<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)/field_options/($field_option_id)")
  let body = {field_option: $field_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Field Option for a Custom Field
#
# DELETE /incidents/types/{type_id_or_name}/custom_fields/{field_id}/field_options/{field_option_id}
# operationId: deleteIncidentTypeCustomFieldFieldOption
export def "incidents-types-custom-fields-field-options delete" [
  type_id_or_name: string
  field_option_id: string
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/types/($type_id_or_name)/custom_fields/($field_id)/field_options/($field_option_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Field
#
# POST /incidents/custom_fields
# DEPRECATED
# operationId: createCustomFieldsField
@deprecated
export def "incidents-custom-fields createCustomFieldsField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  field: any
]: any -> record<field: record<created_at: string, data_type: any, default_value: any, description: any, display_name: any, field_options: list<record>, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incidents/custom_fields")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Fields
#
# GET /incidents/custom_fields
# DEPRECATED
# operationId: listCustomFieldsFields
@deprecated
export def "incidents-custom-fields listCustomFieldsFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-10 # Array of additional details to include.
]: nothing -> record<fields: table<created_at: string, data_type: any, default_value: any, description: any, display_name: any, field_options: list, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents/custom_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Field
#
# GET /incidents/custom_fields/{field_id}
# DEPRECATED
# operationId: getCustomFieldsField
@deprecated
export def "incidents-custom-fields get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-10 # Array of additional details to include.
]: nothing -> record<field: record<created_at: string, data_type: any, default_value: any, description: any, display_name: any, field_options: list<record>, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Field
#
# PUT /incidents/custom_fields/{field_id}
# DEPRECATED
# operationId: updateCustomFieldsField
# --field shape: {display_name?: any, description?: any, default_value?: any, enabled?: "true"|"false"}
@deprecated
export def "incidents-custom-fields updateCustomFieldsField" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  field: record # shape: {display_name?: any, description?: any, default_value?: any, enabled?: "true"|"false"}
]: any -> record<field: record<created_at: string, data_type: any, default_value: any, description: any, display_name: any, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Field
#
# DELETE /incidents/custom_fields/{field_id}
# DEPRECATED
# operationId: deleteCustomFieldsField
@deprecated
export def "incidents-custom-fields delete" [
  field_id: string
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
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Field Option
#
# POST /incidents/custom_fields/{field_id}/field_options
# DEPRECATED
# operationId: createCustomFieldsFieldOption
@deprecated
export def "incidents-custom-fields-field-options createCustomFieldsFieldOption" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  field_option: any
]: any -> record<field_option: record<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)/field_options")
  let body = {field_option: $field_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Field Options
#
# GET /incidents/custom_fields/{field_id}/field_options
# DEPRECATED
# operationId: listCustomFieldsFieldOptions
@deprecated
export def "incidents-custom-fields-field-options listCustomFieldsFieldOptions" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<field_options: table<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)/field_options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Field Option
#
# PUT /incidents/custom_fields/{field_id}/field_options/{field_option_id}
# DEPRECATED
# operationId: updateCustomFieldsFieldOption
# --field_option shape: {data?: any}
@deprecated
export def "incidents-custom-fields-field-options updateCustomFieldsFieldOption" [
  field_id: string
  field_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  field_option: record # shape: {data?: any}
]: any -> record<field_option: record<data: any, id: string, type: string, updated_at: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)/field_options/($field_option_id)")
  let body = {field_option: $field_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Field Option
#
# DELETE /incidents/custom_fields/{field_id}/field_options/{field_option_id}
# DEPRECATED
# operationId: deleteCustomFieldsFieldOption
@deprecated
export def "incidents-custom-fields-field-options delete" [
  field_id: string
  field_option_id: string
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
  let full_url = (build-url $base $"/incidents/custom_fields/($field_id)/field_options/($field_option_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an IP allow list
#
# POST /ip_allow_lists
# operationId: createIpAllowList
# --ip_allow_list shape: {state: "enabled"|"disabled", cidr_entries: list}
export def "ip-allow-lists createIpAllowList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-EARLY-ACCESS: string@X-EARLY-ACCESS-completer # This API is currently in Early Access. You __MUST__ pass in this header with the value `ip-allow-lists`, and your account must be enrolled in the IP Allow Lists Early Access program. Contact your PagerDuty account team to request access.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  ip_allow_list: record # An IP allow list restricts access to a PagerDuty account's subdomain to a set of IPv4 CIDR ranges. Enforcement currently applies to web and mobile application traffic.  (e.g. {id: AGIS47HYOV6BDODBTMQKMPQPHU, type: ip_allow_list, state: enabled, cidr_entries: [{cidr: 192.168.1.0/24, description: Office VPN}, {cidr: 10.0.0.0/24, description: Data Center}]}) — shape: {state: "enabled"|"disabled", cidr_entries: list}
]: any -> record<ip_allow_list: record<id: string, type: string, state: string, cidr_entries: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ip_allow_lists")
  let body = {ip_allow_list: $ip_allow_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-EARLY-ACCESS": $X_EARLY_ACCESS, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List IP allow lists
#
# GET /ip_allow_lists
# operationId: listIpAllowLists
export def "ip-allow-lists listIpAllowLists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-EARLY-ACCESS: string@X-EARLY-ACCESS-completer # This API is currently in Early Access. You __MUST__ pass in this header with the value `ip-allow-lists`, and your account must be enrolled in the IP Allow Lists Early Access program. Contact your PagerDuty account team to request access.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<ip_allow_lists: table<id: string, type: string, state: string, cidr_entries: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ip_allow_lists")
  let extra_headers = {"X-EARLY-ACCESS": $X_EARLY_ACCESS, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an IP allow list
#
# GET /ip_allow_lists/{id}
# operationId: getIpAllowList
export def "ip-allow-lists get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-EARLY-ACCESS: string@X-EARLY-ACCESS-completer # This API is currently in Early Access. You __MUST__ pass in this header with the value `ip-allow-lists`, and your account must be enrolled in the IP Allow Lists Early Access program. Contact your PagerDuty account team to request access.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<ip_allow_list: record<id: string, type: string, state: string, cidr_entries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ip_allow_lists/($id)")
  let extra_headers = {"X-EARLY-ACCESS": $X_EARLY_ACCESS, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an IP allow list
#
# PUT /ip_allow_lists/{id}
# operationId: updateIpAllowList
# --ip_allow_list shape: {state: "enabled"|"disabled", cidr_entries: list}
export def "ip-allow-lists updateIpAllowList" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-EARLY-ACCESS: string@X-EARLY-ACCESS-completer # This API is currently in Early Access. You __MUST__ pass in this header with the value `ip-allow-lists`, and your account must be enrolled in the IP Allow Lists Early Access program. Contact your PagerDuty account team to request access.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  ip_allow_list: record # An IP allow list restricts access to a PagerDuty account's subdomain to a set of IPv4 CIDR ranges. Enforcement currently applies to web and mobile application traffic.  (e.g. {id: AGIS47HYOV6BDODBTMQKMPQPHU, type: ip_allow_list, state: enabled, cidr_entries: [{cidr: 192.168.1.0/24, description: Office VPN}, {cidr: 10.0.0.0/24, description: Data Center}]}) — shape: {state: "enabled"|"disabled", cidr_entries: list}
]: any -> record<ip_allow_list: record<id: string, type: string, state: string, cidr_entries: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ip_allow_lists/($id)")
  let body = {ip_allow_list: $ip_allow_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-EARLY-ACCESS": $X_EARLY_ACCESS, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an IP allow list
#
# DELETE /ip_allow_lists/{id}
# operationId: deleteIpAllowList
export def "ip-allow-lists delete" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-EARLY-ACCESS: string@X-EARLY-ACCESS-completer # This API is currently in Early Access. You __MUST__ pass in this header with the value `ip-allow-lists`, and your account must be enrolled in the IP Allow Lists Early Access program. Contact your PagerDuty account team to request access.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ip_allow_lists/($id)")
  let extra_headers = {"X-EARLY-ACCESS": $X_EARLY_ACCESS, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List audit records for an IP allow list
#
# GET /ip_allow_lists/{id}/audit/records
# operationId: listIpAllowListAuditRecords
export def "ip-allow-lists-audit-records listIpAllowListAuditRecords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --X-EARLY-ACCESS: string@X-EARLY-ACCESS-completer # This API is currently in Early Access. You __MUST__ pass in this header with the value `ip-allow-lists`, and your account must be enrolled in the IP Allow Lists Early Access program. Contact your PagerDuty account team to request access.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ip_allow_lists/($id)/audit/records" $qp)
  let extra_headers = {"X-EARLY-ACCESS": $X_EARLY_ACCESS, "Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List License Allocations
#
# GET /license_allocations
# operationId: listLicenseAllocations
export def "license-allocations listLicenseAllocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<license_allocations: table<user: record, license: any, allocated_at: string>, offset: int, limit: int, more: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/license_allocations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Licenses
#
# GET /licenses
# operationId: listLicenses
export def "licenses listLicenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<licenses: table<id: string, description: string, name: string, valid_roles: list, role_group: string, type: string, self: string, html_url: string, summary: string, current_value: int, allocations_available: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licenses")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List log entries
#
# GET /log_entries
# operationId: listLogEntries
export def "log-entries listLogEntries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --until: string # The end of the date range over which you want to search. (format: date-time)
  --is-overview: string@bool-completer # If `true`, will return a subset of log entries that show only the most important changes to the incident. (default: false)
  --include: string@include-completer-9 # Array of additional Models to include in response.
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, log_entries: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "is_overview" $is_overview "scalar") (serialize-qp "include[]" $include "scalar") (serialize-qp "team_ids[]" $team_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/log_entries" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a log entry
#
# GET /log_entries/{id}
# operationId: getLogEntry
export def "log-entries get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --include: string@include-completer-9 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<log_entry: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/log_entries/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update log entry channel information.
#
# PUT /log_entries/{id}/channel
# operationId: updateLogEntryChannel
# --channel shape: {details: string, type: "web_trigger"|"mobile"}
export def "log-entries-channel updateLogEntryChannel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  channel: record # The parameters to update. — shape: {details: string, type: "web_trigger"|"mobile"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/log_entries/($id)/channel")
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List maintenance windows
#
# GET /maintenance_windows
# operationId: listMaintenanceWindows
export def "maintenance-windows listMaintenanceWindows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --service-ids: list # An array of service IDs. Only results related to these services will be returned.
  --include: string@include-completer-11 # Array of additional Models to include in response.
  --filter: string@filter-completer-2 # Only return maintenance windows in a given state.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, maintenance_windows: table<type: string, sequence_number: int, start_time: string, end_time: string, description: string, created_by: record, services: list, teams: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "service_ids[]" $service_ids "multi") (serialize-qp "include[]" $include "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/maintenance_windows" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a maintenance window
#
# POST /maintenance_windows
# operationId: createMaintenanceWindow
export def "maintenance-windows createMaintenanceWindow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  maintenance_window: any
]: any -> record<maintenance_window: record<type: string, sequence_number: int, start_time: string, end_time: string, description: string, created_by: record<type: string>, services: list<record>, teams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/maintenance_windows")
  let body = {maintenance_window: $maintenance_window} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a maintenance window
#
# GET /maintenance_windows/{id}
# operationId: getMaintenanceWindow
export def "maintenance-windows get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-11 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<maintenance_window: record<type: string, sequence_number: int, start_time: string, end_time: string, description: string, created_by: record<type: string>, services: list<record>, teams: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/maintenance_windows/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete or end a maintenance window
#
# DELETE /maintenance_windows/{id}
# operationId: deleteMaintenanceWindow
export def "maintenance-windows delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance_windows/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a maintenance window
#
# PUT /maintenance_windows/{id}
# operationId: updateMaintenanceWindow
export def "maintenance-windows updateMaintenanceWindow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  maintenance_window: any
]: any -> record<maintenance_window: record<type: string, sequence_number: int, start_time: string, end_time: string, description: string, created_by: record<type: string>, services: list<record>, teams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance_windows/($id)")
  let body = {maintenance_window: $maintenance_window} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List notifications
#
# GET /notifications
# operationId: listNotifications
export def "notifications listNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --since: string # The start of the date range over which you want to search. The time element is optional. (format: date-time)
  --until: string # The end of the date range over which you want to search. This should be in the same format as since. The size of the date range must be less than 3 months. (format: date-time)
  --filter: string@filter-completer-3 # Return notification of this type only.
  --include: string@include-completer-12 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, notifications: table<id: string, type: string, started_at: string, address: string, user: record, conferenceAddress: string, status: string, : string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all OAuth delegations
#
# DELETE /oauth_delegations
# operationId: deleteOauthDelegations
export def "oauth-delegations delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # The ID of the user for whom this request is applicable.
  --type: string@type-completer # The type of OAuth delegations this request should target. Allowed values are 'mobile' (to sign users out of the mobile app) and 'web' (to sign users out of the web app). You can pass one or more types in, separated by commas (e.g., `type=web,mobile`).
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth_delegations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OAuth delegations revocation requests status
#
# GET /oauth_delegations/revocation_requests/status
# DEPRECATED
# operationId: getOauthDelegationsRevocationRequestsStatus
@deprecated
export def "oauth-delegations-revocation-requests-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requested-at-end: string # The end of the date range over which you want to search. If not specified, this will default to current time. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requested_at_end" $requested_at_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth_delegations/revocation_requests/status" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all of the on-calls
#
# GET /oncalls
# operationId: listOnCalls
export def "oncalls listOnCalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --include: string@include-completer-13 # Array of additional details to include.
  --user-ids: list # Filters the results, showing only on-calls for the specified user IDs.
  --escalation-policy-ids: list # Filters the results, showing only on-calls for the specified escalation policy IDs.
  --schedule-ids: list # Filters the results, showing only on-calls for the specified schedule IDs. If `null` is provided in the array, it includes permanent on-calls due to direct user escalation targets.
  --since: string # The start of the time range over which you want to search. If an on-call period overlaps with the range, it will be included in the result. Defaults to current time. On-call shifts are limited to 90 days in the future. (format: date-time)
  --until: string # The end of the time range over which you want to search. If an on-call period overlaps with the range, it will be included in the result. Defaults to current time. On-call shifts are limited to 90 days in the future, and the `until` time cannot be before the `since` time. (format: date-time)
  --earliest: string@bool-completer # This will filter on-calls such that only the earliest on-call for each combination of escalation policy, escalation level, and user is returned. This is useful for determining when the "next" on-calls are for a given set of filters.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, oncalls: table<escalation_policy: record, user: record, schedule: any, escalation_level: int, start: string, end: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "include[]" $include "scalar") (serialize-qp "user_ids[]" $user_ids "multi") (serialize-qp "escalation_policy_ids[]" $escalation_policy_ids "multi") (serialize-qp "schedule_ids[]" $schedule_ids "multi") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "earliest" $earliest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oncalls" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Paused Incident Reporting on Alerts
#
# GET /paused_incident_reports/alerts
# operationId: getPausedIncidentReportAlerts
export def "paused-incident-reports-alerts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --until: string # The end of the date range over which you want to search. (format: date-time)
  --service-id: string # Specifies a filter to limit the scope of reporting to a particular service (e.g. P123456)
  --suspended-by: string@suspended-by-completer # Specifies a filter to scope the response to either alerts suspended by Auto Pause or Event Rules.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<paused_incident_reporting_alerts: record<since: string, until: string, triggered_after_pause_alerts: list<record>, resolved_after_pause_alerts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "suspended_by" $suspended_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paused_incident_reports/alerts" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Paused Incident Reporting counts
#
# GET /paused_incident_reports/counts
# operationId: getPausedIncidentReportCounts
export def "paused-incident-reports-counts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --until: string # The end of the date range over which you want to search. (format: date-time)
  --service-id: string # Specifies a filter to limit the scope of reporting to a particular service (e.g. P123456)
  --suspended-by: string@suspended-by-completer # Specifies a filter to scope the response to either alerts suspended by Auto Pause or Event Rules.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<paused_incident_reporting_counts: record<since: string, until: string, paused_count: float, triggered_after_pause_count: float, resolved_after_pause_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "suspended_by" $suspended_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paused_incident_reports/counts" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List priorities
#
# GET /priorities
# operationId: listPriorities
export def "priorities listPriorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, priorities: table<name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/priorities" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Rulesets
#
# GET /rulesets
# operationId: listRulesets
export def "rulesets listRulesets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, rulesets: table<id: string, self: string, type: string, name: string, routing_keys: list, created_at: string, creator: record, updated_at: string, updater: record, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rulesets" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Ruleset
#
# POST /rulesets
# operationId: createRuleset
export def "rulesets createRuleset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  ruleset: any
]: any -> record<ruleset: record<id: string, self: string, type: string, name: string, routing_keys: list<string>, created_at: string, creator: record<id: string, type: string, self: string>, updated_at: string, updater: record<id: string, type: string, self: string>, team: record<id: string, type: string, self: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rulesets")
  let body = {ruleset: $ruleset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Ruleset
#
# GET /rulesets/{id}
# operationId: getRuleset
export def "rulesets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<ruleset: record<id: string, self: string, type: string, name: string, routing_keys: list<string>, created_at: string, creator: record<id: string, type: string, self: string>, updated_at: string, updater: record<id: string, type: string, self: string>, team: record<id: string, type: string, self: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Ruleset
#
# PUT /rulesets/{id}
# operationId: updateRuleset
# --ruleset shape: {name?: string, team?: record}
export def "rulesets updateRuleset" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  ruleset: record # e.g. {id: 0e84de00-9511-4380-9f4f-a7b568bb49a0, name: MySQL Clusters, type: global, routing_keys: [R0212P1QXGEIQE2NMTQ7L7WXD00DWHIN], self: https://api.pagerduty.com/rulesets/0e84de00-9511-4380-9f4f-a7b568bb49a0, created_at: 2019-12-24T21:18:52Z, creator: {type: user_reference, self: https://api.pagerduty.com/users/PABO808, id: PABO808}, updated_at: 2019-12-25T14:54:23Z, updater: {type: user_reference, self: https://api.pagerduty.com/users/PABO808, id: PABO808}, team: {type: team_reference, self: https://api.pagerduty.com/teams/P3ZQXDF, id: P3ZQXDF}} — shape: {name?: string, team?: record}
]: any -> record<ruleset: record<id: string, self: string, type: string, name: string, routing_keys: list<string>, created_at: string, creator: record<id: string, type: string, self: string>, updated_at: string, updater: record<id: string, type: string, self: string>, team: record<id: string, type: string, self: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)")
  let body = {ruleset: $ruleset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Ruleset
#
# DELETE /rulesets/{id}
# operationId: deleteRuleset
export def "rulesets delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Event Rules
#
# GET /rulesets/{id}/rules
# operationId: listRulesetEventRules
export def "rulesets-rules listRulesetEventRules" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, rules: table<id: string, self: string, disabled: bool, conditions: record, time_frame: record, variables: list, position: int, catch_all: bool, actions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rulesets/($id)/rules" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Event Rule
#
# POST /rulesets/{id}/rules
# operationId: createRulesetEventRule
export def "rulesets-rules createRulesetEventRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  rule: any
]: any -> record<rule: record<id: string, self: string, disabled: bool, conditions: record<operator: string, subconditions: list>, time_frame: record<active_between: record, scheduled_weekly: record>, variables: list<record>, position: int, catch_all: bool, actions: record<annotate: record, event_action: record, extractions: list, priority: record, severity: record, suppress: record, suspend: record, route: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)/rules")
  let body = {rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Event Rule
#
# GET /rulesets/{id}/rules/{rule_id}
# operationId: getRulesetEventRule
export def "rulesets-rules get" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<rule: record<id: string, self: string, disabled: bool, conditions: record<operator: string, subconditions: list>, time_frame: record<active_between: record, scheduled_weekly: record>, variables: list<record>, position: int, catch_all: bool, actions: record<annotate: record, event_action: record, extractions: list, priority: record, severity: record, suppress: record, suspend: record, route: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)/rules/($rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Event Rule
#
# PUT /rulesets/{id}/rules/{rule_id}
# operationId: updateRulesetEventRule
export def "rulesets-rules updateRulesetEventRule" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --rule: any
  --body-rule-id: string # The id of the Event Rule to update.
]: any -> record<rule: record<id: string, self: string, disabled: bool, conditions: record<operator: string, subconditions: list>, time_frame: record<active_between: record, scheduled_weekly: record>, variables: list<record>, position: int, catch_all: bool, actions: record<annotate: record, event_action: record, extractions: list, priority: record, severity: record, suppress: record, suspend: record, route: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)/rules/($rule_id)")
  let body = {rule: $rule, rule_id: $body_rule_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Event Rule
#
# DELETE /rulesets/{id}/rules/{rule_id}
# operationId: deleteRulesetEventRule
export def "rulesets-rules delete" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rulesets/($id)/rules/($rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List schedules
#
# GET /schedules
# operationId: listSchedules
export def "schedules listSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --include: string@include-completer-14 # Array of additional details to include.
  --time-zone: string # Time zone in which results will be rendered. This will default to the current user's time zone and then the account's time zone. (format: tzinfo)
  --include-next-oncall-for-user: string # Specify an `user_id`, and the schedule list API will return information about this user's next on-call.
  --since: string # The start of the date range over which you want to show schedule entries. Defaults to 2 weeks before until if an until is given. Optional parameter. When provided with include[] for schedule types, populates the rendered_schedule_entries fields in the response. (format: date-time)
  --until: string # The end of the date range over which you want to show schedule entries. Defaults to 2 weeks after since if a since is given. Optional parameter. When provided with include[] for schedule types, populates the rendered_schedule_entries fields in the response. (format: date-time)
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, schedules: table<type: string, schedule_layers: list, time_zone: string, name: string, description: string, final_schedule: record, overrides_subschedule: record, escalation_policies: list, users: list, teams: list, next_oncall_for_user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "include[]" $include "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "include_next_oncall_for_user" $include_next_oncall_for_user "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "team_ids[]" $team_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a schedule
#
# POST /schedules
# operationId: createSchedule
export def "schedules createSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overflow: string@bool-completer # Any on-call schedule entries that pass the date range bounds will be truncated at the bounds, unless the parameter `overflow=true` is passed. This parameter defaults to false. For instance, if your schedule is a rotation that changes daily at midnight UTC, and your date range is from `2011-06-01T10:00:00Z` to `2011-06-01T14:00:00Z`:   - If you don't pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T10:00:00Z` and end of `2011-06-01T14:00:00Z`. - If you do pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T00:00:00Z` and end of `2011-06-02T00:00:00Z`.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  schedule: any
]: any -> record<schedule: record<type: string, schedule_layers: list<record>, time_zone: string, name: string, description: string, final_schedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, overrides_subschedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, escalation_policies: list<record>, users: list<record>, teams: list<record>, next_oncall_for_user: record<start: string, end: string, user: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overflow" $overflow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp)
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a schedule
#
# GET /schedules/{id}
# operationId: getSchedule
export def "schedules get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-zone: string # Time zone in which results will be rendered. This will default to the schedule's time zone. (format: tzinfo)
  --since: string # The start of the date range over which you want to show schedule entries. Defaults to 2 weeks before until if an until is given. Optional parameter. When provided with include[] for schedule types, populates the rendered_schedule_entries fields in the response. (format: date-time)
  --until: string # The end of the date range over which you want to show schedule entries. Defaults to 2 weeks after since if a since is given. Optional parameter. When provided with include[] for schedule types, populates the rendered_schedule_entries fields in the response. (format: date-time)
  --overflow: string@bool-completer # Any on-call schedule entries that pass the date range bounds will be truncated at the bounds, unless the parameter `overflow=true` is passed. This parameter defaults to false. For instance, if your schedule is a rotation that changes daily at midnight UTC, and your date range is from `2011-06-01T10:00:00Z` to `2011-06-01T14:00:00Z`:   - If you don't pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T10:00:00Z` and end of `2011-06-01T14:00:00Z`. - If you do pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T00:00:00Z` and end of `2011-06-02T00:00:00Z`.  (default: false)
  --include-next-oncall-for-user: string # Specify an `user_id`, and the schedule list API will return information about this user's next on-call.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<schedule: record<type: string, schedule_layers: list<record>, time_zone: string, name: string, description: string, final_schedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, overrides_subschedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, escalation_policies: list<record>, users: list<record>, teams: list<record>, next_oncall_for_user: record<start: string, end: string, user: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "overflow" $overflow "scalar") (serialize-qp "include_next_oncall_for_user" $include_next_oncall_for_user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a schedule
#
# DELETE /schedules/{id}
# operationId: deleteSchedule
export def "schedules delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a schedule
#
# PUT /schedules/{id}
# operationId: updateSchedule
export def "schedules updateSchedule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overflow: string@bool-completer # Any on-call schedule entries that pass the date range bounds will be truncated at the bounds, unless the parameter `overflow=true` is passed. This parameter defaults to false. For instance, if your schedule is a rotation that changes daily at midnight UTC, and your date range is from `2011-06-01T10:00:00Z` to `2011-06-01T14:00:00Z`:   - If you don't pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T10:00:00Z` and end of `2011-06-01T14:00:00Z`. - If you do pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T00:00:00Z` and end of `2011-06-02T00:00:00Z`.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  schedule: any
]: any -> record<schedule: record<type: string, schedule_layers: list<record>, time_zone: string, name: string, description: string, final_schedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, overrides_subschedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, escalation_policies: list<record>, users: list<record>, teams: list<record>, next_oncall_for_user: record<start: string, end: string, user: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overflow" $overflow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)" $qp)
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit records for a schedule
#
# GET /schedules/{id}/audit/records
# operationId: listSchedulesAuditRecords
export def "schedules-audit-records listSchedulesAuditRecords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List overrides
#
# GET /schedules/{id}/overrides
# operationId: listScheduleOverrides
export def "schedules-overrides listScheduleOverrides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search. (format: date-time, e.g. 2026-04-01T00:00:00Z)
  --until: string # The end of the date range over which you want to search. (format: date-time, e.g. 2026-05-30T00:00:00Z)
  --editable: string@bool-completer # When this parameter is present, only editable overrides will be returned. The result will only include the id of the override if this parameter is present. Only future overrides are editable.
  --overflow: string@bool-completer # Any on-call schedule entries that pass the date range bounds will be truncated at the bounds, unless the parameter overflow=true is passed. This parameter defaults to false.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<overrides: table<id: string, start: string, end: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "editable" $editable "scalar") (serialize-qp "overflow" $overflow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)/overrides" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create one or more overrides
#
# POST /schedules/{id}/overrides
# operationId: createScheduleOverride
# --overrides item shape: {start: string, end: string, user: any}
export def "schedules-overrides createScheduleOverride" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --overrides: list # item shape: {start: string, end: string, user: any}
]: any -> table<status: float, errors: list<string>, override: record<id: string, start: string, end: string, user: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)/overrides")
  let body = {overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an override
#
# DELETE /schedules/{id}/overrides/{override_id}
# operationId: deleteScheduleOverride
export def "schedules-overrides delete-by-id-override_id" [
  id: string
  override_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)/overrides/($override_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users on call.
#
# GET /schedules/{id}/users
# operationId: listScheduleUsers
export def "schedules-users listScheduleUsers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --until: string # The end of the date range over which you want to search. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<users: table<name: string, type: string, email: string, time_zone: string, color: string, role: string, avatar_url: string, description: string, invitation_sent: bool, job_title: string, created_via_sso: bool, teams: list, contact_methods: list, notification_rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)/users" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview a schedule
#
# POST /schedules/preview
# operationId: createSchedulePreview
export def "schedules-preview createSchedulePreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search. (format: date-time)
  --until: string # The end of the date range over which you want to search. (format: date-time)
  --overflow: string@bool-completer # Any on-call schedule entries that pass the date range bounds will be truncated at the bounds, unless the parameter `overflow=true` is passed. This parameter defaults to false. For instance, if your schedule is a rotation that changes daily at midnight UTC, and your date range is from `2011-06-01T10:00:00Z` to `2011-06-01T14:00:00Z`:   - If you don't pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T10:00:00Z` and end of `2011-06-01T14:00:00Z`. - If you do pass the `overflow=true` parameter, you will get one schedule entry returned with a start of `2011-06-01T00:00:00Z` and end of `2011-06-02T00:00:00Z`.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  schedule: any
]: any -> record<schedule: record<type: string, schedule_layers: list<record>, time_zone: string, name: string, description: string, final_schedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, overrides_subschedule: record<name: string, rendered_schedule_entries: list, rendered_coverage_percentage: float>, escalation_policies: list<record>, users: list<record>, teams: list<record>, next_oncall_for_user: record<start: string, end: string, user: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "overflow" $overflow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/preview" $qp)
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associate service dependencies
#
# POST /service_dependencies/associate
# operationId: createServiceDependency
# --relationships item shape: {supporting_service?: record, dependent_service?: record}
export def "service-dependencies-associate createServiceDependency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --relationships: list # List of all service dependencies to be created. — item shape: {supporting_service?: record, dependent_service?: record}
]: any -> record<relationships: table<supporting_service: record, dependent_service: record, id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service_dependencies/associate")
  let body = {relationships: $relationships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Business Service dependencies
#
# GET /service_dependencies/business_services/{id}
# operationId: getBusinessServiceServiceDependencies
export def "service-dependencies-business-services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<relationships: table<supporting_service: record, dependent_service: record, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service_dependencies/business_services/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociate service dependencies
#
# POST /service_dependencies/disassociate
# operationId: deleteServiceDependency
# --relationships item shape: {supporting_service?: record, dependent_service?: record}
export def "service-dependencies-disassociate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --relationships: list # List of all service dependencies to be deleted. — item shape: {supporting_service?: record, dependent_service?: record}
]: any -> record<relationships: table<supporting_service: record, dependent_service: record, id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service_dependencies/disassociate")
  let body = {relationships: $relationships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get technical service dependencies
#
# GET /service_dependencies/technical_services/{id}
# operationId: getTechnicalServiceServiceDependencies
export def "service-dependencies-technical-services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<relationships: table<supporting_service: record, dependent_service: record, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service_dependencies/technical_services/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List services
#
# GET /services
# operationId: listServices
export def "services listServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --time-zone: string # Time zone in which results will be rendered. This will default to the account time zone. (format: tzinfo)
  --sort-by: string@sort-by-completer # Used to specify the field you wish to sort the results on. (default: name)
  --include: string@include-completer-15 # Array of additional details to include.
  --name: string # Filters the results, showing only services with the specified name.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, services: table<type: string, name: string, description: string, auto_resolve_timeout: int, acknowledgement_timeout: int, created_at: string, status: string, last_incident_timestamp: string, escalation_policy: record, response_play: any, teams: list, integrations: list, incident_urgency_rule: record, support_hours: record, scheduled_actions: list, addons: list, alert_creation: string, alert_grouping_parameters: any, alert_grouping: string, alert_grouping_timeout: int, auto_pause_notifications_parameters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "include[]" $include "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service
#
# POST /services
# operationId: createService
export def "services createService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  service: any
]: any -> record<service: record<type: string, name: string, description: string, auto_resolve_timeout: int, acknowledgement_timeout: int, created_at: string, status: string, last_incident_timestamp: string, escalation_policy: record<type: string>, response_play: any, teams: list<record>, integrations: list<record>, incident_urgency_rule: record<type: string, urgency: string, during_support_hours: record, outside_support_hours: record>, support_hours: record<type: string, time_zone: string, days_of_week: list, start_time: string, end_time: string>, scheduled_actions: list<record>, addons: list<record>, alert_creation: string, alert_grouping_parameters: any, alert_grouping: string, alert_grouping_timeout: int, auto_pause_notifications_parameters: record<enabled: bool, timeout: int, recommended_timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/services")
  let body = {service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a service
#
# GET /services/{id}
# operationId: getService
export def "services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-15 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<service: record<type: string, name: string, description: string, auto_resolve_timeout: int, acknowledgement_timeout: int, created_at: string, status: string, last_incident_timestamp: string, escalation_policy: record<type: string>, response_play: any, teams: list<record>, integrations: list<record>, incident_urgency_rule: record<type: string, urgency: string, during_support_hours: record, outside_support_hours: record>, support_hours: record<type: string, time_zone: string, days_of_week: list, start_time: string, end_time: string>, scheduled_actions: list<record>, addons: list<record>, alert_creation: string, alert_grouping_parameters: any, alert_grouping: string, alert_grouping_timeout: int, auto_pause_notifications_parameters: record<enabled: bool, timeout: int, recommended_timeout: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a service
#
# DELETE /services/{id}
# operationId: deleteService
export def "services delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service
#
# PUT /services/{id}
# operationId: updateService
export def "services updateService" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  service: any
]: any -> record<service: record<type: string, name: string, description: string, auto_resolve_timeout: int, acknowledgement_timeout: int, created_at: string, status: string, last_incident_timestamp: string, escalation_policy: record<type: string>, response_play: any, teams: list<record>, integrations: list<record>, incident_urgency_rule: record<type: string, urgency: string, during_support_hours: record, outside_support_hours: record>, support_hours: record<type: string, time_zone: string, days_of_week: list, start_time: string, end_time: string>, scheduled_actions: list<record>, addons: list<record>, alert_creation: string, alert_grouping_parameters: any, alert_grouping: string, alert_grouping_timeout: int, auto_pause_notifications_parameters: record<enabled: bool, timeout: int, recommended_timeout: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)")
  let body = {service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit records for a service
#
# GET /services/{id}/audit/records
# operationId: listServiceAuditRecords
export def "services-audit-records listServiceAuditRecords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Change Events for a service
#
# GET /services/{id}/change_events
# operationId: listServiceChangeEvents
export def "services-change-events listServiceChangeEvents" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start of the date range over which you want to search, as a UTC ISO 8601 datetime string. Will return an HTTP 400 for non-UTC datetimes. (format: date-time)
  --until: string # The end of the date range over which you want to search, as a UTC ISO 8601 datetime string. Will return an HTTP 400 for non-UTC datetimes. (format: date-time)
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --integration-ids: list # An array of integration IDs. Only results related to these integrations will be returned.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<change_events: table<timestamp: string, type: string, services: list, integration: record, routing_key: string, summary: string, source: string, links: list, images: list, custom_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "integration_ids[]" $integration_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/change_events" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new integration
#
# POST /services/{id}/integrations
# operationId: createServiceIntegration
export def "services-integrations createServiceIntegration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  integration: any
]: any -> record<integration: record<type: string, name: string, service: record<type: string>, created_at: string, vendor: record<type: string>, integration_email: string, email_incident_creation: string, email_filter_mode: string, email_parsers: list<record>, email_parsing_fallback: string, email_filters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/integrations")
  let body = {integration: $integration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing integration
#
# PUT /services/{id}/integrations/{integration_id}
# operationId: updateServiceIntegration
export def "services-integrations updateServiceIntegration" [
  id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  integration: any
]: any -> record<integration: record<type: string, name: string, service: record<type: string>, created_at: string, vendor: record<type: string>, integration_email: string, email_incident_creation: string, email_filter_mode: string, email_parsers: list<record>, email_parsing_fallback: string, email_filters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/integrations/($integration_id)")
  let body = {integration: $integration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View an integration
#
# GET /services/{id}/integrations/{integration_id}
# operationId: getServiceIntegration
export def "services-integrations get" [
  id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-16 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<integration: record<type: string, name: string, service: record<type: string>, created_at: string, vendor: record<type: string>, integration_email: string, email_incident_creation: string, email_filter_mode: string, email_parsers: list<record>, email_parsing_fallback: string, email_filters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/integrations/($integration_id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Service's Event Rules
#
# GET /services/{id}/rules
# operationId: listServiceEventRules
export def "services-rules listServiceEventRules" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --include: string@include-completer-2 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, migrated_at: string, migrated_by: record<id: string, type: string, self: string>, migrated_status: string, migrated_to: record<id: string, type: string, self: string>, migrated_via: string, rules: table<position: int, actions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/rules" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Event Rule on a Service
#
# POST /services/{id}/rules
# operationId: createServiceEventRule
export def "services-rules createServiceEventRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  rule: any
]: any -> record<rule: record<position: int, actions: record<annotate: record, event_action: record, extractions: list, priority: record, severity: record, suppress: record, suspend: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/rules")
  let body = {rule: $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Convert a Service's Event Rules into Event Orchestration Rules
#
# POST /services/{id}/rules/convert
# operationId: convertServiceEventRulesToEventOrchestration
export def "services-rules-convert convertServiceEventRulesToEventOrchestration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<convert_status: string, converted_to: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/rules/convert")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Event Rule from a Service
#
# GET /services/{id}/rules/{rule_id}
# operationId: getServiceEventRule
export def "services-rules get" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<rule: record<position: int, actions: record<annotate: record, event_action: record, extractions: list, priority: record, severity: record, suppress: record, suspend: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/rules/($rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Event Rule on a Service
#
# PUT /services/{id}/rules/{rule_id}
# operationId: updateServiceEventRule
export def "services-rules updateServiceEventRule" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --rule: any
  --body-rule-id: string # The id of the Event Rule to update on the Service.
]: any -> record<rule: record<position: int, actions: record<annotate: record, event_action: record, extractions: list, priority: record, severity: record, suppress: record, suspend: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/rules/($rule_id)")
  let body = {rule: $rule, rule_id: $body_rule_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Event Rule from a Service
#
# DELETE /services/{id}/rules/{rule_id}
# operationId: deleteServiceEventRule
export def "services-rules delete" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/rules/($rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Field
#
# POST /services/custom_fields
# operationId: createServiceCustomField
# --field shape: {data_type: any, description?: any, display_name: any, enabled?: any, field_options?: list, field_type: any, name: any}
export def "services-custom-fields createServiceCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field: record # Details of the custom field to be created. — shape: {data_type: any, description?: any, display_name: any, enabled?: any, field_options?: list, field_type: any, name: any}
]: any -> record<field: record<created_at: string, data_type: any, description: any, display_name: any, enabled: any, field_options: list<record>, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/services/custom_fields")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Fields
#
# GET /services/custom_fields
# operationId: listServiceCustomFields
export def "services-custom-fields listServiceCustomFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-10 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<fields: table<created_at: string, data_type: any, description: any, display_name: any, enabled: any, field_options: list, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/custom_fields" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Field
#
# GET /services/custom_fields/{field_id}
# operationId: getServiceCustomField
export def "services-custom-fields get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-10 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<field: record<created_at: string, data_type: any, description: any, display_name: any, enabled: any, field_options: list<record>, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/custom_fields/($field_id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Field
#
# PUT /services/custom_fields/{field_id}
# operationId: updateServiceCustomField
# --field shape: {description?: any, display_name?: any, enabled?: any, field_options?: list}
export def "services-custom-fields updateServiceCustomField" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field: record # Details of the custom field to be updated. — shape: {description?: any, display_name?: any, enabled?: any, field_options?: list}
]: any -> record<field: record<created_at: string, data_type: any, description: any, display_name: any, enabled: any, field_options: list<record>, field_type: any, id: string, name: any, self: string, summary: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Field
#
# DELETE /services/custom_fields/{field_id}
# operationId: deleteServiceCustomField
export def "services-custom-fields delete" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Field Options
#
# GET /services/custom_fields/{field_id}/field_options
# operationId: listServiceCustomFieldOptions
export def "services-custom-fields-field-options listServiceCustomFieldOptions" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<field_options: table<created_at: any, data: record, id: any, type: string, updated_at: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)/field_options")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Field Option
#
# POST /services/custom_fields/{field_id}/field_options
# operationId: createServiceCustomFieldOption
# --field_option shape: {data: record}
export def "services-custom-fields-field-options createServiceCustomFieldOption" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field_option: record # An option for a custom field. Can only be applied to fields with a `field_type` of `single_value_fixed` or `multi_value_fixed`. — shape: {data: record}
]: any -> record<field_option: record<created_at: any, data: record<data_type: string, value: string>, id: any, type: string, updated_at: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)/field_options")
  let body = {field_option: $field_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Field Option
#
# GET /services/custom_fields/{field_id}/field_options/{field_option_id}
# operationId: getServiceCustomFieldOption
export def "services-custom-fields-field-options get" [
  field_id: string
  field_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<field_option: record<created_at: any, data: record<data_type: string, value: string>, id: any, type: string, updated_at: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)/field_options/($field_option_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Field Option
#
# PUT /services/custom_fields/{field_id}/field_options/{field_option_id}
# operationId: updateServiceCustomFieldOption
# --field_option shape: {data: record}
export def "services-custom-fields-field-options updateServiceCustomFieldOption" [
  field_id: string
  field_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  field_option: record # An option for a custom field. Can only be applied to fields with a `field_type` of `single_value_fixed` or `multi_value_fixed`. — shape: {data: record}
]: any -> record<field_option: record<created_at: any, data: record<data_type: string, value: string>, id: any, type: string, updated_at: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)/field_options/($field_option_id)")
  let body = {field_option: $field_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Field Option
#
# DELETE /services/custom_fields/{field_id}/field_options/{field_option_id}
# operationId: deleteServiceCustomFieldOption
export def "services-custom-fields-field-options delete" [
  field_id: string
  field_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/custom_fields/($field_id)/field_options/($field_option_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Field Values
#
# GET /services/{id}/custom_fields/values
# operationId: getServiceCustomFieldValues
export def "services-custom-fields-values get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<custom_fields: table<data_type: any, description: any, display_name: any, field_type: any, id: any, name: any, type: string, value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/custom_fields/values")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Field Values
#
# PUT /services/{id}/custom_fields/values
# operationId: updateServiceCustomFieldValues
export def "services-custom-fields-values updateServiceCustomFieldValues" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  custom_fields: list
]: any -> record<custom_fields: table<data_type: any, description: any, display_name: any, field_type: any, id: any, name: any, type: string, value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/custom_fields/values")
  let body = {custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Enablements for a Service
#
# GET /services/{id}/enablements
# operationId: listServiceFeatureEnablements
export def "services-enablements listServiceFeatureEnablements" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<enablements: table<feature: string, enabled: bool, updated_at: string, warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/enablements")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Enablement for a Service
#
# PUT /services/{id}/enablements/{feature_name}
# operationId: updateServiceFeatureEnablement
# --enablement shape: {enabled: bool}
export def "services-enablements updateServiceFeatureEnablement" [
  id: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  enablement: record # shape: {enabled: bool}
]: any -> record<enablement: record<feature: string, enabled: bool, updated_at: string, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/enablements/($feature_name)")
  let body = {enablement: $enablement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an account's session configurations
#
# GET /session_configurations
# operationId: getSessionConfigurations
export def "session-configurations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Session configuration type. If omitted, returns both mobile and web configurations.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<session_configurations: table<type: string, absolute_session_ttl: int, idle_session_ttl: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session_configurations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure an account's session configurations
#
# PUT /session_configurations
# operationId: updateSessionConfigurations
# --session_configuration shape: {absolute_session_ttl: int, idle_session_ttl: int}
export def "session-configurations updateSessionConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Session configuration type. This can be either 'mobile' or 'web', or a comma-separated list of both.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  session_configuration: record # shape: {absolute_session_ttl: int, idle_session_ttl: int}
]: any -> record<session_configurations: table<type: string, absolute_session_ttl: int, idle_session_ttl: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session_configurations" $qp)
  let body = {session_configuration: $session_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an account's session configurations.
#
# DELETE /session_configurations
# operationId: deleteSessionConfigurations
export def "session-configurations delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Session configuration type. This can be either 'mobile' or 'web', or a comma-separated list of both.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/session_configurations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Standards
#
# GET /standards
# operationId: listStandards
export def "standards listStandards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --resource-type: string@resource-type-completer
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<standards: table<active: bool, description: string, id: string, name: string, type: string, resource_type: string, exclusions: list, inclusions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/standards" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a standard
#
# PUT /standards/{id}
# operationId: updateStandard
# --values shape: {regex?: string}
# --inclusions item shape: {type?: "technical_service_reference", id?: string}
# --exclusions item shape: {type?: "technical_service_reference", id?: string}
export def "standards updateStandard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --active: string@bool-completer
  --values: record # shape: {regex?: string}
  --description: string
  --inclusions: list # item shape: {type?: "technical_service_reference", id?: string}
  --exclusions: list # item shape: {type?: "technical_service_reference", id?: string}
]: any -> record<active: bool, description: string, id: string, name: string, type: string, resource_type: string, exclusions: table<type: string, id: string>, inclusions: table<type: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/standards/($id)")
  let body = {active: $active, values: $values, description: $description, inclusions: $inclusions, exclusions: $exclusions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List resources' standards scores
#
# GET /standards/scores/{resource_type}
# operationId: listResourceStandardsManyServices
export def "standards-scores listResourceStandardsManyServices" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Ids of resources to apply the standards. Maximum of 100 items
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<resources: table<resource_id: string, resource_type: string, score: record, standards: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/standards/scores/($resource_type)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a resource's standards scores
#
# GET /standards/scores/{resource_type}/{id}
# operationId: listResourceStandards
export def "standards-scores listResourceStandards" [
  id: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<resource_id: string, resource_type: string, score: record<passing: int, total: int>, standards: table<active: bool, description: string, id: string, name: string, type: string, pass: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/standards/scores/($resource_type)/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Dashboards
#
# GET /status_dashboards
# operationId: listStatusDashboards
export def "status-dashboards listStatusDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, next_cursor: string, status_dashboards: table<id: string, url_slug: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status_dashboards")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single Status Dashboard by `id`
#
# GET /status_dashboards/{id}
# operationId: getStatusDashboardById
export def "status-dashboards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<status_dashboard: record<id: string, url_slug: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_dashboards/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get impacted Business Services for a Status Dashboard by `id`.
#
# GET /status_dashboards/{id}/service_impacts
# operationId: getStatusDashboardServiceImpactsById
export def "status-dashboards-service-impacts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-fields: string@additional-fields-completer # Provides access to additional fields such as highest priority per business service and total impacted count
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, more: bool, services: table<id: string, name: string, type: string, status: string, additional_fields: record>, additional_fields: record<total_impacted_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional_fields[]" $additional_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_dashboards/($id)/service_impacts" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single Status Dashboard by `url_slug`
#
# GET /status_dashboards/url_slugs/{url_slug}
# operationId: getStatusDashboardByUrlSlug
export def "status-dashboards-url-slugs get" [
  url_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<status_dashboard: record<id: string, url_slug: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_dashboards/url_slugs/($url_slug)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get impacted Business Services for a  Status Dashboard by `url_slug`
#
# GET /status_dashboards/url_slugs/{url_slug}/service_impacts
# operationId: getStatusDashboardServiceImpactsByUrlSlug
export def "status-dashboards-url-slugs-service-impacts get" [
  url_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-fields: string@additional-fields-completer # Provides access to additional fields such as highest priority per business service and total impacted count
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, more: bool, services: table<id: string, name: string, type: string, status: string, additional_fields: record>, additional_fields: record<total_impacted_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional_fields[]" $additional_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_dashboards/url_slugs/($url_slug)/service_impacts" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Pages
#
# GET /status_pages
# operationId: listStatusPages
export def "status-pages listStatusPages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-page-type: string@status-page-type-completer # The type of the Status Page.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, status_pages: table<id: string, name: string, published_at: string, status_page_type: string, url: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status_page_type" $status_page_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status_pages" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Impacts
#
# GET /status_pages/{id}/impacts
# operationId: listStatusPageImpacts
export def "status-pages-impacts listStatusPageImpacts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --post-type: string@post-type-completer # Filter by Post type.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, impacts: table<id: string, self: string, description: string, post_type: string, status_page: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post_type" $post_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/impacts" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Status Page Impact
#
# GET /status_pages/{id}/impacts/{impact_id}
# operationId: getStatusPageImpact
export def "status-pages-impacts get" [
  id: string
  impact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<impact: record<id: string, self: string, description: string, post_type: string, status_page: record<id: string, type: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/impacts/($impact_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Services
#
# GET /status_pages/{id}/services
# operationId: listStatusPageServices
export def "status-pages-services listStatusPageServices" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, services: table<id: string, self: string, name: string, status_page: record, business_service: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/services")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Status Page Service
#
# GET /status_pages/{id}/services/{service_id}
# operationId: getStatusPageService
export def "status-pages-services get" [
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<service: record<id: string, self: string, name: string, status_page: record<id: string, type: string>, business_service: record<id: string, type: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/services/($service_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Severities
#
# GET /status_pages/{id}/severities
# operationId: listStatusPageSeverities
export def "status-pages-severities listStatusPageSeverities" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --post-type: string@post-type-completer # Filter by Post type.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, severities: table<id: string, self: string, description: string, post_type: string, status_page: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post_type" $post_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/severities" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Status Page Severity
#
# GET /status_pages/{id}/severities/{severity_id}
# operationId: getStatusPageSeverity
export def "status-pages-severities get" [
  id: string
  severity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<severity: record<id: string, self: string, description: string, post_type: string, status_page: record<id: string, type: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/severities/($severity_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Statuses
#
# GET /status_pages/{id}/statuses
# operationId: listStatusPageStatuses
export def "status-pages-statuses listStatusPageStatuses" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --post-type: string@post-type-completer # Filter by Post type.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, statuses: table<id: string, self: string, description: string, post_type: string, status_page: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post_type" $post_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/statuses" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Status Page Status
#
# GET /status_pages/{id}/statuses/{status_id}
# operationId: getStatusPageStatus
export def "status-pages-statuses get" [
  id: string
  status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<status: record<id: string, self: string, description: string, post_type: string, status_page: record<id: string, type: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/statuses/($status_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Posts
#
# GET /status_pages/{id}/posts
# operationId: listStatusPagePosts
export def "status-pages-posts listStatusPagePosts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --post-type: string@post-type-completer # Filter by Post type.
  --reviewed-status: string@reviewed-status-completer # Filter by the reviewed status of the Post to retrieve.
  --status: list # Filter by an array of Status identifiers.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, posts: table<id: string, self: string, type: string, post_type: string, status_page: record, linked_resource: record, postmortem: record, title: string, starts_at: string, ends_at: string, updates: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post_type" $post_type "scalar") (serialize-qp "reviewed_status" $reviewed_status "scalar") (serialize-qp "status[]" $status "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/posts" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Status Page Post
#
# POST /status_pages/{id}/posts
# operationId: createStatusPagePost
# --post shape: {type: "status_page_post", title: string, post_type: "incident"|"maintenance", starts_at: string, ends_at: string, updates: list, status_page: record}
export def "status-pages-posts createStatusPagePost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  post: record # Request schema for creating/updating a given Status Page Post resource. — shape: {type: "status_page_post", title: string, post_type: "incident"|"maintenance", starts_at: string, ends_at: string, updates: list, status_page: record}
]: any -> record<post: record<id: string, self: string, type: string, post_type: string, status_page: record<id: string, type: string>, linked_resource: record<id: string, type: string>, postmortem: record<id: string, type: string>, title: string, starts_at: string, ends_at: string, updates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts")
  let body = {post: $post} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Status Page Post
#
# GET /status_pages/{id}/posts/{post_id}
# operationId: getStatusPagePost
export def "status-pages-posts get" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<post: record<id: string, self: string, type: string, post_type: string, status_page: record<id: string, type: string>, linked_resource: record<id: string, type: string>, postmortem: record<id: string, type: string>, title: string, starts_at: string, ends_at: string, updates: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Status Page Post
#
# PUT /status_pages/{id}/posts/{post_id}
# operationId: updateStatusPagePost
# --post shape: {type: "status_page_post", title: string, post_type: "incident"|"maintenance", starts_at: string, ends_at: string, status_page: record}
export def "status-pages-posts updateStatusPagePost" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  post: record # Request schema for creating a given Status Page Post resource. — shape: {type: "status_page_post", title: string, post_type: "incident"|"maintenance", starts_at: string, ends_at: string, status_page: record}
]: any -> record<post: record<id: string, self: string, type: string, post_type: string, status_page: record<id: string, type: string>, linked_resource: record<id: string, type: string>, postmortem: record<id: string, type: string>, title: string, starts_at: string, ends_at: string, updates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)")
  let body = {post: $post} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Status Page Post
#
# DELETE /status_pages/{id}/posts/{post_id}
# operationId: deleteStatusPagePost
export def "status-pages-posts delete" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Post Updates
#
# GET /status_pages/{id}/posts/{post_id}/post_updates
# operationId: listStatusPagePostUpdates
export def "status-pages-posts-post-updates listStatusPagePostUpdates" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reviewed-status: string@reviewed-status-completer # Filter by the reviewed status of the Post Update to retrieve.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, post_updates: table<id: string, self: string, post: record, message: string, reviewed_status: string, status: record, severity: record, impacted_services: list, update_frequency_ms: int, notify_subscribers: bool, reported_at: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reviewed_status" $reviewed_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/post_updates" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Status Page Post Update
#
# POST /status_pages/{id}/posts/{post_id}/post_updates
# operationId: createStatusPagePostUpdate
# --post_update shape: {post: record, message: string, status: record, severity: record, impacted_services: list, update_frequency_ms: int, notify_subscribers: bool, reported_at?: string, type: string}
export def "status-pages-posts-post-updates createStatusPagePostUpdate" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  post_update: record # Attributes for Post Update creation/update — shape: {post: record, message: string, status: record, severity: record, impacted_services: list, update_frequency_ms: int, notify_subscribers: bool, reported_at?: string, type: string}
]: any -> record<post_update: record<id: string, self: string, post: record<id: string, type: string>, message: string, reviewed_status: string, status: record<id: string, type: string>, severity: record<id: string, type: string>, impacted_services: list<record>, update_frequency_ms: int, notify_subscribers: bool, reported_at: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/post_updates")
  let body = {post_update: $post_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Status Page Post Update
#
# GET /status_pages/{id}/posts/{post_id}/post_updates/{post_update_id}
# operationId: getPostUpdate
export def "status-pages-posts-post-updates get" [
  id: string
  post_id: string
  post_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<post_update: record<id: string, self: string, post: record<id: string, type: string>, message: string, reviewed_status: string, status: record<id: string, type: string>, severity: record<id: string, type: string>, impacted_services: list<record>, update_frequency_ms: int, notify_subscribers: bool, reported_at: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/post_updates/($post_update_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Status Page Post Update
#
# PUT /status_pages/{id}/posts/{post_id}/post_updates/{post_update_id}
# operationId: updateStatusPagePostUpdate
# --post_update shape: {post: record, message: string, status: record, severity: record, impacted_services: list, update_frequency_ms: int, notify_subscribers: bool, reported_at?: string, type: string}
export def "status-pages-posts-post-updates updateStatusPagePostUpdate" [
  id: string
  post_id: string
  post_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  post_update: record # Attributes for Post Update creation/update — shape: {post: record, message: string, status: record, severity: record, impacted_services: list, update_frequency_ms: int, notify_subscribers: bool, reported_at?: string, type: string}
]: any -> record<post_update: record<id: string, self: string, post: record<id: string, type: string>, message: string, reviewed_status: string, status: record<id: string, type: string>, severity: record<id: string, type: string>, impacted_services: list<record>, update_frequency_ms: int, notify_subscribers: bool, reported_at: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/post_updates/($post_update_id)")
  let body = {post_update: $post_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Status Page Post Update
#
# DELETE /status_pages/{id}/posts/{post_id}/post_updates/{post_update_id}
# operationId: deleteStatusPagePostUpdate
export def "status-pages-posts-post-updates delete" [
  id: string
  post_id: string
  post_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/post_updates/($post_update_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Post Postmortem
#
# GET /status_pages/{id}/posts/{post_id}/postmortem
# operationId: getPostmortem
export def "status-pages-posts-postmortem get" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<postmortem: record<id: string, self: string, post: record<id: string, type: string>, message: string, notify_subscribers: bool, reported_at: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/postmortem")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update a Post Postmortem
#
# PUT /status_pages/{id}/posts/{post_id}/postmortem
# operationId: createOrUpdateStatusPagePostmortem
# --postmortem shape: {post: record, message: string, notify_subscribers: bool}
export def "status-pages-posts-postmortem createOrUpdateStatusPagePostmortem" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  postmortem: record # Request to create/update a given Postmortem resource. — shape: {post: record, message: string, notify_subscribers: bool}
]: any -> record<postmortem: record<id: string, self: string, post: record<id: string, type: string>, message: string, notify_subscribers: bool, reported_at: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/postmortem")
  let body = {postmortem: $postmortem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Post Postmortem
#
# DELETE /status_pages/{id}/posts/{post_id}/postmortem
# operationId: deleteStatusPagePostmortem
export def "status-pages-posts-postmortem delete" [
  id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/posts/($post_id)/postmortem")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Status Page Subscriptions
#
# GET /status_pages/{id}/subscriptions
# operationId: listStatusPageSubscriptions
export def "status-pages-subscriptions listStatusPageSubscriptions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filter by Subscription status.
  --channel: string@channel-completer # Filter by Subscription channel.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, subscriptions: table<channel: string, contact: string, id: string, self: string, status: string, status_page: record, subscribable_object: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "channel" $channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_pages/($id)/subscriptions" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Status Page Subscription
#
# POST /status_pages/{id}/subscriptions
# operationId: createStatusPageSubscription
# --subscription shape: {channel: "webhook"|"email", contact: string, status_page: record, subscribable_object: record, type: string}
export def "status-pages-subscriptions createStatusPageSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscription: record # Request schema for creating a StatusPageSubscription. — shape: {channel: "webhook"|"email", contact: string, status_page: record, subscribable_object: record, type: string}
]: any -> record<subscription: record<channel: string, contact: string, id: string, self: string, status: string, status_page: record<id: string, type: string>, subscribable_object: record<id: string, type: string>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/subscriptions")
  let body = {subscription: $subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Status Page Subscription
#
# GET /status_pages/{id}/subscriptions/{subscription_id}
# operationId: getStatusPageSubscription
export def "status-pages-subscriptions get" [
  id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<subscription: record<channel: string, contact: string, id: string, self: string, status: string, status_page: record<id: string, type: string>, subscribable_object: record<id: string, type: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/subscriptions/($subscription_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Status Page Subscription
#
# DELETE /status_pages/{id}/subscriptions/{subscription_id}
# operationId: deleteStatusPageSubscription
export def "status-pages-subscriptions delete" [
  id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status_pages/($id)/subscriptions/($subscription_id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SRE Agent memories
#
# GET /sre_agent/memories
# operationId: listSreMemories
export def "sre-agent-memories listSreMemories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results to return per page. (default: 20 - incident_summary)
  --service-id: string # Filter memories by service ID
  --incident-id: string # Filter memories by incident ID
  --type: string@type-completer-1 # Filter memories by type
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<memories: table<id: string, content: string, attributes: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sre_agent/memories" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SRE Agent memory
#
# PUT /sre_agent/memories/{id}
# operationId: updateSreMemory
# --memory shape: {content: string}
export def "sre-agent-memories updateSreMemory" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  memory: record # shape: {content: string}
]: any -> record<memory: record<id: string, content: string, attributes: record<account_id: string, service_id: string, incident_id: string, type: string>, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sre_agent/memories/($id)")
  let body = {memory: $memory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SRE Agent memory
#
# DELETE /sre_agent/memories/{id}
# operationId: deleteSreMemory
export def "sre-agent-memories delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sre_agent/memories/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tags
#
# GET /tags
# operationId: listTags
export def "tags listTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Filters the result, showing only the tags whose label matches the query.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, tags: table<id: string, summary: string, type: string, self: string, html_url: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tag
#
# POST /tags
# operationId: createTags
export def "tags createTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  tag: any
]: any -> record<tag: record<id: string, summary: string, type: string, self: string, html_url: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a tag
#
# GET /tags/{id}
# operationId: getTag
export def "tags get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<tag: record<id: string, summary: string, type: string, self: string, html_url: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag
#
# DELETE /tags/{id}
# operationId: deleteTag
export def "tags delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get connected entities
#
# GET /tags/{id}/{entity_type}
# operationId: getTagsByEntityType
export def "tags get-by-id-entity_type" [
  id: string
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, users: table<type: string>, teams: table<type: string>, escalation_policies: table<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($id)/($entity_type)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /teams
# operationId: createTeam
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  team: any
]: any -> record<team: record<type: string, name: string, description: string, default_role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let body = {team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /teams
# operationId: listTeams
export def "teams listTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, teams: table<type: string, name: string, description: string, default_role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a team
#
# GET /teams/{id}
# operationId: getTeam
export def "teams get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-17 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<team: record<type: string, name: string, description: string, default_role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a team
#
# DELETE /teams/{id}
# operationId: deleteTeam
export def "teams delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reassignment-team: string # Team to reassign unresolved incident to. If an unresolved incident exists on both the reassignment team and the team being deleted, a duplicate will not be made. If not supplied, unresolved incidents will be made account-level.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reassignment_team" $reassignment_team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PUT /teams/{id}
# operationId: updateTeam
export def "teams updateTeam" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  team: any
]: any -> record<team: record<type: string, name: string, description: string, default_role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let body = {team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit records for a team
#
# GET /teams/{id}/audit/records
# operationId: listTeamsAuditRecords
export def "teams-audit-records listTeamsAuditRecords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an escalation policy from a team
#
# DELETE /teams/{id}/escalation_policies/{escalation_policy_id}
# operationId: deleteTeamEscalationPolicy
export def "teams-escalation-policies delete" [
  id: string
  escalation_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/escalation_policies/($escalation_policy_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an escalation policy to a team
#
# PUT /teams/{id}/escalation_policies/{escalation_policy_id}
# operationId: updateTeamEscalationPolicy
export def "teams-escalation-policies updateTeamEscalationPolicy" [
  id: string
  escalation_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/escalation_policies/($escalation_policy_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List members of a team
#
# GET /teams/{id}/members
# operationId: listTeamUsers
export def "teams-members listTeamUsers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --include: string@include-completer-12 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, members: table<user: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)/members" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Team Notification Subscriptions
#
# GET /teams/{id}/notification_subscriptions
# operationId: getTeamNotificationSubscriptions
export def "teams-notification-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, subscriptions: table<subscription: record, subscribable_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/notification_subscriptions")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team Notification Subscriptions
#
# POST /teams/{id}/notification_subscriptions
# operationId: createTeamNotificationSubscriptions
# --subscribables item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
export def "teams-notification-subscriptions createTeamNotificationSubscriptions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribables: list # item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
]: any -> record<subscriptions: table<subscriber_id: string, subscriber_type: string, subscribable_id: string, subscribable_type: string, account_id: string, result: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/notification_subscriptions")
  let body = {subscribables: $subscribables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsubscribe the given Team from Notifications on the matching Subscribable entities.  Scoped OAuth requires: `subscribers.write`
#
# POST /teams/{id}/notification_subscriptions/unsubscribe
# operationId: removeTeamNotificationSubscriptions
# --subscribables item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
export def "teams-notification-subscriptions-unsubscribe removeTeamNotificationSubscriptions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribables: list # item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
]: any -> record<deleted_count: float, unauthorized_count: float, non_existent_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/notification_subscriptions/unsubscribe")
  let body = {subscribables: $subscribables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a user from a team
#
# DELETE /teams/{id}/users/{user_id}
# operationId: deleteTeamUser
export def "teams-users delete" [
  id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/users/($user_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a user to a team
#
# PUT /teams/{id}/users/{user_id}
# operationId: updateTeamUser
export def "teams-users updateTeamUser" [
  id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --role: string@role-completer # The role of the user on the team.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/users/($user_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List templates
#
# GET /templates
# operationId: getTemplates
export def "templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --qp-query: string # Template name or description to search
  --template-type: string # Filters templates by type. (default: status_update)
  --sort-by: string@sort-by-completer-4 # Used to specify both the field you wish to sort the results on (name/created_at), as well as the direction (asc/desc) of the results. The sort_by field and direction should be separated by a colon. Sort direction defaults to ascending. (default: created_at:asc)
]: nothing -> record<offset: int, limit: int, more: bool, total: int, templates: table<template_type: string, name: string, description: string, templated_fields: record, id: string, summary: string, self: string, html_url: string, type: string, created_by: any, updated_by: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "template_type" $template_type "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /templates
# operationId: createTemplate
# --template shape: {template_type?: "status_update", name?: string, description?: string, templated_fields?: record}
export def "templates createTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: record # shape: {template_type?: "status_update", name?: string, description?: string, templated_fields?: record}
]: any -> record<template: record<template_type: string, name: string, description: string, templated_fields: record<email_subject: string, email_body: string, message: string>, id: string, summary: string, self: string, html_url: string, type: string, created_by: any, updated_by: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a template
#
# GET /templates/{id}
# operationId: getTemplate
export def "templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<template: record<template_type: string, name: string, description: string, templated_fields: record<email_subject: string, email_body: string, message: string>, id: string, summary: string, self: string, html_url: string, type: string, created_by: any, updated_by: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PUT /templates/{id}
# operationId: updateTemplate
# --template shape: {template_type?: "status_update", name?: string, description?: string, templated_fields?: record}
export def "templates updateTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template: record # shape: {template_type?: "status_update", name?: string, description?: string, templated_fields?: record}
]: any -> record<template: record<template_type: string, name: string, description: string, templated_fields: record<email_subject: string, email_body: string, message: string>, id: string, summary: string, self: string, html_url: string, type: string, created_by: any, updated_by: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /templates/{id}
# operationId: deleteTemplate
export def "templates delete" [
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
  let full_url = (build-url $base $"/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render a template
#
# POST /templates/{id}/render
# operationId: renderTemplate
# --status_update shape: {message?: string}
export def "templates-render renderTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-id: string # The incident id to render the template for
  --status-update: record # shape: {message?: string}
  --external: any # An optional object collection that can be referenced in the template.
]: any -> record<templated_fields: record<email_subject: string, email_body: string, message: string>, warnings: record<email_subject: list<string>, email_body: list<string>, message: list<string>>, errors: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)/render")
  let body = {incident_id: $incident_id, status_update: $status_update, external: $external} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List template fields
#
# GET /templates/fields
# operationId: getTemplateFields
export def "templates-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<fields: table<data_type: string, default_value: string, description: string, domain_name: record, example: string, keyword: string, summary: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/fields")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --include: string@include-completer-18 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, users: table<name: string, type: string, email: string, time_zone: string, color: string, role: string, avatar_url: string, description: string, invitation_sent: bool, job_title: string, created_via_sso: bool, teams: list, contact_methods: list, notification_rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: createUser
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --From: string # The email address of a valid user associated with the account making the request.
  user: any
]: any -> record<user: record<name: string, type: string, email: string, time_zone: string, color: string, role: string, avatar_url: string, description: string, invitation_sent: bool, job_title: string, created_via_sso: bool, teams: list<record>, contact_methods: list<record>, notification_rules: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "From": $From} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user
#
# GET /users/{id}
# operationId: getUser
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-18 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<user: record<name: string, type: string, email: string, time_zone: string, color: string, role: string, avatar_url: string, description: string, invitation_sent: bool, job_title: string, created_via_sso: bool, teams: list<record>, contact_methods: list<record>, notification_rules: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /users/{id}
# operationId: deleteUser
export def "users delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /users/{id}
# operationId: updateUser
export def "users updateUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  user: any
]: any -> record<user: record<name: string, type: string, email: string, time_zone: string, color: string, role: string, avatar_url: string, description: string, invitation_sent: bool, job_title: string, created_via_sso: bool, teams: list<record>, contact_methods: list<record>, notification_rules: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit records for a user
#
# GET /users/{id}/audit/records
# operationId: listUsersAuditRecords
export def "users-audit-records listUsersAuditRecords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's contact methods
#
# GET /users/{id}/contact_methods
# operationId: getUserContactMethods
export def "users-contact-methods list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<contact_methods: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/contact_methods")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user contact method
#
# POST /users/{id}/contact_methods
# operationId: createUserContactMethod
export def "users-contact-methods createUserContactMethod" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  contact_method: any
]: any -> record<contact_method: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/contact_methods")
  let body = {contact_method: $contact_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's contact method
#
# GET /users/{id}/contact_methods/{contact_method_id}
# operationId: getUserContactMethod
export def "users-contact-methods get" [
  id: string
  contact_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<contact_method: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/contact_methods/($contact_method_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user's contact method
#
# DELETE /users/{id}/contact_methods/{contact_method_id}
# operationId: deleteUserContactMethod
export def "users-contact-methods delete" [
  id: string
  contact_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/contact_methods/($contact_method_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's contact method
#
# PUT /users/{id}/contact_methods/{contact_method_id}
# operationId: updateUserContactMethod
export def "users-contact-methods updateUserContactMethod" [
  id: string
  contact_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  contact_method: any
]: any -> record<contact_method: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/contact_methods/($contact_method_id)")
  let body = {contact_method: $contact_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a user's delegations
#
# GET /users/{id}/oauth_delegations
# operationId: listUserDelegations
export def "users-oauth-delegations listUserDelegations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delegation-type: string@delegation-type-completer # The type of OAuth delegations to filter on. Allowed values are 'mobile', 'web', and 'integration'. You can pass one or more types in, separated by commas (e.g., `type=web,mobile`).
  --status: string@status-completer-1 # The status of the delegations to return. Allowed values are 'issued' and 'revoked'. You can pass one or more statuses in, separated by commas (e.g., `status=issued,revoked`).
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<oauth_delegations: table<id: string, status: string, client_id: string, delegation_type: string, scope: string, created_at: string, expires_at: string, self: string>, limit: int, more: bool, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delegation_type" $delegation_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/oauth_delegations" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's delegation
#
# GET /users/{id}/oauth_delegations/{delegation_id}
# operationId: getUserDelegation
export def "users-oauth-delegations get" [
  id: string
  delegation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<id: string, status: string, client_id: string, delegation_type: string, scope: string, created_at: string, expires_at: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/oauth_delegations/($delegation_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the License allocated to a User
#
# GET /users/{id}/license
# operationId: getUserLicense
export def "users-license get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<license: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/license")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's notification rules
#
# GET /users/{id}/notification_rules
# operationId: getUserNotificationRules
export def "users-notification-rules list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-19 # Array of additional details to include.
  --urgency: string@urgency-completer # The incident urgency for which the notification rules are applied. If not specified, defaults to `high`.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<notification_rules: table<type: string, start_delay_in_minutes: int, contact_method: record, urgency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar") (serialize-qp "urgency" $urgency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/notification_rules" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user notification rule
#
# POST /users/{id}/notification_rules
# operationId: createUserNotificationRule
export def "users-notification-rules createUserNotificationRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  notification_rule: any
]: any -> record<notification_rule: record<type: string, start_delay_in_minutes: int, contact_method: record<type: string>, urgency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/notification_rules")
  let body = {notification_rule: $notification_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's notification rule
#
# GET /users/{id}/notification_rules/{notification_rule_id}
# operationId: getUserNotificationRule
export def "users-notification-rules get" [
  id: string
  notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-19 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<notification_rule: record<type: string, start_delay_in_minutes: int, contact_method: record<type: string>, urgency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/notification_rules/($notification_rule_id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user's notification rule
#
# DELETE /users/{id}/notification_rules/{notification_rule_id}
# operationId: deleteUserNotificationRule
export def "users-notification-rules delete" [
  id: string
  notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/notification_rules/($notification_rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's notification rule
#
# PUT /users/{id}/notification_rules/{notification_rule_id}
# operationId: updateUserNotificationRule
export def "users-notification-rules updateUserNotificationRule" [
  id: string
  notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  notification_rule: any
]: any -> record<notification_rule: record<type: string, start_delay_in_minutes: int, contact_method: record<type: string>, urgency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/notification_rules/($notification_rule_id)")
  let body = {notification_rule: $notification_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Notification Subscriptions
#
# GET /users/{id}/notification_subscriptions
# operationId: getUserNotificationSubscriptions
export def "users-notification-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<offset: int, limit: int, more: bool, total: int, subscriptions: table<subscription: record, subscribable_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/notification_subscriptions")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Notification Subcriptions
#
# POST /users/{id}/notification_subscriptions
# operationId: createUserNotificationSubscriptions
# --subscribables item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
export def "users-notification-subscriptions createUserNotificationSubscriptions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribables: list # item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
]: any -> record<subscriptions: table<subscriber_id: string, subscriber_type: string, subscribable_id: string, subscribable_type: string, account_id: string, result: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/notification_subscriptions")
  let body = {subscribables: $subscribables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Notification Subscriptions
#
# POST /users/{id}/notification_subscriptions/unsubscribe
# operationId: unsubscribeUserNotificationSubscriptions
# --subscribables item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
export def "users-notification-subscriptions-unsubscribe unsubscribeUserNotificationSubscriptions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  subscribables: list # item shape: {subscribable_id?: string, subscribable_type?: "incident"|"business_service"}
]: any -> record<deleted_count: float, unauthorized_count: float, non_existent_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/notification_subscriptions/unsubscribe")
  let body = {subscribables: $subscribables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a User's Handoff Notification Rules
#
# GET /users/{id}/oncall_handoff_notification_rules
# operationId: getUserHandoffNotificationRules
export def "users-oncall-handoff-notification-rules list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<oncall_handoff_notification_rules: table<id: string, notify_advance_in_minutes: int, handoff_type: string, contact_method: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/oncall_handoff_notification_rules")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a User Handoff Notification Rule
#
# POST /users/{id}/oncall_handoff_notification_rules
# operationId: createUserHandoffNotificationRule
# --oncall_handoff_notification_rule shape: {notify_advance_in_minutes?: int, handoff_type: "both"|"oncall"|"offcall", contact_method: any}
export def "users-oncall-handoff-notification-rules createUserHandoffNotificationRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  oncall_handoff_notification_rule: record # A rule for contacting the user for Handoff Notifications. (e.g. {id: PXPGF42, notify_advance_in_minutes: 180, handoff_type: both, contact_method: {id: PXPGF42, type: email_contact_method_reference}}) — shape: {notify_advance_in_minutes?: int, handoff_type: "both"|"oncall"|"offcall", contact_method: any}
]: any -> record<oncall_handoff_notification_rule: record<id: string, notify_advance_in_minutes: int, handoff_type: string, contact_method: record<type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/oncall_handoff_notification_rules")
  let body = {oncall_handoff_notification_rule: $oncall_handoff_notification_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's handoff notification rule
#
# GET /users/{id}/oncall_handoff_notification_rules/{oncall_handoff_notification_rule_id}
# operationId: getUserHandoffNotifiactionRule
export def "users-oncall-handoff-notification-rules get" [
  id: string
  oncall_handoff_notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<oncall_handoff_notification_rule: record<id: string, notify_advance_in_minutes: int, handoff_type: string, contact_method: record<type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/oncall_handoff_notification_rules/($oncall_handoff_notification_rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a User's Handoff Notification rule
#
# DELETE /users/{id}/oncall_handoff_notification_rules/{oncall_handoff_notification_rule_id}
# operationId: deleteUserHandoffNotificationRule
export def "users-oncall-handoff-notification-rules delete" [
  id: string
  oncall_handoff_notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/oncall_handoff_notification_rules/($oncall_handoff_notification_rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a User's Handoff Notification Rule
#
# PUT /users/{id}/oncall_handoff_notification_rules/{oncall_handoff_notification_rule_id}
# operationId: updateUserHandoffNotification
# --oncall_handoff_notification_rule shape: {notify_advance_in_minutes?: int, handoff_type: "both"|"oncall"|"offcall", contact_method: any}
export def "users-oncall-handoff-notification-rules updateUserHandoffNotification" [
  id: string
  oncall_handoff_notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  oncall_handoff_notification_rule: record # A rule for contacting the user for Handoff Notifications. (e.g. {id: PXPGF42, notify_advance_in_minutes: 180, handoff_type: both, contact_method: {id: PXPGF42, type: email_contact_method_reference}}) — shape: {notify_advance_in_minutes?: int, handoff_type: "both"|"oncall"|"offcall", contact_method: any}
]: any -> record<oncall_handoff_notification_rule: record<id: string, notify_advance_in_minutes: int, handoff_type: string, contact_method: record<type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/oncall_handoff_notification_rules/($oncall_handoff_notification_rule_id)")
  let body = {oncall_handoff_notification_rule: $oncall_handoff_notification_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a user's active sessions
#
# GET /users/{id}/sessions
# DEPRECATED
# operationId: getUserSessions
@deprecated
export def "users-sessions get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<user_sessions: table<id: string, user_id: string, created_at: string, type: string, summary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/sessions")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all user sessions
#
# DELETE /users/{id}/sessions
# DEPRECATED
# operationId: deleteUserSessions
@deprecated
export def "users-sessions delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/sessions")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's session
#
# GET /users/{id}/sessions/{type}/{session_id}
# DEPRECATED
# operationId: getUserSession
@deprecated
export def "users-sessions get-by-id-type-session_id" [
  id: string
  type: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<user_session: record<id: string, user_id: string, created_at: string, type: string, summary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/sessions/($type)/($session_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user's session
#
# DELETE /users/{id}/sessions/{type}/{session_id}
# DEPRECATED
# operationId: deleteUserSession
@deprecated
export def "users-sessions delete-by-id-type-session_id" [
  id: string
  type: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/sessions/($type)/($session_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's status update notification rules
#
# GET /users/{id}/status_update_notification_rules
# operationId: getUserStatusUpdateNotificationRules
export def "users-status-update-notification-rules list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-19 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<status_update_notification_rules: table<contact_method: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/status_update_notification_rules" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user status update notification rule
#
# POST /users/{id}/status_update_notification_rules
# operationId: createUserStatusUpdateNotificationRule
# --status_update_notification_rule shape: {contact_method: any}
export def "users-status-update-notification-rules createUserStatusUpdateNotificationRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  status_update_notification_rule: record # A rule for contacting the user for Incident Status Updates. (e.g. {contact_method: {id: PXPGF42, type: email_contact_method_reference}}) — shape: {contact_method: any}
]: any -> record<status_update_notification_rule: record<contact_method: record<type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/status_update_notification_rules")
  let body = {status_update_notification_rule: $status_update_notification_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's status update notification rule
#
# GET /users/{id}/status_update_notification_rules/{status_update_notification_rule_id}
# operationId: getUserStatusUpdateNotificationRule
export def "users-status-update-notification-rules get" [
  id: string
  status_update_notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-19 # Array of additional details to include.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<notification_rule: record<contact_method: record<type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/status_update_notification_rules/($status_update_notification_rule_id)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user's status update notification rule
#
# DELETE /users/{id}/status_update_notification_rules/{status_update_notification_rule_id}
# operationId: deleteUserStatusUpdateNotificationRule
export def "users-status-update-notification-rules delete" [
  id: string
  status_update_notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/status_update_notification_rules/($status_update_notification_rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's status update notification rule
#
# PUT /users/{id}/status_update_notification_rules/{status_update_notification_rule_id}
# operationId: updateUserStatusUpdateNotificationRule
# --status_update_notification_rule shape: {contact_method: any}
export def "users-status-update-notification-rules updateUserStatusUpdateNotificationRule" [
  id: string
  status_update_notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  status_update_notification_rule: record # A rule for contacting the user for Incident Status Updates. (e.g. {contact_method: {id: PXPGF42, type: email_contact_method_reference}}) — shape: {contact_method: any}
]: any -> record<notification_rule: record<contact_method: record<type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/status_update_notification_rules/($status_update_notification_rule_id)")
  let body = {status_update_notification_rule: $status_update_notification_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the current user
#
# GET /users/me
# operationId: getCurrentUser
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-18 # Array of additional Models to include in response.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<user: record<name: string, type: string, email: string, time_zone: string, color: string, role: string, avatar_url: string, description: string, invitation_sent: bool, job_title: string, created_via_sso: bool, teams: list<record>, contact_methods: list<record>, notification_rules: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List vendors
#
# GET /vendors
# operationId: listVendors
export def "vendors listVendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<offset: int, limit: int, more: bool, total: int, vendors: table<name: string, website_url: string, logo_url: string, thumbnail_url: string, description: string, integration_guide_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vendors" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List schedules
#
# GET /v3/schedules
# operationId: listSchedulesV3
export def "schedules listSchedulesV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of schedules to return (default: 100)
  --offset: int # default: 0
  --qp-query: string # Filters the result, showing only the records whose name matches the query.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
]: nothing -> record<schedules: table<id: string, type: string, summary: string, self: string, html_url: string>, limit: int, offset: int, more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "team_ids[]" $team_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a schedule
#
# POST /v3/schedules
# operationId: createScheduleV3
# --schedule shape: {name: string, time_zone: string, description?: string, teams?: list}
export def "schedules createScheduleV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schedule: record # shape: {name: string, time_zone: string, description?: string, teams?: list}
]: any -> record<schedule: record<id: string, type: string, name: string, time_zone: string, description: string, teams: list<record>, escalation_policies: list<record>, users: list<record>, rotations: list<record>, final_schedule: record<type: string, rendered_coverage_percentage: float, computed_shift_assignments: list>, http_cal_url: string, web_cal_url: string, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/schedules")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a schedule
#
# GET /v3/schedules/{id}
# operationId: getScheduleV3
export def "schedules get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start of time range (ISO 8601) (format: date-time, e.g. 2025-01-01T00:00:00Z)
  --until: string # End of time range (ISO 8601) (format: date-time, e.g. 2025-01-31T23:59:59Z)
  --time-zone: string # IANA timezone identifier for rendering shift times. Defaults to the schedule's configured time zone.  (e.g. America/New_York)
  --overflow: string@bool-completer # Include shifts that extend beyond the requested time range boundaries (default: false)
  --include: list # Additional data to include in the schedule response: - `final_schedule`: computed on-call assignments for the time range  (e.g. [final_schedule])
]: nothing -> record<schedule: record<id: string, type: string, name: string, time_zone: string, description: string, teams: list<record>, escalation_policies: list<record>, users: list<record>, rotations: list<record>, final_schedule: record<type: string, rendered_coverage_percentage: float, computed_shift_assignments: list>, http_cal_url: string, web_cal_url: string, self: string, html_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "overflow" $overflow "scalar") (serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a schedule
#
# PUT /v3/schedules/{id}
# operationId: updateScheduleV3
# --schedule shape: {name?: string, time_zone?: string, description?: string}
export def "schedules updateScheduleV3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schedule: record # shape: {name?: string, time_zone?: string, description?: string}
]: any -> record<schedule: record<id: string, type: string, name: string, time_zone: string, description: string, teams: list<record>, escalation_policies: list<record>, users: list<record>, rotations: list<record>, final_schedule: record<type: string, rendered_coverage_percentage: float, computed_shift_assignments: list>, http_cal_url: string, web_cal_url: string, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a schedule
#
# DELETE /v3/schedules/{id}
# operationId: deleteScheduleV3
export def "schedules delete-by-id-1" [
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
  let full_url = (build-url $base $"/v3/schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List audit records for a schedule
#
# GET /v3/schedules/{id}/audit/records
# operationId: listSchedulesAuditRecordsV3
export def "schedules-audit-records listSchedulesAuditRecordsV3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --since: string # The start of the date range over which you want to search. If not specified, defaults to `now() - 24 hours` (past 24 hours) (format: date-time)
  --until: string # The end of the date range over which you want to search. If not specified, defaults to `now()`. May not be more than 31 days after `since`. (format: date-time)
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<records: table<id: string, self: string, execution_time: string, execution_context: record, actors: list, method: record, root_resource: record, action: string, details: record>, response_metadata: any, limit: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/audit/records" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom shifts
#
# GET /v3/schedules/{id}/custom_shifts
# operationId: listCustomShifts
export def "schedules-custom-shifts listCustomShifts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start of time range (ISO 8601) (format: date-time, e.g. 2026-06-01T00:00:00Z)
  --until: string # End of time range (ISO 8601) (format: date-time, e.g. 2026-06-28T23:59:59Z)
  --time-zone: string # IANA timezone identifier for rendering shift times. Defaults to the schedule's configured time zone.  (e.g. America/New_York)
  --overflow: string@bool-completer # Include shifts that extend beyond the requested time range boundaries (default: false)
  --limit: int # default: 25
  --offset: int # default: 0
]: nothing -> record<custom_shifts: table<id: string, type: string, start_time: string, end_time: string, assignments: list, self: string, html_url: string>, limit: int, offset: int, more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "overflow" $overflow "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/custom_shifts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create custom shifts
#
# POST /v3/schedules/{id}/custom_shifts
# operationId: createCustomShifts
# --custom_shifts item shape: {type: "custom_shift", start_time: string, end_time: string, assignments: list}
export def "schedules-custom-shifts createCustomShifts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_shifts: list # item shape: {type: "custom_shift", start_time: string, end_time: string, assignments: list}
]: any -> record<custom_shifts: table<id: string, type: string, start_time: string, end_time: string, assignments: list, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/custom_shifts")
  let body = {custom_shifts: $custom_shifts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a custom shift
#
# GET /v3/schedules/{id}/custom_shifts/{custom_shift_id}
# operationId: getCustomShift
export def "schedules-custom-shifts get" [
  id: string
  custom_shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_shift: record<id: string, type: string, start_time: string, end_time: string, assignments: list<record>, self: string, html_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/custom_shifts/($custom_shift_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom shift
#
# PUT /v3/schedules/{id}/custom_shifts/{custom_shift_id}
# operationId: updateCustomShift
# --custom_shift shape: {start_time?: string, end_time?: string, assignments?: list}
export def "schedules-custom-shifts updateCustomShift" [
  id: string
  custom_shift_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_shift: record # If the shift has already started, only `end_time` can be modified. — shape: {start_time?: string, end_time?: string, assignments?: list}
]: any -> record<custom_shift: record<id: string, type: string, start_time: string, end_time: string, assignments: list<record>, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/custom_shifts/($custom_shift_id)")
  let body = {custom_shift: $custom_shift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom shift
#
# DELETE /v3/schedules/{id}/custom_shifts/{custom_shift_id}
# operationId: deleteCustomShift
export def "schedules-custom-shifts delete" [
  id: string
  custom_shift_id: string
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
  let full_url = (build-url $base $"/v3/schedules/($id)/custom_shifts/($custom_shift_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List overrides
#
# GET /v3/schedules/{id}/overrides
# operationId: listOverrides
export def "schedules-overrides listOverrides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start of time range (ISO 8601) (format: date-time, e.g. 2026-06-01T00:00:00Z)
  --until: string # End of time range (ISO 8601) (format: date-time, e.g. 2026-06-28T23:59:59Z)
  --time-zone: string # IANA timezone identifier for rendering shift times. Defaults to the schedule's configured time zone.  (e.g. America/New_York)
  --overflow: string@bool-completer # Include shifts that extend beyond the requested time range boundaries (default: false)
  --limit: int # default: 25
  --offset: int # default: 0
]: nothing -> record<overrides: table<id: string, type: string, rotation_id: string, custom_shift_id: string, start_time: string, end_time: string, overridden_member: record, overriding_member: record, self: string, html_url: string>, limit: int, offset: int, more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "time_zone" $time_zone "scalar") (serialize-qp "overflow" $overflow "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/overrides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create overrides
#
# POST /v3/schedules/{id}/overrides
# operationId: createOverrides
# --overrides item shape: {type: "override_shift", rotation_id?: string, custom_shift_id?: string, start_time: string, end_time: string, overridden_member: record, overriding_member: record}
export def "schedules-overrides createOverrides" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  overrides: list # item shape: {type: "override_shift", rotation_id?: string, custom_shift_id?: string, start_time: string, end_time: string, overridden_member: record, overriding_member: record}
]: any -> record<overrides: table<id: string, type: string, rotation_id: string, custom_shift_id: string, start_time: string, end_time: string, overridden_member: record, overriding_member: record, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/overrides")
  let body = {overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an override
#
# GET /v3/schedules/{id}/overrides/{override_id}
# operationId: getOverride
export def "schedules-overrides get" [
  id: string
  override_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<override: record<id: string, type: string, rotation_id: string, custom_shift_id: string, start_time: string, end_time: string, overridden_member: record<type: string, user_id: string>, overriding_member: record<type: string, user_id: string>, self: string, html_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/overrides/($override_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an override
#
# PUT /v3/schedules/{id}/overrides/{override_id}
# operationId: updateOverride
# --override shape: {start_time?: string, end_time?: string, overriding_member?: record}
export def "schedules-overrides updateOverride" [
  id: string
  override_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  override: record # shape: {start_time?: string, end_time?: string, overriding_member?: record}
]: any -> record<override: record<id: string, type: string, rotation_id: string, custom_shift_id: string, start_time: string, end_time: string, overridden_member: record<type: string, user_id: string>, overriding_member: record<type: string, user_id: string>, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/overrides/($override_id)")
  let body = {override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an override
#
# DELETE /v3/schedules/{id}/overrides/{override_id}
# operationId: deleteOverride
export def "schedules-overrides delete-by-id-override_id-1" [
  id: string
  override_id: string
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
  let full_url = (build-url $base $"/v3/schedules/($id)/overrides/($override_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List rotations
#
# GET /v3/schedules/{id}/rotations
# operationId: listRotations
export def "schedules-rotations listRotations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 25
  --offset: int # default: 0
]: nothing -> record<rotations: table<id: string, type: string, events: list, self: string, html_url: string>, limit: int, offset: int, more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a rotation
#
# POST /v3/schedules/{id}/rotations
# operationId: createRotation
export def "schedules-rotations createRotation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<rotation: record<id: string, type: string, events: list<record>, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a rotation
#
# GET /v3/schedules/{id}/rotations/{rotation_id}
# operationId: getRotation
export def "schedules-rotations get" [
  id: string
  rotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start of time range (ISO 8601) (format: date-time, e.g. 2025-01-01T00:00:00Z)
  --until: string # End of time range (ISO 8601) (format: date-time, e.g. 2025-01-31T23:59:59Z)
]: nothing -> record<rotation: record<id: string, type: string, events: list<record>, self: string, html_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a rotation
#
# DELETE /v3/schedules/{id}/rotations/{rotation_id}
# operationId: deleteRotation
export def "schedules-rotations delete" [
  id: string
  rotation_id: string
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
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List events
#
# GET /v3/schedules/{id}/rotations/{rotation_id}/events
# operationId: listEvents
export def "schedules-rotations-events listEvents" [
  id: string
  rotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 25
  --offset: int # default: 0
]: nothing -> record<events: table<id: string, type: string, name: string, start_time: record, end_time: record, effective_since: string, effective_until: string, recurrence: list, assignment_strategy: record, self: string, html_url: string>, limit: int, offset: int, more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an event
#
# POST /v3/schedules/{id}/rotations/{rotation_id}/events
# operationId: createEvent
# --event shape: {name: string, start_time: record, end_time: record, effective_since: string, effective_until?: string, recurrence: list, assignment_strategy: record}
export def "schedules-rotations-events createEvent" [
  id: string
  rotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: record # shape: {name: string, start_time: record, end_time: record, effective_since: string, effective_until?: string, recurrence: list, assignment_strategy: record}
]: any -> record<event: record<id: string, type: string, name: string, start_time: record<date_time: string, time_zone: string>, end_time: record<date_time: string, time_zone: string>, effective_since: string, effective_until: string, recurrence: list<string>, assignment_strategy: record<type: string, shifts_per_member: int, members: list>, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)/events")
  let body = {event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an event
#
# GET /v3/schedules/{id}/rotations/{rotation_id}/events/{event_id}
# operationId: getEvent
export def "schedules-rotations-events get" [
  id: string
  rotation_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start of time range (ISO 8601) (format: date-time, e.g. 2025-01-01T00:00:00Z)
  --until: string # End of time range (ISO 8601) (format: date-time, e.g. 2025-01-31T23:59:59Z)
]: nothing -> record<event: record<id: string, type: string, name: string, start_time: record<date_time: string, time_zone: string>, end_time: record<date_time: string, time_zone: string>, effective_since: string, effective_until: string, recurrence: list<string>, assignment_strategy: record<type: string, shifts_per_member: int, members: list>, self: string, html_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an event
#
# PUT /v3/schedules/{id}/rotations/{rotation_id}/events/{event_id}
# operationId: updateEvent
# --event shape: {name?: string, start_time?: record, end_time?: record, effective_since?: string, effective_until?: string, recurrence?: list, assignment_strategy?: record}
export def "schedules-rotations-events updateEvent" [
  id: string
  rotation_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: record # shape: {name?: string, start_time?: record, end_time?: record, effective_since?: string, effective_until?: string, recurrence?: list, assignment_strategy?: record}
]: any -> record<event: record<id: string, type: string, name: string, start_time: record<date_time: string, time_zone: string>, end_time: record<date_time: string, time_zone: string>, effective_since: string, effective_until: string, recurrence: list<string>, assignment_strategy: record<type: string, shifts_per_member: int, members: list>, self: string, html_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)/events/($event_id)")
  let body = {event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an event
#
# DELETE /v3/schedules/{id}/rotations/{rotation_id}/events/{event_id}
# operationId: deleteEvent
export def "schedules-rotations-events delete" [
  id: string
  rotation_id: string
  event_id: string
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
  let full_url = (build-url $base $"/v3/schedules/($id)/rotations/($rotation_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a vendor
#
# GET /vendors/{id}
# operationId: getVendor
export def "vendors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<vendor: table<name: string, website_url: string, logo_url: string, thumbnail_url: string, description: string, integration_guide_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vendors/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhook subscriptions
#
# GET /webhook_subscriptions
# operationId: listWebhookSubscriptions
export def "webhook-subscriptions listWebhookSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results per page.
  --offset: int # Offset to start pagination search results.
  --total: string@bool-completer # By default the `total` field in pagination responses is set to `null` to provide the fastest possible response times. Set `total` to `true` for this field to be populated.  See our [Pagination Docs](https://developer.pagerduty.com/docs/rest-api-v2/pagination/) for more information.  (default: false)
  --filter-type: string@filter-type-completer # The type of resource to filter upon.
  --filter-id: string # The id of the resource to filter upon. Required if filter_type is service or team.
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<webhook_subscriptions: table<id: string, type: string, active: bool, delivery_method: record, description: string, events: list, filter: record, oauth_client: record>, offset: int, limit: int, more: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "filter_type" $filter_type "scalar") (serialize-qp "filter_id" $filter_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook_subscriptions" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook subscription
#
# POST /webhook_subscriptions
# operationId: createWebhookSubscription
# --webhook_subscription shape: {type: "webhook_subscription", active?: bool, delivery_method: record, description?: string, events: list, filter: record}
export def "webhook-subscriptions createWebhookSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  webhook_subscription: record # shape: {type: "webhook_subscription", active?: bool, delivery_method: record, description?: string, events: list, filter: record}
]: any -> record<webhook_subscription: record<id: string, type: string, active: bool, delivery_method: record<id: string, secret: string, temporarily_disabled: bool, type: string, url: string, custom_headers: list>, description: string, events: list<string>, filter: record<id: string, type: string>, oauth_client: record<id: string, type: string, summary: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_subscriptions")
  let body = {webhook_subscription: $webhook_subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a webhook subscription
#
# GET /webhook_subscriptions/{id}
# operationId: getWebhookSubscription
export def "webhook-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<webhook_subscription: record<id: string, type: string, active: bool, delivery_method: record<id: string, secret: string, temporarily_disabled: bool, type: string, url: string, custom_headers: list>, description: string, events: list<string>, filter: record<id: string, type: string>, oauth_client: record<id: string, type: string, summary: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook subscription
#
# PUT /webhook_subscriptions/{id}
# operationId: updateWebhookSubscription
# --webhook_subscription shape: {description?: string, events?: list, filter?: record, active?: bool, oauth_client_id?: string}
export def "webhook-subscriptions updateWebhookSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  --webhook-subscription: record # shape: {description?: string, events?: list, filter?: record, active?: bool, oauth_client_id?: string}
]: any -> record<webhook_subscription: record<id: string, type: string, active: bool, delivery_method: record<id: string, secret: string, temporarily_disabled: bool, type: string, url: string, custom_headers: list>, description: string, events: list<string>, filter: record<id: string, type: string>, oauth_client: record<id: string, type: string, summary: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/($id)")
  let body = {webhook_subscription: $webhook_subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook subscription
#
# DELETE /webhook_subscriptions/{id}
# operationId: deleteWebhookSubscription
export def "webhook-subscriptions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable a webhook subscription
#
# POST /webhook_subscriptions/{id}/enable
# operationId: enableWebhookSubscription
export def "webhook-subscriptions-enable enableWebhookSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<webhook_subscription: record<id: string, type: string, active: bool, delivery_method: record<id: string, secret: string, temporarily_disabled: bool, type: string, url: string, custom_headers: list>, description: string, events: list<string>, filter: record<id: string, type: string>, oauth_client: record<id: string, type: string, summary: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/($id)/enable")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test a webhook subscription
#
# POST /webhook_subscriptions/{id}/ping
# operationId: testWebhookSubscription
export def "webhook-subscriptions-ping testWebhookSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/($id)/ping")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List OAuth clients
#
# GET /webhook_subscriptions/oauth_clients
# operationId: listOauthClients
export def "webhook-subscriptions-oauth-clients listOauthClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<oauth_clients: table<id: string, type: string, name: string, client_id: string, scope: string, token_url: string, grant_type: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_subscriptions/oauth_clients")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an OAuth client
#
# POST /webhook_subscriptions/oauth_clients
# operationId: createOauthClient
# --oauth_client shape: {name: string, client_id: string, client_secret: string, scope?: string, token_url: string, grant_type: "client_credentials"}
export def "webhook-subscriptions-oauth-clients createOauthClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  oauth_client: record # shape: {name: string, client_id: string, client_secret: string, scope?: string, token_url: string, grant_type: "client_credentials"}
]: any -> record<oauth_client: record<id: string, type: string, name: string, client_id: string, scope: string, token_url: string, grant_type: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_subscriptions/oauth_clients")
  let body = {oauth_client: $oauth_client} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an OAuth client
#
# GET /webhook_subscriptions/oauth_clients/{id}
# operationId: getOauthClient
export def "webhook-subscriptions-oauth-clients get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> record<oauth_client: record<id: string, type: string, name: string, client_id: string, scope: string, token_url: string, grant_type: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/oauth_clients/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an OAuth client
#
# PUT /webhook_subscriptions/oauth_clients/{id}
# operationId: updateOauthClient
# --oauth_client shape: {name?: string, client_id?: string, client_secret?: string, scope?: string, token_url?: string, grant_type?: "client_credentials"}
export def "webhook-subscriptions-oauth-clients updateOauthClient" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  oauth_client: record # shape: {name?: string, client_id?: string, client_secret?: string, scope?: string, token_url?: string, grant_type?: "client_credentials"}
]: any -> record<oauth_client: record<id: string, type: string, name: string, client_id: string, scope: string, token_url: string, grant_type: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/oauth_clients/($id)")
  let body = {oauth_client: $oauth_client} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an OAuth client
#
# DELETE /webhook_subscriptions/oauth_clients/{id}
# operationId: deleteOauthClient
export def "webhook-subscriptions-oauth-clients delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_subscriptions/oauth_clients/($id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Workflow Integrations
#
# GET /workflows/integrations
# operationId: listWorkflowIntegrations
export def "workflows-integrations listWorkflowIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --include-deprecated: string@bool-completer # Whether to include deprecated Integrations in the response. (default: false)
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, next_cursor: string, integrations: table<id: string, type: string, domain_name: string, package_name: string, name: string, description: string, icon_svg: string, tags: list, search_keywords: list, is_deprecated: bool, entitled: bool, application: string, configuration_schema: record, secrets_schema: record, created_at: string, created_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "include_deprecated" $include_deprecated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows/integrations" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Workflow Integration
#
# GET /workflows/integrations/{id}
# operationId: getWorkflowIntegration
export def "workflows-integrations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<id: string, type: string, domain_name: string, package_name: string, name: string, description: string, icon_svg: string, tags: list<string>, search_keywords: list<string>, is_deprecated: bool, entitled: bool, application: string, configuration_schema: record, secrets_schema: record, created_at: string, created_by: record<type: string, id: string, summary: string, html_url: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/integrations/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Workflow Integration Connections
#
# GET /workflows/integrations/connections
# operationId: listWorkflowIntegrationConnections
export def "workflows-integrations-connections listWorkflowIntegrationConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --name: string # Filter Integrations by partial name. (e.g. PagerDuty)
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, next_cursor: string, connections: table<id: string, type: string, integration_id: string, name: string, service_url: string, external_id: string, external_id_label: string, scopes: list, is_default: bool, health: record, configuration: record, secrets: record, teams: list, apps: list, created_at: string, created_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows/integrations/connections" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Workflow Integration Connections
#
# GET /workflows/integrations/{integration_id}/connections
# operationId: listWorkflowIntegrationConnectionsByIntegration
export def "workflows-integrations-connections listWorkflowIntegrationConnectionsByIntegration" [
  integration_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The minimum of the `limit` parameter used in the request or the maximum request size of the API.
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --name: string # Filter Integrations by partial name. (e.g. PagerDuty)
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<limit: int, next_cursor: string, connections: table<id: string, type: string, integration_id: string, name: string, service_url: string, external_id: string, external_id_label: string, scopes: list, is_default: bool, health: record, configuration: record, secrets: record, teams: list, apps: list, created_at: string, created_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workflows/integrations/($integration_id)/connections" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workflow Integration Connection
#
# POST /workflows/integrations/{integration_id}/connections
# operationId: createWorkflowIntegrationConnection
# --teams item shape: {team_id?: string, type?: "team_reference"}
# --apps item shape: {app_id?: string, type?: "pd_app_reference"}
export def "workflows-integrations-connections createWorkflowIntegrationConnection" [
  integration_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  name: string # The name given to the connection
  --service-url: string # The URL of the service that this connection is associated with
  --external-id: string # The ID of the external system that this connection is used to connect to
  --external-id-label: string # The label of the external system that this connection is used to connect to
  --scopes: list
  --is-default: string@bool-completer # Whether or not this connection is the default connection for this integration
  --configuration: record # The configuration for this connection. The configuration schema is defined in the Workflow Integration's `configuration_schema` property. It is dynamic based on the specific Workflow Integration.
  secrets: record # The secrets for this connection. The secrets schema is defined in the Workflow Integration's `secrets_schema` property. It is dynamic based on the specific Workflow Integration. This field is write-only and will always be `null` on a response so that secrets are not leaked.
  --teams: list # The teams whose managers are allowed to use or edit this connection — item shape: {team_id?: string, type?: "team_reference"}
  --apps: list # The app IDs for this connection — item shape: {app_id?: string, type?: "pd_app_reference"}
]: any -> record<id: string, type: string, integration_id: string, name: string, service_url: string, external_id: string, external_id_label: string, scopes: list<string>, is_default: bool, health: record<is_healthy: bool, health_message: string, last_checked_at: string>, configuration: record, secrets: record, teams: table<team_id: string, type: string>, apps: table<app_id: string, type: string>, created_at: string, created_by: record<type: string, id: string, summary: string, html_url: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/integrations/($integration_id)/connections")
  let body = {name: $name, service_url: $service_url, external_id: $external_id, external_id_label: $external_id_label, scopes: $scopes, is_default: $is_default, configuration: $configuration, secrets: $secrets, teams: $teams, apps: $apps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Workflow Integration Connection
#
# GET /workflows/integrations/{integration_id}/connections/{id}
# operationId: getWorkflowIntegrationConnection
export def "workflows-integrations-connections get" [
  integration_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> record<id: string, type: string, integration_id: string, name: string, service_url: string, external_id: string, external_id_label: string, scopes: list<string>, is_default: bool, health: record<is_healthy: bool, health_message: string, last_checked_at: string>, configuration: record, secrets: record, teams: table<team_id: string, type: string>, apps: table<app_id: string, type: string>, created_at: string, created_by: record<type: string, id: string, summary: string, html_url: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/integrations/($integration_id)/connections/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Workflow Integration Connection
#
# PATCH /workflows/integrations/{integration_id}/connections/{id}
# operationId: updateWorkflowIntegrationConnection
# --teams item shape: {team_id?: string, type?: "team_reference"}
# --apps item shape: {app_id?: string, type?: "pd_app_reference"}
export def "workflows-integrations-connections updateWorkflowIntegrationConnection" [
  integration_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  name: string # The name given to the connection
  --service-url: string # The URL of the service that this connection is associated with
  --external-id: string # The ID of the external system that this connection is used to connect to
  --external-id-label: string # The label of the external system that this connection is used to connect to
  --scopes: list
  --is-default: string@bool-completer # Whether or not this connection is the default connection for this integration
  --configuration: record # The configuration for this connection. The configuration schema is defined in the Workflow Integration's `configuration_schema` property. It is dynamic based on the specific Workflow Integration.
  secrets: record # The secrets for this connection. The secrets schema is defined in the Workflow Integration's `secrets_schema` property. It is dynamic based on the specific Workflow Integration. This field is write-only and will always be `null` on a response so that secrets are not leaked.
  --teams: list # The teams whose managers are allowed to use or edit this connection — item shape: {team_id?: string, type?: "team_reference"}
  --apps: list # The app IDs for this connection — item shape: {app_id?: string, type?: "pd_app_reference"}
]: any -> record<id: string, type: string, integration_id: string, name: string, service_url: string, external_id: string, external_id_label: string, scopes: list<string>, is_default: bool, health: record<is_healthy: bool, health_message: string, last_checked_at: string>, configuration: record, secrets: record, teams: table<team_id: string, type: string>, apps: table<app_id: string, type: string>, created_at: string, created_by: record<type: string, id: string, summary: string, html_url: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/integrations/($integration_id)/connections/($id)")
  let body = {name: $name, service_url: $service_url, external_id: $external_id, external_id_label: $external_id_label, scopes: $scopes, is_default: $is_default, configuration: $configuration, secrets: $secrets, teams: $teams, apps: $apps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Workflow Integration Connection
#
# DELETE /workflows/integrations/{integration_id}/connections/{id}
# operationId: deleteWorkflowIntegrationConnection
export def "workflows-integrations-connections delete" [
  integration_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/integrations/($integration_id)/connections/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List recommended rules
#
# GET /recommendations/event_orchestrations/rules
# operationId: listRecommendedRules
export def "recommendations-event-orchestrations-rules listRecommendedRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service-id: string # Filter recommended rules for a single service. Cannot be combined with `service_ids[]`.
  --service-ids: list # Filter recommended rules for multiple services. Cannot be combined with `service_id`.
  --team-ids: list # An array of team IDs. Only results related to these teams will be returned. Account must have the `teams` ability to use this parameter.
  --actions: list # Filter recommended rules by action type.
  --limit: int # The number of results per page. (default: 25)
  --cursor: string # Optional parameter used to request the "next" set of results from an API.  The value provided here is most commonly obtained from the `next_cursor` field of the previous request.  When no value is provided, the request starts at the beginning of the result set.
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service_id" $service_id "scalar") (serialize-qp "service_ids[]" $service_ids "multi") (serialize-qp "team_ids[]" $team_ids "multi") (serialize-qp "actions[]" $actions "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recommendations/event_orchestrations/rules" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss a recommended rule
#
# POST /recommendations/event_orchestrations/services/{service_id}/rules/{recommendation_id}/dismiss
# operationId: dismissRecommendedRule
# --decision shape: {feedback: "positive"|"negative"}
export def "recommendations-event-orchestrations-services-rules-dismiss dismissRecommendedRule" [
  service_id: string
  recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
  decision: record # shape: {feedback: "positive"|"negative"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/event_orchestrations/services/($service_id)/rules/($recommendation_id)/dismiss")
  let body = {decision: $decision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accept a recommended rule
#
# POST /recommendations/event_orchestrations/services/{service_id}/rules/{recommendation_id}/accept
# operationId: acceptRecommendedRule
export def "recommendations-event-orchestrations-services-rules-accept acceptRecommendedRule" [
  service_id: string
  recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/event_orchestrations/services/($service_id)/rules/($recommendation_id)/accept")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an accepted rule
#
# DELETE /recommendations/event_orchestrations/services/{service_id}/accepted_rules/{rule_id}
# operationId: deleteAcceptedRecommendedRule
export def "recommendations-event-orchestrations-services-accepted-rules delete" [
  service_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The `Accept` header is used as a versioning header.
  --Content-Type: string@Content-Type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/event_orchestrations/services/($service_id)/accepted_rules/($rule_id)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
