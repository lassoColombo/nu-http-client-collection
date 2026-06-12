# Auto-generated client for Discourse API Documentation vlatest
# Source: https://raw.githubusercontent.com/discourse/discourse_api_docs/main/openapi.json
# Auth: --token flag or $env.DISCOURSE_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://discourse.example.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISCOURSE_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://discourse.example.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def include-details-completer [] { ["false" "true"] }
def include-subcategories-completer [] { ["false" "true"] }
def order-completer [] { ["asc" "desc"] }
def include-subcategories-completer-1 [] { ["true"] }
def status-completer [] { ["archived" "closed" "pinned" "pinned_globally" "visible"] }
def enabled-completer [] { ["false" "true"] }
def notification-level-completer [] { ["0" "1" "2" "3"] }
def upload-type-completer [] { ["avatar" "card_background" "composer" "custom_emoji" "profile_background"] }
def type-completer [] { ["avatar" "card_background" "composer" "custom_emoji" "profile_background"] }
def type-completer-1 [] { ["custom" "gravatar" "system" "uploaded"] }
def period-completer [] { ["all" "daily" "monthly" "quarterly" "weekly" "yearly"] }
def order-completer-1 [] { ["days_visited" "likes_given" "likes_received" "post_count" "posts_read" "topic_count" "topics_entered"] }
def asc-completer [] { ["true"] }
def order-completer-2 [] { ["created" "days_visited" "email" "last_emailed" "posts" "posts_read" "read_time" "seen" "topics_viewed" "trust_level" "username"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "discourse-post-event-eventsjson listEvents" } } | get name | first)
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

# List calendar events
#
# GET /discourse-post-event/events.json
# operationId: listEvents
export def "discourse-post-event-eventsjson listEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-details: string@include-details-completer # Include detailed event information (creator, invitees, stats, etc.)
  --category-id: int # Filter events by category ID
  --include-subcategories: string@include-subcategories-completer # Include events from subcategories when filtering by category
  --post-id: int # Filter to events associated with a specific post ID
  --attending-user: string # Filter to events where the specified user (username) has RSVP'd as going
  --before: string # Return events starting before this date/time (ISO 8601 format) (format: date-time)
  --after: string # Return events starting after this date/time (ISO 8601 format) (format: date-time)
  --order: string@order-completer # Sort order for events by start date (default: asc)
  --limit: int # Maximum number of events to return (default: 200)
]: nothing -> record<events: table<id: int, category_id: int, name: string, recurrence: string, recurrence_until: string, starts_at: string, ends_at: string, rrule: string, show_local_time: bool, timezone: string, duration: string, all_day: bool, post: record, occurrences: list, can_act_on_discourse_post_event: bool, can_update_attendance: bool, creator: record, custom_fields: record, is_closed: bool, is_expired: bool, is_ongoing: bool, is_private: bool, is_public: bool, is_standalone: bool, minimal: bool, raw_invitees: list, reminders: list, sample_invitees: list, should_display_invitees: bool, stats: record, status: string, url: string, description: string, description_html: string, location: string, watching_invitee: record, chat_enabled: bool, channel: record, max_attendees: int, at_capacity: bool, image_upload: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_details" $include_details "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "include_subcategories" $include_subcategories "scalar") (serialize-qp "post_id" $post_id "scalar") (serialize-qp "attending_user" $attending_user "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discourse-post-event/events.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export calendar events in iCalendar format
#
# GET /discourse-post-event/events.ics
# operationId: exportEventsICS
export def "discourse-post-event-eventsics exportEventsICS" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # Filter events by category ID
  --include-subcategories: string@include-subcategories-completer # Include events from subcategories when filtering by category
  --attending-user: string # Filter to events where the specified user (username) has RSVP'd as going
  --before: string # Return events starting before this date/time (ISO 8601 format) (format: date-time)
  --after: string # Return events starting after this date/time (ISO 8601 format) (format: date-time)
  --order: string@order-completer # Sort order for events by start date (default: asc)
  --limit: int # Maximum number of events to return (default: 200)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "include_subcategories" $include_subcategories "scalar") (serialize-qp "attending_user" $attending_user "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discourse-post-event/events.ics" $qp)
  let accept_val = "text/calendar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List backups
#
# GET /admin/backups.json
# operationId: getBackups
export def "admin-backupsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<filename: string, size: int, last_modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/backups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create backup
#
# POST /admin/backups.json
# operationId: createBackup
export def "admin-backupsjson createBackup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-uploads: oneof<nothing, bool>
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/backups.json")
  let body = {with_uploads: $with_uploads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send download backup email
#
# PUT /admin/backups/{filename}
# operationId: sendDownloadBackupEmail
export def "admin-backups sendDownloadBackupEmail" [
  filename: string
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
  let full_url = (build-url $base $"/admin/backups/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download backup
#
# GET /admin/backups/{filename}
# operationId: downloadBackup
export def "admin-backups downloadBackup" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/backups/($filename)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List badges
#
# GET /admin/badges.json
# operationId: adminListBadges
export def "admin-badgesjson adminListBadges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<badges: table<id: int, name: string, description: string, grant_count: int, allow_title: bool, multiple_grant: bool, icon: string, image_url: string, listable: bool, enabled: bool, badge_grouping_id: int, system: bool, long_description: string, slug: string, manually_grantable: bool, query: string, trigger: int, target_posts: bool, auto_revoke: bool, show_posts: bool, i18n_name: string, image_upload_id: int, badge_type_id: int, show_in_post_header: bool>, badge_types: table<id: int, name: string, sort_order: int>, badge_groupings: table<id: int, name: string, description: string, position: int, system: bool>, admin_badges: record<protected_system_fields: list<any>, triggers: record<user_change: int, none: int, post_revision: int, trust_level_change: int, post_action: int>, badge_ids: list<any>, badge_grouping_ids: list<any>, badge_type_ids: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/badges.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create badge
#
# POST /admin/badges.json
# operationId: createBadge
export def "admin-badgesjson createBadge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the new badge.
  badge_type_id: int # The ID for the badge type. 1 for Gold, 2 for Silver, 3 for Bronze.
]: any -> record<badge_types: table<id: int, name: string, sort_order: int>, badge: record<id: int, name: string, description: string, grant_count: int, allow_title: bool, multiple_grant: bool, icon: string, image_url: string, image_upload_id: int, listable: bool, enabled: bool, badge_grouping_id: int, system: bool, long_description: string, slug: string, manually_grantable: bool, query: string, trigger: string, target_posts: bool, auto_revoke: bool, show_posts: bool, badge_type_id: int, show_in_post_header: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/badges.json")
  let body = {name: $name, badge_type_id: $badge_type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update badge
#
# PUT /admin/badges/{id}.json
# operationId: updateBadge
export def "admin-badges updateBadge" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the new badge.
  badge_type_id: int # The ID for the badge type. 1 for Gold, 2 for Silver, 3 for Bronze.
]: any -> record<badge_types: table<id: int, name: string, sort_order: int>, badge: record<id: int, name: string, description: string, grant_count: int, allow_title: bool, multiple_grant: bool, icon: string, image_url: string, image_upload_id: int, listable: bool, enabled: bool, badge_grouping_id: int, system: bool, long_description: string, slug: string, manually_grantable: bool, query: string, trigger: string, target_posts: bool, auto_revoke: bool, show_posts: bool, badge_type_id: int, show_in_post_header: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/badges/($id).json")
  let body = {name: $name, badge_type_id: $badge_type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete badge
#
# DELETE /admin/badges/{id}.json
# operationId: deleteBadge
export def "admin-badges delete" [
  id: int
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
  let full_url = (build-url $base $"/admin/badges/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a category
#
# POST /categories.json
# operationId: createCategory
# --permissions shape: {everyone?: int, staff?: int}
# --category_localizations item shape: {id?: int, locale: string, name: string, description?: string}
export def "categoriesjson createCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --color: string # e.g. 49d9e9
  --text-color: string # e.g. f0fcfd
  --style-type: string
  --emoji: string
  --icon: string
  --parent-category-id: int
  --allow-badges: oneof<nothing, bool>
  --slug: string
  --topic-featured-links-allowed: oneof<nothing, bool>
  --permissions: record # shape: {everyone?: int, staff?: int}
  --search-priority: int
  --form-template-ids: list
  --category-localizations: list # item shape: {id?: int, locale: string, name: string, description?: string}
]: any -> record<category: record<id: int, name: string, color: string, text_color: string, style_type: string, emoji: string, icon: string, slug: string, locale: string, topic_count: int, post_count: int, position: int, description: string, description_text: string, description_excerpt: string, topic_url: string, read_restricted: bool, permission: int, notification_level: int, can_edit: bool, topic_template: string, topic_title_placeholder: string, form_template_ids: list<any>, has_children: bool, subcategory_count: int, sort_order: string, sort_ascending: string, show_subcategory_list: bool, num_featured_topics: int, default_view: string, subcategory_list_style: string, default_top_period: string, default_list_filter: string, minimum_required_tags: int, navigate_to_first_post_after_read: bool, custom_fields: record, allowed_tags: list<any>, allowed_tag_groups: list<any>, allow_global_tags: bool, required_tag_groups: list<record>, category_setting: record<auto_bump_cooldown_days: int, num_auto_bump_daily: int, require_reply_approval: bool, require_topic_approval: bool, nested_replies_default: bool, topic_posting_review_mode: string, reply_posting_review_mode: string>, category_localizations: list<any>, read_only_banner: string, available_groups: list<any>, auto_close_hours: string, auto_close_based_on_last_post: bool, allow_unlimited_owner_edits_on_first_post: bool, default_slow_mode_seconds: string, group_permissions: list<record>, email_in: string, email_in_allow_strangers: bool, mailinglist_mirror: bool, all_topics_wiki: bool, can_delete: bool, allow_badges: bool, topic_featured_link_allowed: bool, search_priority: int, topic_posting_review_group_ids: list<int>, reply_posting_review_group_ids: list<int>, uploaded_logo: string, uploaded_logo_dark: string, uploaded_background: string, uploaded_background_dark: string, category_types: record, category_type_settings: record, available_category_types: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories.json")
  let body = {name: $name, color: $color, text_color: $text_color, style_type: $style_type, emoji: $emoji, icon: $icon, parent_category_id: $parent_category_id, allow_badges: $allow_badges, slug: $slug, topic_featured_links_allowed: $topic_featured_links_allowed, permissions: $permissions, search_priority: $search_priority, form_template_ids: $form_template_ids, category_localizations: $category_localizations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of categories
#
# GET /categories.json
# operationId: listCategories
export def "categoriesjson listCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-subcategories: oneof<nothing, bool>
]: nothing -> record<category_list: record<can_create_category: bool, can_create_topic: bool, categories: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_subcategories" $include_subcategories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a category
#
# PUT /categories/{id}.json
# operationId: updateCategory
# --permissions shape: {everyone?: int, staff?: int}
# --category_localizations item shape: {id?: int, locale: string, name: string, description?: string}
export def "categories updateCategory" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --color: string # e.g. 49d9e9
  --text-color: string # e.g. f0fcfd
  --style-type: string
  --emoji: string
  --icon: string
  --parent-category-id: int
  --allow-badges: oneof<nothing, bool>
  --slug: string
  --topic-featured-links-allowed: oneof<nothing, bool>
  --permissions: record # shape: {everyone?: int, staff?: int}
  --search-priority: int
  --form-template-ids: list
  --category-localizations: list # item shape: {id?: int, locale: string, name: string, description?: string}
]: any -> record<success: string, category: record<id: int, name: string, color: string, text_color: string, style_type: string, emoji: string, icon: string, slug: string, locale: string, topic_count: int, post_count: int, position: int, description: string, description_text: string, description_excerpt: string, topic_url: string, read_restricted: bool, permission: int, notification_level: int, can_edit: bool, topic_template: string, topic_title_placeholder: string, form_template_ids: list<any>, has_children: bool, subcategory_count: int, sort_order: string, sort_ascending: string, show_subcategory_list: bool, num_featured_topics: int, default_view: string, subcategory_list_style: string, default_top_period: string, default_list_filter: string, minimum_required_tags: int, navigate_to_first_post_after_read: bool, custom_fields: record, allowed_tags: list<any>, allowed_tag_groups: list<any>, allow_global_tags: bool, required_tag_groups: list<record>, category_setting: record<auto_bump_cooldown_days: int, num_auto_bump_daily: int, require_reply_approval: bool, require_topic_approval: bool, nested_replies_default: bool, topic_posting_review_mode: string, reply_posting_review_mode: string>, category_localizations: list<any>, read_only_banner: string, available_groups: list<any>, auto_close_hours: string, auto_close_based_on_last_post: bool, allow_unlimited_owner_edits_on_first_post: bool, default_slow_mode_seconds: string, group_permissions: list<record>, email_in: string, email_in_allow_strangers: bool, mailinglist_mirror: bool, all_topics_wiki: bool, can_delete: bool, allow_badges: bool, topic_featured_link_allowed: bool, search_priority: int, topic_posting_review_group_ids: list<int>, reply_posting_review_group_ids: list<int>, uploaded_logo: string, uploaded_logo_dark: string, uploaded_background: string, uploaded_background_dark: string, category_types: record, category_type_settings: record, available_category_types: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/categories/($id).json")
  let body = {name: $name, color: $color, text_color: $text_color, style_type: $style_type, emoji: $emoji, icon: $icon, parent_category_id: $parent_category_id, allow_badges: $allow_badges, slug: $slug, topic_featured_links_allowed: $topic_featured_links_allowed, permissions: $permissions, search_priority: $search_priority, form_template_ids: $form_template_ids, category_localizations: $category_localizations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List topics
#
# GET /c/{slug}/{id}.json
# operationId: listCategoryTopics
export def "c listCategoryTopics" [
  slug: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<id: int, username: string, name: string, avatar_template: string>, primary_groups: list<any>, topic_list: record<can_create_topic: bool, per_page: int, top_tags: list<record>, topics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/c/($slug)/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show category
#
# GET /c/{id}/show.json
# operationId: getCategory
export def "c-showjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category: record<id: int, name: string, color: string, text_color: string, style_type: string, emoji: string, icon: string, slug: string, locale: string, topic_count: int, post_count: int, position: int, description: string, description_text: string, description_excerpt: string, topic_url: string, read_restricted: bool, permission: int, notification_level: int, can_edit: bool, topic_template: string, topic_title_placeholder: string, form_template_ids: list<any>, has_children: bool, subcategory_count: int, sort_order: string, sort_ascending: string, show_subcategory_list: bool, num_featured_topics: int, default_view: string, subcategory_list_style: string, default_top_period: string, default_list_filter: string, minimum_required_tags: int, navigate_to_first_post_after_read: bool, custom_fields: record, allowed_tags: list<any>, allowed_tag_groups: list<any>, allow_global_tags: bool, required_tag_groups: list<record>, category_setting: record<auto_bump_cooldown_days: int, num_auto_bump_daily: int, require_reply_approval: bool, require_topic_approval: bool, nested_replies_default: bool, topic_posting_review_mode: string, reply_posting_review_mode: string>, category_localizations: list<any>, read_only_banner: string, available_groups: list<any>, auto_close_hours: string, auto_close_based_on_last_post: bool, allow_unlimited_owner_edits_on_first_post: bool, default_slow_mode_seconds: string, group_permissions: list<record>, email_in: string, email_in_allow_strangers: bool, mailinglist_mirror: bool, all_topics_wiki: bool, can_delete: bool, allow_badges: bool, topic_featured_link_allowed: bool, search_priority: int, topic_posting_review_group_ids: list<int>, reply_posting_review_group_ids: list<int>, uploaded_logo: string, uploaded_logo_dark: string, uploaded_background: string, uploaded_background_dark: string, category_types: record, category_type_settings: record, available_category_types: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/c/($id)/show.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a group
#
# POST /admin/groups.json
# operationId: createGroup
# --group shape: {name: string, full_name?: string, bio_raw?: string, usernames?: string, owner_usernames?: string, automatic_membership_email_domains?: string, visibility_level?: int, primary_group?: bool, flair_icon?: string, flair_upload_id?: int, flair_bg_color?: string, public_admission?: bool, public_exit?: bool, default_notification_level?: int, muted_category_ids?: list, regular_category_ids?: list, watching_category_ids?: list, tracking_category_ids?: list, watching_first_post_category_ids?: list}
export def "admin-groupsjson createGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group: record # shape: {name: string, full_name?: string, bio_raw?: string, usernames?: string, owner_usernames?: string, automatic_membership_email_domains?: string, visibility_level?: int, primary_group?: bool, flair_icon?: string, flair_upload_id?: int, flair_bg_color?: string, public_admission?: bool, public_exit?: bool, default_notification_level?: int, muted_category_ids?: list, regular_category_ids?: list, watching_category_ids?: list, tracking_category_ids?: list, watching_first_post_category_ids?: list}
]: any -> record<basic_group: record<id: int, automatic: bool, name: string, user_count: int, mentionable_level: int, messageable_level: int, visibility_level: int, primary_group: bool, title: string, grant_trust_level: string, incoming_email: string, has_messages: bool, flair_url: string, flair_bg_color: string, flair_color: string, bio_raw: string, bio_cooked: string, bio_excerpt: string, public_admission: bool, public_exit: bool, allow_membership_requests: bool, full_name: string, default_notification_level: int, membership_request_template: string, members_visibility_level: int, can_see_members: bool, can_admin_group: bool, can_edit_group: bool, publish_read_state: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/groups.json")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a group
#
# DELETE /admin/groups/{id}.json
# operationId: deleteGroup
export def "admin-groups delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/groups/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a group
#
# GET /groups/{name}.json
# operationId: getGroup
export def "groups get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: record<id: int, automatic: bool, name: string, user_count: int, mentionable_level: int, messageable_level: int, visibility_level: int, primary_group: bool, title: string, grant_trust_level: string, incoming_email: string, has_messages: bool, flair_url: string, flair_bg_color: string, flair_color: string, bio_raw: string, bio_cooked: string, bio_excerpt: string, public_admission: bool, public_exit: bool, allow_membership_requests: bool, full_name: string, default_notification_level: int, membership_request_template: string, is_group_user: bool, members_visibility_level: int, can_see_members: bool, can_admin_group: bool, can_edit_group: bool, publish_read_state: bool, is_group_owner_display: bool, mentionable: bool, messageable: bool, automatic_membership_email_domains: string, smtp_updated_at: string, smtp_updated_by: record, smtp_enabled: bool, smtp_server: string, smtp_port: string, smtp_ssl_mode: int, email_username: string, email_from_alias: string, email_password: string, message_count: int, allow_unknown_sender_topic_replies: bool, associated_group_ids: list<any>, watching_category_ids: list<any>, tracking_category_ids: list<any>, watching_first_post_category_ids: list<any>, regular_category_ids: list<any>, muted_category_ids: list<any>, watching_tags: list<any>, watching_first_post_tags: list<any>, tracking_tags: list<any>, regular_tags: list<any>, muted_tags: list<any>>, extras: record<visible_group_names: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($name).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a group
#
# PUT /groups/{id}.json
# operationId: updateGroup
# --group shape: {name: string, full_name?: string, bio_raw?: string, usernames?: string, owner_usernames?: string, automatic_membership_email_domains?: string, visibility_level?: int, primary_group?: bool, flair_icon?: string, flair_upload_id?: int, flair_bg_color?: string, public_admission?: bool, public_exit?: bool, default_notification_level?: int, muted_category_ids?: list, regular_category_ids?: list, watching_category_ids?: list, tracking_category_ids?: list, watching_first_post_category_ids?: list}
export def "groups updateGroup" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group: record # shape: {name: string, full_name?: string, bio_raw?: string, usernames?: string, owner_usernames?: string, automatic_membership_email_domains?: string, visibility_level?: int, primary_group?: bool, flair_icon?: string, flair_upload_id?: int, flair_bg_color?: string, public_admission?: bool, public_exit?: bool, default_notification_level?: int, muted_category_ids?: list, regular_category_ids?: list, watching_category_ids?: list, tracking_category_ids?: list, watching_first_post_category_ids?: list}
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id).json")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a group by id
#
# GET /groups/by-id/{id}.json
# operationId: getGroupById
export def "groups-by-id get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: record<id: int, automatic: bool, name: string, user_count: int, mentionable_level: int, messageable_level: int, visibility_level: int, primary_group: bool, title: string, grant_trust_level: string, incoming_email: string, has_messages: bool, flair_url: string, flair_bg_color: string, flair_color: string, bio_raw: string, bio_cooked: string, bio_excerpt: string, public_admission: bool, public_exit: bool, allow_membership_requests: bool, full_name: string, default_notification_level: int, membership_request_template: string, is_group_user: bool, members_visibility_level: int, can_see_members: bool, can_admin_group: bool, can_edit_group: bool, publish_read_state: bool, is_group_owner_display: bool, mentionable: bool, messageable: bool, automatic_membership_email_domains: string, smtp_updated_at: string, smtp_updated_by: record, smtp_enabled: bool, smtp_server: string, smtp_port: string, smtp_ssl_mode: int, email_username: string, email_from_alias: string, email_password: string, message_count: int, allow_unknown_sender_topic_replies: bool, associated_group_ids: list<any>, watching_category_ids: list<any>, tracking_category_ids: list<any>, watching_first_post_category_ids: list<any>, regular_category_ids: list<any>, muted_category_ids: list<any>, watching_tags: list<any>, watching_first_post_tags: list<any>, tracking_tags: list<any>, regular_tags: list<any>, muted_tags: list<any>>, extras: record<visible_group_names: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/by-id/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List group members
#
# GET /groups/{name}/members.json
# operationId: listGroupMembers
export def "groups-membersjson listGroupMembers" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<members: table<id: int, username: string, name: string, avatar_template: string, title: string, last_posted_at: string, last_seen_at: string, added_at: string, timezone: string>, owners: table<id: int, username: string, name: string, avatar_template: string, title: string, last_posted_at: string, last_seen_at: string, added_at: string, timezone: string>, meta: record<total: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($name)/members.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add group members
#
# PUT /groups/{id}/members.json
# operationId: addGroupMembers
export def "groups-membersjson addGroupMembers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --usernames: string # comma separated list (e.g. username1,username2)
]: any -> record<success: string, usernames: list<any>, emails: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)/members.json")
  let body = {usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove group members
#
# DELETE /groups/{id}/members.json
# operationId: removeGroupMembers
export def "groups-membersjson removeGroupMembers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --usernames: string # comma separated list (e.g. username1,username2)
]: any -> record<success: string, usernames: list<any>, skipped_usernames: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)/members.json")
  let body = {usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List groups
#
# GET /groups.json
# operationId: listGroups
export def "groupsjson listGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: table<id: int, automatic: bool, name: string, display_name: string, user_count: int, mentionable_level: int, messageable_level: int, visibility_level: int, primary_group: bool, title: string, grant_trust_level: string, incoming_email: string, has_messages: bool, flair_url: string, flair_bg_color: string, flair_color: string, bio_raw: string, bio_cooked: string, bio_excerpt: string, public_admission: bool, public_exit: bool, allow_membership_requests: bool, full_name: string, default_notification_level: int, membership_request_template: string, is_group_user: bool, is_group_owner: bool, members_visibility_level: int, can_see_members: bool, can_admin_group: bool, can_edit_group: bool, publish_read_state: bool>, extras: record<type_filters: list<any>>, total_rows_groups: int, load_more_groups: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an invite
#
# POST /invites.json
# operationId: createInvite
export def "invitesjson createInvite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --email: string # required for email invites only (e.g. not-a-user-yet@example.com)
  --skip-email: oneof<nothing, bool> # default: false
  --custom-message: string # optional, for email invites
  --max-redemptions-allowed: int # optional, for link invites (default: 1, e.g. 5)
  --topic-id: int
  --group-ids: string # Optional, either this or `group_names`. Comma separated list for multiple ids. (e.g. 42,43)
  --group-names: string # Optional, either this or `group_ids`. Comma separated list for multiple names. (e.g. foo,bar)
  --expires-at: string # optional, if not supplied, the invite_expiry_days site setting is used
]: any -> record<id: int, invite_key: string, link: string, description: string, email: string, domain: string, emailed: bool, can_delete_invite: bool, custom_message: string, created_at: string, updated_at: string, expires_at: string, expired: bool, topics: list<record>, groups: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invites.json")
  let body = {email: $email, skip_email: $skip_email, custom_message: $custom_message, max_redemptions_allowed: $max_redemptions_allowed, topic_id: $topic_id, group_ids: $group_ids, group_names: $group_names, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple invites
#
# POST /invites/create-multiple.json
# operationId: createMultipleInvites
export def "invites-create-multiplejson createMultipleInvites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --email: string # pass 1 email per invite to be generated. other properties will be shared by each invite. (e.g. [not-a-user-yet-1@example.com, not-a-user-yet-2@example.com])
  --skip-email: oneof<nothing, bool> # default: false
  --custom-message: string # optional, for email invites
  --max-redemptions-allowed: int # optional, for link invites (default: 1, e.g. 5)
  --topic-id: int
  --group-ids: string # Optional, either this or `group_names`. Comma separated list for multiple ids. (e.g. 42,43)
  --group-names: string # Optional, either this or `group_ids`. Comma separated list for multiple names. (e.g. foo,bar)
  --expires-at: string # optional, if not supplied, the invite_expiry_days site setting is used
]: any -> record<num_successfully_created_invitations: int, num_failed_invitations: int, failed_invitations: list<any>, successful_invitations: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invites/create-multiple.json")
  let body = {email: $email, skip_email: $skip_email, custom_message: $custom_message, max_redemptions_allowed: $max_redemptions_allowed, topic_id: $topic_id, group_ids: $group_ids, group_names: $group_names, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the notifications that belong to the current user
#
# GET /notifications.json
# operationId: getNotifications
export def "notificationsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<notifications: table<id: int, user_id: int, notification_type: int, read: bool, created_at: string, post_number: int, topic_id: int, slug: string, data: record>, total_rows_notifications: int, seen_notification_id: int, load_more_notifications: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark notifications as read
#
# PUT /notifications/mark-read.json
# operationId: markNotificationsAsRead
export def "notifications-mark-readjson markNotificationsAsRead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # (optional) Leave off to mark all notifications as read
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/mark-read.json")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List latest posts across topics
#
# GET /posts.json
# operationId: listPosts
export def "postsjson listPosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: int # Load posts with an id lower than this value. Useful for pagination.
]: nothing -> record<latest_posts: table<id: int, name: string, username: string, avatar_template: string, created_at: string, cooked: string, post_number: int, post_type: int, posts_count: int, updated_at: string, reply_count: int, reply_to_post_number: string, quote_count: int, incoming_link_count: int, reads: int, readers_count: int, score: float, yours: bool, topic_id: int, topic_slug: string, topic_title: string, topic_html_title: string, category_id: int, display_username: string, primary_group_name: string, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: string, badges_granted: list, version: int, can_edit: bool, can_delete: bool, can_recover: bool, can_see_hidden_post: bool, can_wiki: bool, user_title: string, bookmarked: bool, raw: string, actions_summary: list, moderator: bool, admin: bool, staff: bool, user_id: int, hidden: bool, trust_level: int, deleted_at: string, user_deleted: bool, edit_reason: string, can_view_edit_history: bool, wiki: bool, excerpt: string, truncated: bool, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, post_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new topic, a new post, or a private message
#
# POST /posts.json
# operationId: createTopicPostPM
@deprecated --flag target-usernames
export def "postsjson createTopicPostPM" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Required if creating a new topic or new private message.
  --body-raw: string
  --topic-id: int # Required if creating a new post.
  --category: int # Optional if creating a new topic, and ignored if creating a new post.
  --target-recipients: string # Required for private message, comma separated. (e.g. blake,sam)
  --target-usernames: string # Deprecated. Use target_recipients instead. (DEPRECATED)
  --archetype: string # Required for new private message. (e.g. private_message)
  --created-at: string
  --reply-to-post-number: int # Optional, the post number to reply to inside a topic.
  --embed-url: string # Provide a URL from a remote system to associate a forum topic with that URL, typically for using Discourse as a comments system for an external blog.
  --external-id: string # Provide an external_id from a remote system to associate a forum topic with that id.
  --auto-track: oneof<nothing, bool> # If false, the user will not track the topic. By default, the user will track the topic.
]: any -> record<id: int, name: string, username: string, avatar_template: string, created_at: string, raw: string, cooked: string, post_number: int, post_type: int, posts_count: int, updated_at: string, reply_count: int, reply_to_post_number: string, quote_count: int, incoming_link_count: int, reads: int, readers_count: int, score: float, yours: bool, topic_id: int, topic_slug: string, display_username: string, primary_group_name: string, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: int, badges_granted: list<any>, version: int, can_edit: bool, can_delete: bool, can_recover: bool, can_see_hidden_post: bool, can_wiki: bool, user_title: string, bookmarked: bool, actions_summary: table<id: int, can_act: bool>, moderator: bool, admin: bool, staff: bool, user_id: int, draft_sequence: int, hidden: bool, trust_level: int, deleted_at: string, user_deleted: bool, edit_reason: string, can_view_edit_history: bool, wiki: bool, reviewable_id: int, reviewable_score_count: int, reviewable_score_pending_count: int, post_url: string, post_localizations: list<any>, mentioned_users: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/posts.json")
  let body = {title: $title, raw: $body_raw, topic_id: $topic_id, category: $category, target_recipients: $target_recipients, target_usernames: $target_usernames, archetype: $archetype, created_at: $created_at, reply_to_post_number: $reply_to_post_number, embed_url: $embed_url, external_id: $external_id, auto_track: $auto_track} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a single post
#
# GET /posts/{id}.json
# operationId: getPost
export def "posts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, username: string, avatar_template: string, created_at: string, cooked: string, post_number: int, post_type: int, posts_count: int, updated_at: string, reply_count: int, reply_to_post_number: string, quote_count: int, incoming_link_count: int, reads: int, readers_count: int, score: float, yours: bool, topic_id: int, topic_slug: string, primary_group_name: string, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: int, version: int, can_edit: bool, can_delete: bool, can_recover: bool, can_see_hidden_post: bool, can_wiki: bool, user_title: string, bookmarked: bool, raw: string, actions_summary: table<id: int, count: int, acted: bool, can_undo: bool, can_act: bool>, moderator: bool, admin: bool, staff: bool, user_id: int, hidden: bool, trust_level: int, deleted_at: string, user_deleted: bool, edit_reason: string, can_view_edit_history: bool, wiki: bool, reviewable_id: int, reviewable_score_count: int, reviewable_score_pending_count: int, post_url: string, mentioned_users: list<any>, name: string, display_username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/posts/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single post
#
# PUT /posts/{id}.json
# operationId: updatePost
# --post shape: {raw: string, edit_reason?: string}
export def "posts updatePost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --post: record # shape: {raw: string, edit_reason?: string}
  --bypass-bump: oneof<nothing, bool> # Skip bumping the topic when updating the post. Requires staff or TL4 permissions.
]: any -> record<post: record<id: int, username: string, avatar_template: string, created_at: string, cooked: string, post_number: int, post_type: int, posts_count: int, updated_at: string, reply_count: int, reply_to_post_number: string, quote_count: int, incoming_link_count: int, reads: int, readers_count: int, score: float, yours: bool, topic_id: int, topic_slug: string, primary_group_name: string, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: int, badges_granted: list<any>, version: int, can_edit: bool, can_delete: bool, can_recover: bool, can_see_hidden_post: bool, can_wiki: bool, user_title: string, bookmarked: bool, raw: string, actions_summary: list<record>, moderator: bool, admin: bool, staff: bool, user_id: int, draft_sequence: int, hidden: bool, trust_level: int, deleted_at: string, user_deleted: bool, edit_reason: string, can_view_edit_history: bool, wiki: bool, reviewable_id: int, reviewable_score_count: int, reviewable_score_pending_count: int, post_url: string, post_localizations: list<any>, mentioned_users: list<any>, name: string, display_username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/posts/($id).json")
  let body = {post: $post, bypass_bump: $bypass_bump} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a single post
#
# DELETE /posts/{id}.json
# operationId: deletePost
export def "posts delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-destroy: oneof<nothing, bool> # The `SiteSetting.can_permanently_delete` needs to be enabled first before this param can be used. Also this endpoint needs to be called first without `force_destroy` and then followed up with a second call 5 minutes later with `force_destroy` to permanently delete. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/posts/($id).json")
  let body = {force_destroy: $force_destroy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List replies to a post
#
# GET /posts/{id}/replies.json
# operationId: postReplies
export def "posts-repliesjson get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string, username: string, avatar_template: string, created_at: string, cooked: string, post_number: int, post_type: int, posts_count: int, updated_at: string, reply_count: int, reply_to_post_number: int, quote_count: int, incoming_link_count: int, reads: int, readers_count: int, score: float, yours: bool, topic_id: int, topic_slug: string, display_username: string, primary_group_name: string, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: int, version: int, can_edit: bool, can_delete: bool, can_recover: bool, can_see_hidden_post: bool, can_wiki: bool, user_title: string, reply_to_user: record<id: int, username: string, name: string, avatar_template: string>, bookmarked: bool, actions_summary: list<record>, moderator: bool, admin: bool, staff: bool, user_id: int, hidden: bool, trust_level: int, deleted_at: string, user_deleted: bool, edit_reason: string, can_view_edit_history: bool, wiki: bool, reviewable_id: int, reviewable_score_count: int, reviewable_score_pending_count: int, post_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/posts/($id)/replies.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lock a post from being edited
#
# PUT /posts/{id}/locked.json
# operationId: lockPost
export def "posts-lockedjson lockPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  locked: string # Whether to lock the post (true/false)
]: any -> record<locked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/posts/($id)/locked.json")
  let body = {locked: $locked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Like a post and other actions
#
# POST /post_actions.json
# operationId: performPostAction
export def "post-actionsjson performPostAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  id: int # The ID of the post to perform the action on
  post_action_type_id: int # The ID of the post action type (e.g., 2 for like)
  --flag-topic: oneof<nothing, bool> # Whether to flag the entire topic
]: any -> record<id: int, name: string, username: string, avatar_template: string, created_at: string, cooked: string, post_number: int, post_type: int, posts_count: int, updated_at: string, reply_count: int, reply_to_post_number: string, quote_count: int, incoming_link_count: int, reads: int, readers_count: int, score: float, yours: bool, topic_id: int, topic_slug: string, display_username: string, primary_group_name: string, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: int, badges_granted: list<any>, version: int, can_edit: bool, can_delete: bool, can_recover: bool, can_see_hidden_post: bool, can_wiki: bool, user_title: string, bookmarked: bool, actions_summary: table<id: int, count: int, acted: bool, can_undo: bool, can_act: bool>, moderator: bool, admin: bool, staff: bool, user_id: int, hidden: bool, trust_level: int, deleted_at: string, user_deleted: bool, edit_reason: string, can_view_edit_history: bool, wiki: bool, reviewable_id: int, reviewable_score_count: int, reviewable_score_pending_count: int, post_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post_actions.json")
  let body = {id: $id, post_action_type_id: $post_action_type_id, flag_topic: $flag_topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of private messages for a user
#
# GET /topics/private-messages/{username}.json
# operationId: listUserPrivateMessages
export def "topics-private-messages listUserPrivateMessages" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<id: int, username: string, name: string, avatar_template: string>, primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/topics/private-messages/($username).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of private messages sent for a user
#
# GET /topics/private-messages-sent/{username}.json
# operationId: getUserSentPrivateMessages
export def "topics-private-messages-sent get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<id: int, username: string, name: string, avatar_template: string>, primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/topics/private-messages-sent/($username).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for a term
#
# GET /search.json
# operationId: search
export def "searchjson search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The query string needs to be url encoded and is made up of the following options: - Search term. This is just a string. Usually it would be the first item in the query. - `@<username>`: Use the `@` followed by the username to specify posts by this user. - `#<category>`: Use the `#` followed by the category slug to search within this category. - `tags:`: `api,solved` or for posts that have all the specified tags `api+solved`. - `before:`: `yyyy-mm-dd` - `after:`: `yyyy-mm-dd` - `order:`: `latest`, `likes`, `views`, `latest_topic` - `assigned:`: username (without `@`) - `in:`: `title`, `likes`, `personal`, `messages`, `seen`, `unseen`, `posted`, `created`, `watching`, `tracking`, `bookmarks`, `assigned`, `unassigned`, `first`, `pinned`, `wiki` - `with:`: `images` - `status:`: `open`, `closed`, `public`, `archived`, `noreplies`, `single_user`, `solved`, `unsolved` - `group:`: group_name or group_id - `group_messages:`: group_name or group_id - `min_posts:`: 1 - `max_posts:`: 10 - `min_views:`: 1 - `max_views:`: 10  If you are using cURL you can use the `-G` and the `--data-urlencode` flags to encode the query:  ``` curl -i -sS -X GET -G "http://localhost:3000/search.json" \ --data-urlencode 'q=wordpress @scossar #fun after:2020-01-01' ```  (e.g. api @blake #support tags:api after:2021-06-04 in:unseen in:open order:latest_topic)
  --page: int # e.g. 1
]: nothing -> record<posts: list<any>, users: list<any>, categories: list<any>, tags: table<id: int, name: string, slug: string>, groups: list<any>, grouped_search_result: record<more_posts: string, more_users: string, more_categories: string, term: string, search_log_id: int, more_full_page_results: string, can_create_topic: bool, error: string, extra: record<categories: list>, post_ids: list<any>, user_ids: list<any>, category_ids: list<any>, tag_ids: list<any>, group_ids: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get site info
#
# GET /site.json
# operationId: getSite
export def "sitejson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<default_archetype: string, notification_types: record<mentioned: int, replied: int, quoted: int, edited: int, liked: int, private_message: int, invited_to_private_message: int, invitee_accepted: int, posted: int, watching_category_or_tag: int, new_features: int, admin_problems: int, moved_post: int, linked: int, granted_badge: int, invited_to_topic: int, custom: int, group_mentioned: int, group_message_summary: int, watching_first_post: int, topic_reminder: int, liked_consolidated: int, linked_consolidated: int, post_approved: int, code_review_commit_approved: int, membership_request_accepted: int, membership_request_consolidated: int, bookmark_reminder: int, reaction: int, votes_released: int, event_reminder: int, event_invitation: int, chat_mention: int, chat_message: int, chat_invitation: int, chat_group_mention: int, chat_quoted: int, chat_watched_thread: int, upcoming_change_available: int, upcoming_change_automatically_promoted: int, assigned: int, question_answer_user_commented: int, following: int, following_created_topic: int, following_replied: int, circles_activity: int, boost: int, suggested_edit_created: int, suggested_edit_accepted: int>, post_types: record<regular: int, moderator_action: int, small_action: int, whisper: int>, trust_levels: record<newuser: int, basic: int, member: int, regular: int, leader: int>, user_tips: record<first_notification: int, topic_timeline: int, post_menu: int, topic_notification_levels: int, suggested_topics: int>, groups: table<id: int, name: string, flair_url: string, flair_bg_color: string, flair_color: string, automatic: bool>, filters: list<any>, periods: list<any>, top_menu_items: list<any>, anonymous_top_menu_items: list<any>, uncategorized_category_id: int, user_field_max_length: int, post_action_types: table<id: int, name_key: string, name: string, description: string, short_description: string, is_flag: bool, require_message: bool, enabled: bool, applies_to: list, is_used: bool, position: int, auto_action_type: bool, system: bool>, topic_flag_types: table<id: int, name_key: string, name: string, description: string, short_description: string, is_flag: bool, require_message: bool, enabled: bool, applies_to: list, is_used: bool, position: int, auto_action_type: bool, system: bool>, can_create_tag: bool, can_tag_topics: bool, can_tag_pms: bool, tags_filter_regexp: string, top_tags: table<id: int, name: string, slug: string>, wizard_required: bool, can_associate_groups: bool, email_configured: bool, upcoming_changes_with_css: list<string>, topic_featured_link_allowed_category_ids: list<any>, user_themes: table<theme_id: int, name: string, default: bool, color_scheme_id: int, dark_color_scheme_id: int, only_theme_color_schemes: bool>, user_color_schemes: table<id: int, name: string, is_dark: bool, theme_id: int, colors: list>, default_light_color_scheme: record, default_dark_color_scheme: record, censored_regexp: list<record>, custom_emoji_translation: record, watched_words_replace: string, watched_words_link: string, markdown_additional_options: record, hashtag_configurations: record, hashtag_icons: record, displayed_about_plugin_stat_groups: list<any>, categories: table<id: int, name: string, color: string, text_color: string, style_type: string, emoji: string, icon: string, slug: string, topic_count: int, post_count: int, position: int, description: string, description_text: string, description_excerpt: string, topic_url: string, read_restricted: bool, permission: int, notification_level: int, topic_template: string, topic_title_placeholder: string, has_children: bool, subcategory_count: int, sort_order: string, sort_ascending: string, show_subcategory_list: bool, num_featured_topics: int, default_view: string, subcategory_list_style: string, default_top_period: string, default_list_filter: string, minimum_required_tags: int, navigate_to_first_post_after_read: bool, allowed_tags: list, allowed_tag_groups: list, allow_global_tags: bool, required_tag_groups: list, read_only_banner: string, uploaded_logo: string, uploaded_logo_dark: string, uploaded_background: string, uploaded_background_dark: string, can_edit: bool, custom_fields: record, parent_category_id: int, form_template_ids: list, category_types: record>, archetypes: table<id: string, name: string, options: list>, user_fields: list<any>, auth_providers: list<any>, whispers_allowed_groups_names: list<any>, denied_emojis: list<any>, valid_flag_applies_to_types: list<any>, navigation_menu_site_top_tags: list<any>, full_name_required_for_signup: bool, full_name_visible_in_signup: bool, admin_config_login_routes: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get site basic info
#
# GET /site/basic-info.json
# operationId: getSiteBasicInfo
export def "site-basic-infojson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<logo_url: string, logo_small_url: string, apple_touch_icon_url: string, favicon_url: string, title: string, description: string, header_primary_color: string, header_background_color: string, login_required: bool, locale: string, include_in_discourse_discover: bool, mobile_logo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site/basic-info.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of tag groups
#
# GET /tag_groups.json
# operationId: listTagGroups
export def "tag-groupsjson listTagGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tag_groups: table<id: int, name: string, tags: list, parent_tag: list, one_per_topic: bool, permissions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tag_groups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a tag group
#
# POST /tag_groups.json
# operationId: createTagGroup
export def "tag-groupsjson createTagGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<tag_group: record<id: int, name: string, tags: list<record>, parent_tag: list<record>, one_per_topic: bool, permissions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tag_groups.json")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single tag group
#
# GET /tag_groups/{id}.json
# operationId: getTagGroup
export def "tag-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tag_group: record<id: int, name: string, tag_names: list<any>, parent_tag_name: list<any>, one_per_topic: bool, permissions: record<everyone: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tag_groups/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update tag group
#
# PUT /tag_groups/{id}.json
# operationId: updateTagGroup
export def "tag-groups updateTagGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> record<success: string, tag_group: record<id: int, name: string, tag_names: list<any>, parent_tag_name: list<any>, one_per_topic: bool, permissions: record<everyone: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tag_groups/($id).json")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of tags
#
# GET /tags.json
# operationId: listTags
export def "tagsjson listTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: table<id: int, text: string, name: string, count: int, pm_count: int, target_tag: string>, extras: record<categories: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific tag
#
# GET /tag/{name}.json
# operationId: getTag
export def "tag get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<id: int, username: string, name: string, avatar_template: string>, primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, tags: list<record>, topics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tag/($name).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get specific posts from a topic
#
# GET /t/{id}/posts.json
# operationId: getSpecificPostsFromTopic
export def "t-postsjson get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  post_ids: int
]: any -> record<post_stream: record<posts: list<record>>, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/posts.json")
  let body = {post_ids[]: $post_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single topic
#
# GET /t/{id}.json
# operationId: getTopic
export def "t get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
]: nothing -> record<post_stream: record<posts: list<record>, stream: list<any>>, timeline_lookup: list<any>, suggested_topics: table<id: int, title: string, fancy_title: string, slug: string, posts_count: int, reply_count: int, highest_post_number: int, image_url: string, created_at: string, last_posted_at: string, bumped: bool, bumped_at: string, archetype: string, unseen: bool, pinned: bool, unpinned: string, excerpt: string, visible: bool, closed: bool, archived: bool, bookmarked: string, liked: string, tags: list, tags_descriptions: record, like_count: int, views: int, category_id: int, featured_link: string, posters: list>, tags: table<id: int, name: string, slug: string>, tags_descriptions: record, id: int, title: string, fancy_title: string, posts_count: int, created_at: string, views: int, reply_count: int, like_count: int, last_posted_at: string, visible: bool, closed: bool, archived: bool, has_summary: bool, archetype: string, slug: string, category_id: int, word_count: int, deleted_at: string, user_id: int, featured_link: string, pinned_globally: bool, pinned_at: string, pinned_until: string, image_url: string, slow_mode_seconds: int, draft: string, draft_key: string, draft_sequence: int, unpinned: string, pinned: bool, current_post_number: int, highest_post_number: int, deleted_by: string, has_deleted: bool, actions_summary: table<id: int, count: int, hidden: bool, can_act: bool>, chunk_size: int, bookmarked: bool, bookmarks: list<any>, topic_timer: string, message_bus_last_id: int, participant_count: int, show_read_indicator: bool, thumbnails: string, slow_mode_enabled_until: string, details: record<can_edit: bool, notification_level: int, can_move_posts: bool, can_delete: bool, can_remove_allowed_users: bool, can_create_post: bool, can_reply_as_new_topic: bool, can_invite_to: bool, can_invite_via_email: bool, can_flag_topic: bool, can_convert_topic: bool, can_review_topic: bool, can_close_topic: bool, can_archive_topic: bool, can_split_merge_topic: bool, can_edit_staff_notes: bool, can_toggle_topic_visibility: bool, can_pin_unpin_topic: bool, can_banner_topic: bool, can_moderate_category: bool, can_remove_self_id: int, participants: list<record>, created_by: record<id: int, username: string, name: string, avatar_template: string>, last_poster: record<id: int, username: string, name: string, avatar_template: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id).json")
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a topic
#
# DELETE /t/{id}.json
# operationId: removeTopic
export def "t removeTopic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id).json")
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a topic
#
# PUT /t/-/{id}.json
# operationId: updateTopic
# --topic shape: {title?: string, category_id?: int}
export def "t updateTopic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --topic: record # shape: {title?: string, category_id?: int}
]: any -> record<basic_topic: record<id: int, title: string, fancy_title: string, slug: string, posts_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/-/($id).json")
  let body = {topic: $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invite to topic
#
# POST /t/{id}/invite.json
# operationId: inviteToTopic
export def "t-invitejson inviteToTopic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --user: string
  --email: string
]: any -> record<user: record<id: int, username: string, name: string, avatar_template: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/invite.json")
  let body = {user: $user, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invite group to topic
#
# POST /t/{id}/invite-group.json
# operationId: inviteGroupToTopic
export def "t-invite-groupjson inviteGroupToTopic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --group: string # The name of the group to invite
  --should-notify: oneof<nothing, bool> # Whether to notify the group, it defaults to true
]: any -> record<group: record<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/invite-group.json")
  let body = {group: $group, should_notify: $should_notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bookmark topic
#
# PUT /t/{id}/bookmark.json
# operationId: bookmarkTopic
export def "t-bookmarkjson bookmarkTopic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/bookmark.json")
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of a topic
#
# PUT /t/{id}/status.json
# operationId: updateTopicStatus
export def "t-statusjson updateTopicStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  status: string@status-completer
  enabled: string@enabled-completer
  --until: string # Only required for `pinned` and `pinned_globally` (e.g. 2030-12-31)
]: any -> record<success: string, topic_status_update: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/status.json")
  let body = {status: $status, enabled: $enabled, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the latest topics
#
# GET /latest.json
# operationId: listLatestTopics
export def "latestjson listLatestTopics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # Enum: `default`, `created`, `activity`, `views`, `posts`, `category`, `likes`, `op_likes`, `posters`
  --ascending: string # Defaults to `desc`, add `ascending=true` to sort asc
  --per-page: int # Maximum number of topics returned, between 1-100
  --Api-Key: string
  --Api-Username: string
]: nothing -> record<users: table<id: int, username: string, name: string, avatar_template: string>, primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "ascending" $ascending "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/latest.json" $qp)
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the top topics filtered by period
#
# GET /top.json
# operationId: listTopTopics
export def "topjson listTopTopics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Enum: `all`, `yearly`, `quarterly`, `monthly`, `weekly`, `daily`
  --per-page: int # Maximum number of topics returned, between 1-100
  --Api-Key: string
  --Api-Username: string
]: nothing -> record<users: table<id: int, username: string, name: string, avatar_template: string>, primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, for_period: string, per_page: int, topics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/top.json" $qp)
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set notification level
#
# POST /t/{id}/notifications.json
# operationId: setNotificationLevel
export def "t-notificationsjson setNotificationLevel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  notification_level: string@notification-level-completer
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/notifications.json")
  let body = {notification_level: $notification_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update topic timestamp
#
# PUT /t/{id}/change-timestamp.json
# operationId: updateTopicTimestamp
export def "t-change-timestampjson updateTopicTimestamp" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  timestamp: string # e.g. 1594291380
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/change-timestamp.json")
  let body = {timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create topic timer
#
# POST /t/{id}/timer.json
# operationId: createTopicTimer
export def "t-timerjson createTopicTimer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --time: string # e.g. 
  --status-type: string
  --based-on-last-post: oneof<nothing, bool>
  --category-id: int
]: any -> record<success: string, execute_at: string, duration: string, based_on_last_post: bool, closed: bool, category_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/t/($id)/timer.json")
  let body = {time: $time, status_type: $status_type, based_on_last_post: $based_on_last_post, category_id: $category_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get topic by external_id
#
# GET /t/external_id/{external_id}.json
# operationId: getTopicByExternalId
export def "t-external-id get" [
  external_id: string
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
  let full_url = (build-url $base $"/t/external_id/($external_id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an upload
#
# POST /uploads.json
# operationId: createUpload
export def "uploadsjson createUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  upload_type: string@upload-type-completer
  --user-id: int # required if uploading an avatar
  --synchronous: oneof<nothing, bool> # Use this flag to return an id and url
  --file: string # format: binary
]: any -> record<id: int, url: string, original_filename: string, filesize: int, width: int, height: int, thumbnail_width: int, thumbnail_height: int, extension: string, short_url: string, short_path: string, retain_hours: string, human_filesize: string, dominant_color: string, thumbnail: record<id: int, upload_id: int, url: string, extension: string, width: int, height: int, filesize: int>, optimized_video: record<id: int, upload_id: int, url: string, extension: string, filesize: int, sha1: string, original_filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads.json")
  let body = {upload_type: $upload_type, user_id: $user_id, synchronous: $synchronous, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Initiates a direct external upload
#
# POST /uploads/generate-presigned-put.json
# operationId: generatePresignedPut
# --metadata shape: {sha1-checksum?: string}
export def "uploads-generate-presigned-putjson generatePresignedPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer
  file_name: string # e.g. IMG_2021.jpeg
  file_size: int # File size should be represented in bytes. (e.g. 4096)
  --metadata: record # shape: {sha1-checksum?: string}
]: any -> record<key: string, url: string, signed_headers: record, unique_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/generate-presigned-put.json")
  let body = {type: $type, file_name: $file_name, file_size: $file_size, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Completes a direct external upload
#
# POST /uploads/complete-external-upload.json
# operationId: completeExternalUpload
export def "uploads-complete-external-uploadjson completeExternalUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  unique_identifier: string # The unique identifier returned in the original /generate-presigned-put request. (e.g. 66e86218-80d9-4bda-b4d5-2b6def968705)
  --for-private-message: string # Optionally set this to true if the upload is for a private message. (e.g. true)
  --for-site-setting: string # Optionally set this to true if the upload is for a site setting. (e.g. true)
  --pasted: string # Optionally set this to true if the upload was pasted into the upload area. This will convert PNG files to JPEG. (e.g. true)
]: any -> record<id: int, url: string, original_filename: string, filesize: int, width: int, height: int, thumbnail_width: int, thumbnail_height: int, extension: string, short_url: string, short_path: string, retain_hours: string, human_filesize: string, dominant_color: string, thumbnail: record<id: int, upload_id: int, url: string, extension: string, width: int, height: int, filesize: int>, optimized_video: record<id: int, upload_id: int, url: string, extension: string, filesize: int, sha1: string, original_filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/complete-external-upload.json")
  let body = {unique_identifier: $unique_identifier, for_private_message: $for_private_message, for_site_setting: $for_site_setting, pasted: $pasted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a multipart external upload
#
# POST /uploads/create-multipart.json
# operationId: createMultipartUpload
# --metadata shape: {sha1-checksum?: string}
export def "uploads-create-multipartjson createMultipartUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  upload_type: string@upload-type-completer
  file_name: string # e.g. IMG_2021.jpeg
  file_size: int # File size should be represented in bytes. (e.g. 4096)
  --metadata: record # shape: {sha1-checksum?: string}
]: any -> record<key: string, external_upload_identifier: string, unique_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/create-multipart.json")
  let body = {upload_type: $upload_type, file_name: $file_name, file_size: $file_size, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates batches of presigned URLs for multipart parts
#
# POST /uploads/batch-presign-multipart-parts.json
# operationId: batchPresignMultipartParts
export def "uploads-batch-presign-multipart-partsjson batchPresignMultipartParts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  part_numbers: list # The part numbers to generate the presigned URLs for, must be between 1 and 10000. (e.g. [1, 2, 3])
  unique_identifier: string # The unique identifier returned in the original /create-multipart request. (e.g. 66e86218-80d9-4bda-b4d5-2b6def968705)
]: any -> record<presigned_urls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/batch-presign-multipart-parts.json")
  let body = {part_numbers: $part_numbers, unique_identifier: $unique_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abort multipart upload
#
# POST /uploads/abort-multipart.json
# operationId: abortMultipart
export def "uploads-abort-multipartjson abortMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  external_upload_identifier: string # The identifier of the multipart upload in the external storage provider. This is the multipart upload_id in AWS S3. (e.g. 84x83tmxy398t3y._Q_z8CoJYVr69bE6D7f8J6Oo0434QquLFoYdGVerWFx9X5HDEI_TP_95c34n853495x35345394.d.ghQ)
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/abort-multipart.json")
  let body = {external_upload_identifier: $external_upload_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete multipart upload
#
# POST /uploads/complete-multipart.json
# operationId: completeMultipart
export def "uploads-complete-multipartjson completeMultipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  unique_identifier: string # The unique identifier returned in the original /create-multipart request. (e.g. 66e86218-80d9-4bda-b4d5-2b6def968705)
  parts: list # All of the part numbers and their corresponding ETags that have been uploaded must be provided. (e.g. [{part_number: 1, etag: 0c376dcfcc2606f4335bbc732de93344}, {part_number: 2, etag: 09ert8cfcc2606f4335bbc732de91122}])
]: any -> record<id: int, url: string, original_filename: string, filesize: int, width: int, height: int, thumbnail_width: int, thumbnail_height: int, extension: string, short_url: string, short_path: string, retain_hours: string, human_filesize: string, dominant_color: string, thumbnail: record<id: int, upload_id: int, url: string, extension: string, width: int, height: int, filesize: int>, optimized_video: record<id: int, upload_id: int, url: string, extension: string, filesize: int, sha1: string, original_filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/complete-multipart.json")
  let body = {unique_identifier: $unique_identifier, parts: $parts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List badges for a user
#
# GET /user-badges/{username}.json
# operationId: listUserBadges
export def "user-badges listUserBadges" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<badges: table<id: int, name: string, description: string, grant_count: int, allow_title: bool, multiple_grant: bool, icon: string, image_url: string, listable: bool, enabled: bool, badge_grouping_id: int, system: bool, slug: string, manually_grantable: bool, badge_type_id: int>, badge_types: table<id: int, name: string, sort_order: int>, granted_bies: table<id: int, username: string, name: string, avatar_template: string, flair_name: string, admin: bool, moderator: bool, trust_level: int>, user_badges: table<id: int, granted_at: string, grouping_position: int, is_favorite: string, can_favorite: bool, badge_id: int, granted_by_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user-badges/($username).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a user
#
# POST /users.json
# operationId: createUser
# --user_fields shape: {1?: bool}
export def "usersjson createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  name: string
  email: string
  password: string
  username: string
  --active: oneof<nothing, bool> # This param requires an admin api key in the request header or it will be ignored
  --approved: oneof<nothing, bool>
  --user-fields: record # shape: {1?: bool}
  --external-ids: record
]: any -> record<success: bool, active: bool, message: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.json")
  let body = {name: $name, email: $email, password: $password, username: $username, active: $active, approved: $approved, user_fields: $user_fields, external_ids: $external_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single user by username
#
# GET /u/{username}.json
# operationId: getUser
export def "u get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
]: nothing -> record<user_badges: list<any>, user: record<id: int, username: string, name: string, avatar_template: string, last_posted_at: string, last_seen_at: string, created_at: string, ignored: bool, muted: bool, can_ignore_user: bool, can_ignore_users: bool, can_mute_user: bool, can_mute_users: bool, can_send_private_messages: bool, can_send_private_message_to_user: bool, trust_level: int, moderator: bool, admin: bool, title: string, badge_count: int, second_factor_backup_enabled: bool, user_fields: record<1: string, 2: string>, custom_fields: record<first_name: string>, time_read: int, recent_time_read: int, primary_group_id: int, primary_group_name: string, flair_group_id: int, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, featured_topic: record<id: int, title: string, fancy_title: string, slug: string, posts_count: int>, staged: bool, can_edit: bool, can_edit_username: bool, can_edit_email: bool, can_edit_name: bool, uploaded_avatar_id: int, has_title_badges: bool, pending_count: int, pending_posts_count: int, profile_view_count: int, second_factor_enabled: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, post_count: int, topic_count: int, can_be_deleted: bool, can_delete_all_posts: bool, locale: string, muted_category_ids: list<any>, regular_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>, tracked_tags: list<any>, muted_tags: list<any>, tracked_category_ids: list<any>, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, system_avatar_upload_id: string, system_avatar_template: string, muted_usernames: list<any>, ignored_usernames: list<any>, allowed_pm_usernames: list<any>, mailing_list_posts_per_day: int, can_change_bio: bool, can_change_location: bool, can_change_website: bool, can_change_tracking_preferences: bool, user_api_keys: string, user_passkeys: list<any>, sidebar_tags: list<any>, sidebar_category_ids: list<any>, display_sidebar_tags: bool, can_pick_theme_with_custom_homepage: bool, user_auth_tokens: list<record>, user_notification_schedule: record<enabled: bool, day_0_start_time: int, day_0_end_time: int, day_1_start_time: int, day_1_end_time: int, day_2_start_time: int, day_2_end_time: int, day_3_start_time: int, day_3_end_time: int, day_4_start_time: int, day_4_end_time: int, day_5_start_time: int, day_5_end_time: int, day_6_start_time: int, day_6_end_time: int>, use_logo_small_as_avatar: bool, featured_user_badge_ids: list<any>, invited_by: string, groups: list<record>, group_users: list<record>, user_option: record<user_id: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, email_digests: bool, email_level: int, email_messages_level: int, external_links_in_new_tab: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, dynamic_favicon: bool, enable_quoting: bool, enable_smart_lists: bool, enable_markdown_monospace_font: bool, enable_defer: bool, digest_after_minutes: int, automatically_unpin_topics: bool, auto_track_topics_after_msecs: int, notification_level_when_replying: int, new_topic_duration_minutes: int, email_previous_replies: int, email_in_reply_to: bool, like_notification_frequency: int, notify_on_linked_posts: bool, enable_upcoming_change_available_notifications: bool, include_tl0_in_digests: bool, theme_ids: list, theme_key_seq: int, allow_private_messages: bool, enable_allowed_pm_users: bool, homepage_id: string, hide_profile_and_presence: bool, hide_profile: bool, hide_presence: bool, text_size: string, text_size_seq: int, title_count_mode: string, timezone: string, skip_new_user_tips: bool, default_calendar: string, oldest_search_log_date: string, sidebar_link_to_filtered_list: bool, sidebar_show_count_of_new_items: bool, watched_precedence_over_muted: bool, seen_popups: list, topics_unread_when_closed: bool, composition_mode: int, interface_color_mode: int, show_original_content: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/($username).json")
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /u/{username}.json
# operationId: updateUser
export def "u updateUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
  --name: string
  --external-ids: record
]: any -> record<success: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/($username).json")
  let body = {name: $name, external_ids: $external_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a user by external_id
#
# GET /u/by-external/{external_id}.json
# operationId: getUserExternalId
export def "u-by-external list" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
]: nothing -> record<user_badges: list<any>, user: record<id: int, username: string, name: string, avatar_template: string, last_posted_at: string, last_seen_at: string, created_at: string, ignored: bool, muted: bool, can_ignore_user: bool, can_ignore_users: bool, can_mute_user: bool, can_mute_users: bool, can_send_private_messages: bool, can_send_private_message_to_user: bool, trust_level: int, moderator: bool, admin: bool, title: string, badge_count: int, second_factor_backup_enabled: bool, user_fields: record<1: string, 2: string>, custom_fields: record<first_name: string>, time_read: int, recent_time_read: int, primary_group_id: int, primary_group_name: string, flair_group_id: int, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, featured_topic: record<id: int, title: string, fancy_title: string, slug: string, posts_count: int>, staged: bool, can_edit: bool, can_edit_username: bool, can_edit_email: bool, can_edit_name: bool, uploaded_avatar_id: int, has_title_badges: bool, pending_count: int, pending_posts_count: int, profile_view_count: int, second_factor_enabled: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, post_count: int, topic_count: int, can_be_deleted: bool, can_delete_all_posts: bool, locale: string, muted_category_ids: list<any>, regular_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>, tracked_tags: list<any>, muted_tags: list<any>, tracked_category_ids: list<any>, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, system_avatar_upload_id: string, system_avatar_template: string, muted_usernames: list<any>, ignored_usernames: list<any>, allowed_pm_usernames: list<any>, mailing_list_posts_per_day: int, can_change_bio: bool, can_change_location: bool, can_change_website: bool, can_change_tracking_preferences: bool, user_api_keys: string, user_passkeys: list<any>, sidebar_tags: list<any>, sidebar_category_ids: list<any>, display_sidebar_tags: bool, can_pick_theme_with_custom_homepage: bool, user_auth_tokens: list<record>, user_notification_schedule: record<enabled: bool, day_0_start_time: int, day_0_end_time: int, day_1_start_time: int, day_1_end_time: int, day_2_start_time: int, day_2_end_time: int, day_3_start_time: int, day_3_end_time: int, day_4_start_time: int, day_4_end_time: int, day_5_start_time: int, day_5_end_time: int, day_6_start_time: int, day_6_end_time: int>, use_logo_small_as_avatar: bool, featured_user_badge_ids: list<any>, invited_by: string, groups: list<record>, group_users: list<record>, user_option: record<user_id: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, email_digests: bool, email_level: int, email_messages_level: int, external_links_in_new_tab: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, dynamic_favicon: bool, enable_quoting: bool, enable_smart_lists: bool, enable_markdown_monospace_font: bool, enable_defer: bool, digest_after_minutes: int, automatically_unpin_topics: bool, auto_track_topics_after_msecs: int, notification_level_when_replying: int, new_topic_duration_minutes: int, email_previous_replies: int, email_in_reply_to: bool, like_notification_frequency: int, notify_on_linked_posts: bool, enable_upcoming_change_available_notifications: bool, include_tl0_in_digests: bool, theme_ids: list, theme_key_seq: int, allow_private_messages: bool, enable_allowed_pm_users: bool, homepage_id: string, hide_profile_and_presence: bool, hide_profile: bool, hide_presence: bool, text_size: string, text_size_seq: int, title_count_mode: string, timezone: string, skip_new_user_tips: bool, default_calendar: string, oldest_search_log_date: string, sidebar_link_to_filtered_list: bool, sidebar_show_count_of_new_items: bool, watched_precedence_over_muted: bool, seen_popups: list, topics_unread_when_closed: bool, composition_mode: int, interface_color_mode: int, show_original_content: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/by-external/($external_id).json")
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user by identity provider external ID
#
# GET /u/by-external/{provider}/{external_id}.json
# operationId: getUserIdentiyProviderExternalId
export def "u-by-external get" [
  provider: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Api-Key: string
  --Api-Username: string
]: nothing -> record<user_badges: list<any>, user: record<id: int, username: string, name: string, avatar_template: string, last_posted_at: string, last_seen_at: string, created_at: string, ignored: bool, muted: bool, can_ignore_user: bool, can_ignore_users: bool, can_mute_user: bool, can_mute_users: bool, can_send_private_messages: bool, can_send_private_message_to_user: bool, trust_level: int, moderator: bool, admin: bool, title: string, badge_count: int, second_factor_backup_enabled: bool, user_fields: record<1: string, 2: string>, custom_fields: record<first_name: string>, time_read: int, recent_time_read: int, primary_group_id: int, primary_group_name: string, flair_group_id: int, flair_name: string, flair_url: string, flair_bg_color: string, flair_color: string, featured_topic: record<id: int, title: string, fancy_title: string, slug: string, posts_count: int>, staged: bool, can_edit: bool, can_edit_username: bool, can_edit_email: bool, can_edit_name: bool, uploaded_avatar_id: int, has_title_badges: bool, pending_count: int, pending_posts_count: int, profile_view_count: int, second_factor_enabled: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, post_count: int, topic_count: int, can_be_deleted: bool, can_delete_all_posts: bool, locale: string, muted_category_ids: list<any>, regular_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>, tracked_tags: list<any>, muted_tags: list<any>, tracked_category_ids: list<any>, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, system_avatar_upload_id: string, system_avatar_template: string, muted_usernames: list<any>, ignored_usernames: list<any>, allowed_pm_usernames: list<any>, mailing_list_posts_per_day: int, can_change_bio: bool, can_change_location: bool, can_change_website: bool, can_change_tracking_preferences: bool, user_api_keys: string, user_passkeys: list<any>, sidebar_tags: list<any>, sidebar_category_ids: list<any>, display_sidebar_tags: bool, can_pick_theme_with_custom_homepage: bool, user_auth_tokens: list<record>, user_notification_schedule: record<enabled: bool, day_0_start_time: int, day_0_end_time: int, day_1_start_time: int, day_1_end_time: int, day_2_start_time: int, day_2_end_time: int, day_3_start_time: int, day_3_end_time: int, day_4_start_time: int, day_4_end_time: int, day_5_start_time: int, day_5_end_time: int, day_6_start_time: int, day_6_end_time: int>, use_logo_small_as_avatar: bool, featured_user_badge_ids: list<any>, invited_by: string, groups: list<record>, group_users: list<record>, user_option: record<user_id: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, email_digests: bool, email_level: int, email_messages_level: int, external_links_in_new_tab: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, dynamic_favicon: bool, enable_quoting: bool, enable_smart_lists: bool, enable_markdown_monospace_font: bool, enable_defer: bool, digest_after_minutes: int, automatically_unpin_topics: bool, auto_track_topics_after_msecs: int, notification_level_when_replying: int, new_topic_duration_minutes: int, email_previous_replies: int, email_in_reply_to: bool, like_notification_frequency: int, notify_on_linked_posts: bool, enable_upcoming_change_available_notifications: bool, include_tl0_in_digests: bool, theme_ids: list, theme_key_seq: int, allow_private_messages: bool, enable_allowed_pm_users: bool, homepage_id: string, hide_profile_and_presence: bool, hide_profile: bool, hide_presence: bool, text_size: string, text_size_seq: int, title_count_mode: string, timezone: string, skip_new_user_tips: bool, default_calendar: string, oldest_search_log_date: string, sidebar_link_to_filtered_list: bool, sidebar_show_count_of_new_items: bool, watched_precedence_over_muted: bool, seen_popups: list, topics_unread_when_closed: bool, composition_mode: int, interface_color_mode: int, show_original_content: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/by-external/($provider)/($external_id).json")
  let extra_headers = {"Api-Key": $Api_Key, "Api-Username": $Api_Username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update avatar
#
# PUT /u/{username}/preferences/avatar/pick.json
# operationId: updateAvatar
export def "u-preferences-avatar-pickjson updateAvatar" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  upload_id: int
  type: string@type-completer-1
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/($username)/preferences/avatar/pick.json")
  let body = {upload_id: $upload_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update email
#
# PUT /u/{username}/preferences/email.json
# operationId: updateEmail
export def "u-preferences-emailjson updateEmail" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/($username)/preferences/email.json")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update username
#
# PUT /u/{username}/preferences/username.json
# operationId: updateUsername
export def "u-preferences-usernamejson updateUsername" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/($username)/preferences/username.json")
  let body = {new_username: $new_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a public list of users
#
# GET /directory_items.json
# operationId: listUsersPublic
export def "directory-itemsjson listUsersPublic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer
  --order: string@order-completer-1
  --asc: string@asc-completer
  --page: int
]: nothing -> record<directory_items: table<id: int, likes_received: int, likes_given: int, topics_entered: int, topic_count: int, post_count: int, posts_read: int, days_visited: int, user: record>, meta: record<last_updated_at: string, total_rows_directory_items: int, load_more_directory_items: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "asc" $asc "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/directory_items.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user by id
#
# GET /admin/users/{id}.json
# operationId: adminGetUser
export def "admin-users adminGetUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, username: string, name: string, avatar_template: string, active: bool, admin: bool, moderator: bool, last_seen_at: string, last_emailed_at: string, created_at: string, last_seen_age: float, last_emailed_age: float, created_at_age: float, trust_level: int, manual_locked_trust_level: string, title: string, time_read: int, staged: bool, days_visited: int, posts_read_count: int, topics_entered: int, post_count: int, associated_accounts: list<any>, can_send_activation_email: bool, can_activate: bool, can_deactivate: bool, can_change_trust_level: bool, ip_address: string, registration_ip_address: string, can_grant_admin: bool, can_revoke_admin: bool, can_grant_moderation: bool, can_revoke_moderation: bool, can_impersonate: bool, like_count: int, like_given_count: int, topic_count: int, flags_given_count: int, flags_received_count: int, private_topics_count: int, can_delete_all_posts: bool, can_be_deleted: bool, can_be_anonymized: bool, can_be_merged: bool, full_suspend_reason: string, latest_export: record, full_silence_reason: string, silence_reason: string, post_edits_count: int, primary_group_id: int, badge_count: int, warnings_received_count: int, bounce_score: int, reset_bounce_score_after: string, can_view_action_logs: bool, can_disable_second_factor: bool, can_delete_sso_record: bool, api_key_count: int, similar_users_count: int, single_sign_on_record: string, approved_by: record<id: int, username: string, name: string, avatar_template: string>, suspended_by: string, silenced_by: string, penalty_counts: record<silenced: int, suspended: int>, next_penalty: string, tl3_requirements: record<time_period: int, requirements_met: bool, requirements_lost: bool, trust_level_locked: bool, on_grace_period: bool, days_visited: int, min_days_visited: int, num_topics_replied_to: int, min_topics_replied_to: int, topics_viewed: int, min_topics_viewed: int, posts_read: int, min_posts_read: int, topics_viewed_all_time: int, min_topics_viewed_all_time: int, posts_read_all_time: int, min_posts_read_all_time: int, num_flagged_posts: int, max_flagged_posts: int, num_flagged_by_users: int, max_flagged_by_users: int, num_likes_given: int, min_likes_given: int, num_likes_received: int, min_likes_received: int, num_likes_received_days: int, min_likes_received_days: int, num_likes_received_users: int, min_likes_received_users: int, penalty_counts: record<silenced: int, suspended: int, total: int>>, groups: table<id: int, automatic: bool, name: string, display_name: string, user_count: int, mentionable_level: int, messageable_level: int, visibility_level: int, primary_group: bool, title: string, grant_trust_level: string, incoming_email: string, has_messages: bool, flair_url: string, flair_bg_color: string, flair_color: string, flair_group_id: int, bio_raw: string, bio_cooked: string, bio_excerpt: string, public_admission: bool, public_exit: bool, allow_membership_requests: bool, full_name: string, default_notification_level: int, membership_request_template: string, members_visibility_level: int, can_see_members: bool, can_admin_group: bool, publish_read_state: bool>, external_ids: record, include_ip: bool, upcoming_changes_stats: table<name: string, humanized_name: string, description: string, enabled: bool, specific_groups: list, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /admin/users/{id}.json
# operationId: deleteUser
export def "admin-users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-posts: oneof<nothing, bool>
  --block-email: oneof<nothing, bool>
  --block-urls: oneof<nothing, bool>
  --block-ip: oneof<nothing, bool>
]: any -> record<deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id).json")
  let body = {delete_posts: $delete_posts, block_email: $block_email, block_urls: $block_urls, block_ip: $block_ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activate a user
#
# PUT /admin/users/{id}/activate.json
# operationId: activateUser
export def "admin-users-activatejson activateUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id)/activate.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deactivate a user
#
# PUT /admin/users/{id}/deactivate.json
# operationId: deactivateUser
export def "admin-users-deactivatejson deactivateUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id)/deactivate.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suspend a user
#
# PUT /admin/users/{id}/suspend.json
# operationId: suspendUser
export def "admin-users-suspendjson suspendUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  suspend_until: string # e.g. 2121-02-22
  reason: string
  --message: string # Will send an email with this message when present
  --post-action: string # e.g. delete
]: any -> record<suspension: record<suspend_reason: string, full_suspend_reason: string, suspended_till: string, suspended_at: string, suspended_by: record<id: int, username: string, name: string, avatar_template: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id)/suspend.json")
  let body = {suspend_until: $suspend_until, reason: $reason, message: $message, post_action: $post_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Silence a user
#
# PUT /admin/users/{id}/silence.json
# operationId: silenceUser
export def "admin-users-silencejson silenceUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  silenced_till: string # e.g. 2022-06-01T08:00:00.000Z
  reason: string
  --message: string # Will send an email with this message when present
  --post-action: string # e.g. delete
]: any -> record<silence: record<silenced: bool, silence_reason: string, full_silence_reason: string, silenced_till: string, silenced_at: string, silenced_by: record<id: int, username: string, name: string, avatar_template: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id)/silence.json")
  let body = {silenced_till: $silenced_till, reason: $reason, message: $message, post_action: $post_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Anonymize a user
#
# PUT /admin/users/{id}/anonymize.json
# operationId: anonymizeUser
export def "admin-users-anonymizejson anonymizeUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id)/anonymize.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Log a user out
#
# POST /admin/users/{id}/log_out.json
# operationId: logOutUser
export def "admin-users-log-outjson logOutUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($id)/log_out.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh gravatar
#
# POST /user_avatar/{username}/refresh_gravatar.json
# operationId: refreshGravatar
export def "user-avatar-refresh-gravatarjson refreshGravatar" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gravatar_upload_id: int, gravatar_avatar_template: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_avatar/($username)/refresh_gravatar.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users
#
# GET /admin/users.json
# operationId: adminListUsers
export def "admin-usersjson adminListUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-2
  --asc: string@asc-completer
  --page: int
  --show-emails: oneof<nothing, bool> # Include user email addresses in response. These requests will be logged in the staff action logs.
  --stats: oneof<nothing, bool> # Include user stats information
  --email: string # Filter to the user with this email address
  --ip: string # Filter to users with this IP address
]: nothing -> table<id: int, username: string, name: string, avatar_template: string, email: string, secondary_emails: list<any>, active: bool, admin: bool, moderator: bool, last_seen_at: string, last_emailed_at: string, created_at: string, last_seen_age: float, last_emailed_age: float, created_at_age: float, trust_level: int, manual_locked_trust_level: string, title: string, time_read: int, staged: bool, days_visited: int, posts_read_count: int, topics_entered: int, post_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "asc" $asc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "show_emails" $show_emails "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users by flag
#
# GET /admin/users/list/{flag}.json
# operationId: adminListUsersFlag
export def "admin-users-list adminListUsersFlag" [
  flag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-2
  --asc: string@asc-completer
  --page: int
  --show-emails: oneof<nothing, bool> # Include user email addresses in response. These requests will be logged in the staff action logs.
  --stats: oneof<nothing, bool> # Include user stats information
  --email: string # Filter to the user with this email address
  --ip: string # Filter to users with this IP address
]: nothing -> table<id: int, username: string, name: string, avatar_template: string, email: string, secondary_emails: list<any>, active: bool, admin: bool, moderator: bool, last_seen_at: string, last_emailed_at: string, created_at: string, last_seen_age: float, last_emailed_age: float, created_at_age: float, trust_level: int, manual_locked_trust_level: string, title: string, time_read: int, staged: bool, days_visited: int, posts_read_count: int, topics_entered: int, post_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "asc" $asc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "show_emails" $show_emails "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/list/($flag).json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of user actions
#
# GET /user_actions.json
# operationId: listUserActions
export def "user-actionsjson listUserActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --username: string
  --filter: string
]: nothing -> record<user_actions: table<excerpt: string, action_type: int, created_at: string, avatar_template: string, acting_avatar_template: string, slug: string, topic_id: int, target_user_id: int, target_name: string, target_username: string, post_number: int, post_id: string, username: string, name: string, user_id: int, acting_username: string, acting_name: string, acting_user_id: int, title: string, deleted: bool, hidden: string, post_type: string, action_code: string, category_id: int, closed: bool, archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_actions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send password reset email
#
# POST /session/forgot_password.json
# operationId: sendPasswordResetEmail
export def "session-forgot-passwordjson sendPasswordResetEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string
]: any -> record<success: string, user_found: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session/forgot_password.json")
  let body = {login: $login} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change password
#
# PUT /users/password-reset/{token}.json
# operationId: changePassword
export def "users-password-reset changePassword" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/password-reset/($token).json")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get email addresses belonging to a user
#
# GET /u/{username}/emails.json
# operationId: getUserEmails
export def "u-emailsjson get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, secondary_emails: list<any>, unconfirmed_emails: list<any>, associated_accounts: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/u/($username)/emails.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
