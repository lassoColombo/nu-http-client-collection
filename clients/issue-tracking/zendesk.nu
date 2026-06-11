# Auto-generated client for Support API v2.0.0
# Source: https://developer.zendesk.com/zendesk/oas.yaml
# Auth: --token flag or $env.SUPPORT_API_TOKEN

const BASE_URL = "https://example.zendesk.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUPPORT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://example.zendesk.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "image/jpg" "image/png"] }
def sort-by-completer [] { ["assignee" "assignee.name" "created_at" "deleted_at" "group" "id" "requester" "requester.name" "status" "subject" "updated_at"] }
def sort-order-completer [] { ["asc" "desc"] }
def type-completer [] { ["email" "phone_number"] }
def sort-by-completer-1 [] { ["created_at" "id" "name" "updated_at"] }
def form-type-completer [] { ["all" "service_catalog" "standard"] }
def sort-completer [] { ["-created_at" "-name" "-position" "-updated_at" "created_at" "name" "position" "updated_at"] }
def include-completer [] { ["rule_counts"] }
def filter-completer [] { ["assignable" "requester"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "relationship-fields GetSourcesByTarget" } } | get name | first)
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

# Get sources by target
#
# GET /api/v2/{target_type}/{target_id}/relationship_fields/{field_id}/{source_type}
# operationId: GetSourcesByTarget
export def "relationship-fields GetSourcesByTarget" [
  target_type: string
  target_id: int
  field_id: int
  source_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/($target_type)/($target_id)/relationship_fields/($field_id)/($source_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Settings
#
# GET /api/v2/account/settings
# operationId: ShowAccountSettings
@deprecated --flag authenticity-token
export def "account-settings ShowAccountSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authenticity-token: string # Legacy CSRF token. Ignored by API. (DEPRECATED)
]: nothing -> record<settings: record<active_features: record<agent_forwarding: bool, allow_ccs: bool, allow_email_template_customization: bool, automatic_answers: bool, bcc_archiving: bool, benchmark_opt_out: bool, business_hours: bool, chat: bool, chat_about_my_ticket: bool, csat_reason_code: bool, custom_dkim_domain: bool, customer_context_as_default: bool, customer_satisfaction: bool, customer_satisfaction_survey: bool, dynamic_contents: bool, explore: bool, explore_on_support_ent_plan: bool, explore_on_support_pro_plan: bool, facebook: bool, facebook_login: bool, fallback_composer: bool, forum_analytics: bool, good_data_and_explore: bool, google_login: bool, is_abusive: bool, light_agents: bool, markdown: bool, on_hold_status: bool, organization_access_enabled: bool, rich_content_in_emails: bool, sandbox: bool, satisfaction_prediction: bool, suspended_ticket_notification: bool, ticket_forms: bool, ticket_tagging: bool, topic_suggestion: bool, twitter: bool, twitter_login: bool, user_org_fields: bool, user_tagging: bool, voice: bool>, agents: record<agent_home: bool, agent_workspace: bool, aw_self_serve_migration_enabled: bool, focus_mode: bool, idle_timeout_enabled: bool, unified_agent_statuses: bool>, api: record<accepted_api_agreement: bool, api_password_access_end_users: bool, api_token_access: string>, apps: record<create_private: bool, create_public: bool, use: bool>, billing: record<backend: string>, branding: record<favicon_url: string, header_color: string, header_logo_url: string, page_background_color: string, tab_background_color: string, text_color: string>, brands: record<default_brand_id: int, end_user_across_brand_requests: bool, end_user_upgrade_brand_association_behavior: string, new_agent_brand_association_behavior: string, require_brand_on_new_tickets: bool>, cdn: record<cdn_provider: string, fallback_cdn_provider: string, hosts: list>, chat: record<available: bool, enabled: bool, integrated: bool, maximum_request_count: int, welcome_message: string>, cross_sell: record<show_chat_tooltip: bool, xsell_source: string>, device_metadata: record<enabled: bool, hide_ip: bool, hide_location: bool>, email: record<accept_wildcard_emails: bool, custom_dkim_domain: bool, email_sender_authentication: bool, email_sender_authentication_profile: string, email_status: bool, email_template_photos: bool, email_template_selection: bool, gmail_actions: bool, html_mail_template: string, mail_delimiter: string, modern_email_template: bool, multi_recipient_email_tickets: bool, no_mail_delimiter: bool, personalized_replies: bool, rich_content_in_emails: bool, send_gmail_messages_via_gmail: bool, text_mail_template: string>, google_apps: record<has_google_apps: bool, has_google_apps_admin: bool>, groups: record<check_group_name_uniqueness: bool>, knowledge: record<default_search_filters_brands: string, default_search_filters_categories: string, default_search_filters_external_content_sources: string, default_search_filters_locales: string, default_search_filters_sections: string, generative_answers: bool, require_article_templates: bool, search_articles: bool, search_community_posts: bool, search_external_content: bool>, limits: record<attachment_size: int>, localization: record<locale_ids: list>, lotus: record<pod_id: int, prefer_lotus: bool, reporting: bool>, messaging_inactivity: record<default_localized_messages: record, enabled: bool, end_session: bool, reminders: list, ticket_status_id: int, timeout: int>, metrics: record<account_size: string>, onboarding: record<checklist_onboarding_version: int, onboarding_segments: string, product_sign_up: string>, routing: record<autorouting_tag: string, enabled: bool, max_email_capacity: int, max_messaging_capacity: int, reassignment_messaging_enabled: bool, reassignment_messaging_timeout: int, reassignment_talk_timeout: int>, rule: record<macro_most_used: bool, macro_order: string, skill_based_filtered_views: list, using_skill_based_routing: bool>, side_conversations: record<email_channel: bool, msteams_channel: bool, show_in_context_panel: bool, slack_channel: bool, tickets_channel: bool>, statistics: record<forum: bool, rule_usage: bool, search: bool>, ticket_form: record<raw_ticket_forms_instructions: string, ticket_forms_instructions: string>, tickets: record<accepted_new_collaboration_tos: bool, agent_collision: bool, agent_invitation_enabled: bool, agent_ticket_deletion: bool, allow_group_reset: bool, assign_default_organization: bool, assign_tickets_upon_solve: bool, auto_translation_enabled: bool, auto_updated_ccs_followers_rules: bool, chat_sla_enablement: bool, collaboration: bool, comments_public_by_default: bool, default_solved_ticket_reassignment_strategy: string, default_to_draft_mode: bool, email_attachments: bool, emoji_autocompletion: bool, follower_and_email_cc_collaborations: bool, has_color_text: bool, is_first_comment_private_enabled: bool, light_agent_email_ccs_allowed: bool, list_empty_views: bool, list_newest_comments_first: bool, markdown_ticket_comments: bool, maximum_personal_views_to_list: int, modern_ticket_reassignment: bool, private_attachments: bool, rich_text_comments: bool, show_modern_ticket_reassignment: bool, status_hold: bool, tagging: bool, using_skill_based_routing: bool>, twitter: record<shorten_url: string>, user: record<agent_created_welcome_emails: bool, end_user_phone_number_validation: bool, have_gravatars_enabled: bool, language_selection: bool, multiple_organizations: bool, tagging: bool, time_zone_selection: bool>, voice: record<agent_confirmation_when_forwarding: bool, agent_wrap_up_after_calls: bool, enabled: bool, logging: bool, maximum_queue_size: int, maximum_queue_wait_time: int, only_during_business_hours: bool, outbound_enabled: bool, recordings_public: bool, uk_mobile_forwarding: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authenticity_token" $authenticity_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/account/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account Settings
#
# PUT /api/v2/account/settings
# operationId: UpdateAccountSettings
export def "account-settings UpdateAccountSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<active_features: record<agent_forwarding: bool, allow_ccs: bool, allow_email_template_customization: bool, automatic_answers: bool, bcc_archiving: bool, benchmark_opt_out: bool, business_hours: bool, chat: bool, chat_about_my_ticket: bool, csat_reason_code: bool, custom_dkim_domain: bool, customer_context_as_default: bool, customer_satisfaction: bool, customer_satisfaction_survey: bool, dynamic_contents: bool, explore: bool, explore_on_support_ent_plan: bool, explore_on_support_pro_plan: bool, facebook: bool, facebook_login: bool, fallback_composer: bool, forum_analytics: bool, good_data_and_explore: bool, google_login: bool, is_abusive: bool, light_agents: bool, markdown: bool, on_hold_status: bool, organization_access_enabled: bool, rich_content_in_emails: bool, sandbox: bool, satisfaction_prediction: bool, suspended_ticket_notification: bool, ticket_forms: bool, ticket_tagging: bool, topic_suggestion: bool, twitter: bool, twitter_login: bool, user_org_fields: bool, user_tagging: bool, voice: bool>, agents: record<agent_home: bool, agent_workspace: bool, aw_self_serve_migration_enabled: bool, focus_mode: bool, idle_timeout_enabled: bool, unified_agent_statuses: bool>, api: record<accepted_api_agreement: bool, api_password_access_end_users: bool, api_token_access: string>, apps: record<create_private: bool, create_public: bool, use: bool>, billing: record<backend: string>, branding: record<favicon_url: string, header_color: string, header_logo_url: string, page_background_color: string, tab_background_color: string, text_color: string>, brands: record<default_brand_id: int, end_user_across_brand_requests: bool, end_user_upgrade_brand_association_behavior: string, new_agent_brand_association_behavior: string, require_brand_on_new_tickets: bool>, cdn: record<cdn_provider: string, fallback_cdn_provider: string, hosts: list>, chat: record<available: bool, enabled: bool, integrated: bool, maximum_request_count: int, welcome_message: string>, cross_sell: record<show_chat_tooltip: bool, xsell_source: string>, device_metadata: record<enabled: bool, hide_ip: bool, hide_location: bool>, email: record<accept_wildcard_emails: bool, custom_dkim_domain: bool, email_sender_authentication: bool, email_sender_authentication_profile: string, email_status: bool, email_template_photos: bool, email_template_selection: bool, gmail_actions: bool, html_mail_template: string, mail_delimiter: string, modern_email_template: bool, multi_recipient_email_tickets: bool, no_mail_delimiter: bool, personalized_replies: bool, rich_content_in_emails: bool, send_gmail_messages_via_gmail: bool, text_mail_template: string>, google_apps: record<has_google_apps: bool, has_google_apps_admin: bool>, groups: record<check_group_name_uniqueness: bool>, knowledge: record<default_search_filters_brands: string, default_search_filters_categories: string, default_search_filters_external_content_sources: string, default_search_filters_locales: string, default_search_filters_sections: string, generative_answers: bool, require_article_templates: bool, search_articles: bool, search_community_posts: bool, search_external_content: bool>, limits: record<attachment_size: int>, localization: record<locale_ids: list>, lotus: record<pod_id: int, prefer_lotus: bool, reporting: bool>, messaging_inactivity: record<default_localized_messages: record, enabled: bool, end_session: bool, reminders: list, ticket_status_id: int, timeout: int>, metrics: record<account_size: string>, onboarding: record<checklist_onboarding_version: int, onboarding_segments: string, product_sign_up: string>, routing: record<autorouting_tag: string, enabled: bool, max_email_capacity: int, max_messaging_capacity: int, reassignment_messaging_enabled: bool, reassignment_messaging_timeout: int, reassignment_talk_timeout: int>, rule: record<macro_most_used: bool, macro_order: string, skill_based_filtered_views: list, using_skill_based_routing: bool>, side_conversations: record<email_channel: bool, msteams_channel: bool, show_in_context_panel: bool, slack_channel: bool, tickets_channel: bool>, statistics: record<forum: bool, rule_usage: bool, search: bool>, ticket_form: record<raw_ticket_forms_instructions: string, ticket_forms_instructions: string>, tickets: record<accepted_new_collaboration_tos: bool, agent_collision: bool, agent_invitation_enabled: bool, agent_ticket_deletion: bool, allow_group_reset: bool, assign_default_organization: bool, assign_tickets_upon_solve: bool, auto_translation_enabled: bool, auto_updated_ccs_followers_rules: bool, chat_sla_enablement: bool, collaboration: bool, comments_public_by_default: bool, default_solved_ticket_reassignment_strategy: string, default_to_draft_mode: bool, email_attachments: bool, emoji_autocompletion: bool, follower_and_email_cc_collaborations: bool, has_color_text: bool, is_first_comment_private_enabled: bool, light_agent_email_ccs_allowed: bool, list_empty_views: bool, list_newest_comments_first: bool, markdown_ticket_comments: bool, maximum_personal_views_to_list: int, modern_ticket_reassignment: bool, private_attachments: bool, rich_text_comments: bool, show_modern_ticket_reassignment: bool, status_hold: bool, tagging: bool, using_skill_based_routing: bool>, twitter: record<shorten_url: string>, user: record<agent_created_welcome_emails: bool, end_user_phone_number_validation: bool, have_gravatars_enabled: bool, language_selection: bool, multiple_organizations: bool, tagging: bool, time_zone_selection: bool>, voice: record<agent_confirmation_when_forwarding: bool, agent_wrap_up_after_calls: bool, enabled: bool, logging: bool, maximum_queue_size: int, maximum_queue_wait_time: int, only_during_business_hours: bool, outbound_enabled: bool, recordings_public: bool, uk_mobile_forwarding: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Trial Account
#
# POST /api/v2/accounts
# operationId: CreateTrialAccount
export def "accounts CreateTrialAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<name: string, subdomain: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Subdomain Availability
#
# GET /api/v2/accounts/available
# operationId: VerifySubdomainAvailability
export def "accounts-available VerifySubdomainAvailability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subdomain: string # Specify the name of the subdomain you want to verify. The name can't contain underscores, hyphens, or spaces.  (e.g. z3ndesk)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subdomain" $subdomain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/accounts/available" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Activities
#
# GET /api/v2/activities
# operationId: ListActivities
export def "activities ListActivities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # A UTC time in ISO 8601 format to return ticket activities since said date. (e.g. 2013-04-03T16:02:46Z)
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --include: string # A comma-separated list of sideloads to include. Supported values: `fields_metadata`.  (e.g. fields_metadata)
]: nothing -> record<activities: table<actor: record, actor_id: int, created_at: string, id: int, object: record, target: record, title: string, updated_at: string, url: string, user: record, user_id: int, verb: string>, actors: list<record>, count: int, next_page: string, previous_page: string, users: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Activity
#
# GET /api/v2/activities/{activity_id}
# operationId: ShowActivity
export def "activities ShowActivity" [
  activity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activity: record<actor: record, actor_id: int, created_at: string, id: int, object: record, target: record, title: string, updated_at: string, url: string, user: record, user_id: int, verb: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/activities/($activity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Activities
#
# GET /api/v2/activities/count
# operationId: CountActivities
export def "activities-count CountActivities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/activities/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report Channelback Error to Zendesk
#
# POST /api/v2/any_channel/channelback/report_error
# operationId: ReportChannelbackError
export def "any-channel-channelback-report-error ReportChannelbackError" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/any_channel/channelback/report_error")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push Content to Support
#
# POST /api/v2/any_channel/push
# operationId: PushContentToSupport
export def "any-channel-push PushContentToSupport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: table<external_resource_id: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/any_channel/push")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Token
#
# POST /api/v2/any_channel/validate_token
# operationId: ValidateToken
export def "any-channel-validate-token ValidateToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/any_channel/validate_token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Approval Requests
#
# GET /api/v2/approval_requests
# operationId: ListApprovalRequests
export def "approval-requests ListApprovalRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterstatus: string # Filter by a comma-separated list of one or more approval statuses. Allowed values are active, approved, rejected, withdrawn. Maximum 100 values.
  --filterassignee-user-id: string # Filter by a comma-separated list of assigned user ids. Maximum 100 ids.
  --filterassignee-group-id: string # Filter by a comma-separated list of assigned group ids. Maximum 100 ids.
  --before-cursor: string # Cursor for pagination. Fetch records before this cursor
  --after-cursor: string # Cursor for pagination. Fetch records after this cursor
]: nothing -> record<approval_requests: table<assignee_group: record, assignee_user: record, clarification_flow_messages: list, created_at: string, created_by_user: record, decided_at: string, decisions: list, id: string, message: string, origination_type: string, status: string, subject: string, ticket_id: int, withdrawn_reason: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[status]" $filterstatus "scalar") (serialize-qp "filter[assignee_user_id]" $filterassignee_user_id "scalar") (serialize-qp "filter[assignee_group_id]" $filterassignee_group_id "scalar") (serialize-qp "before_cursor" $before_cursor "scalar") (serialize-qp "after_cursor" $after_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/approval_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Approval Request
#
# POST /api/v2/approval_requests
# operationId: CreateApprovalRequest
export def "approval-requests CreateApprovalRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assignee-group-id: int # The id of the group assigned to review and approve the request (nullable, format: int64, e.g. 789)
  --assignee-user-id: int # The id of the user assigned to review and approve the request (nullable, format: int64, e.g. 456)
  message: string # Details and context for the approval request (e.g. Please approve this request for a new laptop for the engineering team)
  subject: string # Subject line for the approval request (e.g. Laptop Purchase Approval)
  ticket_id: int # The id of the ticket the approval request was added to (format: int64, e.g. 123)
]: any -> record<approval_request: record<assignee_group_id: int, assignee_user_id: int, created_at: string, created_by_id: int, id: string, message: string, origination_type: string, status: string, subject: string, ticket_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/approval_requests")
  let body = {assignee_group_id: $assignee_group_id, assignee_user_id: $assignee_user_id, message: $message, subject: $subject, ticket_id: $ticket_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Attachment
#
# GET /api/v2/attachments/{attachment_id}
# operationId: ShowAttachment
export def "attachments ShowAttachment" [
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attachment: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Attachment for Malware
#
# PUT /api/v2/attachments/{attachment_id}
# operationId: UpdateAttachment
# --attachment shape: {malware_access_override?: bool}
export def "attachments UpdateAttachment" [
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attachment: record # shape: {malware_access_override?: bool}
]: any -> record<attachment: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/attachments/($attachment_id)")
  let body = {attachment: $attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Attachment
#
# DELETE /api/v2/attachments/{attachment_id}
# operationId: DeleteAttachment
export def "attachments DeleteAttachment" [
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Audit Logs
#
# GET /api/v2/audit_logs
# operationId: ListAuditLogs
export def "audit-logs ListAuditLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filtersource-type: string # Filter audit logs by the source type. For example, user or rule
  --filtersource-id: int # Filter audit logs by the source id. Requires `filter[source_type]` to also be set (format: int64)
  --filteractor-id: int # Filter audit logs by the actor id (format: int64)
  --filterip-address: string # Filter audit logs by the ip address
  --filtercreated-at: string # Filter audit logs by the time of creation. When used, you must specify `filter[created_at]` twice in your request, first with the start time and again with an end time
  --filteraction: string # Filter audit logs by the action
  --sort-by: string # Offset pagination only. Sort audit logs. Default is `sort_by=created_at`
  --sort-order: string # Offset pagination only. Sort audit logs. Default is `sort_order=desc`
  --qp-sort: string # Cursor pagination only. Sort audit logs. Default is `sort=-created_at`
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<audit_logs: table<action: string, action_label: string, actor_id: int, actor_name: string, change_description: string, created_at: string, id: int, ip_address: string, source_id: int, source_label: string, source_type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[source_type]" $filtersource_type "scalar") (serialize-qp "filter[source_id]" $filtersource_id "scalar") (serialize-qp "filter[actor_id]" $filteractor_id "scalar") (serialize-qp "filter[ip_address]" $filterip_address "scalar") (serialize-qp "filter[created_at]" $filtercreated_at "scalar") (serialize-qp "filter[action]" $filteraction "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/audit_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Audit Log
#
# GET /api/v2/audit_logs/{audit_log_id}
# operationId: ShowAuditLog
export def "audit-logs ShowAuditLog" [
  audit_log_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audit_log: record<action: string, action_label: string, actor_id: int, actor_name: string, change_description: string, created_at: string, id: int, ip_address: string, source_id: int, source_label: string, source_type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/audit_logs/($audit_log_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Audit Logs
#
# POST /api/v2/audit_logs/export
# operationId: ExportAuditLogs
export def "audit-logs-export ExportAuditLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filtersource-type: string # Filter audit logs by the source type. For example, user or rule
  --filtersource-id: int # Filter audit logs by the source id. Requires `filter[source_type]` to also be set. (format: int64)
  --filteractor-id: int # Filter audit logs by the actor id (format: int64)
  --filterip-address: string # Filter audit logs by the ip address
  --filtercreated-at: string # Filter audit logs by the time of creation. When used, you must specify `filter[created_at]` twice in your request, first with the start time and again with an end time
  --filteraction: string # Filter audit logs by the action
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[source_type]" $filtersource_type "scalar") (serialize-qp "filter[source_id]" $filtersource_id "scalar") (serialize-qp "filter[actor_id]" $filteractor_id "scalar") (serialize-qp "filter[ip_address]" $filterip_address "scalar") (serialize-qp "filter[created_at]" $filtercreated_at "scalar") (serialize-qp "filter[action]" $filteraction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/audit_logs/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Tags
#
# GET /api/v2/autocomplete/tags
# operationId: AutocompleteTags
export def "autocomplete-tags AutocompleteTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A substring of a tag to search for (e.g. att)
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/autocomplete/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Tags by Request Body
#
# POST /api/v2/autocomplete/tags
# operationId: AutocompleteTagsPost
export def "autocomplete-tags AutocompleteTagsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --name: string # A substring of a tag to search for
]: any -> record<tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/autocomplete/tags" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Automations
#
# GET /api/v2/automations
# operationId: ListAutomations
export def "automations ListAutomations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --active: string@bool-completer # Filter by active automations if true or inactive automations if false (e.g. true)
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_24h)
]: nothing -> record<automations: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>, count: int, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/automations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Automation
#
# POST /api/v2/automations
# operationId: CreateAutomation
export def "automations CreateAutomation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<automation: record<actions: list<record>, active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/automations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Automation
#
# GET /api/v2/automations/{automation_id}
# operationId: ShowAutomation
export def "automations ShowAutomation" [
  automation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<automation: record<actions: list<record>, active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/automations/($automation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Automation
#
# PUT /api/v2/automations/{automation_id}
# operationId: UpdateAutomation
export def "automations UpdateAutomation" [
  automation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<automation: record<actions: list<record>, active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/automations/($automation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Automation
#
# DELETE /api/v2/automations/{automation_id}
# operationId: DeleteAutomation
export def "automations DeleteAutomation" [
  automation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/automations/($automation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Active Automations
#
# GET /api/v2/automations/active
# operationId: ListActiveAutomations
export def "automations-active ListActiveAutomations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<automations: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>, count: int, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/automations/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Automations
#
# DELETE /api/v2/automations/destroy_many
# operationId: BulkDeleteAutomations
export def "automations-destroy-many BulkDeleteAutomations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The IDs of the automations to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/automations/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Automations
#
# GET /api/v2/automations/search
# operationId: SearchAutomations
export def "automations-search SearchAutomations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Query string used to find all automations with matching title (e.g. close)
  --active: string@bool-completer # Filter by active automations if true or inactive automations if false (e.g. true)
  --sort-by: string # Possible values are "alphabetical", "created_at", "updated_at", and "position". If unspecified, the automations are sorted by relevance (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_24h)
]: nothing -> record<automations: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>, count: int, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/automations/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Automations
#
# PUT /api/v2/automations/update_many
# operationId: UpdateManyAutomations
export def "automations-update-many UpdateManyAutomations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<automations: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, id: int, position: int, raw_title: string, title: string, updated_at: string>, count: int, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/automations/update_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Bookmarks
#
# GET /api/v2/bookmarks
# operationId: ListBookmarks
export def "bookmarks ListBookmarks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/bookmarks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Bookmark
#
# POST /api/v2/bookmarks
# operationId: CreateBookmark
# --bookmark shape: {ticket_id?: int}
export def "bookmarks CreateBookmark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark: record # shape: {ticket_id?: int}
]: any -> record<bookmark: record<created_at: string, id: int, ticket: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/bookmarks")
  let body = {bookmark: $bookmark} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Bookmark
#
# DELETE /api/v2/bookmarks/{bookmark_id}
# operationId: DeleteBookmark
export def "bookmarks DeleteBookmark" [
  bookmark_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/bookmarks/($bookmark_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Brand Agent Memberships
#
# GET /api/v2/brand_agents
# operationId: ListBrandAgents
export def "brand-agents ListBrandAgents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<brand_agents: table<brand_id: int, created_at: string, id: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/brand_agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Brand Agent Membership
#
# GET /api/v2/brand_agents/{brand_agent_id}
# operationId: ShowBrandAgentById
export def "brand-agents ShowBrandAgentById" [
  brand_agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<brand_agent: record<brand_id: int, created_at: string, id: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brand_agents/($brand_agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Brand Agent Membership
#
# DELETE /api/v2/brand_agents/{brand_agent_id}
# operationId: DeleteBrandAgentById
export def "brand-agents DeleteBrandAgentById" [
  brand_agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brand_agents/($brand_agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Brands
#
# GET /api/v2/brands
# operationId: ListBrands
export def "brands ListBrands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Cursor pagination parameters using deepObject format.  Use `?page[size]=50&page[after]=cursor` to paginate through results.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (Marked internal-only because only used with traditional offset pagination, which is only supported for internal/bime requests)  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --assignable-from: int # Filters brands to only those assignable from the specified brand ID. A brand-separated brand is only assignable to itself, while account-separated brands are assignable to all other account-separated brands. (format: int64)
  --include-deleted: string@bool-completer # When true, includes soft-deleted brands in the response.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "assignable_from" $assignable_from "scalar") (serialize-qp "include_deleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/brands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Brand
#
# POST /api/v2/brands
# operationId: CreateBrand
# --brand shape: {active?: bool, brand_url?: string, default?: bool, has_help_center?: bool, host_mapping?: string, is_deleted?: bool, logo?: record, name: string, signature_template?: string, subdomain: string, user_separation?: "account"|"brand"}
export def "brands CreateBrand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand: record # e.g. {active: true, brand_url: https://brand1.com, created_at: 2012-04-02T22:55:29Z, default: true, has_help_center: true, help_center_state: enabled, host_mapping: brand1.com, id: 47, logo: {content_type: image/png, content_url: https://company.zendesk.com/logos/brand1_logo.png, file_name: brand1_logo.png, id: 928374, size: 166144, thumbnails: [{content_type: image/png, content_url: https://company.zendesk.com/photos/brand1_logo_thumb.png, file_name: brand1_logo_thumb.png, id: 928375, mapped_content_url: https://company.com/photos/brand1_logo_thumb.png, size: 58298, url: https://company.zendesk.com/api/v2/attachments/928375}, {content_type: image/png, content_url: https://company.zendesk.com/photos/brand1_logo_small.png, file_name: brand1_logo_small.png, id: 928376, mapped_content_url: https://company.com/photos/brand1_logo_small.png, size: 58298, url: https://company.zendesk.com/api/v2/attachments/928376}], url: https://company.zendesk.com/api/v2/attachments/928374}, name: Brand 1, signature_template: {{agent.signature}}, subdomain: brand1, ticket_form_ids: [47, 33, 22], updated_at: 2012-04-02T22:55:29Z, url: https://company.zendesk.com/api/v2/brands/47} — shape: {active?: bool, brand_url?: string, default?: bool, has_help_center?: bool, host_mapping?: string, is_deleted?: bool, logo?: record, name: string, signature_template?: string, subdomain: string, user_separation?: "account"|"brand"}
]: any -> record<brand: record<active: bool, brand_url: string, created_at: string, default: bool, has_help_center: bool, help_center_state: string, host_mapping: string, id: int, is_deleted: bool, logo: record, name: string, signature_template: string, subdomain: string, ticket_form_ids: list<int>, updated_at: string, url: string, user_separation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/brands")
  let body = {brand: $brand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show a Brand
#
# GET /api/v2/brands/{brand_id}
# operationId: ShowBrand
export def "brands ShowBrand" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<brand: record<active: bool, brand_url: string, created_at: string, default: bool, has_help_center: bool, help_center_state: string, host_mapping: string, id: int, is_deleted: bool, logo: record, name: string, signature_template: string, subdomain: string, ticket_form_ids: list<int>, updated_at: string, url: string, user_separation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Brand
#
# PUT /api/v2/brands/{brand_id}
# operationId: UpdateBrand
# --brand shape: {active?: bool, brand_url?: string, default?: bool, has_help_center?: bool, host_mapping?: string, is_deleted?: bool, logo?: record, name: string, signature_template?: string, subdomain: string, user_separation?: "account"|"brand"}
export def "brands UpdateBrand" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --brand: record # e.g. {active: true, brand_url: https://brand1.com, created_at: 2012-04-02T22:55:29Z, default: true, has_help_center: true, help_center_state: enabled, host_mapping: brand1.com, id: 47, logo: {content_type: image/png, content_url: https://company.zendesk.com/logos/brand1_logo.png, file_name: brand1_logo.png, id: 928374, size: 166144, thumbnails: [{content_type: image/png, content_url: https://company.zendesk.com/photos/brand1_logo_thumb.png, file_name: brand1_logo_thumb.png, id: 928375, mapped_content_url: https://company.com/photos/brand1_logo_thumb.png, size: 58298, url: https://company.zendesk.com/api/v2/attachments/928375}, {content_type: image/png, content_url: https://company.zendesk.com/photos/brand1_logo_small.png, file_name: brand1_logo_small.png, id: 928376, mapped_content_url: https://company.com/photos/brand1_logo_small.png, size: 58298, url: https://company.zendesk.com/api/v2/attachments/928376}], url: https://company.zendesk.com/api/v2/attachments/928374}, name: Brand 1, signature_template: {{agent.signature}}, subdomain: brand1, ticket_form_ids: [47, 33, 22], updated_at: 2012-04-02T22:55:29Z, url: https://company.zendesk.com/api/v2/brands/47} — shape: {active?: bool, brand_url?: string, default?: bool, has_help_center?: bool, host_mapping?: string, is_deleted?: bool, logo?: record, name: string, signature_template?: string, subdomain: string, user_separation?: "account"|"brand"}
]: any -> record<brand: record<active: bool, brand_url: string, created_at: string, default: bool, has_help_center: bool, help_center_state: string, host_mapping: string, id: int, is_deleted: bool, logo: record, name: string, signature_template: string, subdomain: string, ticket_form_ids: list<int>, updated_at: string, url: string, user_separation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)")
  let body = {brand: $brand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Brand
#
# DELETE /api/v2/brands/{brand_id}
# operationId: DeleteBrand
export def "brands DeleteBrand" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Agents By Brand
#
# GET /api/v2/brands/{brand_id}/agents
# operationId: ListBrandAgentsByBrand
export def "brands-agents ListBrandAgentsByBrand" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<brand_agents: table<brand_id: int, created_at: string, id: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)/agents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Host Mapping Validity for an Existing Brand
#
# GET /api/v2/brands/{brand_id}/check_host_mapping
# operationId: CheckHostMappingValidityForExistingBrand
export def "brands-check-host-mapping CheckHostMappingValidityForExistingBrand" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cname: string, expected_cnames: list<string>, is_valid: bool, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)/check_host_mapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Brand Logo
#
# PUT /api/v2/brands/{brand_id}/logo
# operationId: UpdateBrandLogo
export def "brands-logo UpdateBrandLogo" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  brandlogouploaded_data: string # Brand logo image file (format: binary)
]: any -> record<brand: record<active: bool, brand_url: string, created_at: string, default: bool, has_help_center: bool, help_center_state: string, host_mapping: string, id: int, is_deleted: bool, logo: record, name: string, signature_template: string, subdomain: string, ticket_form_ids: list<int>, updated_at: string, url: string, user_separation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)/logo")
  let body = {brand[logo][uploaded_data]: $brandlogouploaded_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a Brand Logo
#
# DELETE /api/v2/brands/{brand_id}/logo
# operationId: DeleteBrandLogo
export def "brands-logo DeleteBrandLogo" [
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/brands/($brand_id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Host Mapping Validity
#
# GET /api/v2/brands/check_host_mapping
# operationId: CheckHostMappingValidity
export def "brands-check-host-mapping CheckHostMappingValidity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --host-mapping: string # The hostmapping to a brand, if any (only admins view this key) (e.g. brand1.com)
  --subdomain: string # Subdomain for a given Zendesk account address (e.g. Brand1)
]: nothing -> record<cname: string, expected_cnames: list<string>, is_valid: bool, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_mapping" $host_mapping "scalar") (serialize-qp "subdomain" $subdomain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/brands/check_host_mapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Monitored X Handles
#
# GET /api/v2/channels/twitter/monitored_twitter_handles
# operationId: ListMonitoredTwitterHandles
export def "channels-twitter-monitored-twitter-handles ListMonitoredTwitterHandles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<monitored_twitter_handles: table<allow_reply: bool, avatar_url: string, brand_id: int, can_reply: bool, created_at: string, id: int, name: string, screen_name: string, twitter_user_id: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/channels/twitter/monitored_twitter_handles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Monitored X Handle
#
# GET /api/v2/channels/twitter/monitored_twitter_handles/{monitored_twitter_handle_id}
# operationId: ShowMonitoredTwitterHandle
export def "channels-twitter-monitored-twitter-handles ShowMonitoredTwitterHandle" [
  monitored_twitter_handle_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<monitored_twitter_handle: record<allow_reply: bool, avatar_url: string, brand_id: int, can_reply: bool, created_at: string, id: int, name: string, screen_name: string, twitter_user_id: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/channels/twitter/monitored_twitter_handles/($monitored_twitter_handle_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket from Tweet
#
# POST /api/v2/channels/twitter/tickets
# operationId: CreateTicketFromTweet
export def "channels-twitter-tickets CreateTicketFromTweet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/channels/twitter/tickets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket statuses
#
# GET /api/v2/channels/twitter/tickets/{comment_id}/statuses
# operationId: GettingTwicketStatus
export def "channels-twitter-tickets-statuses GettingTwicketStatus" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Optional comment ids to retrieve tweet information for only particular comments (e.g. 1,3,5)
]: nothing -> record<statuses: table<favorited: bool, id: int, retweeted: bool, user_followed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/channels/twitter/tickets/($comment_id)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Open Ticket in Agent's Browser
#
# POST /api/v2/channels/voice/agents/{agent_id}/tickets/{ticket_id}/display
# operationId: OpenTicketInAgentBrowser
export def "channels-voice-agents-tickets-display OpenTicketInAgentBrowser" [
  agent_id: int
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/channels/voice/agents/($agent_id)/tickets/($ticket_id)/display")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Open a User's Profile in an Agent's Browser
#
# POST /api/v2/channels/voice/agents/{agent_id}/users/{user_id}/display
# operationId: OpenUsersProfileInAgentBrowser
export def "channels-voice-agents-users-display OpenUsersProfileInAgentBrowser" [
  agent_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/channels/voice/agents/($agent_id)/users/($user_id)/display")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket or Voicemail Ticket
#
# POST /api/v2/channels/voice/tickets
# operationId: CreateTicketOrVoicemailTicket
export def "channels-voice-tickets CreateTicketOrVoicemailTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-to-agent: int # Optional value such as the ID of the agent that will see the newly created ticket.
  --ticket: record # Ticket object that lists the values to set when the ticket is created
]: any -> record<ticket: record<additional_collaborators: list<record>, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list<int>, brand_id: int, collaborator_ids: list<int>, collaborators: list<record>, comment: record<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, email_ccs: list<record>, encoded_id: string, external_id: string, fields: list<record>, follower_ids: list<int>, followers: list<record>, followup_ids: list<int>, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list<int>, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list<int>, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record<client: string, ip_address: string>, tags: any, tde_workspace: record<previous_workspace: record, type: string, workspace: record>, ticket_form_id: int, tpe_voice_comment: record<agent_id: int, answering_machine_detection_status: string, app_id: int, app_name: string, author_id: int, call_connected_at: string, call_disposition: string, call_ended_at: string, call_id: int, call_recording_consent: string, call_recording_consent_action: string, call_recording_consent_keypress: string, call_started_at: string, call_type: string, callback_number: string, callback_requested_at: string, completion_status: string, connection_attempts: int, consultation_time: int, direction: string, disconnection_reason: string, dnis: string, duration: int, end_user_id: int, end_user_location: string, exceeded_queue_time: bool, extension: string, external_id: string, from_line: string, from_line_nickname: string, hold_time: int, intent: string, ivr_destination_group_name: string, ivr_time_spent: int, language: string, line_type: string, longest_hold_time: int, number_of_holds: int, outside_business_hours: bool, overflowed_to: string, phone_name: string, public: bool, quality_score: int, queue_name: string, queue_time: int, recorded: bool, recording_time: int, recording_type: string, recording_url: string, sentiment_agent: string, sentiment_call: string, sentiment_customer: string, sentiment_trend: string, short_summary: string, summary: string, talk_time: int, time_to_answer: int, title: string, to_line: string, to_line_nickname: string, transcript: string, via_id: int, video_recording_url: string, voicemail: bool, voicemail_requested_at: string, wait_time: int>, type: string, updated_at: string, updated_stamp: string, url: string, via: record<channel: any, source: record>, via_followup_source_id: int, via_id: int, voice_comment: record<answered_by_id: int, call_duration: int, from: string, location: string, recording_url: string, to: string, transcription_text: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/channels/voice/tickets")
  let body = {display_to_agent: $display_to_agent, ticket: $ticket} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redact Chat Comment Attachment
#
# PUT /api/v2/chat_file_redactions/{ticket_id}
# operationId: RedactChatCommentAttachment
export def "chat-file-redactions RedactChatCommentAttachment" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<chat_event: record<id: int, type: string, value: record<chat_id: string, history: list, visitor_id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/chat_file_redactions/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact Chat Comment
#
# PUT /api/v2/chat_redactions/{ticket_id}
# operationId: RedactChatComment
export def "chat-redactions RedactChatComment" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<chat_event: record<id: int, type: string, value: record<chat_id: string, history: list, visitor_id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/chat_redactions/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact Ticket Comment In Agent Workspace
#
# PUT /api/v2/comment_redactions/{ticket_comment_id}
# operationId: RedactTicketCommentInAgentWorkspace
export def "comment-redactions RedactTicketCommentInAgentWorkspace" [
  ticket_comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: record<add_short_url: bool, attachments: list<record>, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list<string>, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/comment_redactions/($ticket_comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Objects
#
# GET /api/v2/custom_objects
# operationId: ListCustomObjects
export def "custom-objects ListCustomObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-ui-path: string@bool-completer # Include UI path in the response
]: nothing -> record<custom_objects: table<allows_attachments: bool, allows_photos: bool, created_at: string, created_by_user_id: string, description: string, include_in_list_view: bool, key: string, raw_description: string, raw_title: string, raw_title_pluralized: string, title: string, title_pluralized: string, updated_at: string, updated_by_user_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_ui_path" $include_ui_path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/custom_objects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Object
#
# POST /api/v2/custom_objects
# operationId: CreateCustomObject
# --custom_object shape: {allows_attachments?: bool, allows_photos?: bool, description?: string, include_in_list_view?: bool, key?: string, title?: string, title_pluralized?: string}
export def "custom-objects CreateCustomObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-object: record # shape: {allows_attachments?: bool, allows_photos?: bool, description?: string, include_in_list_view?: bool, key?: string, title?: string, title_pluralized?: string}
]: any -> record<custom_object: record<allows_attachments: bool, allows_photos: bool, created_at: string, created_by_user_id: string, description: string, include_in_list_view: bool, key: string, raw_description: string, raw_title: string, raw_title_pluralized: string, title: string, title_pluralized: string, updated_at: string, updated_by_user_id: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_objects")
  let body = {custom_object: $custom_object} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Custom Object
#
# GET /api/v2/custom_objects/{custom_object_key}
# operationId: ShowCustomObject
export def "custom-objects ShowCustomObject" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-permissions-metadata: string@bool-completer # Include permission metadata in the response
  --include-ui-path: string@bool-completer # Include UI path in the response
]: nothing -> record<custom_object: record<allows_attachments: bool, allows_photos: bool, created_at: string, created_by_user_id: string, description: string, include_in_list_view: bool, key: string, raw_description: string, raw_title: string, raw_title_pluralized: string, title: string, title_pluralized: string, updated_at: string, updated_by_user_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_permissions_metadata" $include_permissions_metadata "scalar") (serialize-qp "include_ui_path" $include_ui_path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Object
#
# PATCH /api/v2/custom_objects/{custom_object_key}
# operationId: UpdateCustomObject
export def "custom-objects UpdateCustomObject" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_object: record<allows_attachments: bool, allows_photos: bool, created_at: string, created_by_user_id: string, description: string, include_in_list_view: bool, key: string, raw_description: string, raw_title: string, raw_title_pluralized: string, title: string, title_pluralized: string, updated_at: string, updated_by_user_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Custom Object
#
# DELETE /api/v2/custom_objects/{custom_object_key}
# operationId: DeleteCustomObject
export def "custom-objects DeleteCustomObject" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Access Rules
#
# GET /api/v2/custom_objects/{custom_object_key}/access_rules
# operationId: ListAccessRules
export def "custom-objects-access-rules ListAccessRules" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<access_rules: table<conditions: record, created_at: string, description: string, id: int, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/access_rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Access Rule
#
# POST /api/v2/custom_objects/{custom_object_key}/access_rules
# operationId: CreateAccessRule
# --access_rule shape: {conditions?: record, description?: string, title?: string}
export def "custom-objects-access-rules CreateAccessRule" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-rule: record # shape: {conditions?: record, description?: string, title?: string}
]: any -> record<access_rule: record<conditions: record<all: list, any: list>, created_at: string, description: string, id: int, title: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/access_rules")
  let body = {access_rule: $access_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Access Rule
#
# GET /api/v2/custom_objects/{custom_object_key}/access_rules/{id}
# operationId: ShowAccessRule
export def "custom-objects-access-rules ShowAccessRule" [
  custom_object_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<access_rule: record<conditions: record<all: list, any: list>, created_at: string, description: string, id: int, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/access_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Access Rule
#
# PATCH /api/v2/custom_objects/{custom_object_key}/access_rules/{id}
# operationId: UpdateAccessRule
# --access_rule shape: {conditions?: record, description?: string, title?: string}
export def "custom-objects-access-rules UpdateAccessRule" [
  custom_object_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-rule: record # shape: {conditions?: record, description?: string, title?: string}
]: any -> record<access_rule: record<conditions: record<all: list, any: list>, created_at: string, description: string, id: int, title: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/access_rules/($id)")
  let body = {access_rule: $access_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Access Rule
#
# DELETE /api/v2/custom_objects/{custom_object_key}/access_rules/{id}
# operationId: DeleteAccessRule
export def "custom-objects-access-rules DeleteAccessRule" [
  custom_object_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/access_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Access Rule Definitions
#
# GET /api/v2/custom_objects/{custom_object_key}/access_rules/definitions
# operationId: ListAccessRuleDefinitions
export def "custom-objects-access-rules-definitions ListAccessRuleDefinitions" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<conditions_all: list<record>, conditions_any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/access_rules/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Object Fields
#
# GET /api/v2/custom_objects/{custom_object_key}/fields
# operationId: ListCustomObjectFields
export def "custom-objects-fields ListCustomObjectFields" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-standard-fields: string@bool-completer # Include standard fields if true. Exclude them if false (e.g. true)
]: nothing -> record<custom_object_fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_standard_fields" $include_standard_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Object Field
#
# POST /api/v2/custom_objects/{custom_object_key}/fields
# operationId: CreateCustomObjectField
# --custom_object_field shape: {active?: bool, custom_field_options?: list, description?: string, key: string, position?: int, raw_description?: string, raw_title?: string, regexp_for_validation?: string, relationship_filter?: record, tag?: string, title: string, type: string, properties?: record, relationship_target_type?: string, required?: bool}
export def "custom-objects-fields CreateCustomObjectField" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-object-field: record # e.g. {active: true, created_at: 2022-09-07T23:21:59Z, description: Make, id: 4398096842879, key: make, position: 0, properties: {autoincrement_enabled: true, autoincrement_next_sequence: 1, autoincrement_padding: 5, autoincrement_prefix: Order # , is_unique: false}, raw_description: Make, raw_title: Make, regexp_for_validation: , required: false, system: false, title: Make, type: text, updated_at: 2022-09-07T23:22:00Z, url: https://company.zendesk.com/api/v2/custom_objects/car/fields/4398096842879} — shape: {active?: bool, custom_field_options?: list, description?: string, key: string, position?: int, raw_description?: string, raw_title?: string, regexp_for_validation?: string, relationship_filter?: record, tag?: string, title: string, type: string, properties?: record, relationship_target_type?: string, required?: bool}
]: any -> record<custom_object_field: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/fields")
  let body = {custom_object_field: $custom_object_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Custom Object Field
#
# GET /api/v2/custom_objects/{custom_object_key}/fields/{custom_object_field_key_or_id}
# operationId: ShowCustomObjectField
export def "custom-objects-fields ShowCustomObjectField" [
  custom_object_key: string
  custom_object_field_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-standard-fields: string@bool-completer # If true, returns standard fields in addition to custom fields.
]: nothing -> record<custom_object_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_standard_fields" $include_standard_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/fields/($custom_object_field_key_or_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Object Field
#
# PATCH /api/v2/custom_objects/{custom_object_key}/fields/{custom_object_field_key_or_id}
# operationId: UpdateCustomObjectField
export def "custom-objects-fields UpdateCustomObjectField" [
  custom_object_key: string
  custom_object_field_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_object_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/fields/($custom_object_field_key_or_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Custom Object Field
#
# DELETE /api/v2/custom_objects/{custom_object_key}/fields/{custom_object_field_key_or_id}
# operationId: DeleteCustomObjectField
export def "custom-objects-fields DeleteCustomObjectField" [
  custom_object_key: string
  custom_object_field_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/fields/($custom_object_field_key_or_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Custom Fields of an Object
#
# PUT /api/v2/custom_objects/{custom_object_key}/fields/reorder
# operationId: ReorderCustomObjectFields
export def "custom-objects-fields-reorder ReorderCustomObjectFields" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/fields/reorder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Custom Object Record Bulk Jobs
#
# POST /api/v2/custom_objects/{custom_object_key}/jobs
# operationId: CustomObjectRecordBulkJobs
# --job shape: {action?: string, items?: list}
export def "custom-objects-jobs CustomObjectRecordBulkJobs" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --job: record # shape: {action?: string, items?: list}
]: any -> record<job_status: record<id: string, message: string, progress: int, results: list<record>, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/jobs")
  let body = {job: $job} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Custom Object Fields Limit
#
# GET /api/v2/custom_objects/{custom_object_key}/limits/field_limit
# operationId: CustomObjectFieldsLimit
export def "custom-objects-limits-field-limit CustomObjectFieldsLimit" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/limits/field_limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Permission Policies
#
# GET /api/v2/custom_objects/{custom_object_key}/permission_policies
# operationId: ListPermissionPolicies
export def "custom-objects-permission-policies ListPermissionPolicies" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<policies: table<id: string, records: record, role_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/permission_policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Permission Policy
#
# GET /api/v2/custom_objects/{custom_object_key}/permission_policies/{id}
# operationId: ShowPermissionPolicy
export def "custom-objects-permission-policies ShowPermissionPolicy" [
  custom_object_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<policy: record<id: string, records: record<create: record, delete: record, read: record, update: record>, role_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/permission_policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Permission Policy
#
# PATCH /api/v2/custom_objects/{custom_object_key}/permission_policies/{id}
# operationId: UpdatePermissionPolicy
# --policy shape: {records?: record}
export def "custom-objects-permission-policies UpdatePermissionPolicy" [
  custom_object_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policy: record # shape: {records?: record}
]: any -> record<policy: record<id: string, records: record<create: record, delete: record, read: record, update: record>, role_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/permission_policies/($id)")
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Custom Object Records
#
# GET /api/v2/custom_objects/{custom_object_key}/records
# operationId: ListCustomObjectRecords
export def "custom-objects-records ListCustomObjectRecords" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterids: string # Optional comma-separated list of ids to filter records by. If one or more ids are specified, only matching records are returned. The ids must be unique and are case sensitive.
  --filterexternal-ids: string # Optional comma-separated list of external ids to filter records by. If one or more ids are specified, only matching records are returned. The ids must be unique and are case sensitive.
  --qp-sort: string # One of `id`, `updated_at`, `-id`, or `-updated_at`. The `-` denotes the sort will be descending.
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pagesize: int # Specifies how many records should be returned in the response. You can specify up to 100 records per page.
]: nothing -> record<count: int, custom_object_records: table<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[ids]" $filterids "scalar") (serialize-qp "filter[external_ids]" $filterexternal_ids "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Object Record
#
# POST /api/v2/custom_objects/{custom_object_key}/records
# operationId: CreateCustomObjectRecord
# --custom_object_record shape: {custom_object_fields?: record, external_id?: string, photo?: record}
export def "custom-objects-records CreateCustomObjectRecord" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-object-record: record # shape: {custom_object_fields?: record, external_id?: string, photo?: record}
]: any -> record<custom_object_record: record<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records")
  let body = {custom_object_record: $custom_object_record} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or Update Custom Object Record
#
# PATCH /api/v2/custom_objects/{custom_object_key}/records
# operationId: UpsertCustomObjectRecordByExternalIdOrName
# --custom_object_record shape: {custom_object_fields?: record, external_id?: string, photo?: record}
export def "custom-objects-records UpsertCustomObjectRecordByExternalIdOrName" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-id: string # The external id of a custom object record (e.g. X90001)
  --name: string # The name of a custom object record (e.g. boat)
  --custom-object-record: record # shape: {custom_object_fields?: record, external_id?: string, photo?: record}
]: any -> record<custom_object_record: record<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_id" $external_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records" $qp)
  let body = {custom_object_record: $custom_object_record} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Object Record by External Id Or Name
#
# DELETE /api/v2/custom_objects/{custom_object_key}/records
# operationId: DeleteCustomObjectRecordByExternalIdOrName
export def "custom-objects-records DeleteCustomObjectRecordByExternalIdOrName" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-id: string # The external id of a custom object record (e.g. X90001)
  --name: string # The name of a custom object record (e.g. boat)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_id" $external_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Custom Object Record
#
# GET /api/v2/custom_objects/{custom_object_key}/records/{custom_object_record_id}
# operationId: ShowCustomObjectRecord
export def "custom-objects-records ShowCustomObjectRecord" [
  custom_object_key: string
  custom_object_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_object_record: record<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($custom_object_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Object Record
#
# PATCH /api/v2/custom_objects/{custom_object_key}/records/{custom_object_record_id}
# operationId: UpdateCustomObjectRecord
export def "custom-objects-records UpdateCustomObjectRecord" [
  custom_object_key: string
  custom_object_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_object_record: record<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($custom_object_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Custom Object Record
#
# DELETE /api/v2/custom_objects/{custom_object_key}/records/{custom_object_record_id}
# operationId: DeleteCustomObjectRecord
export def "custom-objects-records DeleteCustomObjectRecord" [
  custom_object_key: string
  custom_object_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($custom_object_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Object Record Attachments
#
# GET /api/v2/custom_objects/{custom_object_key}/records/{record_id}/attachments
# operationId: ListCustomObjectRecordAttachments
export def "custom-objects-records-attachments ListCustomObjectRecordAttachments" [
  custom_object_key: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_object_record_attachments: table<content_type: string, content_url: string, created_at: string, created_by: string, custom_object_record_id: string, filename: string, id: string, malware_access_override: bool, malware_scan_completed_at: string, malware_scan_status: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($record_id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Object Record Attachment
#
# POST /api/v2/custom_objects/{custom_object_key}/records/{record_id}/attachments
# operationId: CreateCustomObjectRecordAttachment
export def "custom-objects-records-attachments CreateCustomObjectRecordAttachment" [
  custom_object_key: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  uploaded_data: string # The file to upload as an attachment (format: binary)
]: any -> record<custom_object_record_attachment: record<content_type: string, content_url: string, created_at: string, created_by: string, custom_object_record_id: string, filename: string, id: string, malware_access_override: bool, malware_scan_completed_at: string, malware_scan_status: string, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($record_id)/attachments")
  let body = {uploaded_data: $uploaded_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update Custom Object Record Attachment for Malware
#
# PUT /api/v2/custom_objects/{custom_object_key}/records/{record_id}/attachments/{id}
# operationId: UpdateCustomObjectRecordAttachment
# --custom_object_record_attachment shape: {malware_access_override: bool}
export def "custom-objects-records-attachments UpdateCustomObjectRecordAttachment" [
  custom_object_key: string
  record_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_object_record_attachment: record # shape: {malware_access_override: bool}
]: any -> record<custom_object_record_attachment: record<content_type: string, content_url: string, created_at: string, created_by: string, custom_object_record_id: string, filename: string, id: string, malware_access_override: bool, malware_scan_completed_at: string, malware_scan_status: string, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($record_id)/attachments/($id)")
  let body = {custom_object_record_attachment: $custom_object_record_attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Object Record Attachment
#
# DELETE /api/v2/custom_objects/{custom_object_key}/records/{record_id}/attachments/{id}
# operationId: DeleteCustomObjectRecordAttachment
export def "custom-objects-records-attachments DeleteCustomObjectRecordAttachment" [
  custom_object_key: string
  record_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($record_id)/attachments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Custom Object Record Attachment
#
# GET /api/v2/custom_objects/{custom_object_key}/records/{record_id}/attachments/{id}/download
# operationId: DownloadCustomObjectRecordAttachment
export def "custom-objects-records-attachments-download DownloadCustomObjectRecordAttachment" [
  custom_object_key: string
  record_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inline: string@bool-completer # If true, the attachment content is displayed inline in the browser. If false or omitted, the attachment is downloaded as a file.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inline" $inline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/($record_id)/attachments/($id)/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Autocomplete Custom Object Record Search
#
# GET /api/v2/custom_objects/{custom_object_key}/records/autocomplete
# operationId: AutocompleteCustomObjectRecordSearch
export def "custom-objects-records-autocomplete AutocompleteCustomObjectRecordSearch" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Part of a name of the record you are searching for
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pagesize: int # The number of records to return in the response. You can specify up to 100 records per page.
  --field-id: string # The id of the lookup field. If the field has a relationship filter, the filter is applied to the results. Must be used with `source` param.
  --qp-source: string # One of "zen:user", "zen:ticket", "zen:organization", or "zen:custom_object:CUSTOM_OBJECT_KEY". Represents the object `field_id` belongs to. Must be used with field_id param.
  --filterdynamic-values: record # Provided values to be used with [dynamic filters](/api-reference/ticketing/lookup_relationships/lookup_relationships/#using-dynamic-filters).  (e.g. {ticket_brand_id: 456, ticket_fields_123: 123})
  --requester-id: int # The id of the requester. For use with dynamic filters.  (format: int64, e.g. 264817272)
  --assignee-id: int # The id of the selected assignee. For use with dynamic filters.  (format: int64, e.g. 7334148660734)
  --organization-id: int # The id of the organization the requester belongs to. For use with dynamic filters.  (format: int64, e.g. 5633330889598)
]: nothing -> record<count: int, custom_object_records: table<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "field_id" $field_id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "filter[dynamic_values]" $filterdynamic_values "deepObject") (serialize-qp "requester_id" $requester_id "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Custom Object Records
#
# GET /api/v2/custom_objects/{custom_object_key}/records/count
# operationId: CountCustomObjectRecords
export def "custom-objects-records-count CountCustomObjectRecords" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Custom Object Records
#
# GET /api/v2/custom_objects/{custom_object_key}/records/search
# operationId: SearchCustomObjectRecords
export def "custom-objects-records-search SearchCustomObjectRecords" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The query parameter is used to search text-based fields for records that match specific query terms. The query can be multiple words or numbers. Every record that matches the beginning of any word or number in the query string is returned.<br/><br/>  Fuzzy search is supported for the following text-based field types: Text fields, Multi Line Text fields, and RegExp fields.<br/><br/>  For example, you might want to search for records related to Tesla vehicles: `query=Tesla`. In this example the API would return every record for the given custom object where any of the supported text fields contain the word 'Tesla'.<br/><br/>  You can include multiple words or numbers in your search. For example: `query=Tesla Honda 2020`. This search phrase would be URL encoded as `query=Tesla%20Honda%202020` and return every record for the custom object for which any of the supported text fields contained 'Tesla', 'Honda', or '2020'.  (e.g. jdoe)
  --qp-sort: string # One of `name`, `created_at`, `updated_at`, `-name`, `-created_at`, or `-updated_at`. The `-` denotes the sort will be descending. Defaults to sorting by relevance.
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pagesize: int # Specifies how many records should be returned in the response. You can specify up to 100 records per page.
]: nothing -> record<count: int, custom_object_records: table<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filtered Search of Custom Object Records
#
# POST /api/v2/custom_objects/{custom_object_key}/records/search
# operationId: FilteredSearchCustomObjectRecords
# --filter shape: {field_key?: record}
export def "custom-objects-records-search FilteredSearchCustomObjectRecords" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The query parameter is used to search text-based fields for records that match specific query terms. The query can be multiple words or numbers. Every record that matches the beginning of any word or number in the query string is returned.<br/><br/>  Fuzzy search is supported for the following text-based field types: Text fields, Multi Line Text fields, and RegExp fields.<br/><br/>  For example, you might want to search for records related to Tesla vehicles: `query=Tesla`. In this example the API would return every record for the given custom object where any of the supported text fields contain the word 'Tesla'.<br/><br/>  You can include multiple words or numbers in your search. For example: `query=Tesla Honda 2020`. This search phrase would be URL encoded as `query=Tesla%20Honda%202020` and return every record for the custom object for which any of the supported text fields contained 'Tesla', 'Honda', or '2020'.  (e.g. jdoe)
  --qp-sort: string # One of "name", "created_at", "updated_at", "-name", "-created_at", or "-updated_at". The "-" denotes the sort will be descending. Defaults to sorting by relevance.
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pagesize: int # Specifies how many records should be returned in the response. You can specify up to 100 records per page.
  --filter: record # shape: {field_key?: record}
]: any -> record<count: int, custom_object_records: table<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, photo: record, updated_at: string, updated_by_user_id: string, url: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/records/search" $qp)
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Object Triggers
#
# GET /api/v2/custom_objects/{custom_object_key}/triggers
# operationId: ListObjectTriggers
export def "custom-objects-triggers ListObjectTriggers" [
  custom_object_key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Filter by active triggers if true or inactive triggers if false (e.g. true)
  --sort-by: string # Offset pagination only. Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", or "usage_7d". Defaults to "position" (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
]: nothing -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Object Trigger
#
# POST /api/v2/custom_objects/{custom_object_key}/triggers
# operationId: CreateObjectTrigger
export def "custom-objects-triggers CreateObjectTrigger" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger: any
]: any -> record<trigger: record<actions: list<record>, active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers")
  let body = {trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Object Trigger
#
# GET /api/v2/custom_objects/{custom_object_key}/triggers/{trigger_id}
# operationId: GetObjectTrigger
export def "custom-objects-triggers GetObjectTrigger" [
  custom_object_key: string
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trigger: record<actions: list<record>, active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/($trigger_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Object Trigger
#
# PUT /api/v2/custom_objects/{custom_object_key}/triggers/{trigger_id}
# operationId: UpdateObjectTrigger
export def "custom-objects-triggers UpdateObjectTrigger" [
  custom_object_key: string
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger: any
]: any -> record<trigger: record<actions: list<record>, active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/($trigger_id)")
  let body = {trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Object Trigger
#
# DELETE /api/v2/custom_objects/{custom_object_key}/triggers/{trigger_id}
# operationId: DeleteObjectTrigger
export def "custom-objects-triggers DeleteObjectTrigger" [
  custom_object_key: string
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/($trigger_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Active Object Triggers
#
# GET /api/v2/custom_objects/{custom_object_key}/triggers/active
# operationId: ListActiveObjectTriggers
export def "custom-objects-triggers-active ListActiveObjectTriggers" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Offset pagination only. Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", or "usage_7d". Defaults to "position" (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
]: nothing -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Object Trigger Action and Condition Definitions
#
# GET /api/v2/custom_objects/{custom_object_key}/triggers/definitions
# operationId: ListObjectTriggersDefinitions
export def "custom-objects-triggers-definitions ListObjectTriggersDefinitions" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<actions: list<record>, conditions_all: list<record>, conditions_any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Many Object Triggers
#
# DELETE /api/v2/custom_objects/{custom_object_key}/triggers/destroy_many
# operationId: DeleteManyObjectTriggers
export def "custom-objects-triggers-destroy-many DeleteManyObjectTriggers" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of trigger IDs (e.g. 131,178,938)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Object Triggers
#
# GET /api/v2/custom_objects/{custom_object_key}/triggers/search
# operationId: SearchObjectTriggers
export def "custom-objects-triggers-search SearchObjectTriggers" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Query string used to find all triggers with matching title (e.g. important_trigger)
  --filter: string # JSON-encoded trigger attribute filters for the search. See [Filter](#filter).  Example: `{"json":{"description":"Close a ticket"}}`  (e.g. {"json":{"description":"Close a ticket"}})
  --active: string@bool-completer # Filter by active triggers if true or inactive triggers if false (e.g. true)
  --qp-sort: string # Cursor-based pagination only. Possible values are "alphabetical", "created_at", "updated_at", or "position". (e.g. position)
  --sort-by: string # Offset pagination only. Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", or "usage_7d". Defaults to "position" (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_24h)
]: nothing -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Object Triggers
#
# PUT /api/v2/custom_objects/{custom_object_key}/triggers/update_many
# operationId: UpdateManyObjectTriggers
# --triggers item shape: {active?: bool, id: int, position?: int}
export def "custom-objects-triggers-update-many UpdateManyObjectTriggers" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --triggers: list # item shape: {active?: bool, id: int, position?: int}
]: any -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_objects/($custom_object_key)/triggers/update_many")
  let body = {triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Custom Objects Limit
#
# GET /api/v2/custom_objects/limits/object_limit
# operationId: CustomObjectsLimit
export def "custom-objects-limits-object-limit CustomObjectsLimit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_objects/limits/object_limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Custom Object Records Limit
#
# GET /api/v2/custom_objects/limits/record_limit
# operationId: CustomObjectRecordsLimit
export def "custom-objects-limits-record-limit CustomObjectRecordsLimit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_objects/limits/record_limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Roles
#
# GET /api/v2/custom_roles
# operationId: ListCustomRoles
export def "custom-roles ListCustomRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_roles: table<configuration: record, created_at: string, description: string, id: int, name: string, role_type: int, team_member_count: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Role
#
# POST /api/v2/custom_roles
# operationId: CreateCustomRole
export def "custom-roles CreateCustomRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_role: record<configuration: record<actions_access: string, assign_tickets_to_any_group: bool, capacity_rules_access: string, chat_access: bool, end_user_list_access: string, end_user_profile_access: string, execute_it_asset_management_actions: bool, explore_access: string, export_views: bool, forum_access: string, forum_access_restricted_content: bool, group_access: bool, light_agent: bool, macro_access: string, manage_api_credentials: bool, manage_business_rules: bool, manage_contextual_workspaces: bool, manage_dynamic_content: bool, manage_extensions_and_channels: bool, manage_facebook: bool, manage_organization_fields: bool, manage_ticket_fields: bool, manage_ticket_forms: bool, manage_ticket_settings: bool, manage_user_fields: bool, manage_user_own_contacts: bool, manage_user_own_forwarding_numbers: bool, manage_user_own_photo: bool, moderate_forums: bool, modify_closed_tickets: bool, organization_editing: bool, organization_notes_editing: bool, report_access: string, side_conversation_create: bool, ticket_access: string, ticket_comment_access: string, ticket_deletion: bool, ticket_editing: bool, ticket_merge: bool, ticket_tag_editing: bool, twitter_search_access: bool, update_api_settings: bool, update_user_own_alias: bool, update_user_own_name: bool, update_user_own_signature: bool, user_view_access: string, view_access: string, view_access_logs: bool, view_audit_logs: bool, view_deleted_tickets: bool, view_filter_tickets: bool, voice_access: bool, voice_dashboard_access: bool>, created_at: string, description: string, id: int, name: string, role_type: int, team_member_count: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Custom Role
#
# GET /api/v2/custom_roles/{custom_role_id}
# operationId: ShowCustomRoleById
export def "custom-roles ShowCustomRoleById" [
  custom_role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_role: record<configuration: record<actions_access: string, assign_tickets_to_any_group: bool, capacity_rules_access: string, chat_access: bool, end_user_list_access: string, end_user_profile_access: string, execute_it_asset_management_actions: bool, explore_access: string, export_views: bool, forum_access: string, forum_access_restricted_content: bool, group_access: bool, light_agent: bool, macro_access: string, manage_api_credentials: bool, manage_business_rules: bool, manage_contextual_workspaces: bool, manage_dynamic_content: bool, manage_extensions_and_channels: bool, manage_facebook: bool, manage_organization_fields: bool, manage_ticket_fields: bool, manage_ticket_forms: bool, manage_ticket_settings: bool, manage_user_fields: bool, manage_user_own_contacts: bool, manage_user_own_forwarding_numbers: bool, manage_user_own_photo: bool, moderate_forums: bool, modify_closed_tickets: bool, organization_editing: bool, organization_notes_editing: bool, report_access: string, side_conversation_create: bool, ticket_access: string, ticket_comment_access: string, ticket_deletion: bool, ticket_editing: bool, ticket_merge: bool, ticket_tag_editing: bool, twitter_search_access: bool, update_api_settings: bool, update_user_own_alias: bool, update_user_own_name: bool, update_user_own_signature: bool, user_view_access: string, view_access: string, view_access_logs: bool, view_audit_logs: bool, view_deleted_tickets: bool, view_filter_tickets: bool, voice_access: bool, voice_dashboard_access: bool>, created_at: string, description: string, id: int, name: string, role_type: int, team_member_count: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_roles/($custom_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Role
#
# PUT /api/v2/custom_roles/{custom_role_id}
# operationId: UpdateCustomRoleById
export def "custom-roles UpdateCustomRoleById" [
  custom_role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_role: record<configuration: record<actions_access: string, assign_tickets_to_any_group: bool, capacity_rules_access: string, chat_access: bool, end_user_list_access: string, end_user_profile_access: string, execute_it_asset_management_actions: bool, explore_access: string, export_views: bool, forum_access: string, forum_access_restricted_content: bool, group_access: bool, light_agent: bool, macro_access: string, manage_api_credentials: bool, manage_business_rules: bool, manage_contextual_workspaces: bool, manage_dynamic_content: bool, manage_extensions_and_channels: bool, manage_facebook: bool, manage_organization_fields: bool, manage_ticket_fields: bool, manage_ticket_forms: bool, manage_ticket_settings: bool, manage_user_fields: bool, manage_user_own_contacts: bool, manage_user_own_forwarding_numbers: bool, manage_user_own_photo: bool, moderate_forums: bool, modify_closed_tickets: bool, organization_editing: bool, organization_notes_editing: bool, report_access: string, side_conversation_create: bool, ticket_access: string, ticket_comment_access: string, ticket_deletion: bool, ticket_editing: bool, ticket_merge: bool, ticket_tag_editing: bool, twitter_search_access: bool, update_api_settings: bool, update_user_own_alias: bool, update_user_own_name: bool, update_user_own_signature: bool, user_view_access: string, view_access: string, view_access_logs: bool, view_audit_logs: bool, view_deleted_tickets: bool, view_filter_tickets: bool, voice_access: bool, voice_dashboard_access: bool>, created_at: string, description: string, id: int, name: string, role_type: int, team_member_count: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_roles/($custom_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Custom Role
#
# DELETE /api/v2/custom_roles/{custom_role_id}
# operationId: DeleteCustomRoleById
export def "custom-roles DeleteCustomRoleById" [
  custom_role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_roles/($custom_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Update Default Custom Ticket Status
#
# PUT /api/v2/custom_status/default
# operationId: BulkUpdateDefaultCustomStatus
export def "custom-status-default BulkUpdateDefaultCustomStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The comma-separated list of custom ticket status ids to be set as default for their status categories
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_status/default")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Custom Ticket Statuses
#
# GET /api/v2/custom_statuses
# operationId: ListCustomStatuses
export def "custom-statuses ListCustomStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-categories: string # Filter the list of custom ticket statuses by a comma-separated list of status categories
  --active: string@bool-completer # If true, show only active custom ticket statuses. If false, show only inactive custom ticket statuses. If the filter is not used, show all custom ticket statuses
  --default: string@bool-completer # If true, show only default custom ticket statuses. If false, show only non-default custom ticket statuses. If the filter is not used, show all custom ticket statuses
]: nothing -> record<custom_statuses: table<active: bool, agent_label: string, created_at: string, default: bool, description: string, end_user_description: string, end_user_label: string, id: int, raw_agent_label: string, raw_description: string, raw_end_user_description: string, raw_end_user_label: string, status_category: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status_categories" $status_categories "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "default" $default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/custom_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Ticket Status
#
# POST /api/v2/custom_statuses
# operationId: CreateCustomStatus
# --custom_status shape: {active?: bool, agent_label?: string, description?: string, end_user_description?: string, end_user_label?: string, status_category?: "new"|"open"|"pending"|"hold"|"solved"}
export def "custom-statuses CreateCustomStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-status: record # shape: {active?: bool, agent_label?: string, description?: string, end_user_description?: string, end_user_label?: string, status_category?: "new"|"open"|"pending"|"hold"|"solved"}
]: any -> record<custom_status: record<active: bool, agent_label: string, created_at: string, default: bool, description: string, end_user_description: string, end_user_label: string, id: int, raw_agent_label: string, raw_description: string, raw_end_user_description: string, raw_end_user_label: string, status_category: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/custom_statuses")
  let body = {custom_status: $custom_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Custom Ticket Status
#
# GET /api/v2/custom_statuses/{custom_status_id}
# operationId: ShowCustomStatus
export def "custom-statuses ShowCustomStatus" [
  custom_status_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_status: record<active: bool, agent_label: string, created_at: string, default: bool, description: string, end_user_description: string, end_user_label: string, id: int, raw_agent_label: string, raw_description: string, raw_end_user_description: string, raw_end_user_label: string, status_category: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_statuses/($custom_status_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Ticket Status
#
# PUT /api/v2/custom_statuses/{custom_status_id}
# operationId: UpdateCustomStatus
# --custom_status shape: {active?: bool, agent_label?: string, description?: string, end_user_description?: string, end_user_label?: string}
export def "custom-statuses UpdateCustomStatus" [
  custom_status_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-status: record # shape: {active?: bool, agent_label?: string, description?: string, end_user_description?: string, end_user_label?: string}
]: any -> record<custom_status: record<active: bool, agent_label: string, created_at: string, default: bool, description: string, end_user_description: string, end_user_label: string, id: int, raw_agent_label: string, raw_description: string, raw_end_user_description: string, raw_end_user_label: string, status_category: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_statuses/($custom_status_id)")
  let body = {custom_status: $custom_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Ticket Status
#
# DELETE /api/v2/custom_statuses/{custom_status_id}
# operationId: DeleteCustomStatus
export def "custom-statuses DeleteCustomStatus" [
  custom_status_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_statuses/($custom_status_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket Form Statuses for a Custom Status
#
# POST /api/v2/custom_statuses/{custom_status_id}/ticket_form_statuses
# operationId: CreateTicketFormStatusesForCustomStatus
# --ticket_form_status item shape: {ticket_form_id?: int}
export def "custom-statuses-ticket-form-statuses CreateTicketFormStatusesForCustomStatus" [
  custom_status_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket-form-status: list # item shape: {ticket_form_id?: int}
]: any -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/custom_statuses/($custom_status_id)/ticket_form_statuses")
  let body = {ticket_form_status: $ticket_form_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Deleted Tickets
#
# GET /api/v2/deleted_tickets
# operationId: ListDeletedTickets
export def "deleted-tickets ListDeletedTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string@sort-by-completer # Sort by
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
  --support-type-scope: string # Lists tickets by support type. Possible values are "all", "agent", or "ai_agent". Defaults to "agent"
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "support_type_scope" $support_type_scope "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/deleted_tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Ticket Permanently
#
# DELETE /api/v2/deleted_tickets/{ticket_id}
# operationId: DeleteTicketPermanently
export def "deleted-tickets DeleteTicketPermanently" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deleted_tickets/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore a Previously Deleted Ticket
#
# PUT /api/v2/deleted_tickets/{ticket_id}/restore
# operationId: RestoreDeletedTicket
export def "deleted-tickets-restore RestoreDeletedTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deleted_tickets/($ticket_id)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Multiple Tickets Permanently
#
# DELETE /api/v2/deleted_tickets/destroy_many
# operationId: BulkPermanentlyDeleteTickets
export def "deleted-tickets-destroy-many BulkPermanentlyDeleteTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket ids (e.g. 35436,35437)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/deleted_tickets/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore Previously Deleted Tickets in Bulk
#
# PUT /api/v2/deleted_tickets/restore_many
# operationId: BulkRestoreDeletedTickets
export def "deleted-tickets-restore-many BulkRestoreDeletedTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket ids (e.g. 35436,35437)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/deleted_tickets/restore_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Deleted Users
#
# GET /api/v2/deleted_users
# operationId: ListDeletedUsers
export def "deleted-users ListDeletedUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<deleted_users: table<active: bool, created_at: string, email: string, id: int, locale: string, locale_id: int, name: string, organization_id: int, phone: string, photo: record, role: string, separation: record, shared_phone_number: string, time_zone: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/deleted_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Deleted User
#
# GET /api/v2/deleted_users/{deleted_user_id}
# operationId: ShowDeletedUser
export def "deleted-users ShowDeletedUser" [
  deleted_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_user: record<active: bool, created_at: string, email: string, id: int, locale: string, locale_id: int, name: string, organization_id: int, phone: string, photo: record, role: string, separation: record<brand_id: int, scope: string>, shared_phone_number: string, time_zone: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deleted_users/($deleted_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently Delete User
#
# DELETE /api/v2/deleted_users/{deleted_user_id}
# operationId: PermanentlyDeleteUser
export def "deleted-users PermanentlyDeleteUser" [
  deleted_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_user: record<active: bool, created_at: string, email: string, id: int, locale: string, locale_id: int, name: string, organization_id: int, phone: string, photo: record, role: string, separation: record<brand_id: int, scope: string>, shared_phone_number: string, time_zone: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deleted_users/($deleted_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Deleted Users
#
# GET /api/v2/deleted_users/count
# operationId: CountDeletedUsers
export def "deleted-users-count CountDeletedUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/deleted_users/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Deletion Schedules
#
# GET /api/v2/deletion_schedules
# operationId: ListDeletionSchedules
export def "deletion-schedules ListDeletionSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletion_schedules: table<active: bool, conditions: record, created_at: string, default: bool, description: string, id: int, object: string, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/deletion_schedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Deletion Schedule
#
# POST /api/v2/deletion_schedules
# operationId: CreateDeletionSchedule
# --deletion_schedule shape: {active?: bool, conditions?: record, description?: string, object?: string, title?: string}
export def "deletion-schedules CreateDeletionSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deletion-schedule: record # shape: {active?: bool, conditions?: record, description?: string, object?: string, title?: string}
]: any -> record<deletion_schedule: record<active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, object: string, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/deletion_schedules")
  let body = {deletion_schedule: $deletion_schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Deletion Schedule
#
# GET /api/v2/deletion_schedules/{deletion_schedule_id}
# operationId: GetDeletionSchedule
export def "deletion-schedules GetDeletionSchedule" [
  deletion_schedule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletion_schedule: record<active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, object: string, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deletion_schedules/($deletion_schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Deletion Schedule
#
# PUT /api/v2/deletion_schedules/{deletion_schedule_id}
# operationId: UpdateDeletionSchedule
# --deletion_schedule shape: {active?: bool, conditions?: record, description?: string, object?: string, title?: string}
export def "deletion-schedules UpdateDeletionSchedule" [
  deletion_schedule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deletion-schedule: record # shape: {active?: bool, conditions?: record, description?: string, object?: string, title?: string}
]: any -> record<deletion_schedule: record<active: bool, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, object: string, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deletion_schedules/($deletion_schedule_id)")
  let body = {deletion_schedule: $deletion_schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Deletion Schedule
#
# DELETE /api/v2/deletion_schedules/{deletion_schedule_id}
# operationId: DeleteDeletionSchedule
export def "deletion-schedules DeleteDeletionSchedule" [
  deletion_schedule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/deletion_schedules/($deletion_schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Items
#
# GET /api/v2/dynamic_content/items
# operationId: ListDynamicContents
export def "dynamic-content-items ListDynamicContents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<items: table<created_at: string, default_locale_id: int, id: int, name: string, outdated: bool, placeholder: string, updated_at: string, url: string, variants: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/dynamic_content/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Item
#
# POST /api/v2/dynamic_content/items
# operationId: CreateDynamicContent
export def "dynamic-content-items CreateDynamicContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<created_at: string, default_locale_id: int, id: int, name: string, outdated: bool, placeholder: string, updated_at: string, url: string, variants: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/dynamic_content/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Item
#
# GET /api/v2/dynamic_content/items/{dynamic_content_item_id}
# operationId: ShowDynamicContentItem
export def "dynamic-content-items ShowDynamicContentItem" [
  dynamic_content_item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<created_at: string, default_locale_id: int, id: int, name: string, outdated: bool, placeholder: string, updated_at: string, url: string, variants: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Item
#
# PUT /api/v2/dynamic_content/items/{dynamic_content_item_id}
# operationId: UpdateDynamicContentItem
export def "dynamic-content-items UpdateDynamicContentItem" [
  dynamic_content_item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<item: record<created_at: string, default_locale_id: int, id: int, name: string, outdated: bool, placeholder: string, updated_at: string, url: string, variants: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Item
#
# DELETE /api/v2/dynamic_content/items/{dynamic_content_item_id}
# operationId: DeleteDynamicContentItem
export def "dynamic-content-items DeleteDynamicContentItem" [
  dynamic_content_item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Variants
#
# GET /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants
# operationId: DynamicContentListVariants
export def "dynamic-content-items-variants DynamicContentListVariants" [
  dynamic_content_item_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<variants: table<active: bool, content: string, created_at: string, default: bool, id: int, locale_id: int, outdated: bool, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Variant
#
# POST /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants
# operationId: CreateDynamicContentVariant
export def "dynamic-content-items-variants CreateDynamicContentVariant" [
  dynamic_content_item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variant: record<active: bool, content: string, created_at: string, default: bool, id: int, locale_id: int, outdated: bool, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Variant
#
# GET /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants/{dynamic_content_variant_id}
# operationId: ShowDynamicContentVariant
export def "dynamic-content-items-variants ShowDynamicContentVariant" [
  dynamic_content_item_id: int
  dynamic_content_variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variant: record<active: bool, content: string, created_at: string, default: bool, id: int, locale_id: int, outdated: bool, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants/($dynamic_content_variant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Variant
#
# PUT /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants/{dynamic_content_variant_id}
# operationId: UpdateDynamicContentVariant
export def "dynamic-content-items-variants UpdateDynamicContentVariant" [
  dynamic_content_item_id: int
  dynamic_content_variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variant: record<active: bool, content: string, created_at: string, default: bool, id: int, locale_id: int, outdated: bool, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants/($dynamic_content_variant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Variant
#
# DELETE /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants/{dynamic_content_variant_id}
# operationId: DeleteDynamicContentVariant
export def "dynamic-content-items-variants DeleteDynamicContentVariant" [
  dynamic_content_item_id: int
  dynamic_content_variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants/($dynamic_content_variant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Many Variants
#
# POST /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants/create_many
# operationId: CreateManyDynamicContentVariants
export def "dynamic-content-items-variants-create-many CreateManyDynamicContentVariants" [
  dynamic_content_item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variants: table<active: bool, content: string, created_at: string, default: bool, id: int, locale_id: int, outdated: bool, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants/create_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Variants
#
# PUT /api/v2/dynamic_content/items/{dynamic_content_item_id}/variants/update_many
# operationId: UpdateManyDynamicContentVariants
export def "dynamic-content-items-variants-update-many UpdateManyDynamicContentVariants" [
  dynamic_content_item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variants: table<active: bool, content: string, created_at: string, default: bool, id: int, locale_id: int, outdated: bool, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dynamic_content/items/($dynamic_content_item_id)/variants/update_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Items
#
# GET /api/v2/dynamic_content/items/show_many
# operationId: ShowManyDynamicContents
export def "dynamic-content-items-show-many ShowManyDynamicContents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifiers: string # Identifiers for the dynamic contents (e.g. item1,item2)
]: nothing -> record<items: table<created_at: string, default_locale_id: int, id: int, name: string, outdated: bool, placeholder: string, updated_at: string, url: string, variants: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifiers" $identifiers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/dynamic_content/items/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Email Notifications
#
# GET /api/v2/email_notifications
# operationId: ListEmailNotifications
export def "email-notifications ListEmailNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # Filters the email notifications by ticket, comment, or notification id.
  --per-page: int # The number of records to return per page
  --qp-sort: string # The field to sort the list.  Possible values are "created_at", "updated_at" (ascending order) or "-created_at", "-updated_at" (descending order) (e.g. updated_at)
]: nothing -> record<email_notifications: table<comment_id: int, created_at: string, email_id: string, message_id: string, notification_id: int, recipients: list, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/email_notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Email Notification
#
# GET /api/v2/email_notifications/{notification_id}
# operationId: ShowEmailNotification
export def "email-notifications ShowEmailNotification" [
  notification_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email_notification: record<comment_id: int, created_at: string, email_id: string, message_id: string, notification_id: int, recipients: list<record>, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/email_notifications/($notification_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Email Notifications
#
# GET /api/v2/email_notifications/show_many
# operationId: ShowManyEmailNotifications
export def "email-notifications-show-many ShowManyEmailNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of notification ids. One of ids, comment_ids, or ticket_ids is required. (e.g. 8433702508541,8433348111869)
  --comment-ids: string # Comma-separated list of comment ids. One of ids, comment_ids, or ticket_ids is required. (e.g. 8433348111741,8433544226045,8433702508413)
  --ticket-ids: string # Comma-separated list of ticket ids. One of ids, comment_ids, or ticket_ids is required. (e.g. 35436,35437)
]: nothing -> record<email_notification: record<comment_id: int, created_at: string, email_id: string, message_id: string, notification_id: int, recipients: list<record>, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "comment_ids" $comment_ids "scalar") (serialize-qp "ticket_ids" $ticket_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/email_notifications/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List End User Identities
#
# GET /api/v2/end_users/{user_id}/identities
# operationId: ListEndUserIdentities
export def "end-users-identities ListEndUserIdentities" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Filters results by one or more identity types using the format `?type[]={type}&type[]={type}`
]: nothing -> record<identities: table<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type[]" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/end_users/($user_id)/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create End User Identity
#
# POST /api/v2/end_users/{user_id}/identities
# operationId: CreateEndUserIdentity
export def "end-users-identities CreateEndUserIdentity" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Filters results by one or more identity types using the format `?type[]={type}&type[]={type}`
  --brand-id: int # When brand separation is enabled, associates the new identity with the specified brand. (format: int64)
]: nothing -> record<identity: record<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type[]" $type "scalar") (serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/end_users/($user_id)/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show End User Identity
#
# GET /api/v2/end_users/{user_id}/identities/{user_identity_id}
# operationId: ShowEndUserIdentity
export def "end-users-identities ShowEndUserIdentity" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identity: record<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/end_users/($user_id)/identities/($user_identity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete End User Identity
#
# DELETE /api/v2/end_users/{user_id}/identities/{user_identity_id}
# operationId: DeleteEndUserIdentity
export def "end-users-identities DeleteEndUserIdentity" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/end_users/($user_id)/identities/($user_identity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make End User Identity Primary
#
# PUT /api/v2/end_users/{user_id}/identities/{user_identity_id}/make_primary
# operationId: MakeEndUserIdentityPrimary
export def "end-users-identities-make-primary MakeEndUserIdentityPrimary" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identities: table<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/end_users/($user_id)/identities/($user_identity_id)/make_primary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request End User Verification
#
# PUT /api/v2/end_users/{user_id}/identities/{user_identity_id}/request_verification
# operationId: RequestEndUserVerification
export def "end-users-identities-request-verification RequestEndUserVerification" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/end_users/($user_id)/identities/($user_identity_id)/request_verification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Memberships
#
# GET /api/v2/group_memberships
# operationId: ListGroupMemberships
export def "group-memberships ListGroupMemberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. Valid values: `users`, `groups`.  (e.g. users,groups)
]: nothing -> record<group_memberships: table<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/group_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Membership
#
# POST /api/v2/group_memberships
# operationId: CreateGroupMembership
export def "group-memberships CreateGroupMembership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_membership: record<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/group_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Membership
#
# GET /api/v2/group_memberships/{group_membership_id}
# operationId: ShowGroupMembershipById
export def "group-memberships ShowGroupMembershipById" [
  group_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_membership: record<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/group_memberships/($group_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Membership
#
# DELETE /api/v2/group_memberships/{group_membership_id}
# operationId: DeleteGroupMembership
export def "group-memberships DeleteGroupMembership" [
  group_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/group_memberships/($group_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assignable Memberships
#
# GET /api/v2/group_memberships/assignable
# operationId: ListAssignableGroupMemberships
export def "group-memberships-assignable ListAssignableGroupMemberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_memberships: table<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/group_memberships/assignable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Create Memberships
#
# POST /api/v2/group_memberships/create_many
# operationId: GroupMembershipBulkCreate
export def "group-memberships-create-many GroupMembershipBulkCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/group_memberships/create_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Memberships
#
# DELETE /api/v2/group_memberships/destroy_many
# operationId: GroupMembershipBulkDelete
export def "group-memberships-destroy-many GroupMembershipBulkDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Id of the group memberships to delete. Comma separated (e.g. 1,2,3)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/group_memberships/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Group SLA Policies
#
# GET /api/v2/group_slas/policies
# operationId: ListGroupSLAPolicies
export def "group-slas-policies ListGroupSLAPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, group_sla_policies: table<created_at: string, description: string, filter: record, id: string, policy_metrics: list, position: int, title: string, updated_at: string, url: string>, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/group_slas/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Group SLA Policy
#
# POST /api/v2/group_slas/policies
# operationId: CreateGroupSLAPolicy
export def "group-slas-policies CreateGroupSLAPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_sla_policy: record<created_at: string, description: string, filter: record<all: list>, id: string, policy_metrics: list<record>, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/group_slas/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Group SLA Policy
#
# GET /api/v2/group_slas/policies/{group_sla_policy_id}
# operationId: ShowGroupSLAPolicy
export def "group-slas-policies ShowGroupSLAPolicy" [
  group_sla_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_sla_policy: record<created_at: string, description: string, filter: record<all: list>, id: string, policy_metrics: list<record>, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/group_slas/policies/($group_sla_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Group SLA Policy
#
# PUT /api/v2/group_slas/policies/{group_sla_policy_id}
# operationId: UpdateGroupSLAPolicy
export def "group-slas-policies UpdateGroupSLAPolicy" [
  group_sla_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_sla_policy: record<created_at: string, description: string, filter: record<all: list>, id: string, policy_metrics: list<record>, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/group_slas/policies/($group_sla_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Group SLA Policy
#
# DELETE /api/v2/group_slas/policies/{group_sla_policy_id}
# operationId: DeleteGroupSLAPolicy
export def "group-slas-policies DeleteGroupSLAPolicy" [
  group_sla_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/group_slas/policies/($group_sla_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Supported Filter Definition Items
#
# GET /api/v2/group_slas/policies/definitions
# operationId: RetrieveGroupSLAPolicyFilterDefinitionItems
export def "group-slas-policies-definitions RetrieveGroupSLAPolicyFilterDefinitionItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<all: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/group_slas/policies/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Group SLA Policies
#
# PUT /api/v2/group_slas/policies/reorder
# operationId: ReorderGroupSLAPolicies
export def "group-slas-policies-reorder ReorderGroupSLAPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-sla-policy-ids: list # The ids of the Group SLA policies to reorder
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_sla_policy_ids" $group_sla_policy_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/group_slas/policies/reorder" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Groups
#
# GET /api/v2/groups
# operationId: ListGroups
export def "groups ListGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exclude-deleted: string@bool-completer # Whether to exclude deleted entities (e.g. false)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values.  (e.g. users,group_settings)
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<groups: table<created_at: string, default: bool, deleted: bool, description: string, id: int, is_public: bool, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclude_deleted" $exclude_deleted "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Group
#
# POST /api/v2/groups
# operationId: CreateGroup
export def "groups CreateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group: record<created_at: string, default: bool, deleted: bool, description: string, id: int, is_public: bool, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Group
#
# GET /api/v2/groups/{group_id}
# operationId: ShowGroupById
export def "groups ShowGroupById" [
  group_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values.  (e.g. users,group_settings)
]: nothing -> record<group: record<created_at: string, default: bool, deleted: bool, description: string, id: int, is_public: bool, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/groups/($group_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Group
#
# PUT /api/v2/groups/{group_id}
# operationId: UpdateGroup
export def "groups UpdateGroup" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group: record<created_at: string, default: bool, deleted: bool, description: string, id: int, is_public: bool, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Group
#
# DELETE /api/v2/groups/{group_id}
# operationId: DeleteGroup
export def "groups DeleteGroup" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Memberships By Group
#
# GET /api/v2/groups/{group_id}/memberships
# operationId: ListGroupMembershipsByGroup
export def "groups-memberships ListGroupMembershipsByGroup" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_memberships: table<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/groups/($group_id)/memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assignable Memberships By Group
#
# GET /api/v2/groups/{group_id}/memberships/assignable
# operationId: ListAssignableGroupMembershipsByGroup
export def "groups-memberships-assignable ListAssignableGroupMembershipsByGroup" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_memberships: table<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/groups/($group_id)/memberships/assignable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Users By Group
#
# GET /api/v2/groups/{group_id}/users
# operationId: ListGroupUsers
export def "groups-users ListGroupUsers" [
  group_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # Filters the results by role. Possible values are "end-user", "agent", "admin", or a custom role name  (e.g. agent)
  --role: string # Filters the results by more than one role using the format `role[]={role}&role[]={role}`  (e.g. agent)
  --permission-set: int # For custom roles which is available on the Enterprise plan and above. You can only filter by one role ID per request (format: int64, e.g. 123)
  --external-id: string # List users by external id. External id has to be unique for each user under the same account. (e.g. abc)
]: nothing -> record<users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "role[]" $role "scalar") (serialize-qp "permission_set" $permission_set "scalar") (serialize-qp "external_id" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/groups/($group_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Users By Group
#
# GET /api/v2/groups/{group_id}/users/count
# operationId: CountGroupUsers
export def "groups-users-count CountGroupUsers" [
  group_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # Filters the results by role. Possible values are "end-user", "agent", "admin", or a custom role name  (e.g. agent)
  --role: string # Filters the results by more than one role using the format `role[]={role}&role[]={role}`  (e.g. agent)
  --permission-set: int # For custom roles which is available on the Enterprise plan and above. You can only filter by one role ID per request (format: int64, e.g. 123)
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "role[]" $role "scalar") (serialize-qp "permission_set" $permission_set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/groups/($group_id)/users/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assignable Groups
#
# GET /api/v2/groups/assignable
# operationId: ListAssignableGroups
export def "groups-assignable ListAssignableGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<groups: table<created_at: string, default: bool, deleted: bool, description: string, id: int, is_public: bool, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/groups/assignable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Groups
#
# GET /api/v2/groups/count
# operationId: CountGroups
export def "groups-count CountGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/groups/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ticket Import
#
# POST /api/v2/imports/tickets
# operationId: TicketImport
# --ticket shape: {assignee_id?: int, brand_id?: int, collaborators?: list, comment?: any, comments?: list, created_at?: string, custom_fields?: list, custom_status_id?: int, description?: string, email_ccs?: list, external_id?: string, followers?: list, group_id?: int, priority?: "urgent"|"high"|"normal"|"low", recipient?: string, requester_id?: int, solved_at?: string, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, tags?: list, updated_at?: string, via?: record}
export def "imports-tickets TicketImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archive-immediately: string@bool-completer # If `true`, any ticket created with a `closed` status bypasses the normal ticket lifecycle and will be created directly in your ticket archive
  --ticket: record # shape: {assignee_id?: int, brand_id?: int, collaborators?: list, comment?: any, comments?: list, created_at?: string, custom_fields?: list, custom_status_id?: int, description?: string, email_ccs?: list, external_id?: string, followers?: list, group_id?: int, priority?: "urgent"|"high"|"normal"|"low", recipient?: string, requester_id?: int, solved_at?: string, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, tags?: list, updated_at?: string, via?: record}
]: any -> record<ticket: record<additional_collaborators: list<record>, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list<int>, brand_id: int, collaborator_ids: list<int>, collaborators: list<record>, comment: record<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, email_ccs: list<record>, encoded_id: string, external_id: string, fields: list<record>, follower_ids: list<int>, followers: list<record>, followup_ids: list<int>, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list<int>, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list<int>, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record<client: string, ip_address: string>, tags: any, tde_workspace: record<previous_workspace: record, type: string, workspace: record>, ticket_form_id: int, tpe_voice_comment: record<agent_id: int, answering_machine_detection_status: string, app_id: int, app_name: string, author_id: int, call_connected_at: string, call_disposition: string, call_ended_at: string, call_id: int, call_recording_consent: string, call_recording_consent_action: string, call_recording_consent_keypress: string, call_started_at: string, call_type: string, callback_number: string, callback_requested_at: string, completion_status: string, connection_attempts: int, consultation_time: int, direction: string, disconnection_reason: string, dnis: string, duration: int, end_user_id: int, end_user_location: string, exceeded_queue_time: bool, extension: string, external_id: string, from_line: string, from_line_nickname: string, hold_time: int, intent: string, ivr_destination_group_name: string, ivr_time_spent: int, language: string, line_type: string, longest_hold_time: int, number_of_holds: int, outside_business_hours: bool, overflowed_to: string, phone_name: string, public: bool, quality_score: int, queue_name: string, queue_time: int, recorded: bool, recording_time: int, recording_type: string, recording_url: string, sentiment_agent: string, sentiment_call: string, sentiment_customer: string, sentiment_trend: string, short_summary: string, summary: string, talk_time: int, time_to_answer: int, title: string, to_line: string, to_line_nickname: string, transcript: string, via_id: int, video_recording_url: string, voicemail: bool, voicemail_requested_at: string, wait_time: int>, type: string, updated_at: string, updated_stamp: string, url: string, via: record<channel: any, source: record>, via_followup_source_id: int, via_id: int, voice_comment: record<answered_by_id: int, call_duration: int, from: string, location: string, recording_url: string, to: string, transcription_text: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "archive_immediately" $archive_immediately "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/imports/tickets" $qp)
  let body = {ticket: $ticket} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ticket Bulk Import
#
# POST /api/v2/imports/tickets/create_many
# operationId: TicketBulkImport
# --tickets item shape: {assignee_id?: int, brand_id?: int, collaborators?: list, comment?: any, comments?: list, created_at?: string, custom_fields?: list, custom_status_id?: int, description?: string, email_ccs?: list, external_id?: string, followers?: list, group_id?: int, priority?: "urgent"|"high"|"normal"|"low", recipient?: string, requester_id?: int, solved_at?: string, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, tags?: list, updated_at?: string, via?: record}
export def "imports-tickets-create-many TicketBulkImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archive-immediately: string@bool-completer # If `true`, any ticket created with a `closed` status bypasses the normal ticket lifecycle and will be created directly in your ticket archive
  --tickets: list # item shape: {assignee_id?: int, brand_id?: int, collaborators?: list, comment?: any, comments?: list, created_at?: string, custom_fields?: list, custom_status_id?: int, description?: string, email_ccs?: list, external_id?: string, followers?: list, group_id?: int, priority?: "urgent"|"high"|"normal"|"low", recipient?: string, requester_id?: int, solved_at?: string, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, tags?: list, updated_at?: string, via?: record}
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "archive_immediately" $archive_immediately "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/imports/tickets/create_many" $qp)
  let body = {tickets: $tickets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Incremental Sample Export
#
# GET /api/v2/incremental/{incremental_resource}/sample
# operationId: IncrementalSampleExport
export def "incremental-sample IncrementalSampleExport" [
  incremental_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute (e.g. 1332034771)
]: nothing -> record<count: int, end_of_stream: bool, end_time: int, next_page: string, tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/incremental/($incremental_resource)/sample" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Custom Object Record Export, Cursor Based
#
# GET /api/v2/incremental/custom_objects/{custom_object_key}/cursor
# operationId: IncrementalCustomObjectRecordExportCursor
export def "incremental-custom-objects-cursor IncrementalCustomObjectRecordExportCursor" [
  custom_object_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute. Required on the initial export request; not required on subsequent cursor-based pagination requests (e.g. 1332034771)
  --cursor: string # The cursor pointer to work with for all subsequent exports after the initial request
  --per-page: int # Number of records to return per page (default 1000, maximum 1000) (default: 1000)
  --filterexclude-deleted: string@bool-completer # If true, exclude deleted records from the export (default: false)
]: nothing -> record<after_cursor: string, after_url: string, before_cursor: string, before_url: string, custom_object_records: table<created_at: string, created_by_user_id: string, custom_object_fields: record, custom_object_key: string, external_id: string, id: string, name: string, updated_at: string, updated_by_user_id: string, url: string>, filter: record<exclude_deleted: bool>, meta: record<has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "filter[exclude_deleted]" $filterexclude_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/incremental/custom_objects/($custom_object_key)/cursor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Organization Export
#
# GET /api/v2/incremental/organizations
# operationId: IncrementalOrganizationExport
export def "incremental-organizations IncrementalOrganizationExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute (e.g. 1332034771)
  --per-page: int # The number of records to return per page
]: nothing -> record<count: int, end_of_stream: bool, end_time: int, next_page: string, organizations: table<created_at: string, details: string, domain_names: list, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Attributes Values Export
#
# GET /api/v2/incremental/routing/attribute_values
# operationId: IncrementalSkilBasedRoutingAttributeValuesExport
export def "incremental-routing-attribute-values IncrementalSkilBasedRoutingAttributeValuesExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<attribute_id: string, id: string, name: string, time: string, type: string>, attributes: table<id: string, name: string, time: string, type: string>, count: int, end_time: int, instance_values: table<attribute_value_id: string, id: string, instance_id: string, time: string, type: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/incremental/routing/attribute_values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Attributes Export
#
# GET /api/v2/incremental/routing/attributes
# operationId: IncrementalSkilBasedRoutingAttributesExport
export def "incremental-routing-attributes IncrementalSkilBasedRoutingAttributesExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<attribute_id: string, id: string, name: string, time: string, type: string>, attributes: table<id: string, name: string, time: string, type: string>, count: int, end_time: int, instance_values: table<attribute_value_id: string, id: string, instance_id: string, time: string, type: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/incremental/routing/attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Instance Values Export
#
# GET /api/v2/incremental/routing/instance_values
# operationId: IncrementalSkilBasedRoutingInstanceValuesExport
export def "incremental-routing-instance-values IncrementalSkilBasedRoutingInstanceValuesExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<attribute_id: string, id: string, name: string, time: string, type: string>, attributes: table<id: string, name: string, time: string, type: string>, count: int, end_time: int, instance_values: table<attribute_value_id: string, id: string, instance_id: string, time: string, type: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/incremental/routing/instance_values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Ticket Event Export
#
# GET /api/v2/incremental/ticket_events
# operationId: IncrementalTicketEvents
export def "incremental-ticket-events IncrementalTicketEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. Supports `comment_events` to include full comment data in the response.  (e.g. comment_events)
]: nothing -> record<count: int, end_of_stream: bool, end_time: int, next_page: string, ticket_events: table<deleted: bool, id: int, instance_id: int, metric: string, ticket_id: int, time: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/ticket_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Metric Events
#
# GET /api/v2/incremental/ticket_metric_events
# operationId: ListTicketMetricEvents
export def "incremental-ticket-metric-events ListTicketMetricEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The Unix UTC epoch time of the oldest event you're interested in. Example: 1332034771. (e.g. 1332034771)
  --include-changes: string@bool-completer # This optional parameter enhances incremental data retrieval, delivering a consistent and accurate representation of data changes.
  --exclude-deleted: string@bool-completer # When true, excludes ticket metric events for deleted tickets. Use this to avoid receiving events for tickets that are deleted.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "include_changes" $include_changes "scalar") (serialize-qp "exclude_deleted" $exclude_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/ticket_metric_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Ticket Export, Time Based
#
# GET /api/v2/incremental/tickets
# operationId: IncrementalTicketExportTime
export def "incremental-tickets IncrementalTicketExportTime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute (e.g. 1332034771)
  --support-type-scope: string # Lists tickets by support type. Possible values are "all", "agent", or "ai_agent". Defaults to "agent"
]: nothing -> record<count: int, end_of_stream: bool, end_time: int, next_page: string, tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "support_type_scope" $support_type_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental Ticket Export, Cursor Based
#
# GET /api/v2/incremental/tickets/cursor
# operationId: IncrementalTicketExportCursor
export def "incremental-tickets-cursor IncrementalTicketExportCursor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute. Required on the initial export request; not required on subsequent cursor-based pagination requests (e.g. 1332034771)
  --cursor: string # The cursor pointer to work with for all subsequent exports after the initial request
  --support-type-scope: string # Lists tickets by support type. Possible values are "all", "agent", or "ai_agent". Defaults to "agent"
]: nothing -> record<after_cursor: string, after_url: string, before_cursor: string, before_url: string, end_of_stream: bool, tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "support_type_scope" $support_type_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/tickets/cursor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental User Export, Time Based
#
# GET /api/v2/incremental/users
# operationId: IncrementalUserExportTime
export def "incremental-users IncrementalUserExportTime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute (e.g. 1332034771)
  --per-page: int # The number of records to return per page
]: nothing -> record<count: int, end_of_stream: bool, end_time: int, next_page: string, users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incremental User Export, Cursor Based
#
# GET /api/v2/incremental/users/cursor
# operationId: IncrementalUserExportCursor
export def "incremental-users-cursor IncrementalUserExportCursor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The time to start the incremental export from. Must be at least one minute in the past. Data isn't provided for the most recent minute. Required on the initial export request; not required on subsequent cursor-based pagination requests (e.g. 1332034771)
  --cursor: string # The cursor pointer to work with for all subsequent exports after the initial request
  --per-page: int # The number of records to return per page
]: nothing -> record<after_cursor: string, after_url: string, before_cursor: string, before_url: string, end_of_stream: bool, users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/incremental/users/cursor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Asset Types
#
# GET /api/v2/it_asset_management/asset_types
# operationId: ListItamAssetTypes
export def "it-asset-management-asset-types ListItamAssetTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asset_types: table<created_at: string, created_by_user_id: int, description: string, external_id: string, field_keys: list, hierarchy_depth: int, id: string, is_standard: bool, name: string, parent_id: string, updated_at: string, updated_by_user_id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/asset_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Asset Type
#
# POST /api/v2/it_asset_management/asset_types
# operationId: CreateItamAssetType
# --asset_type shape: {description?: string, external_id?: string, field_keys?: list, parent_id: string}
export def "it-asset-management-asset-types CreateItamAssetType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset-type: record # shape: {description?: string, external_id?: string, field_keys?: list, parent_id: string}
]: any -> record<asset_type: record<created_at: string, created_by_user_id: int, description: string, external_id: string, field_keys: list<string>, hierarchy_depth: int, id: string, is_standard: bool, name: string, parent_id: string, updated_at: string, updated_by_user_id: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/asset_types")
  let body = {asset_type: $asset_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Asset Type
#
# GET /api/v2/it_asset_management/asset_types/{asset_type_id}
# operationId: ShowItamAssetType
export def "it-asset-management-asset-types ShowItamAssetType" [
  asset_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asset_type: record<created_at: string, created_by_user_id: int, description: string, external_id: string, field_keys: list<string>, hierarchy_depth: int, id: string, is_standard: bool, name: string, parent_id: string, updated_at: string, updated_by_user_id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Asset Type
#
# PATCH /api/v2/it_asset_management/asset_types/{asset_type_id}
# operationId: UpdateItamAssetType
export def "it-asset-management-asset-types UpdateItamAssetType" [
  asset_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asset_type: record<created_at: string, created_by_user_id: int, description: string, external_id: string, field_keys: list<string>, hierarchy_depth: int, id: string, is_standard: bool, name: string, parent_id: string, updated_at: string, updated_by_user_id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Asset Type
#
# DELETE /api/v2/it_asset_management/asset_types/{asset_type_id}
# operationId: DeleteItamAssetType
export def "it-asset-management-asset-types DeleteItamAssetType" [
  asset_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Asset Fields
#
# GET /api/v2/it_asset_management/asset_types/{asset_type_id}/fields
# operationId: ListItamAssetTypeFields
export def "it-asset-management-asset-types-fields ListItamAssetTypeFields" [
  asset_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)/fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Asset Field
#
# POST /api/v2/it_asset_management/asset_types/{asset_type_id}/fields
# operationId: CreateItamAssetTypeField
export def "it-asset-management-asset-types-fields CreateItamAssetTypeField" [
  asset_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: record
]: any -> record<field: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)/fields")
  let body = {field: $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Asset Field
#
# GET /api/v2/it_asset_management/asset_types/{asset_type_id}/fields/{asset_type_field_id}
# operationId: ShowItamAssetTypeField
export def "it-asset-management-asset-types-fields ShowItamAssetTypeField" [
  asset_type_id: string
  asset_type_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)/fields/($asset_type_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Asset Field
#
# PATCH /api/v2/it_asset_management/asset_types/{asset_type_id}/fields/{asset_type_field_id}
# operationId: UpdateItamAssetTypeField
export def "it-asset-management-asset-types-fields UpdateItamAssetTypeField" [
  asset_type_id: string
  asset_type_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)/fields/($asset_type_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Asset Field
#
# DELETE /api/v2/it_asset_management/asset_types/{asset_type_id}/fields/{asset_type_field_id}
# operationId: DeleteItamAssetTypeField
export def "it-asset-management-asset-types-fields DeleteItamAssetTypeField" [
  asset_type_id: string
  asset_type_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/asset_types/($asset_type_id)/fields/($asset_type_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assets
#
# GET /api/v2/it_asset_management/assets
# operationId: ListItamAssets
export def "it-asset-management-assets ListItamAssets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filterids: string # Optional comma-separated list of ids to filter assets by. If one or more ids are specified, only matching assets are returned. The ids must be unique and are case sensitive.
  --filterexternal-ids: string # Optional comma-separated list of external ids to filter assets by. If one or more external ids are specified, only matching assets are returned. The external ids must be unique and are case sensitive.
]: nothing -> record<assets: table<asset_tag: string, asset_type_id: string, created_at: string, custom_field_values: record, external_id: string, id: string, location_id: string, manufacturer: string, model: string, name: string, notes: string, organization_id: int, purchase_cost: float, purchase_date: string, serial_number: string, status_id: string, updated_at: string, url: string, user_id: int, vendor: string, warranty_expiration: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[ids]" $filterids "scalar") (serialize-qp "filter[external_ids]" $filterexternal_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/it_asset_management/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Asset
#
# POST /api/v2/it_asset_management/assets
# operationId: CreateItamAsset
# --asset shape: {asset_tag?: string, custom_field_values?: record, external_id?: string, location_id?: string, manufacturer?: string, model?: string, name: string, notes?: string, organization_id?: int, purchase_cost?: float, purchase_date?: string, serial_number?: string, status_id: string, user_id?: int, vendor?: string, warranty_expiration?: string}
export def "it-asset-management-assets CreateItamAsset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: record # shape: {asset_tag?: string, custom_field_values?: record, external_id?: string, location_id?: string, manufacturer?: string, model?: string, name: string, notes?: string, organization_id?: int, purchase_cost?: float, purchase_date?: string, serial_number?: string, status_id: string, user_id?: int, vendor?: string, warranty_expiration?: string}
]: any -> record<asset: record<asset_tag: string, asset_type_id: string, created_at: string, custom_field_values: record, external_id: string, id: string, location_id: string, manufacturer: string, model: string, name: string, notes: string, organization_id: int, purchase_cost: float, purchase_date: string, serial_number: string, status_id: string, updated_at: string, url: string, user_id: int, vendor: string, warranty_expiration: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/assets")
  let body = {asset: $asset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Asset
#
# GET /api/v2/it_asset_management/assets/{asset_id}
# operationId: ShowItamAsset
export def "it-asset-management-assets ShowItamAsset" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asset: record<asset_tag: string, asset_type_id: string, created_at: string, custom_field_values: record, external_id: string, id: string, location_id: string, manufacturer: string, model: string, name: string, notes: string, organization_id: int, purchase_cost: float, purchase_date: string, serial_number: string, status_id: string, updated_at: string, url: string, user_id: int, vendor: string, warranty_expiration: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Asset
#
# PATCH /api/v2/it_asset_management/assets/{asset_id}
# operationId: UpdateItamAsset
export def "it-asset-management-assets UpdateItamAsset" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asset: record<asset_tag: string, asset_type_id: string, created_at: string, custom_field_values: record, external_id: string, id: string, location_id: string, manufacturer: string, model: string, name: string, notes: string, organization_id: int, purchase_cost: float, purchase_date: string, serial_number: string, status_id: string, updated_at: string, url: string, user_id: int, vendor: string, warranty_expiration: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Asset
#
# DELETE /api/v2/it_asset_management/assets/{asset_id}
# operationId: DeleteItamAsset
export def "it-asset-management-assets DeleteItamAsset" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Asset Bulk Jobs
#
# POST /api/v2/it_asset_management/assets/jobs
# operationId: ItamAssetBulkJobs
# --job shape: {action?: "create"|"update"|"delete"|"delete_by_external_id", items?: list}
export def "it-asset-management-assets-jobs ItamAssetBulkJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --job: record # shape: {action?: "create"|"update"|"delete"|"delete_by_external_id", items?: list}
]: any -> record<job_status: record<id: string, message: string, progress: int, results: list<record>, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/assets/jobs")
  let body = {job: $job} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Assets
#
# GET /api/v2/it_asset_management/assets/search
# operationId: SearchItamAssets
export def "it-asset-management-assets-search SearchItamAssets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Lists the search terms, separated by a space, used to identify the asset records.  (e.g. laptop)
  --qp-sort: string # Orders the returned records by: `name`, `created_at`, or `updated_at`. Defaults to sorting by relevance. Prepending `-` (`-name`, `-created_at`, or `-updated_at`) sorts the results in descending order by that value.
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pagesize: int # Specifies how many assets should be returned in the response, up to 100 assets per page.
]: nothing -> record<assets: table<asset_tag: string, asset_type_id: string, created_at: string, custom_field_values: record, external_id: string, id: string, location_id: string, manufacturer: string, model: string, name: string, notes: string, organization_id: int, purchase_cost: float, purchase_date: string, serial_number: string, status_id: string, updated_at: string, url: string, user_id: int, vendor: string, warranty_expiration: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/it_asset_management/assets/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filtered Search of Assets
#
# POST /api/v2/it_asset_management/assets/search
# operationId: FilteredSearchItamAssets
# --filter shape: {field_key?: record}
export def "it-asset-management-assets-search FilteredSearchItamAssets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Lists the search terms, separated by a space, used to identify the asset records.  (e.g. laptop)
  --qp-sort: string # Orders the returned records by: `name`, `created_at`, or `updated_at`. Defaults to sorting by relevance. Prepending `-` (`-name`, `-created_at`, or `-updated_at`) sorts the results in descending order by that value.
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request
  --pagesize: int # Specifies how many assets should be returned in the response, up to 100 assets per page.
  --filter: record # shape: {field_key?: record}
]: any -> record<assets: table<asset_tag: string, asset_type_id: string, created_at: string, custom_field_values: record, external_id: string, id: string, location_id: string, manufacturer: string, model: string, name: string, notes: string, organization_id: int, purchase_cost: float, purchase_date: string, serial_number: string, status_id: string, updated_at: string, url: string, user_id: int, vendor: string, warranty_expiration: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/it_asset_management/assets/search" $qp)
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Asset Locations
#
# GET /api/v2/it_asset_management/locations
# operationId: ListItamLocations
export def "it-asset-management-locations ListItamLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/locations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Asset Location
#
# POST /api/v2/it_asset_management/locations
# operationId: CreateItamLocation
# --location shape: {external_id?: string, name: string}
export def "it-asset-management-locations CreateItamLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: record # shape: {external_id?: string, name: string}
]: any -> record<location: record<created_at: string, external_id: string, id: string, name: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/locations")
  let body = {location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Asset Location
#
# GET /api/v2/it_asset_management/locations/{location_id}
# operationId: ShowItamLocation
export def "it-asset-management-locations ShowItamLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<location: record<created_at: string, external_id: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/locations/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Asset Location
#
# PATCH /api/v2/it_asset_management/locations/{location_id}
# operationId: UpdateItamLocation
export def "it-asset-management-locations UpdateItamLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<location: record<created_at: string, external_id: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/locations/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Asset Location
#
# DELETE /api/v2/it_asset_management/locations/{location_id}
# operationId: DeleteItamLocation
export def "it-asset-management-locations DeleteItamLocation" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/locations/($location_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Asset Statuses
#
# GET /api/v2/it_asset_management/statuses
# operationId: ListItamStatuses
export def "it-asset-management-statuses ListItamStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<statuses: table<created_at: string, external_id: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/it_asset_management/statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Asset Status
#
# GET /api/v2/it_asset_management/statuses/{status_id}
# operationId: ShowItamStatus
export def "it-asset-management-statuses ShowItamStatus" [
  status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: record<created_at: string, external_id: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/it_asset_management/statuses/($status_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Job Statuses
#
# GET /api/v2/job_statuses
# operationId: ListJobStatuses
export def "job-statuses ListJobStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
]: nothing -> record<job_statuses: table<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/job_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Job Status
#
# GET /api/v2/job_statuses/{job_status_id}
# operationId: ShowJobStatus
export def "job-statuses ShowJobStatus" [
  job_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/job_statuses/($job_status_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Job Statuses
#
# GET /api/v2/job_statuses/show_many
# operationId: ShowManyJobStatuses
export def "job-statuses-show-many ShowManyJobStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of job status ids. (e.g. 8b726e606741012ffc2d782bcb7848fe,e7665094164c498781ebe4c8db6d2af5)
]: nothing -> record<job_statuses: table<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/job_statuses/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Locales
#
# GET /api/v2/locales
# operationId: ListLocales
export def "locales ListLocales" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locales: table<created_at: string, id: int, locale: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/locales")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Locale
#
# GET /api/v2/locales/{locale_id}
# operationId: ShowLocaleById
export def "locales ShowLocaleById" [
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locale: record<created_at: string, id: int, locale: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/locales/($locale_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Locales for Agent
#
# GET /api/v2/locales/agent
# operationId: ListLocalesForAgent
export def "locales-agent ListLocalesForAgent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locales: table<created_at: string, id: int, locale: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/locales/agent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Current Locale
#
# GET /api/v2/locales/current
# operationId: ShowCurrentLocale
export def "locales-current ShowCurrentLocale" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locale: record<created_at: string, id: int, locale: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/locales/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detect Best Language for User
#
# GET /api/v2/locales/detect_best_locale
# operationId: DetectBestLocale
export def "locales-detect-best-locale DetectBestLocale" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locale: record<created_at: string, id: int, locale: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/locales/detect_best_locale")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Available Public Locales
#
# GET /api/v2/locales/public
# operationId: ListAvailablePublicLocales
export def "locales-public ListAvailablePublicLocales" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locales: table<created_at: string, id: int, locale: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/locales/public")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Macros
#
# GET /api/v2/macros
# operationId: ListMacros
export def "macros ListMacros" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_7d)
  --access: string # Filter macros by access. Possible values are "personal", "agents", "shared", or "account". The "agents" value returns all personal macros for the account's agents and is only available to admins. (e.g. personal)
  --active: string@bool-completer # Filter by active macros if true or inactive macros if false (e.g. true)
  --category: int # Filter macros by category (e.g. 25)
  --group-id: int # Filter macros by group (format: int64, e.g. 25)
  --only-viewable: string@bool-completer # If true, returns only macros that can be applied to tickets. If false, returns all macros the current user can manage. Default is false (e.g. false)
  --sort-by: string # Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", "usage_7d", or "usage_30d". Defaults to alphabetical (e.g. alphabetical)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. asc)
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "only_viewable" $only_viewable "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/macros" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Macro
#
# POST /api/v2/macros
# operationId: CreateMacro
# --macro shape: {actions: list, active?: bool, description?: string, restriction?: record, title: string}
export def "macros CreateMacro" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --macro: record # shape: {actions: list, active?: bool, description?: string, restriction?: record, title: string}
]: any -> record<macro: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/macros")
  let body = {macro: $macro} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Macro
#
# GET /api/v2/macros/{macro_id}
# operationId: ShowMacro
export def "macros ShowMacro" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<macro: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/macros/($macro_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Macro
#
# PUT /api/v2/macros/{macro_id}
# operationId: UpdateMacro
# --macro shape: {actions: list, active?: bool, description?: string, restriction?: record, title: string}
export def "macros UpdateMacro" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --macro: record # shape: {actions: list, active?: bool, description?: string, restriction?: record, title: string}
]: any -> record<macro: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/macros/($macro_id)")
  let body = {macro: $macro} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Macro
#
# DELETE /api/v2/macros/{macro_id}
# operationId: DeleteMacro
export def "macros DeleteMacro" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/macros/($macro_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Changes to Ticket
#
# GET /api/v2/macros/{macro_id}/apply
# operationId: ShowChangesToTicket
export def "macros-apply ShowChangesToTicket" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --normalize-comment: string@bool-completer # If true, normalizes the newline formatting of the macro's comment to more closely match the formatting produced by the ticket comment editor
]: nothing -> record<result: record<ticket: record<assignee_id: int, comment: record, fields: record, group_id: int, id: int, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "normalize_comment" $normalize_comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/macros/($macro_id)/apply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Macro Attachments
#
# GET /api/v2/macros/{macro_id}/attachments
# operationId: ListMacroAttachments
export def "macros-attachments ListMacroAttachments" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<macro_attachments: table<content_type: string, content_url: string, created_at: string, filename: string, id: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/macros/($macro_id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Macro Attachment
#
# POST /api/v2/macros/{macro_id}/attachments
# operationId: CreateAssociatedMacroAttachment
export def "macros-attachments CreateAssociatedMacroAttachment" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<macro_attachment: record<content_type: string, content_url: string, created_at: string, filename: string, id: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/macros/($macro_id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Supported Actions for Macros
#
# GET /api/v2/macros/actions
# operationId: ListMacrosActions
export def "macros-actions ListMacrosActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<actions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/macros/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Active Macros
#
# GET /api/v2/macros/active
# operationId: ListActiveMacros
export def "macros-active ListActiveMacros" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_7d)
  --access: string # Filter macros by access. Possible values are "personal", "agents", "shared", or "account". The "agents" value returns all personal macros for the account's agents and is only available to admins. (e.g. personal)
  --category: int # Filter macros by category (e.g. 25)
  --group-id: int # Filter macros by group (format: int64, e.g. 25)
  --sort-by: string # Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", "usage_7d", or "usage_30d". Defaults to alphabetical (e.g. alphabetical)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. asc)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/macros/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Unassociated Macro Attachment
#
# POST /api/v2/macros/attachments
# operationId: CreateMacroAttachment
export def "macros-attachments CreateMacroAttachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<macro_attachment: record<content_type: string, content_url: string, created_at: string, filename: string, id: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/macros/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Macro Attachment
#
# GET /api/v2/macros/attachments/{attachment_id}
# operationId: ShowMacroAttachment
export def "macros-attachments ShowMacroAttachment" [
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<macro_attachment: record<content_type: string, content_url: string, created_at: string, filename: string, id: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/macros/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Macro Categories
#
# GET /api/v2/macros/categories
# operationId: ListMacroCategories
export def "macros-categories ListMacroCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/macros/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Macro Action Definitions
#
# GET /api/v2/macros/definitions
# operationId: ListMacroActionDefinitions
export def "macros-definitions ListMacroActionDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<actions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/macros/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Macros
#
# DELETE /api/v2/macros/destroy_many
# operationId: DeleteManyMacros
export def "macros-destroy-many DeleteManyMacros" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The IDs of the macros to delete (e.g. [1, 2, 3])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/macros/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Macro Replica
#
# GET /api/v2/macros/new
# operationId: ShowDerivedMacro
export def "macros-new ShowDerivedMacro" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --macro-id: int # The ID of the macro to replicate (format: int64, e.g. 25)
  --ticket-id: int # The ID of the ticket from which to build a macro replica (format: int64, e.g. 35436)
]: nothing -> record<macro: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "macro_id" $macro_id "scalar") (serialize-qp "ticket_id" $ticket_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/macros/new" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Macros
#
# GET /api/v2/macros/search
# operationId: SearchMacro
export def "macros-search SearchMacro" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_7d)
  --access: string # Filter macros by access. Possible values are "personal", "agents", "shared", or "account". The "agents" value returns all personal macros for the account's agents and is only available to admins. (e.g. personal)
  --active: string@bool-completer # Filter by active macros if true or inactive macros if false (e.g. true)
  --category: int # Filter macros by category (e.g. 25)
  --group-id: int # Filter macros by group (format: int64, e.g. 25)
  --only-viewable: string@bool-completer # If true, returns only macros that can be applied to tickets. If false, returns all macros the current user can manage. Default is false (e.g. false)
  --sort-by: string # Possible values are "alphabetical", "created_at", "updated_at", or "position". Defaults to alphabetical (e.g. alphabetical)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. asc)
  --qp-query: string # Query string used to find macros with matching titles (e.g. close)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "only_viewable" $only_viewable "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/macros/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Macros
#
# PUT /api/v2/macros/update_many
# operationId: UpdateManyMacros
# --macros item shape: {active?: bool, id: int, position?: int}
export def "macros-update-many UpdateManyMacros" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --macros: list # item shape: {active?: bool, id: int, position?: int}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/macros/update_many")
  let body = {macros: $macros} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Clients
#
# GET /api/v2/oauth/clients
# operationId: ListOAuthClients
export def "oauth-clients ListOAuthClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<clients: table<company: string, created_at: string, description: string, global: bool, id: int, identifier: string, kind: string, logo_url: string, name: string, redirect_uri: list, secret: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/oauth/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Client
#
# POST /api/v2/oauth/clients
# operationId: CreateOAuthClient
export def "oauth-clients CreateOAuthClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client: record<company: string, created_at: string, description: string, global: bool, id: int, identifier: string, kind: string, logo_url: string, name: string, redirect_uri: list<string>, secret: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/oauth/clients")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Client
#
# GET /api/v2/oauth/clients/{oauth_client_id}
# operationId: ShowClient
export def "oauth-clients ShowClient" [
  oauth_client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client: record<company: string, created_at: string, description: string, global: bool, id: int, identifier: string, kind: string, logo_url: string, name: string, redirect_uri: list<string>, secret: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/clients/($oauth_client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Client
#
# PUT /api/v2/oauth/clients/{oauth_client_id}
# operationId: UpdateClient
export def "oauth-clients UpdateClient" [
  oauth_client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client: record<company: string, created_at: string, description: string, global: bool, id: int, identifier: string, kind: string, logo_url: string, name: string, redirect_uri: list<string>, secret: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/clients/($oauth_client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Client
#
# DELETE /api/v2/oauth/clients/{oauth_client_id}
# operationId: DeleteClient
export def "oauth-clients DeleteClient" [
  oauth_client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/clients/($oauth_client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate Secret
#
# PUT /api/v2/oauth/clients/{oauth_client_id}/generate_secret
# operationId: ClientGenerateSecret
export def "oauth-clients-generate-secret ClientGenerateSecret" [
  oauth_client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client: record<company: string, created_at: string, description: string, global: bool, id: int, identifier: string, kind: string, logo_url: string, name: string, redirect_uri: list<string>, secret: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/clients/($oauth_client_id)/generate_secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Global OAuth Clients
#
# GET /api/v2/oauth/global_clients
# operationId: ListGlobalOAuthClients
export def "oauth-global-clients ListGlobalOAuthClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<global_clients: table<company: string, description: string, id: int, identifier: string, kind: string, logo_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/oauth/global_clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Global OAuth Client
#
# GET /api/v2/oauth/global_clients/{global_client_id}
# operationId: ShowGlobalClient
export def "oauth-global-clients ShowGlobalClient" [
  global_client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<global_client: record<company: string, description: string, id: int, identifier: string, kind: string, logo_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/global_clients/($global_client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Token summary for Global OAuth Clients
#
# GET /api/v2/oauth/global_clients/token_summary
# operationId: GlobalOAuthClientsTokenSummary
export def "oauth-global-clients-token-summary GlobalOAuthClientsTokenSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --global-client-id: int # The id of the global OAuth client (format: int64, e.g. 334556)
  --include-expired: string@bool-completer # If true, includes expired tokens in summary (e.g. true)
]: nothing -> record<global_clients: table<id: int, last_used_at: string, tokens_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "global_client_id" $global_client_id "scalar") (serialize-qp "include_expired" $include_expired "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/oauth/global_clients/token_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Tokens
#
# GET /api/v2/oauth/tokens
# operationId: ListOAuthTokens
export def "oauth-tokens ListOAuthTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<tokens: table<client_id: int, created_at: string, expires_at: string, id: int, refresh_token: string, refresh_token_expires_at: string, scopes: list, token: string, url: string, used_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/oauth/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Token
#
# POST /api/v2/oauth/tokens
# operationId: CreateOAuthToken
export def "oauth-tokens CreateOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: int # The id of the OAuth client (format: int64, e.g. 223443)
  --global-client-id: int # The id of the global OAuth client (format: int64, e.g. 334556)
  --all: string@bool-completer # A boolean that returns all OAuth tokens in the account. Requires admin role (e.g. true)
]: nothing -> record<token: record<client_id: int, created_at: string, expires_at: string, id: int, refresh_token: string, refresh_token_expires_at: string, scopes: list<string>, token: string, url: string, used_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "global_client_id" $global_client_id "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/oauth/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Token
#
# GET /api/v2/oauth/tokens/{oauth_token_id}
# operationId: ShowToken
export def "oauth-tokens ShowToken" [
  oauth_token_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: record<client_id: int, created_at: string, expires_at: string, id: int, refresh_token: string, refresh_token_expires_at: string, scopes: list<string>, token: string, url: string, used_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/tokens/($oauth_token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke Token
#
# DELETE /api/v2/oauth/tokens/{oauth_token_id}
# operationId: RevokeOAuthToken
export def "oauth-tokens RevokeOAuthToken" [
  oauth_token_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/oauth/tokens/($oauth_token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Current Token
#
# GET /api/v2/oauth/tokens/current
# operationId: ShowCurrentToken
export def "oauth-tokens-current ShowCurrentToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: record<client_id: int, created_at: string, expires_at: string, id: int, refresh_token: string, refresh_token_expires_at: string, scopes: list<string>, token: string, url: string, used_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/oauth/tokens/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke Current Token
#
# DELETE /api/v2/oauth/tokens/current
# operationId: RevokeCurrentOAuthToken
export def "oauth-tokens-current RevokeCurrentOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/oauth/tokens/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Fields
#
# GET /api/v2/organization_fields
# operationId: ListOrganizationFields
export def "organization-fields ListOrganizationFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --resolve-dc: string@bool-completer # If true, resolves dynamic content placeholders.
]: nothing -> record<count: int, next_page: string, organization_fields: list<record>, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "resolve_dc" $resolve_dc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organization_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization Field
#
# POST /api/v2/organization_fields
# operationId: CreateOrganizationField
export def "organization-fields CreateOrganizationField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organization_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Organization Field
#
# GET /api/v2/organization_fields/{organization_field_id}
# operationId: ShowOrganizationField
export def "organization-fields ShowOrganizationField" [
  organization_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_fields/($organization_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization Field
#
# PUT /api/v2/organization_fields/{organization_field_id}
# operationId: UpdateOrganizationField
export def "organization-fields UpdateOrganizationField" [
  organization_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_fields/($organization_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Organization Field
#
# DELETE /api/v2/organization_fields/{organization_field_id}
# operationId: DeleteOrganizationField
export def "organization-fields DeleteOrganizationField" [
  organization_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_fields/($organization_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Organization Field
#
# PUT /api/v2/organization_fields/reorder
# operationId: ReorderOrganizationField
export def "organization-fields-reorder ReorderOrganizationField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organization_fields/reorder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Memberships
#
# GET /api/v2/organization_memberships
# operationId: ListOrganizationMemberships
export def "organization-memberships ListOrganizationMemberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. Valid values: `users`, `organizations`.  (e.g. organizations)
]: nothing -> record<organization_memberships: table<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Membership
#
# POST /api/v2/organization_memberships
# operationId: CreateOrganizationMembership
export def "organization-memberships CreateOrganizationMembership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_membership: record<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organization_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Membership
#
# GET /api/v2/organization_memberships/{organization_membership_id}
# operationId: ShowOrganizationMembershipById
export def "organization-memberships ShowOrganizationMembershipById" [
  organization_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_membership: record<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_memberships/($organization_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Membership
#
# DELETE /api/v2/organization_memberships/{organization_membership_id}
# operationId: DeleteOrganizationMembership
export def "organization-memberships DeleteOrganizationMembership" [
  organization_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_memberships/($organization_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Many Memberships
#
# POST /api/v2/organization_memberships/create_many
# operationId: CreateManyOrganizationMemberships
export def "organization-memberships-create-many CreateManyOrganizationMemberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organization_memberships/create_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Memberships
#
# DELETE /api/v2/organization_memberships/destroy_many
# operationId: DeleteManyOrganizationMemberships
export def "organization-memberships-destroy-many DeleteManyOrganizationMemberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The IDs of the organization memberships to delete
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organization_memberships/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Organization Merge
#
# GET /api/v2/organization_merges/{organization_merge_id}
# operationId: ShowOrganizationMerge
export def "organization-merges ShowOrganizationMerge" [
  organization_merge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_merge: record<id: string, loser_id: int, status: string, url: string, winner_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_merges/($organization_merge_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Subscriptions
#
# GET /api/v2/organization_subscriptions
# operationId: ListOrganizationSubscriptions
export def "organization-subscriptions ListOrganizationSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organization_subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization Subscription
#
# POST /api/v2/organization_subscriptions
# operationId: CreateOrganizationSubscription
# --organization_subscription shape: {organization_id?: int, user_id?: int}
export def "organization-subscriptions CreateOrganizationSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-subscription: record # shape: {organization_id?: int, user_id?: int}
]: any -> record<organization_subscription: record<created_at: string, id: int, organization_id: int, user_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organization_subscriptions")
  let body = {organization_subscription: $organization_subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Organization Subscription
#
# GET /api/v2/organization_subscriptions/{organization_subscription_id}
# operationId: ShowOrganizationSubscription
export def "organization-subscriptions ShowOrganizationSubscription" [
  organization_subscription_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_subscription: record<created_at: string, id: int, organization_id: int, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_subscriptions/($organization_subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Organization Subscription
#
# DELETE /api/v2/organization_subscriptions/{organization_subscription_id}
# operationId: DeleteOrganizationSubscription
export def "organization-subscriptions DeleteOrganizationSubscription" [
  organization_subscription_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organization_subscriptions/($organization_subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organizations
#
# GET /api/v2/organizations
# operationId: ListOrganizations
export def "organizations ListOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<count: int, next_page: string, organizations: table<created_at: string, details: string, domain_names: list, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list, updated_at: string, url: string>, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization
#
# POST /api/v2/organizations
# operationId: CreateOrganization
# --organization shape: {details?: string, domain_names?: list, external_id?: string, group_id?: int, id?: int, name: string, notes?: string, organization_fields?: record, shared_comments?: bool, shared_tickets?: bool, tags?: list}
export def "organizations CreateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization: record # e.g. {created_at: 2009-07-20T22:55:29Z, details: This is a kind of organization, domain_names: [example.com, test.com], external_id: ABC123, group_id: , id: 35436, name: One Organization, notes: , organization_fields: {org_decimal: 5.2, org_dropdown: option_1}, shared_comments: true, shared_tickets: true, tags: [enterprise, other_tag], updated_at: 2011-05-05T10:38:52Z, url: https://company.zendesk.com/api/v2/organizations/35436} — shape: {details?: string, domain_names?: list, external_id?: string, group_id?: int, id?: int, name: string, notes?: string, organization_fields?: record, shared_comments?: bool, shared_tickets?: bool, tags?: list}
]: any -> record<organization: record<created_at: string, details: string, domain_names: list<string>, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list<string>, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organizations")
  let body = {organization: $organization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Organization
#
# GET /api/v2/organizations/{organization_id}
# operationId: ShowOrganization
export def "organizations ShowOrganization" [
  organization_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Include additional related data. Supported values: `lookup_relationship_fields`.
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<organization: record<created_at: string, details: string, domain_names: list<string>, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list<string>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization
#
# PUT /api/v2/organizations/{organization_id}
# operationId: UpdateOrganization
export def "organizations UpdateOrganization" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization: record<created_at: string, details: string, domain_names: list<string>, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list<string>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Organization
#
# DELETE /api/v2/organizations/{organization_id}
# operationId: DeleteOrganization
export def "organizations DeleteOrganization" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge Organization With Another Organization
#
# POST /api/v2/organizations/{organization_id}/merge
# operationId: CreateOrganizationMerge
# --organization_merge shape: {winner_id?: int}
export def "organizations-merge CreateOrganizationMerge" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-merge: record # shape: {winner_id?: int}
]: any -> record<organization_merge: record<id: string, loser_id: int, status: string, url: string, winner_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/merge")
  let body = {organization_merge: $organization_merge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Organization Merges
#
# GET /api/v2/organizations/{organization_id}/merges
# operationId: ListOrganizationMerges
export def "organizations-merges ListOrganizationMerges" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_merges: table<id: string, loser_id: int, status: string, url: string, winner_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/merges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Memberships by Organization
#
# GET /api/v2/organizations/{organization_id}/organization_memberships
# operationId: ListOrganizationMembershipsByOrganization
export def "organizations-organization-memberships ListOrganizationMembershipsByOrganization" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_memberships: table<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/organization_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Organization's Related Information
#
# GET /api/v2/organizations/{organization_id}/related
# operationId: OrganizationRelated
export def "organizations-related OrganizationRelated" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_related: record<tickets_count: int, users_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/related")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Requests
#
# GET /api/v2/organizations/{organization_id}/requests
# operationId: ListOrganizationRequests
export def "organizations-requests ListOrganizationRequests" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Possible values are "updated_at", "created_at"
  --sort-order: string # One of "asc", "desc". Defaults to "asc"
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Subscriptions By Organization
#
# GET /api/v2/organizations/{organization_id}/subscriptions
# operationId: ListOrganizationSubscriptionsByOrganization
export def "organizations-subscriptions ListOrganizationSubscriptionsByOrganization" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Tags
#
# GET /api/v2/organizations/{organization_id}/tags
# operationId: ListOrganizationTags
export def "organizations-tags ListOrganizationTags" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Organization Tags
#
# POST /api/v2/organizations/{organization_id}/tags
# operationId: SetOrganizationTags
export def "organizations-tags SetOrganizationTags" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Organization Tags
#
# PUT /api/v2/organizations/{organization_id}/tags
# operationId: AddOrganizationTags
export def "organizations-tags AddOrganizationTags" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Organization Tags
#
# DELETE /api/v2/organizations/{organization_id}/tags
# operationId: RemoveOrganizationTags
export def "organizations-tags RemoveOrganizationTags" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Tickets
#
# GET /api/v2/organizations/{organization_id}/tickets
# operationId: ListOrganizationTickets
export def "organizations-tickets ListOrganizationTickets" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/tickets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Organization Tickets
#
# GET /api/v2/organizations/{organization_id}/tickets/count
# operationId: CountOrganizationTickets
export def "organizations-tickets-count CountOrganizationTickets" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/tickets/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organization Users
#
# GET /api/v2/organizations/{organization_id}/users
# operationId: ListOrganizationUsers
export def "organizations-users ListOrganizationUsers" [
  organization_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # Filters the results by role. Possible values are "end-user", "agent", "admin", or a custom role name  (e.g. agent)
  --role: string # Filters the results by more than one role using the format `role[]={role}&role[]={role}`  (e.g. agent)
  --permission-set: int # For custom roles which is available on the Enterprise plan and above. You can only filter by one role ID per request (format: int64, e.g. 123)
  --external-id: string # List users by external id. External id has to be unique for each user under the same account. (e.g. abc)
  --sort-by: string@sort-by-completer-1 # The field to sort users by
  --sort-order: string@sort-order-completer # The sort order (default: asc)
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "role[]" $role "scalar") (serialize-qp "permission_set" $permission_set "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Organization Users
#
# GET /api/v2/organizations/{organization_id}/users/count
# operationId: CountOrganizationUsers
export def "organizations-users-count CountOrganizationUsers" [
  organization_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # Filters the results by role. Possible values are "end-user", "agent", "admin", or a custom role name  (e.g. agent)
  --role: string # Filters the results by more than one role using the format `role[]={role}&role[]={role}`  (e.g. agent)
  --permission-set: int # For custom roles which is available on the Enterprise plan and above. You can only filter by one role ID per request (format: int64, e.g. 123)
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "role[]" $role "scalar") (serialize-qp "permission_set" $permission_set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/organizations/($organization_id)/users/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Autocomplete Organizations
#
# GET /api/v2/organizations/autocomplete
# operationId: AutocompleteOrganizations
export def "organizations-autocomplete AutocompleteOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A substring of an organization to search for (e.g. imp)
  --field-id: string # The id of a lookup relationship field.  The type of field is determined by the `source` param
  --qp-source: string # If a `field_id` is provided, this specifies the type of the field. For example, if the field is on a "zen:user", it references a field on a user
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<count: int, next_page: string, organizations: table<created_at: string, details: string, domain_names: list, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list, updated_at: string, url: string>, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "field_id" $field_id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Organizations
#
# GET /api/v2/organizations/count
# operationId: CountOrganizations
export def "organizations-count CountOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Many Organizations
#
# POST /api/v2/organizations/create_many
# operationId: CreateManyOrganizations
export def "organizations-create-many CreateManyOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organizations/create_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Or Update Organization
#
# POST /api/v2/organizations/create_or_update
# operationId: CreateOrUpdateOrganization
export def "organizations-create-or-update CreateOrUpdateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization: record<created_at: string, details: string, domain_names: list<string>, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list<string>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/organizations/create_or_update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Organizations
#
# DELETE /api/v2/organizations/destroy_many
# operationId: DeleteManyOrganizations
export def "organizations-destroy-many DeleteManyOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A list of organization ids (e.g. 35436,20057623)
  --external-ids: string # A list of external ids (e.g. 1764,42156)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "external_ids" $external_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Organizations
#
# GET /api/v2/organizations/search
# operationId: SearchOrganizations
export def "organizations-search SearchOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-id: int # The external id of an organization (e.g. 1234)
  --name: string # The name of an organization (e.g. ACME Incorporated)
]: nothing -> record<count: int, next_page: string, organizations: table<created_at: string, details: string, domain_names: list, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list, updated_at: string, url: string>, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_id" $external_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Organizations
#
# GET /api/v2/organizations/show_many
# operationId: ShowManyOrganizations
export def "organizations-show-many ShowManyOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A list of organization ids (e.g. 35436,20057623)
  --external-ids: string # A list of external ids (e.g. 1764,42156)
]: nothing -> record<count: int, next_page: string, organizations: table<created_at: string, details: string, domain_names: list, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list, updated_at: string, url: string>, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "external_ids" $external_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Organizations
#
# PUT /api/v2/organizations/update_many
# operationId: UpdateManyOrganizations
export def "organizations-update-many UpdateManyOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A list of organization ids (e.g. 35436,20057623)
  --external-ids: string # A list of external ids (e.g. 1764,42156)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "external_ids" $external_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/organizations/update_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Problems
#
# GET /api/v2/problems
# operationId: ListTicketProblems
export def "problems ListTicketProblems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/problems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Autocomplete Problems
#
# POST /api/v2/problems/autocomplete
# operationId: AutocompleteProblems
export def "problems-autocomplete AutocompleteProblems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The text to search for
  --text: string # The text to search for
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/problems/autocomplete" $qp)
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Unregister Push Notification Devices
#
# POST /api/v2/push_notification_devices/destroy_many
# operationId: PushNotificationDevices
export def "push-notification-devices-destroy-many PushNotificationDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --push-notification-devices: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/push_notification_devices/destroy_many")
  let body = {push_notification_devices: $push_notification_devices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List queues
#
# GET /api/v2/queues
# operationId: ListQueues
export def "queues ListQueues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queues: table<created_at: string, definition: record, description: string, id: string, name: string, order: int, primary_groups: record, priority: int, secondary_groups: record, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/queues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Queue
#
# POST /api/v2/queues
# operationId: CreateQueue
export def "queues CreateQueue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queue: record<created_at: string, definition: record<all: list, any: list>, description: string, id: string, name: string, order: int, primary_groups: record<count: int, groups: list>, priority: int, secondary_groups: record<count: int, groups: list>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/queues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Queue
#
# GET /api/v2/queues/{queue_id}
# operationId: ShowQueueById
export def "queues ShowQueueById" [
  queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queue: record<created_at: string, definition: record<all: list, any: list>, description: string, id: string, name: string, order: int, primary_groups: record<count: int, groups: list>, priority: int, secondary_groups: record<count: int, groups: list>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/queues/($queue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Queue
#
# PUT /api/v2/queues/{queue_id}
# operationId: UpdateQueue
export def "queues UpdateQueue" [
  queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queue: record<created_at: string, definition: record<all: list, any: list>, description: string, id: string, name: string, order: int, primary_groups: record<count: int, groups: list>, priority: int, secondary_groups: record<count: int, groups: list>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/queues/($queue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Queue
#
# DELETE /api/v2/queues/{queue_id}
# operationId: DeleteQueue
export def "queues DeleteQueue" [
  queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/queues/($queue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Queue Definitions
#
# GET /api/v2/queues/definitions
# operationId: ListQueueDefinitions
export def "queues-definitions ListQueueDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<conditions_all: list<record>, conditions_any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/queues/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Queues
#
# PATCH /api/v2/queues/order
# operationId: ReorderQueues
export def "queues-order ReorderQueues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/queues/order")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Support Addresses
#
# GET /api/v2/recipient_addresses
# operationId: ListSupportAddresses
export def "recipient-addresses ListSupportAddresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include: string # A comma-separated list of sideloads to include in the response.
]: nothing -> record<recipient_addresses: table<brand_id: int, cname_status: string, created_at: string, default: bool, dns_results: string, domain_verification_code: string, domain_verification_status: string, email: string, forwarding_status: string, id: int, name: string, spf_status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/recipient_addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Support Address
#
# POST /api/v2/recipient_addresses
# operationId: CreateSupportAddress
export def "recipient-addresses CreateSupportAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recipient_address: record<brand_id: int, cname_status: string, created_at: string, default: bool, dns_results: string, domain_verification_code: string, domain_verification_status: string, email: string, forwarding_status: string, id: int, name: string, spf_status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/recipient_addresses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Support Address
#
# GET /api/v2/recipient_addresses/{support_address_id}
# operationId: ShowSupportAddress
export def "recipient-addresses ShowSupportAddress" [
  support_address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recipient_address: record<brand_id: int, cname_status: string, created_at: string, default: bool, dns_results: string, domain_verification_code: string, domain_verification_status: string, email: string, forwarding_status: string, id: int, name: string, spf_status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/recipient_addresses/($support_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Support Address
#
# PUT /api/v2/recipient_addresses/{support_address_id}
# operationId: UpdateSupportAddress
export def "recipient-addresses UpdateSupportAddress" [
  support_address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recipient_address: record<brand_id: int, cname_status: string, created_at: string, default: bool, dns_results: string, domain_verification_code: string, domain_verification_status: string, email: string, forwarding_status: string, id: int, name: string, spf_status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/recipient_addresses/($support_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Support Address
#
# DELETE /api/v2/recipient_addresses/{support_address_id}
# operationId: DeleteRecipientAddress
export def "recipient-addresses DeleteRecipientAddress" [
  support_address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/recipient_addresses/($support_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Support Address Forwarding
#
# PUT /api/v2/recipient_addresses/{support_address_id}/verify
# operationId: VerifySupportAddressForwarding
export def "recipient-addresses-verify VerifySupportAddressForwarding" [
  support_address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/recipient_addresses/($support_address_id)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filter Definitions
#
# GET /api/v2/relationships/definitions/{target_type}
# operationId: GetRelationshipFilterDefinitions
export def "relationships-definitions GetRelationshipFilterDefinitions" [
  target_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-type: string # The source type for which you would like to see filter definitions. The options are "zen:user", "zen:ticket", and "zen:organization"  (e.g. zen:user)
]: nothing -> record<definitions: record<conditions_all: list<record>, conditions_any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_type" $source_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/relationships/definitions/($target_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Remote Authentications
#
# GET /api/v2/remote_authentications
# operationId: ListRemoteAuthentications
export def "remote-authentications ListRemoteAuthentications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand-id: int # When brand separation is enabled, scopes the remote authentications to the specified brand.  (format: int64)
]: nothing -> record<remote_authentications: table<agent: bool, agent_primary: bool, auth_flow: string, auth_mode: int, auth_mode_name: string, auth_url: string, auto_discovery: bool, brand_id: int, can_display_button_to_end_users: bool, can_display_button_to_team_members: bool, client_id: string, end_user: bool, end_user_primary: bool, fingerprint: string, id: int, ip_ranges: string, is_active: bool, issuer_url: string, jwks_url: string, label: string, masked_client_secret: string, masked_secret: string, name: string, priority: int, remote_login_url: string, remote_logout_url: string, scope: string, token_url: string, update_external_ids: bool, user_info_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/remote_authentications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Requests
#
# GET /api/v2/requests
# operationId: ListRequests
export def "requests ListRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Possible values are "updated_at", "created_at"
  --sort-order: string # One of "asc", "desc". Defaults to "asc"
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Request
#
# POST /api/v2/requests
# operationId: CreateRequest
export def "requests CreateRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request: record<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list<int>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Request
#
# GET /api/v2/requests/{request_id}
# operationId: ShowRequest
export def "requests ShowRequest" [
  request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request: record<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list<int>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/requests/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Request
#
# PUT /api/v2/requests/{request_id}
# operationId: UpdateRequest
export def "requests UpdateRequest" [
  request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request: record<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list<int>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/requests/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Listing Comments
#
# GET /api/v2/requests/{request_id}/comments
# operationId: ListComments
export def "requests-comments ListComments" [
  request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Filters the comments from the given datetime
  --role: string # One of "agent", "end_user". If not specified it does not filter
]: nothing -> record<comments: table<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/requests/($request_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Getting Comments
#
# GET /api/v2/requests/{request_id}/comments/{ticket_comment_id}
# operationId: ShowComment
export def "requests-comments ShowComment" [
  request_id: int
  ticket_comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: record<add_short_url: bool, attachments: list<record>, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list<string>, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/requests/($request_id)/comments/($ticket_comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List CCD Requests
#
# GET /api/v2/requests/ccd
# operationId: ListCCDRequests
export def "requests-ccd ListCCDRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Possible values are "updated_at", "created_at"
  --sort-order: string # One of "asc", "desc". Defaults to "asc"
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/requests/ccd" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Open Requests
#
# GET /api/v2/requests/open
# operationId: ListOpenRequests
export def "requests-open ListOpenRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Possible values are "updated_at", "created_at"
  --sort-order: string # One of "asc", "desc". Defaults to "asc"
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/requests/open" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Requests
#
# GET /api/v2/requests/search
# operationId: SearchRequests
export def "requests-search SearchRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The syntax and matching logic for the string is detailed in the [Zendesk Support search reference](https://support.zendesk.com/hc/en-us/articles/4408886879258). See also [Query basics](/api-reference/ticketing/ticket-management/search/#query-basics) in the Tickets API doc.
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/requests/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Solved Requests
#
# GET /api/v2/requests/solved
# operationId: ListSolvedRequests
export def "requests-solved ListSolvedRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Possible values are "updated_at", "created_at"
  --sort-order: string # One of "asc", "desc". Defaults to "asc"
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/requests/solved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resource Collections
#
# GET /api/v2/resource_collections
# operationId: ListResourceCollections
export def "resource-collections ListResourceCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<count: int, next_page: string, previous_page: string, resource_collections: table<created_at: string, id: int, resources: list, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/resource_collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Resource Collection
#
# POST /api/v2/resource_collections
# operationId: CreateResourceCollection
export def "resource-collections CreateResourceCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/resource_collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Resource Collection
#
# GET /api/v2/resource_collections/{resource_collection_id}
# operationId: RetrieveResourceCollection
export def "resource-collections RetrieveResourceCollection" [
  resource_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resource_collection: record<created_at: string, id: int, resources: list<record>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/resource_collections/($resource_collection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Resource Collection
#
# PUT /api/v2/resource_collections/{resource_collection_id}
# operationId: UpdateResourceCollection
export def "resource-collections UpdateResourceCollection" [
  resource_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/resource_collections/($resource_collection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Resource Collection
#
# DELETE /api/v2/resource_collections/{resource_collection_id}
# operationId: DeleteResourceCollection
export def "resource-collections DeleteResourceCollection" [
  resource_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/resource_collections/($resource_collection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Agent Attribute Values
#
# GET /api/v2/routing/agents/{user_id}/instance_values
# operationId: ListAGentAttributeValues
export def "routing-agents-instance-values ListAGentAttributeValues" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<agent_skill_priority: string, attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/agents/($user_id)/instance_values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Agent Attribute Values
#
# POST /api/v2/routing/agents/{user_id}/instance_values
# operationId: SetAgentAttributeValues
export def "routing-agents-instance-values SetAgentAttributeValues" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/agents/($user_id)/instance_values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Attribute Values for Many Agents
#
# GET /api/v2/routing/agents/instance_values
# operationId: ListManyAgentsAttributeValues
export def "routing-agents-instance-values ListManyAgentsAttributeValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filteragent-ids: string # A comma-separated list of agent ids (e.g. 224,225)
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request.
  --pagesize: int # The number of items to return per page (format: int32)
]: nothing -> record<count: int, instance_values: table<agent_id: int, agent_skill_priority: string, attribute_id: string, attribute_value_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[agent_ids]" $filteragent_ids "scalar") (serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/routing/agents/instance_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Set Agent Attribute Values Jobs
#
# POST /api/v2/routing/agents/instance_values/jobs
# operationId: BulkSetAgentAttributeValuesJob
# --job shape: {attributes: record}
export def "routing-agents-instance-values-jobs BulkSetAgentAttributeValuesJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --job: record # shape: {attributes: record}
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/routing/agents/instance_values/jobs")
  let body = {job: $job} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Account Attributes
#
# GET /api/v2/routing/attributes
# operationId: ListAccountAttributes
export def "routing-attributes ListAccountAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/ticket-management/skill_based_routing/#sideloads).  (e.g. attribute_values)
]: nothing -> record<attributes: table<created_at: string, id: string, name: string, updated_at: string, url: string>, count: int, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/routing/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Attribute
#
# POST /api/v2/routing/attributes
# operationId: CreateAttribute
export def "routing-attributes CreateAttribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute: record<created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/routing/attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Attribute
#
# GET /api/v2/routing/attributes/{attribute_id}
# operationId: ShowAttribute
export def "routing-attributes ShowAttribute" [
  attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute: record<created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Attribute
#
# PUT /api/v2/routing/attributes/{attribute_id}
# operationId: UpdateAttribute
export def "routing-attributes UpdateAttribute" [
  attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute: record<created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Attribute
#
# DELETE /api/v2/routing/attributes/{attribute_id}
# operationId: DeleteAttribute
export def "routing-attributes DeleteAttribute" [
  attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Attribute Values for an Attribute
#
# GET /api/v2/routing/attributes/{attribute_id}/values
# operationId: ListAttributeValues
export def "routing-attributes-values ListAttributeValues" [
  attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Attribute Value
#
# POST /api/v2/routing/attributes/{attribute_id}/values
# operationId: CreateAttributeValue
export def "routing-attributes-values CreateAttributeValue" [
  attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_value: record<agent_skill_priority: string, attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Attribute Value
#
# GET /api/v2/routing/attributes/{attribute_id}/values/{attribute_value_id}
# operationId: ShowAttributeValue
export def "routing-attributes-values ShowAttributeValue" [
  attribute_id: string
  attribute_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_value: record<agent_skill_priority: string, attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)/values/($attribute_value_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Attribute Value
#
# PATCH /api/v2/routing/attributes/{attribute_id}/values/{attribute_value_id}
# operationId: UpdateAttributeValue
export def "routing-attributes-values UpdateAttributeValue" [
  attribute_id: string
  attribute_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_value: record<agent_skill_priority: string, attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)/values/($attribute_value_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Attribute Value
#
# DELETE /api/v2/routing/attributes/{attribute_id}/values/{attribute_value_id}
# operationId: DeleteAttributeValue
export def "routing-attributes-values DeleteAttributeValue" [
  attribute_id: string
  attribute_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/attributes/($attribute_id)/values/($attribute_value_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Routing Attribute Definitions
#
# GET /api/v2/routing/attributes/definitions
# operationId: ListRoutingAttributeDefinitions
export def "routing-attributes-definitions ListRoutingAttributeDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<conditions_all: list<record>, conditions_any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/routing/attributes/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Tickets Fulfilled by a User
#
# GET /api/v2/routing/requirements/fulfilled
# operationId: ListTicketsFullfilledByUser
export def "routing-requirements-fulfilled ListTicketsFullfilledByUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket-ids: int # The IDs of the relevant tickets to check for matching attributes (format: int64, e.g. 1)
]: nothing -> record<fulfilled_ticket_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket_ids" $ticket_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/routing/requirements/fulfilled" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Attribute Values
#
# GET /api/v2/routing/tickets/{ticket_id}/instance_values
# operationId: ListTicketAttributeValues
export def "routing-tickets-instance-values ListTicketAttributeValues" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<agent_skill_priority: string, attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/tickets/($ticket_id)/instance_values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Ticket Attribute Values
#
# POST /api/v2/routing/tickets/{ticket_id}/instance_values
# operationId: SetTicketAttributeValues
export def "routing-tickets-instance-values SetTicketAttributeValues" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attribute_values: table<agent_skill_priority: string, attribute_id: string, created_at: string, id: string, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/routing/tickets/($ticket_id)/instance_values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Satisfaction Ratings
#
# GET /api/v2/satisfaction_ratings
# operationId: ListSatisfactionRatings
export def "satisfaction-ratings ListSatisfactionRatings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<satisfaction_ratings: table<assignee_id: int, comment: string, created_at: string, group_id: int, id: int, reason: string, reason_code: int, reason_id: int, requester_id: int, score: string, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/satisfaction_ratings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Satisfaction Rating
#
# GET /api/v2/satisfaction_ratings/{satisfaction_rating_id}
# operationId: ShowSatisfactionRating
export def "satisfaction-ratings ShowSatisfactionRating" [
  satisfaction_rating_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<satisfaction_rating: table<assignee_id: int, comment: string, created_at: string, group_id: int, id: int, reason: string, reason_code: int, reason_id: int, requester_id: int, score: string, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/satisfaction_ratings/($satisfaction_rating_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Satisfaction Ratings
#
# GET /api/v2/satisfaction_ratings/count
# operationId: CountSatisfactionRatings
export def "satisfaction-ratings-count CountSatisfactionRatings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/satisfaction_ratings/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Reasons for Satisfaction Rating
#
# GET /api/v2/satisfaction_reasons
# operationId: ListSatisfactionRatingReasons
export def "satisfaction-reasons ListSatisfactionRatingReasons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<reasons: table<created_at: string, deleted_at: string, id: int, raw_value: string, reason_code: int, updated_at: string, url: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/satisfaction_reasons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Reason for Satisfaction Rating
#
# GET /api/v2/satisfaction_reasons/{satisfaction_reason_id}
# operationId: ShowSatisfactionRatings
export def "satisfaction-reasons ShowSatisfactionRatings" [
  satisfaction_reason_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<reason: table<created_at: string, deleted_at: string, id: int, raw_value: string, reason_code: int, updated_at: string, url: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/satisfaction_reasons/($satisfaction_reason_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Search Results
#
# GET /api/v2/search
# operationId: ListSearchResults
export def "search ListSearchResults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query. See [Query basics](#query-basics) above. For details on the query syntax, see the [Zendesk Support search reference](https://support.zendesk.com/hc/en-us/articles/4408886879258) (e.g. https://subdomain.zendesk.com/api/v2/search?query=type:ticket status:closed&sort_by=status&sort_order=desc)
  --sort-by: string # One of `updated_at`, `created_at`, `priority`, `status`, or `ticket_type`. Defaults to sorting by relevance
  --sort-order: string # One of `asc` or `desc`.  Defaults to `desc`
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. The available sideloads depend on the search result types.  (e.g. users,organizations)
]: nothing -> record<count: int, facets: string, next_page: string, previous_page: string, results: table<created_at: string, default: bool, deleted: bool, description: string, id: int, name: string, result_type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Results Count
#
# GET /api/v2/search/count
# operationId: CountSearchResults
export def "search-count CountSearchResults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query (e.g. https://subdomain.zendesk.com/api/v2/search?query=type:ticket status:closed)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/search/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Search Results
#
# GET /api/v2/search/export
# operationId: ExportSearchResults
export def "search-export ExportSearchResults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query. See [Query basics](#query-basics) above. For details on the query syntax, see the [Zendesk Support search reference](https://support.zendesk.com/hc/en-us/articles/4408886879258) (e.g. https://subdomain.zendesk.com/api/v2/search?query=type:ticket status:closed&sort_by=status&sort_order=desc)
  --pagesize: int # The number of results shown in a page.
  --pageafter: string # The cursor token for fetching the next page of results.
  --filtertype: string # The object type returned by the export query. Can be `ticket`, `organization`, `user`, or `group`.
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. The available sideloads depend on the search result types.  (e.g. users,organizations)
]: nothing -> record<facets: string, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>, results: table<created_at: string, default: bool, deleted: bool, description: string, id: int, name: string, result_type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "filter[type]" $filtertype "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/search/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Security Settings
#
# GET /api/v2/security_settings
# operationId: ShowSecuritySettings
export def "security-settings ShowSecuritySettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand-id: int # When brand separation is enabled, scopes the security settings to the specified brand.  (format: int64)
]: nothing -> record<security_settings: record<admins_can_set_user_passwords: bool, agent_session_timeout: int, assumable: bool, assumable_account_type: bool, assumption_duration: string, assumption_expiration: string, authentication: record<agent: record, end_user: record>, csp_blocking_enabled: bool, email_agent_when_sensitive_fields_changed: bool, end_user_session_timeout: int, ip: record<enable_agent_ip_restrictions: bool, ip_ranges: string, ip_restriction_enabled: bool>, maximum_session_duration: int, maximum_session_duration_enabled: bool, mobile_app_access: bool, mobile_app_session_timeout: int, two_factor_last_update: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/security_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sessions
#
# GET /api/v2/sessions
# operationId: ListSessions
export def "sessions ListSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<sessions: table<authenticated_at: string, id: int, last_seen_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sharing Agreements
#
# GET /api/v2/sharing_agreements
# operationId: ListSharingAgreements
export def "sharing-agreements ListSharingAgreements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sharing_agreements: table<created_at: string, id: int, name: string, partner_name: string, remote_subdomain: string, status: string, type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/sharing_agreements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Sharing Agreement
#
# POST /api/v2/sharing_agreements
# operationId: CreateSharingAgreement
export def "sharing-agreements CreateSharingAgreement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sharing_agreement: record<created_at: string, id: int, name: string, partner_name: string, remote_subdomain: string, status: string, type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/sharing_agreements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show a Sharing Agreement
#
# GET /api/v2/sharing_agreements/{sharing_agreement_id}
# operationId: ShowSharingAgreement
export def "sharing-agreements ShowSharingAgreement" [
  sharing_agreement_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sharing_agreement: record<created_at: string, id: int, name: string, partner_name: string, remote_subdomain: string, status: string, type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/sharing_agreements/($sharing_agreement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Sharing Agreement
#
# PUT /api/v2/sharing_agreements/{sharing_agreement_id}
# operationId: UpdateSharingAgreement
export def "sharing-agreements UpdateSharingAgreement" [
  sharing_agreement_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sharing_agreement: record<created_at: string, id: int, name: string, partner_name: string, remote_subdomain: string, status: string, type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/sharing_agreements/($sharing_agreement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Sharing Agreement
#
# DELETE /api/v2/sharing_agreements/{sharing_agreement_id}
# operationId: DeleteSharingAgreement
export def "sharing-agreements DeleteSharingAgreement" [
  sharing_agreement_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/sharing_agreements/($sharing_agreement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Skips
#
# GET /api/v2/skips
# operationId: ListSkips
export def "skips ListSkips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
]: nothing -> record<skips: table<created_at: string, id: int, reason: string, ticket: record, ticket_id: int, updated_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/skips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Record a New Skip for the Current User
#
# POST /api/v2/skips
# operationId: RecordNewSkip
export def "skips RecordNewSkip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
]: nothing -> record<skip: record<created_at: string, id: int, reason: string, ticket: record, ticket_id: int, updated_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/skips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SLA Policies
#
# GET /api/v2/slas/policies
# operationId: ListSLAPolicies
export def "slas-policies ListSLAPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next_page: string, previous_page: string, sla_policies: table<created_at: string, description: string, filter: record, id: int, policy_metrics: list, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/slas/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create SLA Policy
#
# POST /api/v2/slas/policies
# operationId: CreateSLAPolicy
export def "slas-policies CreateSLAPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sla_policy: record<created_at: string, description: string, filter: record<all: list, any: list>, id: int, policy_metrics: list<record>, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/slas/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show SLA Policy
#
# GET /api/v2/slas/policies/{sla_policy_id}
# operationId: ShowSLAPolicy
export def "slas-policies ShowSLAPolicy" [
  sla_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sla_policy: record<created_at: string, description: string, filter: record<all: list, any: list>, id: int, policy_metrics: list<record>, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/slas/policies/($sla_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SLA Policy
#
# PUT /api/v2/slas/policies/{sla_policy_id}
# operationId: UpdateSLAPolicy
export def "slas-policies UpdateSLAPolicy" [
  sla_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sla_policy: record<created_at: string, description: string, filter: record<all: list, any: list>, id: int, policy_metrics: list<record>, position: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/slas/policies/($sla_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete SLA Policy
#
# DELETE /api/v2/slas/policies/{sla_policy_id}
# operationId: DeleteSLAPolicy
export def "slas-policies DeleteSLAPolicy" [
  sla_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/slas/policies/($sla_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Supported Filter Definition Items
#
# GET /api/v2/slas/policies/definitions
# operationId: RetrieveSLAPolicyFilterDefinitionItems
export def "slas-policies-definitions RetrieveSLAPolicyFilterDefinitionItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<all: list<record>, any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/slas/policies/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder SLA Policies
#
# PUT /api/v2/slas/policies/reorder
# operationId: ReorderSLAPolicies
export def "slas-policies-reorder ReorderSLAPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sla-policy-ids: list # The IDs of the SLA Policies to reorder
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sla_policy_ids" $sla_policy_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/slas/policies/reorder" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Suspended Tickets
#
# GET /api/v2/suspended_tickets
# operationId: ListSuspendedTickets
export def "suspended-tickets ListSuspendedTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<suspended_tickets: table<attachments: list, author: record, brand_id: int, cause: string, cause_id: int, content: string, created_at: string, error_messages: list, id: int, message_id: string, recipient: string, subject: string, ticket_id: int, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/suspended_tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Suspended Ticket
#
# GET /api/v2/suspended_tickets/{id}
# operationId: ShowSuspendedTickets
export def "suspended-tickets ShowSuspendedTickets" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<suspended_tickets: table<attachments: list, author: record, brand_id: int, cause: string, cause_id: int, content: string, created_at: string, error_messages: list, id: int, message_id: string, recipient: string, subject: string, ticket_id: int, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/suspended_tickets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Suspended Ticket
#
# DELETE /api/v2/suspended_tickets/{id}
# operationId: DeleteSuspendedTicket
export def "suspended-tickets DeleteSuspendedTicket" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/suspended_tickets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Suspended Ticket
#
# PUT /api/v2/suspended_tickets/{id}/recover
# operationId: RecoverSuspendedTicket
export def "suspended-tickets-recover RecoverSuspendedTicket" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/suspended_tickets/($id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspended Ticket Attachments
#
# POST /api/v2/suspended_tickets/attachments
# operationId: SuspendedTicketsAttachments
export def "suspended-tickets-attachments SuspendedTicketsAttachments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<upload: record<attachments: list<record>, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/suspended_tickets/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Multiple Suspended Tickets
#
# DELETE /api/v2/suspended_tickets/destroy_many
# operationId: DeleteSuspendedTickets
export def "suspended-tickets-destroy-many DeleteSuspendedTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of ids of suspended tickets to delete. (e.g. 94,141)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/suspended_tickets/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Suspended Tickets
#
# POST /api/v2/suspended_tickets/export
# operationId: ExportSuspendedTickets
export def "suspended-tickets-export ExportSuspendedTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<export: record<status: string, view_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/suspended_tickets/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Multiple Suspended Tickets
#
# PUT /api/v2/suspended_tickets/recover_many
# operationId: RecoverSuspendedTickets
export def "suspended-tickets-recover-many RecoverSuspendedTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of ids of suspended tickets to recover. (e.g. 14,77)
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/suspended_tickets/recover_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Tags
#
# GET /api/v2/tags
# operationId: ListTags
export def "tags ListTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<count: int, next_page: string, previous_page: string, tags: table<count: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Tags
#
# GET /api/v2/tags/count
# operationId: CountTags
export def "tags-count CountTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/tags/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Target Failures
#
# GET /api/v2/target_failures
# operationId: ListTargetFailures
export def "target-failures ListTargetFailures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<target_failures: table<consecutive_failure_count: int, created_at: string, id: int, raw_request: string, raw_response: string, status_code: int, target_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/target_failures")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Target Failure
#
# GET /api/v2/target_failures/{target_failure_id}
# operationId: ShowTargetFailure
export def "target-failures ShowTargetFailure" [
  target_failure_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<target_failure: record<consecutive_failure_count: int, created_at: string, id: int, raw_request: string, raw_response: string, status_code: int, target_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/target_failures/($target_failure_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Targets
#
# GET /api/v2/targets
# operationId: ListTargets
export def "targets ListTargets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<targets: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/targets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Target
#
# POST /api/v2/targets
# operationId: CreateTarget
export def "targets CreateTarget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<target: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/targets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Target
#
# GET /api/v2/targets/{target_id}
# operationId: ShowTarget
export def "targets ShowTarget" [
  target_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<target: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/targets/($target_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Target
#
# PUT /api/v2/targets/{target_id}
# operationId: UpdateTarget
export def "targets UpdateTarget" [
  target_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<target: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/targets/($target_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Target
#
# DELETE /api/v2/targets/{target_id}
# operationId: DeleteTarget
export def "targets DeleteTarget" [
  target_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/targets/($target_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Task List Templates
#
# GET /api/v2/task_list_templates
# operationId: ListTaskListTemplates
export def "task-list-templates ListTaskListTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>, task_list_templates: table<created_at: string, description: string, id: string, is_active: bool, is_required: bool, name: string, task_count: int, tasks: list, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/task_list_templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Task List Template
#
# POST /api/v2/task_list_templates
# operationId: CreateTaskListTemplate
# --task_list_template shape: {description?: string, is_active?: bool, is_required?: bool, name: string, tasks?: list}
export def "task-list-templates CreateTaskListTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --task-list-template: record # e.g. {created_at: 2025-08-06T17:08:40Z, description: Complete HR, IT, and payroll setup for new employees., id: 01K205PG0J2ET0B8AFHA106C1E, is_active: true, is_required: false, name: Onboarding checklist, task_count: 2, tasks: [{created_at: 2025-08-06T17:08:40Z, description: Ensure the employee has signed and returned all required documents before proceeding., id: 01K3KVF20JE2QNA47FY6HJWQKB, name: Verify signed offer letter and contract, position: 1, required: true, updated_at: 2025-08-06T17:08:40Z}, {created_at: 2025-08-06T17:08:40Z, description: Submit the background check request and verify employee eligibility before onboarding., id: 01K3KVF23JWZ5M98BJBQHENYZ9, name: Initiate background check, position: 2, required: false, updated_at: 2025-08-06T17:08:40Z}], updated_at: 2025-08-06T17:08:40Z} — shape: {description?: string, is_active?: bool, is_required?: bool, name: string, tasks?: list}
]: any -> record<task_list_template: record<created_at: string, description: string, id: string, is_active: bool, is_required: bool, name: string, task_count: int, tasks: list<record>, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/task_list_templates")
  let body = {task_list_template: $task_list_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Task List Template
#
# GET /api/v2/task_list_templates/{task_list_template_id}
# operationId: ShowTaskListTemplate
export def "task-list-templates ShowTaskListTemplate" [
  task_list_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<task_list_template: record<created_at: string, description: string, id: string, is_active: bool, is_required: bool, name: string, task_count: int, tasks: list<record>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/task_list_templates/($task_list_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Task List Template
#
# PUT /api/v2/task_list_templates/{task_list_template_id}
# operationId: UpdateTaskListTemplate
# --task_list_template shape: {description?: string, is_active?: bool, is_required?: bool, name?: string, tasks?: list}
export def "task-list-templates UpdateTaskListTemplate" [
  task_list_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  task_list_template: record # shape: {description?: string, is_active?: bool, is_required?: bool, name?: string, tasks?: list}
]: any -> record<task_list_template: record<created_at: string, description: string, id: string, is_active: bool, is_required: bool, name: string, task_count: int, tasks: list<record>, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/task_list_templates/($task_list_template_id)")
  let body = {task_list_template: $task_list_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Task List Template
#
# DELETE /api/v2/task_list_templates/{task_list_template_id}
# operationId: DeleteTaskListTemplate
export def "task-list-templates DeleteTaskListTemplate" [
  task_list_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/task_list_templates/($task_list_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tasks by Task List Template Id
#
# GET /api/v2/task_list_templates/{task_list_template_id}/tasks
# operationId: GetTasksByTaskListTemplateId
export def "task-list-templates-tasks GetTasksByTaskListTemplateId" [
  task_list_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next_page: string, previous_page: string, tasks: table<created_at: string, description: string, id: string, name: string, position: int, required: bool, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/task_list_templates/($task_list_template_id)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Ticket Audits
#
# GET /api/v2/ticket_audits
# operationId: ListTicketAudits
export def "ticket-audits ListTicketAudits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pagebefore: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.before_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pageafter: string # A [pagination cursor](/documentation/api-basics/pagination/paginating-through-lists-using-cursor-pagination) that tells the endpoint which page to start on. It should be a `meta.after_cursor` value from a previous request. Note: `page[before]` and `page[after]` can't be used together in the same request.
  --pagesize: int # Specifies how many records to be returned in the response. You can specify up to 100 records per page.
]: nothing -> record<after_cursor: string, after_url: string, audits: table<author_id: int, created_at: string, events: list, id: int, metadata: record, ticket_id: int, via: record>, before_cursor: string, before_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[before]" $pagebefore "scalar") (serialize-qp "page[after]" $pageafter "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_audits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Content Pins
#
# GET /api/v2/ticket_content_pins
# operationId: ListTicketContentPins
export def "ticket-content-pins ListTicketContentPins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket-id: string # The id of the ticket for which to list content pins
]: nothing -> record<count: int, ticket_content_pins: table<account_id: string, content_id: string, content_type: string, created_at: string, id: string, locale: string, ticket_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket_id" $ticket_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_content_pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket Content Pin
#
# POST /api/v2/ticket_content_pins
# operationId: CreateTicketContentPin
# --ticket_content_pin shape: {content_id: string, content_type: string, locale?: string, ticket_id: string}
export def "ticket-content-pins CreateTicketContentPin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket-content-pin: record # shape: {content_id: string, content_type: string, locale?: string, ticket_id: string}
]: any -> record<account_id: string, content_id: string, content_type: string, created_at: string, id: string, locale: string, ticket_id: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ticket_content_pins")
  let body = {ticket_content_pin: $ticket_content_pin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Content Pin from Ticket
#
# DELETE /api/v2/ticket_content_pins/{content_pin_id}
# operationId: DeleteTicketContentPin
export def "ticket-content-pins DeleteTicketContentPin" [
  content_pin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, content_id: string, content_type: string, created_at: string, id: string, locale: string, ticket_id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_content_pins/($content_pin_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Fields
#
# GET /api/v2/ticket_fields
# operationId: ListTicketFields
export def "ticket-fields ListTicketFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Forces the `title_in_portal` property to return a dynamic content variant for the specified locale.  Only accepts [active locale ids](/api-reference/ticketing/account-configuration/locales/#list-locales). Example: `locale="de"`.
  --creator: string@bool-completer # Displays the `creator_user_id` and `creator_app_name` properties. If the ticket field is created  by an app, `creator_app_name` is the name of the app and `creator_user_id` is `-1`. If the ticket field  is not created by an app, `creator_app_name` is null
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<ticket_fields: table<active: bool, agent_can_edit: bool, agent_description: string, collapsed_for_agents: bool, created_at: string, creator_app_name: string, creator_user_id: int, custom_field_options: list, custom_statuses: list, description: string, editable_in_portal: bool, id: int, position: int, raw_description: string, raw_title: string, raw_title_in_portal: string, regexp_for_validation: string, relationship_filter: record, relationship_target_type: string, removable: bool, required: bool, required_in_portal: bool, sub_type_id: int, system_field_options: list, tag: string, title: string, title_in_portal: string, type: string, updated_at: string, url: string, visible_in_portal: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "creator" $creator "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket Field
#
# POST /api/v2/ticket_fields
# operationId: CreateTicketField
export def "ticket-fields CreateTicketField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_field: record<active: bool, agent_can_edit: bool, agent_description: string, collapsed_for_agents: bool, created_at: string, creator_app_name: string, creator_user_id: int, custom_field_options: list<record>, custom_statuses: list<record>, description: string, editable_in_portal: bool, id: int, position: int, raw_description: string, raw_title: string, raw_title_in_portal: string, regexp_for_validation: string, relationship_filter: record, relationship_target_type: string, removable: bool, required: bool, required_in_portal: bool, sub_type_id: int, system_field_options: list<record>, tag: string, title: string, title_in_portal: string, type: string, updated_at: string, url: string, visible_in_portal: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ticket_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket Field
#
# GET /api/v2/ticket_fields/{ticket_field_id}
# operationId: ShowTicketfield
export def "ticket-fields ShowTicketfield" [
  ticket_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creator: string@bool-completer # If true, displays the `creator_user_id` and `creator_app_name` properties. If the ticket field is created  by an app, `creator_app_name` is the name of the app and `creator_user_id` is `-1`. If the ticket field  is not created by an app, then `creator_app_name` is null
]: nothing -> record<ticket_field: record<active: bool, agent_can_edit: bool, agent_description: string, collapsed_for_agents: bool, created_at: string, creator_app_name: string, creator_user_id: int, custom_field_options: list<record>, custom_statuses: list<record>, description: string, editable_in_portal: bool, id: int, position: int, raw_description: string, raw_title: string, raw_title_in_portal: string, regexp_for_validation: string, relationship_filter: record, relationship_target_type: string, removable: bool, required: bool, required_in_portal: bool, sub_type_id: int, system_field_options: list<record>, tag: string, title: string, title_in_portal: string, type: string, updated_at: string, url: string, visible_in_portal: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creator" $creator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ticket Field
#
# PUT /api/v2/ticket_fields/{ticket_field_id}
# operationId: UpdateTicketField
export def "ticket-fields UpdateTicketField" [
  ticket_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creator: string@bool-completer # If true, displays the `creator_user_id` and `creator_app_name` properties. If the ticket field is created  by an app, `creator_app_name` is the name of the app and `creator_user_id` is `-1`. If the ticket field  is not created by an app, then `creator_app_name` is null
]: nothing -> record<ticket_field: record<active: bool, agent_can_edit: bool, agent_description: string, collapsed_for_agents: bool, created_at: string, creator_app_name: string, creator_user_id: int, custom_field_options: list<record>, custom_statuses: list<record>, description: string, editable_in_portal: bool, id: int, position: int, raw_description: string, raw_title: string, raw_title_in_portal: string, regexp_for_validation: string, relationship_filter: record, relationship_target_type: string, removable: bool, required: bool, required_in_portal: bool, sub_type_id: int, system_field_options: list<record>, tag: string, title: string, title_in_portal: string, type: string, updated_at: string, url: string, visible_in_portal: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creator" $creator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Ticket Field
#
# DELETE /api/v2/ticket_fields/{ticket_field_id}
# operationId: DeleteTicketField
export def "ticket-fields DeleteTicketField" [
  ticket_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creator: string@bool-completer # If true, displays the `creator_user_id` and `creator_app_name` properties. If the ticket field is created  by an app, `creator_app_name` is the name of the app and `creator_user_id` is `-1`. If the ticket field  is not created by an app, then `creator_app_name` is null
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creator" $creator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Field Options
#
# GET /api/v2/ticket_fields/{ticket_field_id}/options
# operationId: ListTicketFieldOptions
export def "ticket-fields-options ListTicketFieldOptions" [
  ticket_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, custom_field_options: table<allow_solving: bool, id: int, name: string, position: int, raw_name: string, url: string, value: string>, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update Ticket Field Option
#
# POST /api/v2/ticket_fields/{ticket_field_id}/options
# operationId: CreateOrUpdateTicketFieldOption
export def "ticket-fields-options CreateOrUpdateTicketFieldOption" [
  ticket_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_field_option: record<allow_solving: bool, id: int, name: string, position: int, raw_name: string, url: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket Field Option
#
# GET /api/v2/ticket_fields/{ticket_field_id}/options/{ticket_field_option_id}
# operationId: ShowTicketFieldOption
export def "ticket-fields-options ShowTicketFieldOption" [
  ticket_field_id: int
  ticket_field_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_field_option: record<allow_solving: bool, id: int, name: string, position: int, raw_name: string, url: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)/options/($ticket_field_option_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Ticket Field Option
#
# DELETE /api/v2/ticket_fields/{ticket_field_id}/options/{ticket_field_option_id}
# operationId: DeleteTicketFieldOption
export def "ticket-fields-options DeleteTicketFieldOption" [
  ticket_field_id: int
  ticket_field_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_fields/($ticket_field_id)/options/($ticket_field_option_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Ticket Fields
#
# GET /api/v2/ticket_fields/count
# operationId: CountTicketFields
export def "ticket-fields-count CountTicketFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ticket_fields/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Ticket Fields
#
# PUT /api/v2/ticket_fields/reorder
# operationId: ReorderTicketFields
export def "ticket-fields-reorder ReorderTicketFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ticket_fields/reorder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Ticket Fields
#
# GET /api/v2/ticket_fields/show_many
# operationId: ShowManyTicketFields
export def "ticket-fields-show-many ShowManyTicketFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket field IDs to retrieve. Up to 100 values accepted.  Either `ids` or `keys` can be used, but not both.  (e.g. 123,456,789)
  --keys: string # Comma-separated list of ticket field keys to retrieve. Up to 100 values accepted.  Use field keys like 'priority', 'status', 'subject' instead of numeric IDs.  Either `ids` or `keys` can be used, but not both.  (e.g. priority,status,subject)
  --creator: string@bool-completer # If true, includes creator information in the response.
  --exclude-sub-selection-options: string@bool-completer # If true, excludes sub-selection options from dropdown fields in the response.
]: nothing -> record<count: int, next_page: string, previous_page: string, ticket_fields: table<active: bool, agent_can_edit: bool, agent_description: string, collapsed_for_agents: bool, created_at: string, creator_app_name: string, creator_user_id: int, custom_field_options: list, custom_statuses: list, description: string, editable_in_portal: bool, id: int, position: int, raw_description: string, raw_title: string, raw_title_in_portal: string, regexp_for_validation: string, relationship_filter: record, relationship_target_type: string, removable: bool, required: bool, required_in_portal: bool, sub_type_id: int, system_field_options: list, tag: string, title: string, title_in_portal: string, type: string, updated_at: string, url: string, visible_in_portal: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "keys" $keys "scalar") (serialize-qp "creator" $creator "scalar") (serialize-qp "exclude_sub_selection_options" $exclude_sub_selection_options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_fields/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Form Statuses
#
# GET /api/v2/ticket_form_statuses
# operationId: ListTicketFormStatuses
export def "ticket-form-statuses ListTicketFormStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket-form-id: string # Filter by ticket form ID.  Supports single ID or comma-separated list of IDs.
  --filter: record # Additional filter criteria (e.g. {custom_status_id: 789, id: 123,456})
]: nothing -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket_form_id" $ticket_form_id "scalar") (serialize-qp "filter" $filter "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_form_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Ticket Form Statuses
#
# GET /api/v2/ticket_form_statuses/show_many
# operationId: ShowManyTicketFormStatuses
export def "ticket-form-statuses-show-many ShowManyTicketFormStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Ticket form status ids to retrieve records for (e.g. abc,def,ghi)
]: nothing -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_form_statuses/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Forms
#
# GET /api/v2/ticket_forms
# operationId: ListTicketForms
export def "ticket-forms ListTicketForms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # true returns active ticket forms; false returns inactive ticket forms. If not present, returns both
  --end-user-visible: string@bool-completer # true returns ticket forms where `end_user_visible`; false returns ticket forms that are not end-user visible. If not present, returns both
  --fallback-to-default: string@bool-completer # true returns the default ticket form when the criteria defined by the parameters results in a set without active and end-user visible ticket forms
  --form-type: string@form-type-completer # Filter ticket forms by type. Use 'standard' for regular ticket forms, 'service_catalog' for service catalog forms, or 'all' to return all form types (e.g. standard)
  --associated-to-brand: string@bool-completer # true returns the ticket forms of the brand specified by the url's subdomain
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --locale: string # Locale to use for the ticket form names. If not specified, the default locale is used.
]: nothing -> record<ticket_forms: table<active: bool, agent_conditions: list, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list, ticket_field_ids: list, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "end_user_visible" $end_user_visible "scalar") (serialize-qp "fallback_to_default" $fallback_to_default "scalar") (serialize-qp "form_type" $form_type "scalar") (serialize-qp "associated_to_brand" $associated_to_brand "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket Form
#
# POST /api/v2/ticket_forms
# operationId: CreateTicketForm
export def "ticket-forms CreateTicketForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_form: record<active: bool, agent_conditions: list<record>, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list<record>, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list<int>, ticket_field_ids: list<int>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ticket_forms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket Form
#
# GET /api/v2/ticket_forms/{ticket_form_id}
# operationId: ShowTicketForm
export def "ticket-forms ShowTicketForm" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_form: record<active: bool, agent_conditions: list<record>, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list<record>, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list<int>, ticket_field_ids: list<int>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ticket Form
#
# PUT /api/v2/ticket_forms/{ticket_form_id}
# operationId: UpdateTicketForm
export def "ticket-forms UpdateTicketForm" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_form: record<active: bool, agent_conditions: list<record>, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list<record>, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list<int>, ticket_field_ids: list<int>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Ticket Form
#
# DELETE /api/v2/ticket_forms/{ticket_form_id}
# operationId: DeleteTicketForm
export def "ticket-forms DeleteTicketForm" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clone an Already Existing Ticket Form
#
# POST /api/v2/ticket_forms/{ticket_form_id}/clone
# operationId: CloneTicketForm
export def "ticket-forms-clone CloneTicketForm" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_form: record<active: bool, agent_conditions: list<record>, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list<record>, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list<int>, ticket_field_ids: list<int>, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/clone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Form Statuses of a Ticket Form
#
# GET /api/v2/ticket_forms/{ticket_form_id}/ticket_form_statuses
# operationId: TicketFormTicketFormStatuses
export def "ticket-forms-ticket-form-statuses TicketFormTicketFormStatuses" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/ticket_form_statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket Form Statuses
#
# POST /api/v2/ticket_forms/{ticket_form_id}/ticket_form_statuses
# operationId: CreateTicketFormStatuses
# --ticket_form_status item shape: {custom_status_id: int}
export def "ticket-forms-ticket-form-statuses CreateTicketFormStatuses" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ticket_form_status: list # item shape: {custom_status_id: int}
]: any -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/ticket_form_statuses")
  let body = {ticket_form_status: $ticket_form_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Update Ticket Form Statuses of a Ticket Form
#
# PUT /api/v2/ticket_forms/{ticket_form_id}/ticket_form_statuses
# operationId: UpdateTicketFormStatuses
# --ticket_form_status item shape: {_destroy?: string, custom_status_id?: int, id?: string}
export def "ticket-forms-ticket-form-statuses UpdateTicketFormStatuses" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ticket_form_status: list # item shape: {_destroy?: string, custom_status_id?: int, id?: string}
]: any -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/ticket_form_statuses")
  let body = {ticket_form_status: $ticket_form_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ticket Form Statuses
#
# DELETE /api/v2/ticket_forms/{ticket_form_id}/ticket_form_statuses
# operationId: DeleteTicketFormStatuses
export def "ticket-forms-ticket-form-statuses DeleteTicketFormStatuses" [
  ticket_form_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list # List of ids to delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/ticket_form_statuses")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Ticket Form Status By Id
#
# PUT /api/v2/ticket_forms/{ticket_form_id}/ticket_form_statuses/{ticket_form_status_id}
# operationId: UpdateTicketFormStatusById
# --ticket_form_status item shape: {_destroy?: string, custom_status_id?: int, id?: string}
export def "ticket-forms-ticket-form-statuses UpdateTicketFormStatusById" [
  ticket_form_id: int
  ticket_form_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ticket_form_status: list # item shape: {_destroy?: string, custom_status_id?: int, id?: string}
]: any -> record<ticket_form_statuses: table<custom_status_id: int, id: string, ticket_form_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/ticket_form_statuses/($ticket_form_status_id)")
  let body = {ticket_form_status: $ticket_form_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ticket Form Status By Id
#
# DELETE /api/v2/ticket_forms/{ticket_form_id}/ticket_form_statuses/{ticket_form_status_id}
# operationId: DeleteTicketFormStatusById
export def "ticket-forms-ticket-form-statuses DeleteTicketFormStatusById" [
  ticket_form_id: int
  ticket_form_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_forms/($ticket_form_id)/ticket_form_statuses/($ticket_form_status_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Ticket Forms
#
# PUT /api/v2/ticket_forms/reorder
# operationId: ReorderTicketForms
export def "ticket-forms-reorder ReorderTicketForms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_forms: table<active: bool, agent_conditions: list, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list, ticket_field_ids: list, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ticket_forms/reorder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Ticket Forms
#
# GET /api/v2/ticket_forms/show_many
# operationId: ShowManyTicketForms
export def "ticket-forms-show-many ShowManyTicketForms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # IDs of the ticket forms to be shown (e.g. 1,2,3)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --active: string@bool-completer # true returns active ticket forms; false returns inactive ticket forms. If not present, returns both
  --end-user-visible: string@bool-completer # true returns ticket forms where `end_user_visible`; false returns ticket forms that are not end-user visible. If not present, returns both
  --fallback-to-default: string@bool-completer # true returns the default ticket form when the criteria defined by the parameters results in a set without active and end-user visible ticket forms
  --associated-to-brand: string@bool-completer # true returns the ticket forms of the brand specified by the url's subdomain
]: nothing -> record<ticket_forms: table<active: bool, agent_conditions: list, created_at: string, default: bool, deleted_at: string, display_name: string, end_user_conditions: list, end_user_visible: bool, id: int, in_all_brands: bool, name: string, position: int, raw_display_name: string, raw_name: string, restricted_brand_ids: list, ticket_field_ids: list, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "end_user_visible" $end_user_visible "scalar") (serialize-qp "fallback_to_default" $fallback_to_default "scalar") (serialize-qp "associated_to_brand" $associated_to_brand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_forms/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Metrics
#
# GET /api/v2/ticket_metrics
# operationId: ListTicketMetrics
export def "ticket-metrics ListTicketMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<ticket_metrics: table<agent_wait_time_in_minutes: record, assigned_at: string, assignee_stations: int, assignee_updated_at: string, created_at: string, custom_status_updated_at: string, first_resolution_time_in_minutes: record, full_resolution_time_in_minutes: record, group_stations: int, id: int, initially_assigned_at: string, latest_comment_added_at: string, on_hold_time_in_minutes: record, reopens: int, replies: int, reply_time_in_minutes: record, reply_time_in_seconds: record, requester_updated_at: string, requester_wait_time_in_minutes: record, solved_at: string, status_updated_at: string, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ticket_metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket Metrics
#
# GET /api/v2/ticket_metrics/{ticket_metric_id}
# operationId: ShowTicketMetrics
export def "ticket-metrics ShowTicketMetrics" [
  ticket_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_metric: table<agent_wait_time_in_minutes: record, assigned_at: string, assignee_stations: int, assignee_updated_at: string, created_at: string, custom_status_updated_at: string, first_resolution_time_in_minutes: record, full_resolution_time_in_minutes: record, group_stations: int, id: int, initially_assigned_at: string, latest_comment_added_at: string, on_hold_time_in_minutes: record, reopens: int, replies: int, reply_time_in_minutes: record, reply_time_in_seconds: record, requester_updated_at: string, requester_wait_time_in_minutes: record, solved_at: string, status_updated_at: string, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ticket_metrics/($ticket_metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Tickets
#
# GET /api/v2/tickets
# operationId: ListTickets
export def "tickets ListTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-id: string # Lists tickets by external id. External ids don't have to be unique for each ticket. As a result, the request may return multiple tickets with the same external id.
  --sort-by: string@sort-by-completer # Sort by
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
  --support-type-scope: string # Lists tickets by support type. Possible values are "all", "agent", or "ai_agent". Defaults to "agent"
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/tickets/tickets/#sideloading).  (e.g. users,groups,organizations)
  --start-time: int # Unix epoch time to filter tickets. Only tickets created or updated after this time are returned. Example: `?start_time=1332034771`  (e.g. 1332034771)
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_id" $external_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "support_type_scope" $support_type_scope "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "start_time" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket
#
# POST /api/v2/tickets
# operationId: CreateTicket
# --ticket shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record}
export def "tickets CreateTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/tickets/tickets/#sideloading).  (e.g. users,groups,organizations)
  --system-metadata: record # System metadata for the request, typically set by internal clients
  --ticket: record # e.g. {assignee_id: 235323, collaborator_ids: [35334, 234], created_at: 2009-07-20T22:55:29Z, custom_fields: [{id: 27642, value: 745}, {id: 27648, value: yes}], custom_status_id: 123, description: The fire is very colorful., due_at: , external_id: ahg35h3jh, follower_ids: [35334, 234], from_messaging_channel: false, generated_timestamp: 1304553600, group_id: 98738, has_incidents: false, id: 35436, organization_id: 509974, priority: high, problem_id: 9873764, raw_subject: {{dc.printer_on_fire}}, recipient: support@company.com, requester_id: 20978392, satisfaction_rating: {comment: Great support!, id: 1234, score: good}, sharing_agreement_ids: [84432], status: open, subject: Help, my printer is on fire!, submitter_id: 76872, tags: [enterprise, other_tag], type: incident, updated_at: 2011-05-05T10:38:52Z, url: https://company.zendesk.com/api/v2/tickets/35436, via: {channel: web}} — shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record}
]: any -> record<ticket: record<additional_collaborators: list<record>, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list<int>, brand_id: int, collaborator_ids: list<int>, collaborators: list<record>, comment: record<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, email_ccs: list<record>, encoded_id: string, external_id: string, fields: list<record>, follower_ids: list<int>, followers: list<record>, followup_ids: list<int>, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list<int>, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list<int>, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record<client: string, ip_address: string>, tags: any, tde_workspace: record<previous_workspace: record, type: string, workspace: record>, ticket_form_id: int, tpe_voice_comment: record<agent_id: int, answering_machine_detection_status: string, app_id: int, app_name: string, author_id: int, call_connected_at: string, call_disposition: string, call_ended_at: string, call_id: int, call_recording_consent: string, call_recording_consent_action: string, call_recording_consent_keypress: string, call_started_at: string, call_type: string, callback_number: string, callback_requested_at: string, completion_status: string, connection_attempts: int, consultation_time: int, direction: string, disconnection_reason: string, dnis: string, duration: int, end_user_id: int, end_user_location: string, exceeded_queue_time: bool, extension: string, external_id: string, from_line: string, from_line_nickname: string, hold_time: int, intent: string, ivr_destination_group_name: string, ivr_time_spent: int, language: string, line_type: string, longest_hold_time: int, number_of_holds: int, outside_business_hours: bool, overflowed_to: string, phone_name: string, public: bool, quality_score: int, queue_name: string, queue_time: int, recorded: bool, recording_time: int, recording_type: string, recording_url: string, sentiment_agent: string, sentiment_call: string, sentiment_customer: string, sentiment_trend: string, short_summary: string, summary: string, talk_time: int, time_to_answer: int, title: string, to_line: string, to_line_nickname: string, transcript: string, via_id: int, video_recording_url: string, voicemail: bool, voicemail_requested_at: string, wait_time: int>, type: string, updated_at: string, updated_stamp: string, url: string, via: record<channel: any, source: record>, via_followup_source_id: int, via_id: int, voice_comment: record<answered_by_id: int, call_duration: int, from: string, location: string, recording_url: string, to: string, transcription_text: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tickets" $qp)
  let body = {system_metadata: $system_metadata, ticket: $ticket} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Ticket
#
# GET /api/v2/tickets/{ticket_id}
# operationId: ShowTicket
export def "tickets ShowTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/tickets/tickets/#sideloading).  (e.g. users,groups,organizations)
  --reduced-payload-size: string@bool-completer # When true, returns a reduced ticket payload (omits null custom fields).
  --remove-duplicate-fields: string@bool-completer # When true, removes duplicate custom field entries from the response.
]: nothing -> record<ticket: record<additional_collaborators: list<record>, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list<int>, brand_id: int, collaborator_ids: list<int>, collaborators: list<record>, comment: record<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, email_ccs: list<record>, encoded_id: string, external_id: string, fields: list<record>, follower_ids: list<int>, followers: list<record>, followup_ids: list<int>, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list<int>, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list<int>, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record<client: string, ip_address: string>, tags: any, tde_workspace: record<previous_workspace: record, type: string, workspace: record>, ticket_form_id: int, tpe_voice_comment: record<agent_id: int, answering_machine_detection_status: string, app_id: int, app_name: string, author_id: int, call_connected_at: string, call_disposition: string, call_ended_at: string, call_id: int, call_recording_consent: string, call_recording_consent_action: string, call_recording_consent_keypress: string, call_started_at: string, call_type: string, callback_number: string, callback_requested_at: string, completion_status: string, connection_attempts: int, consultation_time: int, direction: string, disconnection_reason: string, dnis: string, duration: int, end_user_id: int, end_user_location: string, exceeded_queue_time: bool, extension: string, external_id: string, from_line: string, from_line_nickname: string, hold_time: int, intent: string, ivr_destination_group_name: string, ivr_time_spent: int, language: string, line_type: string, longest_hold_time: int, number_of_holds: int, outside_business_hours: bool, overflowed_to: string, phone_name: string, public: bool, quality_score: int, queue_name: string, queue_time: int, recorded: bool, recording_time: int, recording_type: string, recording_url: string, sentiment_agent: string, sentiment_call: string, sentiment_customer: string, sentiment_trend: string, short_summary: string, summary: string, talk_time: int, time_to_answer: int, title: string, to_line: string, to_line_nickname: string, transcript: string, via_id: int, video_recording_url: string, voicemail: bool, voicemail_requested_at: string, wait_time: int>, type: string, updated_at: string, updated_stamp: string, url: string, via: record<channel: any, source: record>, via_followup_source_id: int, via_id: int, voice_comment: record<answered_by_id: int, call_duration: int, from: string, location: string, recording_url: string, to: string, transcription_text: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "reduced_payload_size" $reduced_payload_size "scalar") (serialize-qp "remove_duplicate_fields" $remove_duplicate_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ticket
#
# PUT /api/v2/tickets/{ticket_id}
# operationId: UpdateTicket
# --ticket shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record}
export def "tickets UpdateTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --system-metadata: record # System metadata for the request, typically set by internal clients
  --ticket: record # e.g. {assignee_id: 235323, collaborator_ids: [35334, 234], created_at: 2009-07-20T22:55:29Z, custom_fields: [{id: 27642, value: 745}, {id: 27648, value: yes}], custom_status_id: 123, description: The fire is very colorful., due_at: , external_id: ahg35h3jh, follower_ids: [35334, 234], from_messaging_channel: false, generated_timestamp: 1304553600, group_id: 98738, has_incidents: false, id: 35436, organization_id: 509974, priority: high, problem_id: 9873764, raw_subject: {{dc.printer_on_fire}}, recipient: support@company.com, requester_id: 20978392, satisfaction_rating: {comment: Great support!, id: 1234, score: good}, sharing_agreement_ids: [84432], status: open, subject: Help, my printer is on fire!, submitter_id: 76872, tags: [enterprise, other_tag], type: incident, updated_at: 2011-05-05T10:38:52Z, url: https://company.zendesk.com/api/v2/tickets/35436, via: {channel: web}} — shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record}
]: any -> record<audit: record<author_id: int, created_at: string, events: list<record>, id: int, metadata: record, ticket_id: int, via: record<channel: any, source: record>>, ticket: record<additional_collaborators: list<record>, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list<int>, brand_id: int, collaborator_ids: list<int>, collaborators: list<record>, comment: record<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, email_ccs: list<record>, encoded_id: string, external_id: string, fields: list<record>, follower_ids: list<int>, followers: list<record>, followup_ids: list<int>, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list<int>, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list<int>, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record<client: string, ip_address: string>, tags: any, tde_workspace: record<previous_workspace: record, type: string, workspace: record>, ticket_form_id: int, tpe_voice_comment: record<agent_id: int, answering_machine_detection_status: string, app_id: int, app_name: string, author_id: int, call_connected_at: string, call_disposition: string, call_ended_at: string, call_id: int, call_recording_consent: string, call_recording_consent_action: string, call_recording_consent_keypress: string, call_started_at: string, call_type: string, callback_number: string, callback_requested_at: string, completion_status: string, connection_attempts: int, consultation_time: int, direction: string, disconnection_reason: string, dnis: string, duration: int, end_user_id: int, end_user_location: string, exceeded_queue_time: bool, extension: string, external_id: string, from_line: string, from_line_nickname: string, hold_time: int, intent: string, ivr_destination_group_name: string, ivr_time_spent: int, language: string, line_type: string, longest_hold_time: int, number_of_holds: int, outside_business_hours: bool, overflowed_to: string, phone_name: string, public: bool, quality_score: int, queue_name: string, queue_time: int, recorded: bool, recording_time: int, recording_type: string, recording_url: string, sentiment_agent: string, sentiment_call: string, sentiment_customer: string, sentiment_trend: string, short_summary: string, summary: string, talk_time: int, time_to_answer: int, title: string, to_line: string, to_line_nickname: string, transcript: string, via_id: int, video_recording_url: string, voicemail: bool, voicemail_requested_at: string, wait_time: int>, type: string, updated_at: string, updated_stamp: string, url: string, via: record<channel: any, source: record>, via_followup_source_id: int, via_id: int, voice_comment: record<answered_by_id: int, call_duration: int, from: string, location: string, recording_url: string, to: string, transcription_text: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)")
  let body = {system_metadata: $system_metadata, ticket: $ticket} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ticket
#
# DELETE /api/v2/tickets/{ticket_id}
# operationId: DeleteTicket
export def "tickets DeleteTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Audits for a Ticket
#
# GET /api/v2/tickets/{ticket_id}/audits
# operationId: ListAuditsForTicket
export def "tickets-audits ListAuditsForTicket" [
  ticket_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include: string # A comma-separated list of sideloads to include in the response.
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --filter-events: list # Filter audit events by type. Use the format `filter_events[]=Type1&filter_events[]=Type2`.
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
]: nothing -> record<audits: table<author_id: int, created_at: string, events: list, id: int, metadata: record, ticket_id: int, via: record>, count: int, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar") (serialize-qp "filter_events" $filter_events "multi") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/audits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Audit
#
# GET /api/v2/tickets/{ticket_id}/audits/{ticket_audit_id}
# operationId: ShowTicketAudit
export def "tickets-audits ShowTicketAudit" [
  ticket_id: int
  ticket_audit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audit: record<author_id: int, created_at: string, events: list<record>, id: int, metadata: record, ticket_id: int, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/audits/($ticket_audit_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change a Comment From Public To Private
#
# PUT /api/v2/tickets/{ticket_id}/audits/{ticket_audit_id}/make_private
# operationId: MakeTicketCommentPrivateFromAudits
export def "tickets-audits-make-private MakeTicketCommentPrivateFromAudits" [
  ticket_id: int
  ticket_audit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/audits/($ticket_audit_id)/make_private")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Audits for a Ticket
#
# GET /api/v2/tickets/{ticket_id}/audits/count
# operationId: CountAuditsForTicket
export def "tickets-audits-count CountAuditsForTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/audits/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Collaborators for a Ticket
#
# GET /api/v2/tickets/{ticket_id}/collaborators
# operationId: ListTicketCollaborators
export def "tickets-collaborators ListTicketCollaborators" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/collaborators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Comments
#
# GET /api/v2/tickets/{ticket_id}/comments
# operationId: ListTicketComments
export def "tickets-comments ListTicketComments" [
  ticket_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-inline-images: string@bool-completer # Default is false. When true, inline images are also listed as attachments in the response
  --include: string # Accepts "users". Use this parameter to list email CCs by side-loading users. Example: `?include=users`. **Note**: If the comment source is email, a deleted user will be represented as the CCd email address. If the comment source is anything else, a deleted user will be represented as the user name.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
]: nothing -> record<comments: table<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_inline_images" $include_inline_images "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact Comment Attachment
#
# PUT /api/v2/tickets/{ticket_id}/comments/{comment_id}/attachments/{attachment_id}/redact
# operationId: RedactCommentAttachment
export def "tickets-comments-attachments-redact RedactCommentAttachment" [
  ticket_id: int
  comment_id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attachment: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/comments/($comment_id)/attachments/($attachment_id)/redact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make Comment Private
#
# PUT /api/v2/tickets/{ticket_id}/comments/{ticket_comment_id}/make_private
# operationId: MakeTicketCommentPrivate
export def "tickets-comments-make-private MakeTicketCommentPrivate" [
  ticket_id: int
  ticket_comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/comments/($ticket_comment_id)/make_private")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact String in Comment
#
# PUT /api/v2/tickets/{ticket_id}/comments/{ticket_comment_id}/redact
# operationId: RedactStringInComment
export def "tickets-comments-redact RedactStringInComment" [
  ticket_id: int
  ticket_comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: record<add_short_url: bool, attachments: list<record>, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list<string>, via: record<channel: string, source: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/comments/($ticket_comment_id)/redact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Ticket Comments
#
# GET /api/v2/tickets/{ticket_id}/comments/count
# operationId: CountTicketComments
export def "tickets-comments-count CountTicketComments" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/comments/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Conversation log for Ticket
#
# GET /api/v2/tickets/{ticket_id}/conversation_log
# operationId: ListConversationLogForTicket
export def "tickets-conversation-log ListConversationLogForTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
]: nothing -> record<events: table<attachments: list, author: record, content: record, created_at: string, id: string, metadata: record, reference: string, type: string>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/conversation_log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Email CCs for a Ticket
#
# GET /api/v2/tickets/{ticket_id}/email_ccs
# operationId: ListTicketEmailCCs
export def "tickets-email-ccs ListTicketEmailCCs" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/email_ccs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Followers for a Ticket
#
# GET /api/v2/tickets/{ticket_id}/followers
# operationId: ListTicketFollowers
export def "tickets-followers ListTicketFollowers" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/followers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Incidents
#
# GET /api/v2/tickets/{ticket_id}/incidents
# operationId: ListTicketIncidents
export def "tickets-incidents ListTicketIncidents" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/incidents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket After Changes
#
# GET /api/v2/tickets/{ticket_id}/macros/{macro_id}/apply
# operationId: ShowTicketAfterChanges
export def "tickets-macros-apply ShowTicketAfterChanges" [
  macro_id: int
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --normalize-comment: string@bool-completer # If true, normalizes the newline formatting of the macro's comment to more closely match the formatting produced by the ticket comment editor
]: nothing -> record<result: record<ticket: record<assignee_id: int, comment: record, fields: record, group_id: int, id: int, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "normalize_comment" $normalize_comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/macros/($macro_id)/apply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark Ticket as Spam and Suspend Requester
#
# PUT /api/v2/tickets/{ticket_id}/mark_as_spam
# operationId: MarkTicketAsSpamAndSuspendRequester
export def "tickets-mark-as-spam MarkTicketAsSpamAndSuspendRequester" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/mark_as_spam")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge Tickets into Target Ticket
#
# POST /api/v2/tickets/{ticket_id}/merge
# operationId: MergeTicketsIntoTargetTicket
export def "tickets-merge MergeTicketsIntoTargetTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # Ids of tickets to merge into the target ticket
  --source-comment: string # Private comment to add to the source ticket
  --source-comment-is-public: string@bool-completer # Whether comment in source tickets are public or private
  --target-comment: string # Private comment to add to the target ticket
  --target-comment-is-public: string@bool-completer # Whether comment in target ticket is public or private
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/merge")
  let body = {ids: $ids, source_comment: $source_comment, source_comment_is_public: $source_comment_is_public, target_comment: $target_comment, target_comment_is_public: $target_comment_is_public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Ticket Metrics By Ticket
#
# GET /api/v2/tickets/{ticket_id}/metrics
# operationId: ShowTicketMetricsByTicket
export def "tickets-metrics ShowTicketMetricsByTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket_metric: table<agent_wait_time_in_minutes: record, assigned_at: string, assignee_stations: int, assignee_updated_at: string, created_at: string, custom_status_updated_at: string, first_resolution_time_in_minutes: record, full_resolution_time_in_minutes: record, group_stations: int, id: int, initially_assigned_at: string, latest_comment_added_at: string, on_hold_time_in_minutes: record, reopens: int, replies: int, reply_time_in_minutes: record, reply_time_in_seconds: record, requester_updated_at: string, requester_wait_time_in_minutes: record, solved_at: string, status_updated_at: string, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ticket Related Information
#
# GET /api/v2/tickets/{ticket_id}/related
# operationId: TicketRelatedInformation
export def "tickets-related TicketRelatedInformation" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<followup_source_ids: list<string>, from_archive: bool, incidents: int, jira_issue_ids: list<string>, topic_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/related")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Satisfaction Rating
#
# POST /api/v2/tickets/{ticket_id}/satisfaction_rating
# operationId: CreateTicketSatisfactionRating
export def "tickets-satisfaction-rating CreateTicketSatisfactionRating" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<satisfaction_rating: table<assignee_id: int, comment: string, created_at: string, group_id: int, id: int, reason: string, reason_code: int, reason_id: int, requester_id: int, score: string, ticket_id: int, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/satisfaction_rating")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Skips By Ticket
#
# GET /api/v2/tickets/{ticket_id}/skips
# operationId: ListTicketSkipsByTicket
export def "tickets-skips ListTicketSkipsByTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
]: nothing -> record<skips: table<created_at: string, id: int, reason: string, ticket: record, ticket_id: int, updated_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/skips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resource Tags
#
# GET /api/v2/tickets/{ticket_id}/tags
# operationId: ListResourceTags
export def "tickets-tags ListResourceTags" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Tags
#
# POST /api/v2/tickets/{ticket_id}/tags
# operationId: SetTagsTicket
export def "tickets-tags SetTagsTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Tags
#
# PUT /api/v2/tickets/{ticket_id}/tags
# operationId: PutTagsTicket
export def "tickets-tags PutTagsTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Tags
#
# DELETE /api/v2/tickets/{ticket_id}/tags
# operationId: DeleteTagsTicket
export def "tickets-tags DeleteTagsTicket" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tags: string # Comma-separated list of tags to remove from the ticket.
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Task List
#
# GET /api/v2/tickets/{ticket_id}/task_lists
# operationId: ShowTaskList
export def "tickets-task-lists ShowTaskList" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next_page: string, previous_page: string, task_lists: table<created_at: string, description: string, id: string, is_required: bool, name: string, task_count: int, task_list_template_id: string, ticket_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/task_lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Task List
#
# POST /api/v2/tickets/{ticket_id}/task_lists
# operationId: CreateTaskList
# --task_list shape: {task_list_template_id?: string}
export def "tickets-task-lists CreateTaskList" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --task-list: record # shape: {task_list_template_id?: string}
]: any -> record<count: int, next_page: string, previous_page: string, task_lists: table<created_at: string, description: string, id: string, is_required: bool, name: string, task_count: int, task_list_template_id: string, ticket_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/($ticket_id)/task_lists")
  let body = {task_list: $task_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Tickets
#
# GET /api/v2/tickets/count
# operationId: CountTickets
export def "tickets-count CountTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/tickets/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Many Tickets
#
# POST /api/v2/tickets/create_many
# operationId: TicketsCreateMany
# --tickets item shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record}
export def "tickets-create-many TicketsCreateMany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tickets: list # item shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record}
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/tickets/create_many")
  let body = {tickets: $tickets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Tickets
#
# DELETE /api/v2/tickets/destroy_many
# operationId: BulkDeleteTickets
export def "tickets-destroy-many BulkDeleteTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket ids (e.g. 35436,35437)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tickets/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Mark Tickets as Spam
#
# PUT /api/v2/tickets/mark_many_as_spam
# operationId: MarkManyTicketsAsSpam
export def "tickets-mark-many-as-spam MarkManyTicketsAsSpam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket ids (e.g. 35436,35437)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tickets/mark_many_as_spam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket by Messaging Conversation ID
#
# GET /api/v2/tickets/messaging/conversations/{conversation_id}/ticket
# operationId: ShowTicketByMessagingConversationId
export def "tickets-messaging-conversations-ticket ShowTicketByMessagingConversationId" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ticket: record<additional_collaborators: list<record>, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list<int>, brand_id: int, collaborator_ids: list<int>, collaborators: list<record>, comment: record<add_short_url: bool, attachments: list, audit_id: int, author_id: int, body: string, channel_back: string, channel_source_id: string, created_at: string, html_body: string, id: int, metadata: record, plain_body: string, public: bool, translate_to: string, type: string, uploads: list, via: record>, created_at: string, custom_fields: list<record>, custom_status_id: int, description: string, due_at: string, email_cc_ids: list<int>, email_ccs: list<record>, encoded_id: string, external_id: string, fields: list<record>, follower_ids: list<int>, followers: list<record>, followup_ids: list<int>, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list<int>, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list<int>, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record<client: string, ip_address: string>, tags: any, tde_workspace: record<previous_workspace: record, type: string, workspace: record>, ticket_form_id: int, tpe_voice_comment: record<agent_id: int, answering_machine_detection_status: string, app_id: int, app_name: string, author_id: int, call_connected_at: string, call_disposition: string, call_ended_at: string, call_id: int, call_recording_consent: string, call_recording_consent_action: string, call_recording_consent_keypress: string, call_started_at: string, call_type: string, callback_number: string, callback_requested_at: string, completion_status: string, connection_attempts: int, consultation_time: int, direction: string, disconnection_reason: string, dnis: string, duration: int, end_user_id: int, end_user_location: string, exceeded_queue_time: bool, extension: string, external_id: string, from_line: string, from_line_nickname: string, hold_time: int, intent: string, ivr_destination_group_name: string, ivr_time_spent: int, language: string, line_type: string, longest_hold_time: int, number_of_holds: int, outside_business_hours: bool, overflowed_to: string, phone_name: string, public: bool, quality_score: int, queue_name: string, queue_time: int, recorded: bool, recording_time: int, recording_type: string, recording_url: string, sentiment_agent: string, sentiment_call: string, sentiment_customer: string, sentiment_trend: string, short_summary: string, summary: string, talk_time: int, time_to_answer: int, title: string, to_line: string, to_line_nickname: string, transcript: string, via_id: int, video_recording_url: string, voicemail: bool, voicemail_requested_at: string, wait_time: int>, type: string, updated_at: string, updated_stamp: string, url: string, via: record<channel: any, source: record>, via_followup_source_id: int, via_id: int, voice_comment: record<answered_by_id: int, call_duration: int, from: string, location: string, recording_url: string, to: string, transcription_text: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tickets/messaging/conversations/($conversation_id)/ticket")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Recent Tickets
#
# GET /api/v2/tickets/recent
# operationId: ListRecentTickets
export def "tickets-recent ListRecentTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/tickets/recent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Multiple Tickets
#
# GET /api/v2/tickets/show_many
# operationId: TicketsShowMany
export def "tickets-show-many TicketsShowMany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket ids (e.g. 35436,35437)
  --include: string # A comma-separated list of sideloads to include.
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tickets/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Tickets
#
# PUT /api/v2/tickets/update_many
# operationId: TicketsUpdateMany
# --ticket shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record, additional_tags?: list, remove_tags?: list}
# --tickets item shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, id: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record, additional_tags?: list, remove_tags?: list}
export def "tickets-update-many TicketsUpdateMany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Comma-separated list of ticket ids (e.g. 35436,35437)
  --ticket: record # shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record, additional_tags?: list, remove_tags?: list}
  --tickets: list # item shape: {additional_collaborators?: list, assignee_email?: string, assignee_id?: int, attribute_value_ids?: list, brand_id?: int, collaborator_ids?: list, collaborators?: list, comment?: record, custom_fields?: list, custom_status_id?: int, description?: string, due_at?: string, email_ccs?: list, external_id?: string, fields?: list, followers?: list, forum_topic_id?: int, group_id?: int, id: int, macro_id?: int, macro_ids?: list, metadata?: record, organization_id?: int, origin_zrn?: string, priority?: "urgent"|"high"|"normal"|"low", problem_id?: int, raw_subject?: string, recipient?: string, requester?: any, requester_id?: int, safe_update?: bool, sharing_agreement_ids?: list, sharing_agreements?: any, status?: "new"|"open"|"pending"|"hold"|"solved"|"closed", subject?: string, submitter_id?: int, support_type?: "agent"|"ai_agent", suspended_ticket_id?: int, suspension_type_id?: int, system_metadata?: record, tags?: any, tde_workspace?: record, ticket_form_id?: int, tpe_voice_comment?: record, type?: "problem"|"incident"|"question"|"task", updated_stamp?: string, via_followup_source_id?: int, via_id?: int, voice_comment?: record, additional_tags?: list, remove_tags?: list}
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/tickets/update_many" $qp)
  let body = {ticket: $ticket, tickets: $tickets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Ticket Trigger Categories
#
# GET /api/v2/trigger_categories
# operationId: ListTriggerCategories
export def "trigger-categories ListTriggerCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Pagination parameters (e.g. {after: eyJvIjoiLXNjb3JlLGlkIiwidiI6ImFRSUFBQUFBQUFBQWFRMHBJUUVBQUFBQSJ9, before: eyJvIjoiLXNjb3JlLGlkIiwidiI6ImFRSUFBQUFBQUFBQWFRMHBJUUVBQUFBQSJ9, size: 50})
  --qp-sort: string@sort-completer # Sort parameters
  --include: string@include-completer # Allowed sideloads
]: nothing -> record<trigger_categories: list<record>, links: record<next: string, prev: string>, meta: record<after_cursor: string, before_cursor: string, has_more: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/trigger_categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ticket Trigger Category
#
# POST /api/v2/trigger_categories
# operationId: CreateTriggerCategory
# --trigger_category shape: {name: string, position?: int}
export def "trigger-categories CreateTriggerCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger-category: record # shape: {name: string, position?: int}
]: any -> record<trigger_category: record<created_at: string, id: string, name: string, position: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/trigger_categories")
  let body = {trigger_category: $trigger_category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Ticket Trigger Category
#
# GET /api/v2/trigger_categories/{trigger_category_id}
# operationId: ShowTriggerCategoryById
export def "trigger-categories ShowTriggerCategoryById" [
  trigger_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trigger_category: record<created_at: string, id: string, name: string, position: int, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/trigger_categories/($trigger_category_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ticket Trigger Category
#
# PATCH /api/v2/trigger_categories/{trigger_category_id}
# operationId: UpdateTriggerCategory
# --trigger_category shape: {name?: string, position?: int}
export def "trigger-categories UpdateTriggerCategory" [
  trigger_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger-category: record # shape: {name?: string, position?: int}
]: any -> record<trigger_category: record<created_at: string, id: string, name: string, position: int, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/trigger_categories/($trigger_category_id)")
  let body = {trigger_category: $trigger_category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ticket Trigger Category
#
# DELETE /api/v2/trigger_categories/{trigger_category_id}
# operationId: DeleteTriggerCategory
export def "trigger-categories DeleteTriggerCategory" [
  trigger_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/trigger_categories/($trigger_category_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Batch Job for Ticket Trigger Categories
#
# POST /api/v2/trigger_categories/jobs
# operationId: BatchOperateTriggerCategories
# --job shape: {action?: "patch", items?: record}
export def "trigger-categories-jobs BatchOperateTriggerCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --job: record # shape: {action?: "patch", items?: record}
]: any -> record<errors: list<record>, results: record<trigger_categories: list<record>, triggers: list<record>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/trigger_categories/jobs")
  let body = {job: $job} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Ticket Triggers
#
# GET /api/v2/triggers
# operationId: ListTriggers
export def "triggers ListTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Filter by active triggers if true or inactive triggers if false (e.g. true)
  --qp-sort: string # Cursor-based pagination only. Possible values are "alphabetical", "created_at", "updated_at", or "position". (e.g. position)
  --sort-by: string # Offset pagination only. Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", or "usage_7d". Defaults to "position" (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
  --category-id: string # Filter triggers by category ID (e.g. 10026)
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_24h)
]: nothing -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, all: list, any: list, brand_id: int, category: record, category_id: string, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Trigger
#
# POST /api/v2/triggers
# operationId: CreateTrigger
# --trigger shape: {actions: list, active?: bool, all?: list, any?: list, brand_id?: int, category?: record, category_id?: string, conditions?: record, description?: string, position?: int, raw_title?: string, restriction?: record, title: string}
export def "triggers CreateTrigger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger: record # e.g. {actions: [{}], active: true, category_id: 10026, conditions: {}, created_at: 2012-09-25T22:50:26Z, default: false, description: Close and save a ticket, id: 25, position: 8, raw_title: Close and Save, title: Close and Save, updated_at: 2012-09-25T22:50:26Z, url: http://{subdomain}.zendesk.com/api/v2/triggers/25} — shape: {actions: list, active?: bool, all?: list, any?: list, brand_id?: int, category?: record, category_id?: string, conditions?: record, description?: string, position?: int, raw_title?: string, restriction?: record, title: string}
]: any -> record<trigger: record<actions: list<record>, active: bool, all: list<record>, any: list<record>, brand_id: int, category: record<name: string, position: int>, category_id: string, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/triggers")
  let body = {trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Ticket Trigger
#
# GET /api/v2/triggers/{trigger_id}
# operationId: GetTrigger
export def "triggers GetTrigger" [
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trigger: record<actions: list<record>, active: bool, all: list<record>, any: list<record>, brand_id: int, category: record<name: string, position: int>, category_id: string, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/triggers/($trigger_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ticket Trigger
#
# PUT /api/v2/triggers/{trigger_id}
# operationId: UpdateTrigger
# --trigger shape: {actions: list, active?: bool, all?: list, any?: list, brand_id?: int, category?: record, category_id?: string, conditions?: record, description?: string, position?: int, raw_title?: string, restriction?: record, title: string}
export def "triggers UpdateTrigger" [
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger: record # e.g. {actions: [{}], active: true, category_id: 10026, conditions: {}, created_at: 2012-09-25T22:50:26Z, default: false, description: Close and save a ticket, id: 25, position: 8, raw_title: Close and Save, title: Close and Save, updated_at: 2012-09-25T22:50:26Z, url: http://{subdomain}.zendesk.com/api/v2/triggers/25} — shape: {actions: list, active?: bool, all?: list, any?: list, brand_id?: int, category?: record, category_id?: string, conditions?: record, description?: string, position?: int, raw_title?: string, restriction?: record, title: string}
]: any -> record<trigger: record<actions: list<record>, active: bool, all: list<record>, any: list<record>, brand_id: int, category: record<name: string, position: int>, category_id: string, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/triggers/($trigger_id)")
  let body = {trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ticket Trigger
#
# DELETE /api/v2/triggers/{trigger_id}
# operationId: DeleteTrigger
export def "triggers DeleteTrigger" [
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/triggers/($trigger_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Trigger Revisions
#
# GET /api/v2/triggers/{trigger_id}/revisions
# operationId: ListTriggerRevisions
export def "triggers-revisions ListTriggerRevisions" [
  trigger_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<after_cursor: string, after_url: string, before_cursor: string, before_url: string, count: int, trigger_revisions: table<author_id: int, created_at: string, diff: record, id: int, snapshot: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/triggers/($trigger_id)/revisions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Ticket Trigger Revision
#
# GET /api/v2/triggers/{trigger_id}/revisions/{trigger_revision_id}
# operationId: TriggerRevision
export def "triggers-revisions TriggerRevision" [
  trigger_id: int
  trigger_revision_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trigger_revision: record<author_id: int, created_at: string, id: int, snapshot: record<actions: list, active: bool, conditions: record, description: string, title: string>, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/triggers/($trigger_id)/revisions/($trigger_revision_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Active Ticket Triggers
#
# GET /api/v2/triggers/active
# operationId: ListActiveTriggers
export def "triggers-active ListActiveTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # Cursor-based pagination only. Possible values are "alphabetical", "created_at", "updated_at", or "position". (e.g. position)
  --sort-by: string # Offset pagination only. Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", or "usage_7d". Defaults to "position" (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
  --category-id: string # Filter triggers by category ID (e.g. 10026)
]: nothing -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, all: list, any: list, brand_id: int, category: record, category_id: string, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "category_id" $category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/triggers/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Trigger Action and Condition Definitions
#
# GET /api/v2/triggers/definitions
# operationId: ListTriggerActionConditionDefinitions
export def "triggers-definitions ListTriggerActionConditionDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<actions: list<record>, conditions_all: list<record>, conditions_any: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/triggers/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Ticket Triggers
#
# DELETE /api/v2/triggers/destroy_many
# operationId: DeleteManyTriggers
export def "triggers-destroy-many DeleteManyTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of trigger IDs (e.g. 131,178,938)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/triggers/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Ticket Triggers
#
# PUT /api/v2/triggers/reorder
# operationId: ReorderTriggers
export def "triggers-reorder ReorderTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trigger: record<actions: list<record>, active: bool, all: list<record>, any: list<record>, brand_id: int, category: record<name: string, position: int>, category_id: string, conditions: record<all: list, any: list>, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/triggers/reorder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Ticket Triggers
#
# GET /api/v2/triggers/search
# operationId: SearchTriggers
export def "triggers-search SearchTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Query string used to find all triggers with matching title (e.g. important_trigger)
  --filter: string # JSON-encoded trigger attribute filters for the search. See [Filter](#filter).  Example: `{"json":{"description":"Close a ticket"}}`  (e.g. {"json":{"description":"Close a ticket"}})
  --active: string@bool-completer # Filter by active triggers if true or inactive triggers if false (e.g. true)
  --qp-sort: string # Cursor-based pagination only. Possible values are "alphabetical", "created_at", "updated_at", or "position". (e.g. position)
  --sort-by: string # Offset pagination only. Possible values are "alphabetical", "created_at", "updated_at", "usage_1h", "usage_24h", or "usage_7d". Defaults to "position" (e.g. position)
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others (e.g. desc)
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-2) (e.g. usage_24h)
]: nothing -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, all: list, any: list, brand_id: int, category: record, category_id: string, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/triggers/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Ticket Triggers
#
# PUT /api/v2/triggers/update_many
# operationId: UpdateManyTriggers
# --triggers item shape: {active?: bool, category_id?: string, id: int, position?: int}
export def "triggers-update-many UpdateManyTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --triggers: list # item shape: {active?: bool, category_id?: string, id: int, position?: int}
]: any -> record<count: int, next_page: string, previous_page: string, triggers: table<actions: list, active: bool, all: list, any: list, brand_id: int, category: record, category_id: string, conditions: record, created_at: string, default: bool, description: string, id: int, position: int, raw_title: string, restriction: record, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/triggers/update_many")
  let body = {triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload Files
#
# POST /api/v2/uploads
# operationId: UploadFiles
export def "uploads UploadFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # The name to assign to the uploaded file (e.g. my_document.pdf)
]: nothing -> record<upload: record<attachment: record, attachments: list<record>, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filename" $filename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/uploads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Upload
#
# DELETE /api/v2/uploads/{token}
# operationId: DeleteUpload
export def "uploads DeleteUpload" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/uploads/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Fields
#
# GET /api/v2/user_fields
# operationId: ListUserFields
export def "user-fields ListUserFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --resolve-dc: string@bool-completer # If true, resolves dynamic content placeholders.
]: nothing -> record<count: int, next_page: string, previous_page: string, user_fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "resolve_dc" $resolve_dc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/user_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Field
#
# POST /api/v2/user_fields
# operationId: CreateUserField
export def "user-fields CreateUserField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/user_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show User Field
#
# GET /api/v2/user_fields/{user_field_id}
# operationId: ShowUserField
export def "user-fields ShowUserField" [
  user_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Field
#
# PUT /api/v2/user_fields/{user_field_id}
# operationId: UpdateUserField
export def "user-fields UpdateUserField" [
  user_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_field: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Field
#
# DELETE /api/v2/user_fields/{user_field_id}
# operationId: DeleteUserField
export def "user-fields DeleteUserField" [
  user_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Field Options
#
# GET /api/v2/user_fields/{user_field_id}/options
# operationId: ListUserFieldOptions
export def "user-fields-options ListUserFieldOptions" [
  user_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, custom_field_options: table<allow_solving: bool, id: int, name: string, position: int, raw_name: string, url: string, value: string>, next_page: string, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update a User Field Option
#
# POST /api/v2/user_fields/{user_field_id}/options
# operationId: CreateOrUpdateUserFieldOption
export def "user-fields-options CreateOrUpdateUserFieldOption" [
  user_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_field_option: record<allow_solving: bool, id: int, name: string, position: int, raw_name: string, url: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show a User Field Option
#
# GET /api/v2/user_fields/{user_field_id}/options/{user_field_option_id}
# operationId: ShowUserFieldOption
export def "user-fields-options ShowUserFieldOption" [
  user_field_id: string
  user_field_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<custom_field_option: record<allow_solving: bool, id: int, name: string, position: int, raw_name: string, url: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)/options/($user_field_option_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Field Option
#
# DELETE /api/v2/user_fields/{user_field_id}/options/{user_field_option_id}
# operationId: DeleteUserFieldOption
export def "user-fields-options DeleteUserFieldOption" [
  user_field_id: string
  user_field_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/user_fields/($user_field_id)/options/($user_field_option_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder User Field
#
# PUT /api/v2/user_fields/reorder
# operationId: ReorderUserField
export def "user-fields-reorder ReorderUserField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/user_fields/reorder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many User Fields
#
# GET /api/v2/user_fields/show_many
# operationId: ShowManyUserFields
export def "user-fields-show-many ShowManyUserFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keys: string # Comma-separated list of user field keys to retrieve.  (e.g. my_field_1,my_field_2)
]: nothing -> record<count: int, next_page: string, previous_page: string, user_fields: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/user_fields/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Users
#
# GET /api/v2/users
# operationId: ListUsers
export def "users ListUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # Filters the results by role. Possible values are "end-user", "agent", "admin", or a custom role name  (e.g. agent)
  --role: string # Filters the results by more than one role using the format `role[]={role}&role[]={role}`  (e.g. agent)
  --permission-set: int # For custom roles which is available on the Enterprise plan and above. You can only filter by one role ID per request (format: int64, e.g. 123)
  --external-id: string # List users by external id. External id has to be unique for each user under the same account. (e.g. abc)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/users/users/#sideloading).  (e.g. roles,organizations)
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --brand-id: int # When brand separation is enabled, scopes the listing to users belonging to the specified brand. Only applicable when the account has brand separation enabled.  (format: int64, e.g. 123)
]: nothing -> record<users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "role[]" $role "scalar") (serialize-qp "permission_set" $permission_set "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar") (serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User
#
# POST /api/v2/users
# operationId: CreateUser
export def "users CreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user: any
]: any -> record<user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show User
#
# GET /api/v2/users/{user_id}
# operationId: ShowUser
export def "users ShowUser" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/users/users/#sideloading).  (e.g. roles,organizations)
]: nothing -> record<user: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User
#
# PUT /api/v2/users/{user_id}
# operationId: UpdateUser
# --user shape: {agent_brand_ids?: list, alias?: string, custom_role_id?: int, default_group_id?: int, details?: string, email?: string, external_id?: string, group_id?: int, identities?: list, language?: string, locale?: string, locale_id?: int, moderator?: bool, name?: string, notes?: string, only_private_comments?: bool, organization_id?: int, organization_ids?: list, phone?: string, photo?: record, remote_photo_url?: string, role?: string, shared_phone_number?: bool, signature?: string, skip_verify_email?: bool, suspended?: bool, tags?: list, ticket_restriction?: string, time_zone?: string, user_fields?: record, verified?: bool}
export def "users UpdateUser" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user: record # Input schema for updating a user. All fields are optional - only include the fields you want to update. — shape: {agent_brand_ids?: list, alias?: string, custom_role_id?: int, default_group_id?: int, details?: string, email?: string, external_id?: string, group_id?: int, identities?: list, language?: string, locale?: string, locale_id?: int, moderator?: bool, name?: string, notes?: string, only_private_comments?: bool, organization_id?: int, organization_ids?: list, phone?: string, photo?: record, remote_photo_url?: string, role?: string, shared_phone_number?: bool, signature?: string, skip_verify_email?: bool, suspended?: bool, tags?: list, ticket_restriction?: string, time_zone?: string, user_fields?: record, verified?: bool}
]: any -> record<user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User
#
# DELETE /api/v2/users/{user_id}
# operationId: DeleteUser
export def "users DeleteUser" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Brand Agent Memberships By User
#
# GET /api/v2/users/{user_id}/brand_agents
# operationId: ListUserBrandAgents
export def "users-brand-agents ListUserBrandAgents" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<brand_agents: table<brand_id: int, created_at: string, id: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/brand_agents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Brand Agent Membership By User
#
# GET /api/v2/users/{user_id}/brand_agents/{brand_agent_id}
# operationId: ShowUserBrandAgentById
export def "users-brand-agents ShowUserBrandAgentById" [
  user_id: int
  brand_agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<brand_agent: record<brand_id: int, created_at: string, id: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/brand_agents/($brand_agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Compliance Deletion Statuses
#
# GET /api/v2/users/{user_id}/compliance_deletion_statuses
# operationId: ShowUserComplianceDeletionStatuses
export def "users-compliance-deletion-statuses ShowUserComplianceDeletionStatuses" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string # Area of compliance (e.g. chat)
]: nothing -> record<compliance_deletion_statuses: table<account_subdomain: string, action: string, application: string, created_at: string, executer_id: int, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "application" $application "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/compliance_deletion_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Full User Entitlements
#
# GET /api/v2/users/{user_id}/entitlements/full
# operationId: GetUserEntitlementsFull
export def "users-entitlements-full GetUserEntitlementsFull" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entitlements: record<chat: record<is_active: bool, name: string>, explore: record<is_active: bool, name: string>, guide: record<is_active: bool, name: string>, talk: record<is_active: bool, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/entitlements/full")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Group Memberships by User
#
# GET /api/v2/users/{user_id}/group_memberships
# operationId: ListUserGroupMemberships
export def "users-group-memberships ListUserGroupMemberships" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. Valid values: `users`, `groups`.  (e.g. users,groups)
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<group_memberships: table<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "include" $include "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/group_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Group Membership for User
#
# POST /api/v2/users/{user_id}/group_memberships
# operationId: CreateUserGroupMembership
export def "users-group-memberships CreateUserGroupMembership" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_membership: record<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/group_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show User's Group Membership
#
# GET /api/v2/users/{user_id}/group_memberships/{group_membership_id}
# operationId: ShowUserGroupMembershipById
export def "users-group-memberships ShowUserGroupMembershipById" [
  user_id: int
  group_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_membership: record<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/group_memberships/($group_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User's Group Membership
#
# DELETE /api/v2/users/{user_id}/group_memberships/{group_membership_id}
# operationId: DeleteUserGroupMembership
export def "users-group-memberships DeleteUserGroupMembership" [
  user_id: int
  group_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/group_memberships/($group_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Membership as Default
#
# PUT /api/v2/users/{user_id}/group_memberships/{group_membership_id}/make_default
# operationId: GroupMembershipSetDefault
export def "users-group-memberships-make-default GroupMembershipSetDefault" [
  user_id: int
  group_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_memberships: table<created_at: string, default: bool, group_id: int, id: int, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/group_memberships/($group_membership_id)/make_default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Groups
#
# GET /api/v2/users/{user_id}/groups
# operationId: ListUserGroups
export def "users-groups ListUserGroups" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<groups: table<created_at: string, default: bool, deleted: bool, description: string, id: int, is_public: bool, name: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count User Groups
#
# GET /api/v2/users/{user_id}/groups/count
# operationId: CountUserGroups
export def "users-groups-count CountUserGroups" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/groups/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Identities
#
# GET /api/v2/users/{user_id}/identities
# operationId: ListUserIdentities
export def "users-identities ListUserIdentities" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Filters results by one or more identity types using the format `?type[]={type}&type[]={type}`
  --page: record # Cursor-based pagination parameters (JSON:API style).  Supports nested parameters: - `page[size]` - Number of records per page (default varies by endpoint, typically 100) - `page[after]` - Cursor token to fetch records after this position - `page[before]` - Cursor token to fetch records before this position  Example: `?page[size]=50&page[after]=eyJvIjoiaWQiLCJ2IjoiYVFFPSJ9`
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<identities: table<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "page" $page "deepObject") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Identity
#
# POST /api/v2/users/{user_id}/identities
# operationId: CreateUserIdentity
export def "users-identities CreateUserIdentity" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand-id: int # When the account has multiple active brands, sets the active brand context for the created identity. Used to scope verification emails to the correct brand.  (format: int64, e.g. 123)
]: nothing -> record<identity: record<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Identity
#
# GET /api/v2/users/{user_id}/identities/{user_identity_id}
# operationId: ShowUserIdentity
export def "users-identities ShowUserIdentity" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identity: record<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities/($user_identity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Identity
#
# PUT /api/v2/users/{user_id}/identities/{user_identity_id}
# operationId: UpdateUserIdentity
export def "users-identities UpdateUserIdentity" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identity: record<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities/($user_identity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Identity
#
# DELETE /api/v2/users/{user_id}/identities/{user_identity_id}
# operationId: DeleteUserIdentity
export def "users-identities DeleteUserIdentity" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities/($user_identity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make Identity Primary
#
# PUT /api/v2/users/{user_id}/identities/{user_identity_id}/make_primary
# operationId: MakeUserIdentityPrimary
export def "users-identities-make-primary MakeUserIdentityPrimary" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identities: table<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities/($user_identity_id)/make_primary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request User Verification
#
# PUT /api/v2/users/{user_id}/identities/{user_identity_id}/request_verification
# operationId: RequestUserVerification
export def "users-identities-request-verification RequestUserVerification" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand-id: int # When the account has multiple active brands, sets the active brand context for the verification email. Scopes the email template and sender to the specified brand.  (format: int64, e.g. 123)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities/($user_identity_id)/request_verification" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Identity
#
# PUT /api/v2/users/{user_id}/identities/{user_identity_id}/verify
# operationId: VerifyUserIdentity
export def "users-identities-verify VerifyUserIdentity" [
  user_id: int
  user_identity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identity: record<brand_id: int, created_at: string, deliverable_state: string, id: int, primary: bool, type: string, undeliverable_count: int, updated_at: string, url: string, user_id: int, value: string, verification_method: string, verified: bool, verified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/identities/($user_identity_id)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge End Users
#
# PUT /api/v2/users/{user_id}/merge
# operationId: MergeEndUsers
export def "users-merge MergeEndUsers" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user: any
]: any -> record<user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/merge")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Organization Memberships by User
#
# GET /api/v2/users/{user_id}/organization_memberships
# operationId: ListUserOrganizationMemberships
export def "users-organization-memberships ListUserOrganizationMemberships" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. Valid values: `users`, `organizations`.  (e.g. organizations)
]: nothing -> record<organization_memberships: table<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization Membership for User
#
# POST /api/v2/users/{user_id}/organization_memberships
# operationId: CreateUserOrganizationMembership
export def "users-organization-memberships CreateUserOrganizationMembership" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_membership: record<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organization_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Organization Membership by User
#
# GET /api/v2/users/{user_id}/organization_memberships/{organization_membership_id}
# operationId: ShowOrganizationMembershipByUserId
export def "users-organization-memberships ShowOrganizationMembershipByUserId" [
  user_id: int
  organization_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_membership: record<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organization_memberships/($organization_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Organization Membership for User
#
# DELETE /api/v2/users/{user_id}/organization_memberships/{organization_membership_id}
# operationId: DeleteUserOrganizationMembership
export def "users-organization-memberships DeleteUserOrganizationMembership" [
  user_id: int
  organization_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organization_memberships/($organization_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Membership as Default
#
# PUT /api/v2/users/{user_id}/organization_memberships/{organization_membership_id}/make_default
# operationId: SetOrganizationMembershipAsDefault
export def "users-organization-memberships-make-default SetOrganizationMembershipAsDefault" [
  user_id: int
  organization_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_memberships: table<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organization_memberships/($organization_membership_id)/make_default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User's Organization Subscriptions
#
# GET /api/v2/users/{user_id}/organization_subscriptions
# operationId: ListUserOrganizationSubscriptions
export def "users-organization-subscriptions ListUserOrganizationSubscriptions" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organization_subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Organizations
#
# GET /api/v2/users/{user_id}/organizations
# operationId: ListUserOrganizations
export def "users-organizations ListUserOrganizations" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-sort: string # Field to sort results by. Prefix with `-` for descending order.  When used with cursor pagination, this determines the cursor ordering.  Example: `?sort=name` or `?sort=-created_at`  (e.g. name)
  --include-boundary-indicators: string@bool-completer # When true, includes `has_more` indicator in the cursor pagination response meta.  Only valid with cursor pagination (page[size], page[after], page[before]).
  --include-item-cursors: string@bool-completer # When true, includes cursor values for each item in the cursor pagination response.  Only valid with cursor pagination (page[size], page[after], page[before]).
]: nothing -> record<count: int, next_page: string, organizations: table<created_at: string, details: string, domain_names: list, external_id: string, group_id: int, id: int, name: string, notes: string, organization_fields: record, shared_comments: bool, shared_tickets: bool, tags: list, updated_at: string, url: string>, previous_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_boundary_indicators" $include_boundary_indicators "scalar") (serialize-qp "include_item_cursors" $include_item_cursors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unassign Organization
#
# DELETE /api/v2/users/{user_id}/organizations/{organization_id}
# operationId: UnassignOrganization
export def "users-organizations UnassignOrganization" [
  organization_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Organization as Default
#
# PUT /api/v2/users/{user_id}/organizations/{organization_id}/make_default
# operationId: SetOrganizationAsDefault
export def "users-organizations-make-default SetOrganizationAsDefault" [
  user_id: int
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_membership: record<created_at: string, default: bool, id: int, organization_id: int, organization_name: string, updated_at: string, url: string, user_id: int, view_tickets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organizations/($organization_id)/make_default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count User's Organizations
#
# GET /api/v2/users/{user_id}/organizations/count
# operationId: CountUserOrganizations
export def "users-organizations-count CountUserOrganizations" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/organizations/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a User's Password
#
# POST /api/v2/users/{user_id}/password
# operationId: SetUserPassword
export def "users-password SetUserPassword" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Your Password
#
# PUT /api/v2/users/{user_id}/password
# operationId: ChangeOwnPassword
export def "users-password ChangeOwnPassword" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brand-id: int # Sets the active brand context for the password change. Used to scope the session to the correct brand when the account has multiple active brands.  (format: int64, e.g. 123)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/password" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List password requirements
#
# GET /api/v2/users/{user_id}/password/requirements
# operationId: GetUserPasswordRequirements
export def "users-password-requirements GetUserPasswordRequirements" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<requirements: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/password/requirements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show User Related Information
#
# GET /api/v2/users/{user_id}/related
# operationId: ShowUserRelated
export def "users-related ShowUserRelated" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_related: record<assigned_tickets: int, ccd_tickets: int, organization_subscriptions: int, requested_tickets: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/related")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Requests
#
# GET /api/v2/users/{user_id}/requests
# operationId: ListUserRequests
export def "users-requests ListUserRequests" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Possible values are "updated_at", "created_at"
  --sort-order: string # One of "asc", "desc". Defaults to "asc"
]: nothing -> record<requests: table<assignee_id: int, can_be_solved_by_me: bool, collaborator_ids: list, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, followup_source_id: int, group_id: int, id: int, is_public: bool, organization_id: int, priority: string, recipient: string, requester_id: int, solved: bool, status: string, subject: string, ticket_form_id: int, type: string, updated_at: string, url: string, via: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sessions for User
#
# GET /api/v2/users/{user_id}/sessions
# operationId: ListUserSessions
export def "users-sessions ListUserSessions" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sessions: table<authenticated_at: string, id: int, last_seen_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Sessions
#
# DELETE /api/v2/users/{user_id}/sessions
# operationId: BulkDeleteSessionsByUserId
export def "users-sessions BulkDeleteSessionsByUserId" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Session
#
# GET /api/v2/users/{user_id}/sessions/{session_id}
# operationId: ShowSession
export def "users-sessions ShowSession" [
  session_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<session: table<authenticated_at: string, id: int, last_seen_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/sessions/($session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Session
#
# DELETE /api/v2/users/{user_id}/sessions/{session_id}
# operationId: DeleteSession
export def "users-sessions DeleteSession" [
  session_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/sessions/($session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ticket Skips
#
# GET /api/v2/users/{user_id}/skips
# operationId: ListTicketSkips
export def "users-skips ListTicketSkips" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
]: nothing -> record<skips: table<created_at: string, id: int, reason: string, ticket: record, ticket_id: int, updated_at: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/skips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Tags
#
# GET /api/v2/users/{user_id}/tags
# operationId: ListUserTags
export def "users-tags ListUserTags" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set User Tags
#
# POST /api/v2/users/{user_id}/tags
# operationId: SetUserTags
export def "users-tags SetUserTags" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add User Tags
#
# PUT /api/v2/users/{user_id}/tags
# operationId: PutUserTags
export def "users-tags PutUserTags" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove User Tags
#
# DELETE /api/v2/users/{user_id}/tags
# operationId: DeleteUserTags
export def "users-tags DeleteUserTags" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Assigned Tickets
#
# GET /api/v2/users/{user_id}/tickets/assigned
# operationId: ListUserAssignedTickets
export def "users-tickets-assigned ListUserAssignedTickets" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tickets/assigned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count User Assigned Tickets
#
# GET /api/v2/users/{user_id}/tickets/assigned/count
# operationId: CountUserAssignedTickets
export def "users-tickets-assigned-count CountUserAssignedTickets" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tickets/assigned/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User CCD Tickets
#
# GET /api/v2/users/{user_id}/tickets/ccd
# operationId: ListUserCCDTickets
export def "users-tickets-ccd ListUserCCDTickets" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tickets/ccd")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count User CCD Tickets
#
# GET /api/v2/users/{user_id}/tickets/ccd/count
# operationId: CountUserCCDTickets
export def "users-tickets-ccd-count CountUserCCDTickets" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tickets/ccd/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Followed Tickets
#
# GET /api/v2/users/{user_id}/tickets/followed
# operationId: ListUserFollowedTickets
export def "users-tickets-followed ListUserFollowedTickets" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string@sort-by-completer # Sort by
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --exclude-archived: string@bool-completer # If true, excludes archived tickets from the results.
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tickets/followed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Requested Tickets
#
# GET /api/v2/users/{user_id}/tickets/requested
# operationId: ListUserRequestedTickets
export def "users-tickets-requested ListUserRequestedTickets" [
  user_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string@sort-by-completer # Sort by
  --sort-order: string@sort-order-completer # Sort order. Defaults to "asc"
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/tickets/tickets/#sideloading).  (e.g. users,groups,organizations)
  --exclude-archived: string@bool-completer # If true, excludes archived tickets from the results.
  --exclude-count: string@bool-completer # If true, excludes the total count from the results.
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar") (serialize-qp "exclude_count" $exclude_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/users/($user_id)/tickets/requested" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Autocomplete Users
#
# GET /api/v2/users/autocomplete
# operationId: AutocompleteUsers
export def "users-autocomplete AutocompleteUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name to search for the user. You must specify either `name` or `phone`.  (e.g. gil)
  --phone: string # The phone number to search for the user. You must specify either `name` or `phone`.
  --filter: string@filter-completer # Filter to apply to autocomplete results. Accepted values: `assignable`, `requester`.
  --field-id: string # The id of a lookup relationship field.  The type of field is determined by the `source` param
  --qp-source: string # If a `field_id` is provided, this specifies the type of the field. For example, if the field is on a "zen:user", it references a field on a user
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/users/users/#sideloading).  (e.g. roles,organizations)
  --per-page: int # Number of results to return.
  --brand-id: int # When brand separation is enabled, scopes the autocomplete results to users belonging to the specified brand. Only applicable when the account has brand separation enabled.  (format: int64, e.g. 123)
]: nothing -> record<users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "phone" $phone "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "field_id" $field_id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Autocomplete Users by Request Body
#
# POST /api/v2/users/autocomplete
# operationId: AutocompleteUsersPost
export def "users-autocomplete AutocompleteUsersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/users/users/#sideloading).  (e.g. roles,organizations)
  --filter: string # Filter to apply to autocomplete results. Common values: `assignable`, `requester`.
  --per-page: int # Number of results to return.
  --brand-id: int # When brand separation is enabled, scopes the autocomplete results to users belonging to the specified brand. Only applicable when the account has brand separation enabled.  (format: int64)
  --field-id: int # Field ID for lookup relationship autocomplete (format: int64)
  --filter: any # Filter to apply (assignable, requester, or dynamic_values)
  --name: string # The name to search for the user (e.g. gil)
  --phone: string # The phone number to search for the user
  --body-source: string # Source for lookup relationship autocomplete
]: any -> record<users: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/autocomplete" $qp)
  let body = {brand_id: $brand_id, field_id: $field_id, filter: $filter, name: $name, phone: $phone, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Users
#
# GET /api/v2/users/count
# operationId: CountUsers
export def "users-count CountUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # Filters the results by role. Possible values are "end-user", "agent", "admin", or a custom role name  (e.g. agent)
  --role: string # Filters the results by more than one role using the format `role[]={role}&role[]={role}`  (e.g. agent)
  --permission-set: int # For custom roles which is available on the Enterprise plan and above. You can only filter by one role ID per request (format: int64, e.g. 123)
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "role[]" $role "scalar") (serialize-qp "permission_set" $permission_set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Many Users
#
# POST /api/v2/users/create_many
# operationId: CreateManyUsers
export def "users-create-many CreateManyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/create_many")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Or Update User
#
# POST /api/v2/users/create_or_update
# operationId: CreateOrUpdateUser
export def "users-create-or-update CreateOrUpdateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user: any
]: any -> record<user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/create_or_update")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Or Update Many Users
#
# POST /api/v2/users/create_or_update_many
# operationId: CreateOrUpdateManyUsers
export def "users-create-or-update-many CreateOrUpdateManyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/create_or_update_many")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Users
#
# DELETE /api/v2/users/destroy_many
# operationId: DestroyManyUsers
export def "users-destroy-many DestroyManyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Id of the users to delete. Comma separated (e.g. 1,2,3)
  --external-ids: string # External Id of the users to delete. Comma separated (e.g. abc,def,ghi)
  --brand-id: string # Scopes the deletion of users matched by `external_ids` to a specific brand or to account-scoped (brand-less) users. Only applicable when the account has brand separation enabled (`brand_user_separation_eap`); ignored otherwise so existing numeric callers continue to behave as before.  Accepted values:  * `0` — restrict the lookup to account-scoped (brand-less) users only. * A numeric brand id — restrict to that brand. Brands without   `user_separation` enabled collapse to account scope (`0`).  Rejected with `400 Bad Request`:  * `all` — cross-brand deletion is not supported on this endpoint. * Any other non-numeric string. * A numeric brand id that does not exist on the account. * Combining `brand_id` with `ids` (use `external_ids` instead — `ids` are   globally unique so brand scoping is meaningless).  When `external_ids` is provided without `brand_id`, the request defaults to account scope (`0`).  When forwarded to the bulk-delete background job, the resolved brand id is always passed as an Integer (`0` for account scope; the brand id otherwise) for backward compatibility with existing job consumers.  (e.g. 0)
]: nothing -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "external_ids" $external_ids "scalar") (serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logout many users
#
# POST /api/v2/users/logout_many
# operationId: LogoutManyUsers
export def "users-logout-many LogoutManyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Accepts a comma-separated list of up to 100 user ids.  (e.g. 1,2)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/logout_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Self
#
# GET /api/v2/users/me
# operationId: ShowCurrentUser
export def "users-me ShowCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/users/users/#sideloading).  (e.g. roles,organizations)
]: nothing -> record<user: record<authenticity_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Authenticated Session
#
# DELETE /api/v2/users/me/logout
# operationId: DeleteAuthenticatedSession
export def "users-me-logout DeleteAuthenticatedSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Current User's Clients
#
# GET /api/v2/users/me/oauth/clients
# operationId: ListCurrentUserOAuthClients
export def "users-me-oauth-clients ListCurrentUserOAuthClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<clients: table<company: string, created_at: string, description: string, global: bool, id: int, identifier: string, kind: string, logo_url: string, name: string, redirect_uri: list, secret: string, updated_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/oauth/clients")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the Currently Authenticated Session
#
# GET /api/v2/users/me/session
# operationId: ShowCurrentlyAuthenticatedSession
export def "users-me-session ShowCurrentlyAuthenticatedSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<session: table<authenticated_at: string, id: int, last_seen_at: string, url: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/session")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renew the current session
#
# GET /api/v2/users/me/session/renew
# operationId: RenewCurrentSession
export def "users-me-session-renew RenewCurrentSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authenticity_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/session/renew")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Current User Settings
#
# GET /api/v2/users/me/settings
# operationId: ShowCurrentUserSettings
export def "users-me-settings ShowCurrentUserSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<admin_center: record<has_admin_center_side_nav_open: bool>, lotus: record<agent_workspace_theme_preference: string, agent_workspace_theme_preference_for_conversation_panel: string, keyboard_shortcuts_enabled: bool, macro_shortcuts_enabled: bool, show_onboarding_tooltips: bool, two_factor_authentication: bool>, shared_views_order: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Current User Settings
#
# PUT /api/v2/users/me/settings
# operationId: UpdateCurrentUserSettings
# --settings shape: {admin_center?: record, lotus?: record, shared_views_order?: list}
export def "users-me-settings UpdateCurrentUserSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: record # User settings to update — shape: {admin_center?: record, lotus?: record, shared_views_order?: list}
]: any -> record<settings: record<admin_center: record<has_admin_center_side_nav_open: bool>, lotus: record<agent_workspace_theme_preference: string, agent_workspace_theme_preference_for_conversation_panel: string, keyboard_shortcuts_enabled: bool, macro_shortcuts_enabled: bool, show_onboarding_tooltips: bool, two_factor_authentication: bool>, shared_views_order: list<int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/settings")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request User Create
#
# POST /api/v2/users/request_create
# operationId: RequestUserCreate
export def "users-request-create RequestUserCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user: any
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/request_create")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Users
#
# GET /api/v2/users/search
# operationId: SearchUsers
export def "users-search SearchUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for offset-based pagination (non-negative integer). (e.g. 1)
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --qp-query: string # The `query` parameter supports the Zendesk search syntax for more advanced user searches. It can specify a partial or full value of any user property, including name, email address, notes, or phone. Example: `query="jdoe"`. See the [Search API](/api-reference/ticketing/ticket-management/search/).  (e.g. jdoe)
  --external-id: string # The `external_id` parameter does not support the search syntax. It only accepts ids.  (e.g. abc124)
  --brand-id: int # When brand separation is enabled, scopes the search to users belonging to the specified brand. Only applicable when the account has brand separation enabled.  (format: int64, e.g. 123)
  --include: string # A comma-separated list of sideloads to include in the response.
]: nothing -> record<users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "brand_id" $brand_id "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Many Users
#
# GET /api/v2/users/show_many
# operationId: ShowManyUsers
export def "users-show-many ShowManyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Accepts a comma-separated list of up to 100 user ids.  (e.g. 1,2)
  --external-ids: string # Accepts a comma-separated list of up to 100 external ids.  (e.g. abc,def)
  --include-deleted: string@bool-completer # If true, returns inactive or deleted users.
  --brand-id: int # When brand separation is enabled and `external_ids` is provided, scopes the lookup to users belonging to the specified brand. Only applicable when the account has brand separation enabled.  (format: int64, e.g. 123)
  --include: string # Sideloads to include in the response. Accepts a comma-separated list of values. See [Sideloading](/api-reference/ticketing/users/users/#sideloading).  (e.g. roles,organizations)
]: nothing -> record<users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "external_ids" $external_ids "scalar") (serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "brand_id" $brand_id "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Users
#
# PUT /api/v2/users/update_many
# operationId: UpdateManyUsers
# --user shape: {agent_brand_ids?: list, alias?: string, custom_role_id?: int, default_group_id?: int, details?: string, email?: string, external_id?: string, group_id?: int, identities?: list, language?: string, locale?: string, locale_id?: int, moderator?: bool, name?: string, notes?: string, only_private_comments?: bool, organization_id?: int, organization_ids?: list, phone?: string, photo?: record, remote_photo_url?: string, role?: string, shared_phone_number?: bool, signature?: string, skip_verify_email?: bool, suspended?: bool, tags?: list, ticket_restriction?: string, time_zone?: string, user_fields?: record, verified?: bool}
export def "users-update-many UpdateManyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Id of the users to update. Comma separated (e.g. 1,2,3)
  --external-ids: string # External Id of the users to update. Comma separated (e.g. abc,def,ghi)
  --brand-id: int # When brand separation is enabled and `external_ids` is provided, scopes the bulk update to users belonging to the specified brand. Only applicable when the account has brand separation enabled.  (format: int64, e.g. 123)
  --user: record # Input schema for updating a user. All fields are optional - only include the fields you want to update. — shape: {agent_brand_ids?: list, alias?: string, custom_role_id?: int, default_group_id?: int, details?: string, email?: string, external_id?: string, group_id?: int, identities?: list, language?: string, locale?: string, locale_id?: int, moderator?: bool, name?: string, notes?: string, only_private_comments?: bool, organization_id?: int, organization_ids?: list, phone?: string, photo?: record, remote_photo_url?: string, role?: string, shared_phone_number?: bool, signature?: string, skip_verify_email?: bool, suspended?: bool, tags?: list, ticket_restriction?: string, time_zone?: string, user_fields?: record, verified?: bool}
  --users: list
]: any -> record<job_status: record<id: string, job_type: string, message: string, progress: int, results: any, status: string, total: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "external_ids" $external_ids "scalar") (serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/update_many" $qp)
  let body = {user: $user, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Views
#
# GET /api/v2/views
# operationId: ListViews
export def "views ListViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access: string # Only views with given access. May be "personal", "shared", or "account"
  --active: string@bool-completer # Only active views if true, inactive views if false
  --group-id: int # Only views belonging to given group (format: int64)
  --qp-sort: string # The sort parameter used with cursor pagination. Defaults to "created_at". Prefix with '-' for descending order
  --sort-by: string # The sort_by parameter used with offset pagination. Possible values are "alphabetical", "created_at", or "updated_at". Defaults to "position"
  --sort-order: string # The sort_order parameter used with offset pagination. One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
]: nothing -> record<count: int, next_page: string, previous_page: string, views: table<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access" $access "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create View
#
# POST /api/v2/views
# operationId: CreateView
export def "views CreateView" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<columns: list<record>, groups: list<record>, rows: list<record>, view: record<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/views")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show View
#
# GET /api/v2/views/{view_id}
# operationId: ShowView
export def "views ShowView" [
  view_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # A comma-separated list of sideloads to include in the response.
]: nothing -> record<columns: list<record>, groups: list<record>, rows: list<record>, view: record<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/views/($view_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update View
#
# PUT /api/v2/views/{view_id}
# operationId: UpdateView
export def "views UpdateView" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<columns: list<record>, groups: list<record>, rows: list<record>, view: record<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/views/($view_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete View
#
# DELETE /api/v2/views/{view_id}
# operationId: DeleteView
export def "views DeleteView" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/views/($view_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Tickets in View
#
# GET /api/v2/views/{view_id}/count
# operationId: GetViewCount
export def "views-count GetViewCount" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<view_count: record<active: bool, fresh: bool, pretty: string, url: string, value: int, view_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/views/($view_id)/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute View
#
# GET /api/v2/views/{view_id}/execute
# operationId: ExecuteView
export def "views-execute ExecuteView" [
  view_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --sort-by: string # The ticket field used for sorting. This will either be a title or a custom field id.
  --sort-order: string # The direction the tickets are sorted. May be one of 'asc' or 'desc'
  --include: string # A comma-separated list of sideloads to include in the response.
  --exclude: string # A comma-separated list of sideloads to exclude from the response.
  --group-by: string # The ticket field used for grouping. This will either be a title or a custom field id.
]: nothing -> record<columns: list<record>, groups: list<record>, rows: list<record>, view: record<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/views/($view_id)/execute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export View
#
# GET /api/v2/views/{view_id}/export
# operationId: ExportView
export def "views-export ExportView" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<export: record<status: string, view_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/views/($view_id)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Tickets From a View
#
# GET /api/v2/views/{view_id}/tickets
# operationId: ListTicketsFromView
export def "views-tickets ListTicketsFromView" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Sort or group the tickets by a column in the [View columns](#view-columns) table. The `subject` and `submitter` columns are not supported
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others
]: nothing -> record<tickets: table<additional_collaborators: list, allow_attachments: bool, allow_channelback: bool, assignee_email: string, assignee_id: int, attribute_value_ids: list, brand_id: int, collaborator_ids: list, collaborators: list, comment: record, created_at: string, custom_fields: list, custom_status_id: int, description: string, due_at: string, email_cc_ids: list, email_ccs: list, encoded_id: string, external_id: string, fields: list, follower_ids: list, followers: list, followup_ids: list, forum_topic_id: int, from_messaging_channel: bool, generated_timestamp: int, group_id: int, has_incidents: bool, id: int, is_public: bool, macro_id: int, macro_ids: list, metadata: record, organization_id: int, origin_zrn: string, priority: string, problem_id: int, raw_subject: string, recipient: string, requester: any, requester_id: int, safe_update: bool, satisfaction_probability: float, satisfaction_rating: record, sharing_agreement_ids: list, sharing_agreements: any, status: string, subject: string, submitter_id: int, support_type: string, suspended_ticket_id: int, suspension_type_id: int, system_metadata: record, tags: any, tde_workspace: record, ticket_form_id: int, tpe_voice_comment: record, type: string, updated_at: string, updated_stamp: string, url: string, via: record, via_followup_source_id: int, via_id: int, voice_comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/views/($view_id)/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Active Views
#
# GET /api/v2/views/active
# operationId: ListActiveViews
export def "views-active ListActiveViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access: string # Only views with given access. May be "personal", "shared", or "account"
  --group-id: int # Only views belonging to given group (format: int64)
  --sort-by: string # Possible values are "alphabetical", "created_at", or "updated_at". Defaults to "position"
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others
]: nothing -> record<count: int, next_page: string, previous_page: string, views: table<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access" $access "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Views - Compact
#
# GET /api/v2/views/compact
# operationId: ListCompactViews
export def "views-compact ListCompactViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next_page: string, previous_page: string, views: table<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/views/compact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Views
#
# GET /api/v2/views/count
# operationId: CountViews
export def "views-count CountViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: record<refreshed_at: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/views/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Tickets in Views
#
# GET /api/v2/views/count_many
# operationId: GetViewCounts
export def "views-count-many GetViewCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # List of view's ids separated by commas. (e.g. 1,2,3)
]: nothing -> record<view_counts: table<active: bool, fresh: bool, pretty: string, url: string, value: int, view_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views/count_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List View Filter Definitions
#
# GET /api/v2/views/definitions
# operationId: ListViewDefinitions
export def "views-definitions ListViewDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definitions: record<conditions_all: list<record>, conditions_any: list<record>, groupables: list<record>, output: list<record>, sortables: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/views/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Views
#
# DELETE /api/v2/views/destroy_many
# operationId: BulkDeleteViews
export def "views-destroy-many BulkDeleteViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The IDs of the views to delete (e.g. 1,2,3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview Views
#
# POST /api/v2/views/preview
# operationId: PreviewViews
export def "views-preview PreviewViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination parameter. Supports both traditional offset and cursor-based pagination:  - Traditional: `?page=2` (integer page number) - Cursor: `?page[size]=50&page[after]=cursor` (deepObject with size, after, before)  These are mutually exclusive - use one format or the other, not both.
  --per-page: int # Number of records to return per page.  Note: Default and maximum values vary by endpoint. Check endpoint-specific documentation for limits.  (e.g. 50)
  --include: string # A comma-separated list of sideloads to include in the response.
  --exclude: string # A comma-separated list of sideloads to exclude from the response.
]: nothing -> record<columns: list<record>, groups: list<record>, rows: list<record>, view: record<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "deepObject") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views/preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview Ticket Count
#
# POST /api/v2/views/preview/count
# operationId: PreviewCount
export def "views-preview-count PreviewCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<view_count: record<active: bool, fresh: bool, pretty: string, url: string, value: int, view_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/views/preview/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Views
#
# GET /api/v2/views/search
# operationId: SearchViews
export def "views-search SearchViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Query string used to find all views with matching title (e.g. sales&group_id=25789188)
  --access: string # Filter views by access. May be "personal", "shared", or "account"
  --active: string@bool-completer # Filter by active views if true or inactive views if false
  --group-id: int # Filter views by group (format: int64)
  --sort-by: string # Possible values are "alphabetical", "created_at", "updated_at", and "position". If unspecified, the views are sorted by relevance
  --sort-order: string # One of "asc" or "desc". Defaults to "asc" for alphabetical and position sort, "desc" for all others
  --include: string # A sideload to include in the response. See [Sideloads](#sideloads-3) (e.g. permissions)
]: nothing -> record<count: int, next_page: string, previous_page: string, views: table<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Views By ID
#
# GET /api/v2/views/show_many
# operationId: ListViewsById
export def "views-show-many ListViewsById" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # List of view's ids separated by commas. (e.g. 1,2,3)
  --active: string@bool-completer # Only active views if true, inactive views if false
]: nothing -> record<count: int, next_page: string, previous_page: string, views: table<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/views/show_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Many Views
#
# PUT /api/v2/views/update_many
# operationId: UpdateManyViews
export def "views-update-many UpdateManyViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next_page: string, previous_page: string, views: table<active: bool, conditions: record, created_at: string, default: bool, description: string, execution: record, id: int, position: int, restriction: record, title: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/views/update_many")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Workspaces
#
# GET /api/v2/workspaces
# operationId: ListWorkspaces
export def "workspaces ListWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workspace
#
# POST /api/v2/workspaces
# operationId: CreateWorkspace
# --workspace shape: {conditions?: record, description?: string, macros?: list, ticket_form_id?: float, title?: string}
export def "workspaces CreateWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspace: record # shape: {conditions?: record, description?: string, macros?: list, ticket_form_id?: float, title?: string}
]: any -> record<workspace: record<activated: bool, apps: list<record>, conditions: record<all: list, any: list>, created_at: string, description: string, id: int, macro_ids: list<int>, macros: list<int>, position: int, prefer_workspace_app_order: bool, selected_macros: list<record>, ticket_form_id: int, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/workspaces")
  let body = {workspace: $workspace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Workspace
#
# GET /api/v2/workspaces/{workspace_id}
# operationId: ShowWorkspace
export def "workspaces ShowWorkspace" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<workspace: record<activated: bool, apps: list<record>, conditions: record<all: list, any: list>, created_at: string, description: string, id: int, macro_ids: list<int>, macros: list<int>, position: int, prefer_workspace_app_order: bool, selected_macros: list<record>, ticket_form_id: int, title: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Workspace
#
# PUT /api/v2/workspaces/{workspace_id}
# operationId: UpdateWorkspace
# --workspace shape: {conditions?: record, description?: string, macros?: list, ticket_form_id?: float, title?: string}
export def "workspaces UpdateWorkspace" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspace: record # shape: {conditions?: record, description?: string, macros?: list, ticket_form_id?: float, title?: string}
]: any -> record<workspace: record<activated: bool, apps: list<record>, conditions: record<all: list, any: list>, created_at: string, description: string, id: int, macro_ids: list<int>, macros: list<int>, position: int, prefer_workspace_app_order: bool, selected_macros: list<record>, ticket_form_id: int, title: string, updated_at: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/workspaces/($workspace_id)")
  let body = {workspace: $workspace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Workspace
#
# DELETE /api/v2/workspaces/{workspace_id}
# operationId: DeleteWorkspace
export def "workspaces DeleteWorkspace" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Delete Workspaces
#
# DELETE /api/v2/workspaces/destroy_many
# operationId: DestroyManyWorkspaces
export def "workspaces-destroy-many DestroyManyWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The ids of the workspaces to delete (e.g. [1, 2, 3])
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/workspaces/destroy_many" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder Workspaces
#
# PUT /api/v2/workspaces/reorder
# operationId: ReorderWorkspaces
export def "workspaces-reorder ReorderWorkspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/workspaces/reorder")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Token for Grant Type
#
# POST /oauth/tokens
# operationId: CreateTokenForGrantType
export def "oauth-tokens CreateTokenForGrantType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_in: int, scope: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
