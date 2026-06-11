# Auto-generated client for Statuspage API v1.0.0
# Source: https://raw.githubusercontent.com/sbecker59/statuspage-api-client-go/main/api/v1/statuspage/api/openapi.yaml
# Auth: --token flag or $env.STATUSPAGE_API_TOKEN

const BASE_URL = "https://api.statuspage.io/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STATUSPAGE_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api.statuspage.io/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["email" "integration_partner" "slack" "sms" "webhook"] }
def state-completer [] { ["active" "all" "quarantined" "unconfirmed"] }
def sort-field-completer [] { ["created_at" "primary" "quarantined_at" "relevance"] }
def sort-direction-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "pages list" } } | get name | first)
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

# Get a list of pages
#
# GET /pages
# operationId: getPages
export def "pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, created_at: string, updated_at: string, name: string, page_description: string, headline: string, branding: string, subdomain: string, domain: string, url: string, support_url: string, hidden_from_search: bool, allow_page_subscribers: bool, allow_incident_subscribers: bool, allow_email_subscribers: bool, allow_sms_subscribers: bool, allow_rss_atom_feeds: bool, allow_webhook_subscribers: bool, notifications_from_email: string, notifications_email_footer: string, activity_score: float, twitter_username: string, viewers_must_be_team_members: bool, ip_restrictions: string, city: string, state: string, country: string, time_zone: string, css_body_background_color: string, css_font_color: string, css_light_font_color: string, css_greens: string, css_yellows: string, css_oranges: string, css_blues: string, css_reds: string, css_border_color: string, css_graph_color: string, css_link_color: string, css_no_data: string, favicon_logo: string, transactional_logo: string, hero_cover: string, email_logo: string, twitter_logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a page
#
# GET /pages/{page_id}
# operationId: getPagesPageId
export def "pages get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: string, updated_at: string, name: string, page_description: string, headline: string, branding: string, subdomain: string, domain: string, url: string, support_url: string, hidden_from_search: bool, allow_page_subscribers: bool, allow_incident_subscribers: bool, allow_email_subscribers: bool, allow_sms_subscribers: bool, allow_rss_atom_feeds: bool, allow_webhook_subscribers: bool, notifications_from_email: string, notifications_email_footer: string, activity_score: float, twitter_username: string, viewers_must_be_team_members: bool, ip_restrictions: string, city: string, state: string, country: string, time_zone: string, css_body_background_color: string, css_font_color: string, css_light_font_color: string, css_greens: string, css_yellows: string, css_oranges: string, css_blues: string, css_reds: string, css_border_color: string, css_graph_color: string, css_link_color: string, css_no_data: string, favicon_logo: string, transactional_logo: string, hero_cover: string, email_logo: string, twitter_logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a page
#
# PATCH /pages/{page_id}
# operationId: patchPagesPageId
# --page shape: {name?: string, domain?: string, subdomain?: string, url?: string, branding?: "basic"|"premium", css_body_background_color?: string, css_font_color?: string, css_light_font_color?: string, css_greens?: string, css_yellows?: string, css_oranges?: string, css_reds?: string, css_blues?: string, css_border_color?: string, css_graph_color?: string, css_link_color?: string, css_no_data?: string, hidden_from_search?: bool, viewers_must_be_team_members?: bool, allow_page_subscribers?: bool, allow_incident_subscribers?: bool, allow_email_subscribers?: bool, allow_sms_subscribers?: bool, allow_rss_atom_feeds?: bool, allow_webhook_subscribers?: bool, notifications_from_email?: string, time_zone?: string, notifications_email_footer?: string}
export def "pages patch" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # shape: {name?: string, domain?: string, subdomain?: string, url?: string, branding?: "basic"|"premium", css_body_background_color?: string, css_font_color?: string, css_light_font_color?: string, css_greens?: string, css_yellows?: string, css_oranges?: string, css_reds?: string, css_blues?: string, css_border_color?: string, css_graph_color?: string, css_link_color?: string, css_no_data?: string, hidden_from_search?: bool, viewers_must_be_team_members?: bool, allow_page_subscribers?: bool, allow_incident_subscribers?: bool, allow_email_subscribers?: bool, allow_sms_subscribers?: bool, allow_rss_atom_feeds?: bool, allow_webhook_subscribers?: bool, notifications_from_email?: string, time_zone?: string, notifications_email_footer?: string}
]: any -> record<id: string, created_at: string, updated_at: string, name: string, page_description: string, headline: string, branding: string, subdomain: string, domain: string, url: string, support_url: string, hidden_from_search: bool, allow_page_subscribers: bool, allow_incident_subscribers: bool, allow_email_subscribers: bool, allow_sms_subscribers: bool, allow_rss_atom_feeds: bool, allow_webhook_subscribers: bool, notifications_from_email: string, notifications_email_footer: string, activity_score: float, twitter_username: string, viewers_must_be_team_members: bool, ip_restrictions: string, city: string, state: string, country: string, time_zone: string, css_body_background_color: string, css_font_color: string, css_light_font_color: string, css_greens: string, css_yellows: string, css_oranges: string, css_blues: string, css_reds: string, css_border_color: string, css_graph_color: string, css_link_color: string, css_no_data: string, favicon_logo: string, transactional_logo: string, hero_cover: string, email_logo: string, twitter_logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)")
  let body = {page: $page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a page
#
# PUT /pages/{page_id}
# operationId: putPagesPageId
# --page shape: {name?: string, domain?: string, subdomain?: string, url?: string, branding?: "basic"|"premium", css_body_background_color?: string, css_font_color?: string, css_light_font_color?: string, css_greens?: string, css_yellows?: string, css_oranges?: string, css_reds?: string, css_blues?: string, css_border_color?: string, css_graph_color?: string, css_link_color?: string, css_no_data?: string, hidden_from_search?: bool, viewers_must_be_team_members?: bool, allow_page_subscribers?: bool, allow_incident_subscribers?: bool, allow_email_subscribers?: bool, allow_sms_subscribers?: bool, allow_rss_atom_feeds?: bool, allow_webhook_subscribers?: bool, notifications_from_email?: string, time_zone?: string, notifications_email_footer?: string}
export def "pages put" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record # shape: {name?: string, domain?: string, subdomain?: string, url?: string, branding?: "basic"|"premium", css_body_background_color?: string, css_font_color?: string, css_light_font_color?: string, css_greens?: string, css_yellows?: string, css_oranges?: string, css_reds?: string, css_blues?: string, css_border_color?: string, css_graph_color?: string, css_link_color?: string, css_no_data?: string, hidden_from_search?: bool, viewers_must_be_team_members?: bool, allow_page_subscribers?: bool, allow_incident_subscribers?: bool, allow_email_subscribers?: bool, allow_sms_subscribers?: bool, allow_rss_atom_feeds?: bool, allow_webhook_subscribers?: bool, notifications_from_email?: string, time_zone?: string, notifications_email_footer?: string}
]: any -> record<id: string, created_at: string, updated_at: string, name: string, page_description: string, headline: string, branding: string, subdomain: string, domain: string, url: string, support_url: string, hidden_from_search: bool, allow_page_subscribers: bool, allow_incident_subscribers: bool, allow_email_subscribers: bool, allow_sms_subscribers: bool, allow_rss_atom_feeds: bool, allow_webhook_subscribers: bool, notifications_from_email: string, notifications_email_footer: string, activity_score: float, twitter_username: string, viewers_must_be_team_members: bool, ip_restrictions: string, city: string, state: string, country: string, time_zone: string, css_body_background_color: string, css_font_color: string, css_light_font_color: string, css_greens: string, css_yellows: string, css_oranges: string, css_blues: string, css_reds: string, css_border_color: string, css_graph_color: string, css_link_color: string, css_no_data: string, favicon_logo: string, transactional_logo: string, hero_cover: string, email_logo: string, twitter_logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)")
  let body = {page: $page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of page access users
#
# GET /pages/{page_id}/page_access_users
# operationId: getPagesPageIdPageAccessUsers
export def "pages-page-access-users list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email address to search for
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a page access user
#
# POST /pages/{page_id}/page_access_users
# operationId: postPagesPageIdPageAccessUsers
# --page_access_user shape: {external_login?: string, email?: string, page_access_group_ids?: list, subscribe_to_components?: bool}
export def "pages-page-access-users post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-access-user: record # shape: {external_login?: string, email?: string, page_access_group_ids?: list, subscribe_to_components?: bool}
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users")
  let body = {page_access_user: $page_access_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete page access user
#
# DELETE /pages/{page_id}/page_access_users/{page_access_user_id}
# operationId: deletePagesPageIdPageAccessUsersPageAccessUserId
export def "pages-page-access-users delete" [
  page_id: string
  page_access_user_id: string
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
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get page access user
#
# GET /pages/{page_id}/page_access_users/{page_access_user_id}
# operationId: getPagesPageIdPageAccessUsersPageAccessUserId
export def "pages-page-access-users get" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update page access user
#
# PATCH /pages/{page_id}/page_access_users/{page_access_user_id}
# operationId: patchPagesPageIdPageAccessUsersPageAccessUserId
export def "pages-page-access-users patch" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update page access user
#
# PUT /pages/{page_id}/page_access_users/{page_access_user_id}
# operationId: putPagesPageIdPageAccessUsersPageAccessUserId
export def "pages-page-access-users put" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove components for page access user
#
# DELETE /pages/{page_id}/page_access_users/{page_access_user_id}/components
# operationId: deletePagesPageIdPageAccessUsersPageAccessUserIdComponents
export def "pages-page-access-users-components delete-by-page_id-page_access_user_id" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component-ids: list # List of components codes to remove.  If omitted, all components will be removed.
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get components for page access user
#
# GET /pages/{page_id}/page_access_users/{page_access_user_id}/components
# operationId: getPagesPageIdPageAccessUsersPageAccessUserIdComponents
export def "pages-page-access-users-components get" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add components for page access user
#
# PATCH /pages/{page_id}/page_access_users/{page_access_user_id}/components
# operationId: patchPagesPageIdPageAccessUsersPageAccessUserIdComponents
export def "pages-page-access-users-components patch" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  component_ids: list # List of component codes to allow access to
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace components for page access user
#
# POST /pages/{page_id}/page_access_users/{page_access_user_id}/components
# operationId: postPagesPageIdPageAccessUsersPageAccessUserIdComponents
export def "pages-page-access-users-components post" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  component_ids: list # List of component codes to allow access to
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add components for page access user
#
# PUT /pages/{page_id}/page_access_users/{page_access_user_id}/components
# operationId: putPagesPageIdPageAccessUsersPageAccessUserIdComponents
export def "pages-page-access-users-components put" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  component_ids: list # List of component codes to allow access to
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove component for page access user
#
# DELETE /pages/{page_id}/page_access_users/{page_access_user_id}/components/{component_id}
# operationId: deletePagesPageIdPageAccessUsersPageAccessUserIdComponentsComponentId
export def "pages-page-access-users-components delete-by-page_id-page_access_user_id-component_id" [
  page_id: string
  page_access_user_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete metrics for page access user
#
# DELETE /pages/{page_id}/page_access_users/{page_access_user_id}/metrics
# operationId: deletePagesPageIdPageAccessUsersPageAccessUserIdMetrics
export def "pages-page-access-users-metrics delete-by-page_id-page_access_user_id" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric-ids: list # List of metrics to remove
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/metrics")
  let body = {metric_ids: $metric_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metrics for page access user
#
# GET /pages/{page_id}/page_access_users/{page_access_user_id}/metrics
# operationId: getPagesPageIdPageAccessUsersPageAccessUserIdMetrics
export def "pages-page-access-users-metrics get" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add metrics for page access user
#
# PATCH /pages/{page_id}/page_access_users/{page_access_user_id}/metrics
# operationId: patchPagesPageIdPageAccessUsersPageAccessUserIdMetrics
export def "pages-page-access-users-metrics patch" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metric_ids: list # List of metrics to add
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/metrics")
  let body = {metric_ids: $metric_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace metrics for page access user
#
# POST /pages/{page_id}/page_access_users/{page_access_user_id}/metrics
# operationId: postPagesPageIdPageAccessUsersPageAccessUserIdMetrics
export def "pages-page-access-users-metrics post" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metric_ids: list # List of metrics to add
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/metrics")
  let body = {metric_ids: $metric_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add metrics for page access user
#
# PUT /pages/{page_id}/page_access_users/{page_access_user_id}/metrics
# operationId: putPagesPageIdPageAccessUsersPageAccessUserIdMetrics
export def "pages-page-access-users-metrics put" [
  page_id: string
  page_access_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metric_ids: list # List of metrics to add
]: any -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/metrics")
  let body = {metric_ids: $metric_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete metric for page access user
#
# DELETE /pages/{page_id}/page_access_users/{page_access_user_id}/metrics/{metric_id}
# operationId: deletePagesPageIdPageAccessUsersPageAccessUserIdMetricsMetricId
export def "pages-page-access-users-metrics delete-by-page_id-page_access_user_id-metric_id" [
  page_id: string
  page_access_user_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, email: string, external_login: string, page_access_group_id: string, page_access_group_ids: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_users/($page_access_user_id)/metrics/($metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of page access groups
#
# GET /pages/{page_id}/page_access_groups
# operationId: getPagesPageIdPageAccessGroups
export def "pages-page-access-groups list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a page access group
#
# POST /pages/{page_id}/page_access_groups
# operationId: postPagesPageIdPageAccessGroups
# --page_access_group shape: {name?: string, external_identifier?: string, component_ids?: list, metric_ids?: list, page_access_user_ids?: list}
export def "pages-page-access-groups post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-access-group: record # shape: {name?: string, external_identifier?: string, component_ids?: list, metric_ids?: list, page_access_user_ids?: list}
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups")
  let body = {page_access_group: $page_access_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a page access group
#
# DELETE /pages/{page_id}/page_access_groups/{page_access_group_id}
# operationId: deletePagesPageIdPageAccessGroupsPageAccessGroupId
export def "pages-page-access-groups delete" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a page access group
#
# GET /pages/{page_id}/page_access_groups/{page_access_group_id}
# operationId: getPagesPageIdPageAccessGroupsPageAccessGroupId
export def "pages-page-access-groups get" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a page access group
#
# PATCH /pages/{page_id}/page_access_groups/{page_access_group_id}
# operationId: patchPagesPageIdPageAccessGroupsPageAccessGroupId
# --page_access_group shape: {name?: string, external_identifier?: string, component_ids?: list, metric_ids?: list, page_access_user_ids?: list}
export def "pages-page-access-groups patch" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-access-group: record # shape: {name?: string, external_identifier?: string, component_ids?: list, metric_ids?: list, page_access_user_ids?: list}
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)")
  let body = {page_access_group: $page_access_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a page access group
#
# PUT /pages/{page_id}/page_access_groups/{page_access_group_id}
# operationId: putPagesPageIdPageAccessGroupsPageAccessGroupId
# --page_access_group shape: {name?: string, external_identifier?: string, component_ids?: list, metric_ids?: list, page_access_user_ids?: list}
export def "pages-page-access-groups put" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-access-group: record # shape: {name?: string, external_identifier?: string, component_ids?: list, metric_ids?: list, page_access_user_ids?: list}
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)")
  let body = {page_access_group: $page_access_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete components for a page access group
#
# DELETE /pages/{page_id}/page_access_groups/{page_access_group_id}/components
# operationId: deletePagesPageIdPageAccessGroupsPageAccessGroupIdComponents
export def "pages-page-access-groups-components delete-by-page_id-page_access_group_id" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component-ids: list
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List components for a page access group
#
# GET /pages/{page_id}/page_access_groups/{page_access_group_id}/components
# operationId: getPagesPageIdPageAccessGroupsPageAccessGroupIdComponents
export def "pages-page-access-groups-components get" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add components to page access group
#
# PATCH /pages/{page_id}/page_access_groups/{page_access_group_id}/components
# operationId: patchPagesPageIdPageAccessGroupsPageAccessGroupIdComponents
export def "pages-page-access-groups-components patch" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component-ids: list # List of Component identifiers
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace components for a page access group
#
# POST /pages/{page_id}/page_access_groups/{page_access_group_id}/components
# operationId: postPagesPageIdPageAccessGroupsPageAccessGroupIdComponents
export def "pages-page-access-groups-components post" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  component_ids: list # List of components codes to set on the page access group
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add components to page access group
#
# PUT /pages/{page_id}/page_access_groups/{page_access_group_id}/components
# operationId: putPagesPageIdPageAccessGroupsPageAccessGroupIdComponents
export def "pages-page-access-groups-components put" [
  page_id: string
  page_access_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component-ids: list # List of Component identifiers
]: any -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)/components")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a component from a page access group
#
# DELETE /pages/{page_id}/page_access_groups/{page_access_group_id}/components/{component_id}
# operationId: deletePagesPageIdPageAccessGroupsPageAccessGroupIdComponentsComponentId
export def "pages-page-access-groups-components delete-by-page_id-page_access_group_id-component_id" [
  page_id: string
  page_access_group_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, name: string, page_access_user_ids: list<string>, external_identifier: string, metric_ids: list<string>, component_ids: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/page_access_groups/($page_access_group_id)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend confirmations to a list of subscribers
#
# POST /pages/{page_id}/subscribers/resend_confirmation
# operationId: postPagesPageIdSubscribersResendConfirmation
export def "pages-subscribers-resend-confirmation post-by-page_id" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscribers: string # The array of subscriber codes to resend confirmations for, or "all" to resend confirmations to all subscribers. Only unconfirmed email subscribers will receive this notification.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/resend_confirmation")
  let body = {subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsubscribe a list of subscribers
#
# POST /pages/{page_id}/subscribers/unsubscribe
# operationId: postPagesPageIdSubscribersUnsubscribe
export def "pages-subscribers-unsubscribe post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscribers: string # The array of subscriber codes to unsubscribe (limited to 100), or "all" to unsubscribe all subscribers if the number of subscribers is less than 100.
  --type: string@type-completer # If this is present, only unsubscribe subscribers of this type.
  --state: string@state-completer # If this is present, only unsubscribe subscribers in this state. Specify state "all" to unsubscribe subscribers in any states. (default: active)
  --skip-unsubscription-notification: string@bool-completer # If skip_unsubscription_notification is true, the subscribers do not receive any notifications when they are unsubscribed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/unsubscribe")
  let body = {subscribers: $subscribers, type: $type, state: $state, skip_unsubscription_notification: $skip_unsubscription_notification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reactivate a list of subscribers
#
# POST /pages/{page_id}/subscribers/reactivate
# operationId: postPagesPageIdSubscribersReactivate
export def "pages-subscribers-reactivate post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscribers: string # The array of quarantined subscriber codes to reactivate, or "all" to reactivate all quarantined subscribers.
  --type: string@type-completer # If this is present, only reactivate subscribers of this type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/reactivate")
  let body = {subscribers: $subscribers, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a histogram of subscribers by type and then state
#
# GET /pages/{page_id}/subscribers/histogram_by_state
# operationId: getPagesPageIdSubscribersHistogramByState
export def "pages-subscribers-histogram-by-state get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: record<active: int, unconfirmed: int, quarantined: int, total: int>, sms: record<active: int, unconfirmed: int, quarantined: int, total: int>, webhook: record<active: int, unconfirmed: int, quarantined: int, total: int>, integration_partner: record<active: int, unconfirmed: int, quarantined: int, total: int>, slack: record<active: int, unconfirmed: int, quarantined: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/histogram_by_state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a count of subscribers by type
#
# GET /pages/{page_id}/subscribers/count
# operationId: getPagesPageIdSubscribersCount
export def "pages-subscribers-count get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # If this is present, only count subscribers of this type.
  --state: string@state-completer # If this is present, only count subscribers in this state. Specify state "all" to count subscribers in any states. (default: active)
]: nothing -> record<email: int, sms: int, webhook: int, integration_partner: int, slack: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of unsubscribed subscribers
#
# GET /pages/{page_id}/subscribers/unsubscribed
# operationId: getPagesPageIdSubscribersUnsubscribed
export def "pages-subscribers-unsubscribed get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/unsubscribed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of subscribers
#
# GET /pages/{page_id}/subscribers
# operationId: getPagesPageIdSubscribers
export def "pages-subscribers list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # If this is specified, search the contact information (email, endpoint, or phone number) for the provided value. This parameter doesn’t support searching for Slack subscribers.
  --type: string@type-completer # If specified, only return subscribers of the indicated type.
  --state: string@state-completer # If this is present, only return subscribers in this state. Specify state "all" to find subscribers in any states. (default: active)
  --limit: int # The maximum number of rows to return. If a text query string is specified (q=), the default and maximum limit is 100. If the text query string is not specified, the default and maximum limit are not set, and not providing a limit will return all the subscribers. Beginning February 28, 2023, a default limit of 100 will be imposed and this endpoint will return paginated data (i.e. will no longer return all subscribers) even if this query parameter is not provided. (format: int32)
  --page: int # The page offset of subscribers. The first page is page 0, the second page 1, etc. This skips page * limit subscribers. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32, default: 0)
  --sort-field: string@sort-field-completer # The field on which to sort: 'primary' to indicate sorting by the identifying field, 'created_at' for sorting by creation timestamp, 'quarantined_at' for sorting by quarantine timestamp, and 'relevance' which sorts by the relevancy of the search text. 'relevance' is not a valid parameter if no search text is supplied. (default: primary)
  --sort-direction: string@sort-direction-completer # The sort direction of the listing. (default: asc)
]: nothing -> table<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a subscriber
#
# POST /pages/{page_id}/subscribers
# operationId: postPagesPageIdSubscribers
# --subscriber shape: {email?: string, endpoint?: string, phone_country?: string, phone_number?: string, skip_confirmation_notification?: bool, page_access_user?: string, component_ids?: list}
export def "pages-subscribers post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriber: record # shape: {email?: string, endpoint?: string, phone_country?: string, phone_number?: string, skip_confirmation_notification?: bool, page_access_user?: string, component_ids?: list}
]: any -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers")
  let body = {subscriber: $subscriber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resend confirmation to a subscriber
#
# POST /pages/{page_id}/subscribers/{subscriber_id}/resend_confirmation
# operationId: postPagesPageIdSubscribersSubscriberIdResendConfirmation
export def "pages-subscribers-resend-confirmation post-by-page_id-subscriber_id" [
  page_id: string
  subscriber_id: string
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
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/($subscriber_id)/resend_confirmation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe a subscriber
#
# DELETE /pages/{page_id}/subscribers/{subscriber_id}
# operationId: deletePagesPageIdSubscribersSubscriberId
export def "pages-subscribers delete" [
  page_id: string
  subscriber_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip-unsubscription-notification: string@bool-completer # If skip_unsubscription_notification is true, the subscriber does not receive any notifications when they are unsubscribed.
]: nothing -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_unsubscription_notification" $skip_unsubscription_notification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/($subscriber_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a subscriber
#
# GET /pages/{page_id}/subscribers/{subscriber_id}
# operationId: getPagesPageIdSubscribersSubscriberId
export def "pages-subscribers get" [
  page_id: string
  subscriber_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/($subscriber_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscriber
#
# PATCH /pages/{page_id}/subscribers/{subscriber_id}
# operationId: patchPagesPageIdSubscribersSubscriberId
export def "pages-subscribers patch" [
  page_id: string
  subscriber_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component-ids: list # A list of component ids for which the subscriber should recieve updates for. Components must be an array with at least one element if it is passed at all. Each component must belong to the page indicated in the path. To set the subscriber to be subscribed to all components on the page, exclude this parameter.
]: any -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/subscribers/($subscriber_id)")
  let body = {component_ids: $component_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of templates
#
# GET /pages/{page_id}/incident_templates
# operationId: getPagesPageIdIncidentTemplates
export def "pages-incident-templates get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. (format: int32, default: 1)
  --per-page: int # Number of results to return per page. (format: int32, default: 100)
]: nothing -> table<id: string, components: list<record>, name: string, title: string, body: string, group_id: string, update_status: string, should_tweet: bool, should_send_notifications: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incident_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /pages/{page_id}/incident_templates
# operationId: postPagesPageIdIncidentTemplates
# --template shape: {name: string, title: string, body: string, group_id?: string, update_status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", should_tweet?: bool, should_send_notifications?: bool, component_ids?: list}
export def "pages-incident-templates post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: record # shape: {name: string, title: string, body: string, group_id?: string, update_status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", should_tweet?: bool, should_send_notifications?: bool, component_ids?: list}
]: any -> record<id: string, components: table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string>, name: string, title: string, body: string, group_id: string, update_status: string, should_tweet: bool, should_send_notifications: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incident_templates")
  let body = {template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of incidents
#
# GET /pages/{page_id}/incidents
# operationId: getPagesPageIdIncidents
export def "pages-incidents list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # If this is specified, search for the text query string in the incidents' name, status, postmortem_body, and incident_updates fields.
  --limit: int # The maximum number of rows to return per page. The default and maximum limit is 100. (format: int32)
  --page: int # Page offset to fetch. (format: int32)
]: nothing -> table<id: string, components: list<record>, created_at: string, impact: string, impact_override: string, incident_updates: list<record>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an incident
#
# POST /pages/{page_id}/incidents
# operationId: postPagesPageIdIncidents
# --incident shape: {name: string, status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", impact_override?: "none"|"maintenance"|"minor"|"major"|"critical", scheduled_for?: string, scheduled_until?: string, scheduled_remind_prior?: bool, auto_transition_to_maintenance_state?: bool, auto_transition_to_operational_state?: bool, scheduled_auto_in_progress?: bool, scheduled_auto_completed?: bool, auto_transition_deliver_notifications_at_start?: bool, auto_transition_deliver_notifications_at_end?: bool, metadata?: record, deliver_notifications?: bool, auto_tweet_at_beginning?: bool, auto_tweet_on_completion?: bool, auto_tweet_on_creation?: bool, auto_tweet_one_hour_before?: bool, backfill_date?: string, backfilled?: bool, body?: string, components?: record, component_ids?: list, scheduled_auto_transition?: bool}
export def "pages-incidents post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident: record # shape: {name: string, status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", impact_override?: "none"|"maintenance"|"minor"|"major"|"critical", scheduled_for?: string, scheduled_until?: string, scheduled_remind_prior?: bool, auto_transition_to_maintenance_state?: bool, auto_transition_to_operational_state?: bool, scheduled_auto_in_progress?: bool, scheduled_auto_completed?: bool, auto_transition_deliver_notifications_at_start?: bool, auto_transition_deliver_notifications_at_end?: bool, metadata?: record, deliver_notifications?: bool, auto_tweet_at_beginning?: bool, auto_tweet_on_completion?: bool, auto_tweet_on_creation?: bool, auto_tweet_one_hour_before?: bool, backfill_date?: string, backfilled?: bool, body?: string, components?: record, component_ids?: list, scheduled_auto_transition?: bool}
]: any -> record<id: string, components: table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string>, created_at: string, impact: string, impact_override: string, incident_updates: table<id: string, incident_id: string, affected_components: list, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents")
  let body = {incident: $incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of active maintenances
#
# GET /pages/{page_id}/incidents/active_maintenance
# operationId: getPagesPageIdIncidentsActiveMaintenance
export def "pages-incidents-active-maintenance get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. (format: int32, default: 1)
  --per-page: int # Number of results to return per page. (format: int32, default: 100)
]: nothing -> table<id: string, components: list<record>, created_at: string, impact: string, impact_override: string, incident_updates: list<record>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incidents/active_maintenance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of upcoming incidents
#
# GET /pages/{page_id}/incidents/upcoming
# operationId: getPagesPageIdIncidentsUpcoming
export def "pages-incidents-upcoming get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. (format: int32, default: 1)
  --per-page: int # Number of results to return per page. (format: int32, default: 100)
]: nothing -> table<id: string, components: list<record>, created_at: string, impact: string, impact_override: string, incident_updates: list<record>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incidents/upcoming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of scheduled incidents
#
# GET /pages/{page_id}/incidents/scheduled
# operationId: getPagesPageIdIncidentsScheduled
export def "pages-incidents-scheduled get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. (format: int32, default: 1)
  --per-page: int # Number of results to return per page. (format: int32, default: 100)
]: nothing -> table<id: string, components: list<record>, created_at: string, impact: string, impact_override: string, incident_updates: list<record>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incidents/scheduled" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of unresolved incidents
#
# GET /pages/{page_id}/incidents/unresolved
# operationId: getPagesPageIdIncidentsUnresolved
export def "pages-incidents-unresolved get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. (format: int32, default: 1)
  --per-page: int # Number of results to return per page. (format: int32, default: 100)
]: nothing -> table<id: string, components: list<record>, created_at: string, impact: string, impact_override: string, incident_updates: list<record>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incidents/unresolved" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an incident
#
# DELETE /pages/{page_id}/incidents/{incident_id}
# operationId: deletePagesPageIdIncidentsIncidentId
export def "pages-incidents delete" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, components: table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string>, created_at: string, impact: string, impact_override: string, incident_updates: table<id: string, incident_id: string, affected_components: list, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an incident
#
# GET /pages/{page_id}/incidents/{incident_id}
# operationId: getPagesPageIdIncidentsIncidentId
export def "pages-incidents get" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, components: table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string>, created_at: string, impact: string, impact_override: string, incident_updates: table<id: string, incident_id: string, affected_components: list, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an incident
#
# PATCH /pages/{page_id}/incidents/{incident_id}
# operationId: patchPagesPageIdIncidentsIncidentId
# --incident shape: {name?: string, status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", impact_override?: "none"|"maintenance"|"minor"|"major"|"critical", scheduled_for?: string, scheduled_until?: string, scheduled_remind_prior?: bool, auto_transition_to_maintenance_state?: bool, auto_transition_to_operational_state?: bool, scheduled_auto_in_progress?: bool, scheduled_auto_completed?: bool, auto_transition_deliver_notifications_at_start?: bool, auto_transition_deliver_notifications_at_end?: bool, metadata?: record, deliver_notifications?: bool, auto_tweet_at_beginning?: bool, auto_tweet_on_completion?: bool, auto_tweet_on_creation?: bool, auto_tweet_one_hour_before?: bool, backfill_date?: string, backfilled?: bool, body?: string, components?: record, component_ids?: list, scheduled_auto_transition?: bool}
export def "pages-incidents patch" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident: record # shape: {name?: string, status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", impact_override?: "none"|"maintenance"|"minor"|"major"|"critical", scheduled_for?: string, scheduled_until?: string, scheduled_remind_prior?: bool, auto_transition_to_maintenance_state?: bool, auto_transition_to_operational_state?: bool, scheduled_auto_in_progress?: bool, scheduled_auto_completed?: bool, auto_transition_deliver_notifications_at_start?: bool, auto_transition_deliver_notifications_at_end?: bool, metadata?: record, deliver_notifications?: bool, auto_tweet_at_beginning?: bool, auto_tweet_on_completion?: bool, auto_tweet_on_creation?: bool, auto_tweet_one_hour_before?: bool, backfill_date?: string, backfilled?: bool, body?: string, components?: record, component_ids?: list, scheduled_auto_transition?: bool}
]: any -> record<id: string, components: table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string>, created_at: string, impact: string, impact_override: string, incident_updates: table<id: string, incident_id: string, affected_components: list, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)")
  let body = {incident: $incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an incident
#
# PUT /pages/{page_id}/incidents/{incident_id}
# operationId: putPagesPageIdIncidentsIncidentId
# --incident shape: {name?: string, status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", impact_override?: "none"|"maintenance"|"minor"|"major"|"critical", scheduled_for?: string, scheduled_until?: string, scheduled_remind_prior?: bool, auto_transition_to_maintenance_state?: bool, auto_transition_to_operational_state?: bool, scheduled_auto_in_progress?: bool, scheduled_auto_completed?: bool, auto_transition_deliver_notifications_at_start?: bool, auto_transition_deliver_notifications_at_end?: bool, metadata?: record, deliver_notifications?: bool, auto_tweet_at_beginning?: bool, auto_tweet_on_completion?: bool, auto_tweet_on_creation?: bool, auto_tweet_one_hour_before?: bool, backfill_date?: string, backfilled?: bool, body?: string, components?: record, component_ids?: list, scheduled_auto_transition?: bool}
export def "pages-incidents put" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident: record # shape: {name?: string, status?: "investigating"|"identified"|"monitoring"|"resolved"|"scheduled"|"in_progress"|"verifying"|"completed", impact_override?: "none"|"maintenance"|"minor"|"major"|"critical", scheduled_for?: string, scheduled_until?: string, scheduled_remind_prior?: bool, auto_transition_to_maintenance_state?: bool, auto_transition_to_operational_state?: bool, scheduled_auto_in_progress?: bool, scheduled_auto_completed?: bool, auto_transition_deliver_notifications_at_start?: bool, auto_transition_deliver_notifications_at_end?: bool, metadata?: record, deliver_notifications?: bool, auto_tweet_at_beginning?: bool, auto_tweet_on_completion?: bool, auto_tweet_on_creation?: bool, auto_tweet_one_hour_before?: bool, backfill_date?: string, backfilled?: bool, body?: string, components?: record, component_ids?: list, scheduled_auto_transition?: bool}
]: any -> record<id: string, components: table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string>, created_at: string, impact: string, impact_override: string, incident_updates: table<id: string, incident_id: string, affected_components: list, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool>, metadata: any, monitoring_at: string, name: string, page_id: string, postmortem_body: string, postmortem_body_last_updated_at: string, postmortem_ignored: bool, postmortem_notified_subscribers: bool, postmortem_notified_twitter: bool, postmortem_published_at: bool, resolved_at: string, scheduled_auto_completed: bool, scheduled_auto_in_progress: bool, scheduled_for: string, auto_transition_deliver_notifications_at_end: bool, auto_transition_deliver_notifications_at_start: bool, auto_transition_to_maintenance_state: bool, auto_transition_to_operational_state: bool, scheduled_remind_prior: bool, scheduled_reminded_at: string, scheduled_until: string, shortlink: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)")
  let body = {incident: $incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a previous incident update
#
# PATCH /pages/{page_id}/incidents/{incident_id}/incident_updates/{incident_update_id}
# operationId: patchPagesPageIdIncidentsIncidentIdIncidentUpdatesIncidentUpdateId
# --incident_update shape: {wants_twitter_update?: bool, body?: string, display_at?: string, deliver_notifications?: bool}
export def "pages-incidents-incident-updates patch" [
  page_id: string
  incident_id: string
  incident_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-update: record # shape: {wants_twitter_update?: bool, body?: string, display_at?: string, deliver_notifications?: bool}
]: any -> record<id: string, incident_id: string, affected_components: list<record>, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/incident_updates/($incident_update_id)")
  let body = {incident_update: $incident_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a previous incident update
#
# PUT /pages/{page_id}/incidents/{incident_id}/incident_updates/{incident_update_id}
# operationId: putPagesPageIdIncidentsIncidentIdIncidentUpdatesIncidentUpdateId
# --incident_update shape: {wants_twitter_update?: bool, body?: string, display_at?: string, deliver_notifications?: bool}
export def "pages-incidents-incident-updates put" [
  page_id: string
  incident_id: string
  incident_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --incident-update: record # shape: {wants_twitter_update?: bool, body?: string, display_at?: string, deliver_notifications?: bool}
]: any -> record<id: string, incident_id: string, affected_components: list<record>, body: string, created_at: string, custom_tweet: string, deliver_notifications: bool, display_at: string, status: string, tweet_id: string, twitter_updated_at: string, updated_at: string, wants_twitter_update: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/incident_updates/($incident_update_id)")
  let body = {incident_update: $incident_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of incident subscribers
#
# GET /pages/{page_id}/incidents/{incident_id}/subscribers
# operationId: getPagesPageIdIncidentsIncidentIdSubscribers
export def "pages-incidents-subscribers list" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an incident subscriber
#
# POST /pages/{page_id}/incidents/{incident_id}/subscribers
# operationId: postPagesPageIdIncidentsIncidentIdSubscribers
# --subscriber shape: {email?: string, phone_country?: string, phone_number?: string, skip_confirmation_notification?: bool}
export def "pages-incidents-subscribers post" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriber: record # shape: {email?: string, phone_country?: string, phone_number?: string, skip_confirmation_notification?: bool}
]: any -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/subscribers")
  let body = {subscriber: $subscriber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsubscribe an incident subscriber
#
# DELETE /pages/{page_id}/incidents/{incident_id}/subscribers/{subscriber_id}
# operationId: deletePagesPageIdIncidentsIncidentIdSubscribersSubscriberId
export def "pages-incidents-subscribers delete" [
  page_id: string
  incident_id: string
  subscriber_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/subscribers/($subscriber_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an incident subscriber
#
# GET /pages/{page_id}/incidents/{incident_id}/subscribers/{subscriber_id}
# operationId: getPagesPageIdIncidentsIncidentIdSubscribersSubscriberId
export def "pages-incidents-subscribers get" [
  page_id: string
  incident_id: string
  subscriber_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, skip_confirmation_notification: bool, mode: string, email: string, endpoint: string, phone_number: string, phone_country: string, display_phone_number: string, obfuscated_channel_name: string, workspace_name: string, quarantined_at: string, purge_at: string, components: string, page_access_user_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/subscribers/($subscriber_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend confirmation to an incident subscriber
#
# POST /pages/{page_id}/incidents/{incident_id}/subscribers/{subscriber_id}/resend_confirmation
# operationId: postPagesPageIdIncidentsIncidentIdSubscribersSubscriberIdResendConfirmation
export def "pages-incidents-subscribers-resend-confirmation post" [
  page_id: string
  incident_id: string
  subscriber_id: string
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
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/subscribers/($subscriber_id)/resend_confirmation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Postmortem
#
# DELETE /pages/{page_id}/incidents/{incident_id}/postmortem
# operationId: deletePagesPageIdIncidentsIncidentIdPostmortem
export def "pages-incidents-postmortem delete" [
  page_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/postmortem")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Postmortem
#
# GET /pages/{page_id}/incidents/{incident_id}/postmortem
# operationId: getPagesPageIdIncidentsIncidentIdPostmortem
export def "pages-incidents-postmortem get" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<preview_key: string, body: string, body_updated_at: string, body_draft: string, body_draft_updated_at: string, published_at: string, notify_subscribers: bool, notify_twitter: bool, custom_tweet: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/postmortem")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Postmortem
#
# PUT /pages/{page_id}/incidents/{incident_id}/postmortem
# operationId: putPagesPageIdIncidentsIncidentIdPostmortem
# --postmortem shape: {body_draft: string}
export def "pages-incidents-postmortem put" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --postmortem: record # shape: {body_draft: string}
]: any -> record<preview_key: string, body: string, body_updated_at: string, body_draft: string, body_draft_updated_at: string, published_at: string, notify_subscribers: bool, notify_twitter: bool, custom_tweet: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/postmortem")
  let body = {postmortem: $postmortem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Publish Postmortem
#
# PUT /pages/{page_id}/incidents/{incident_id}/postmortem/publish
# operationId: putPagesPageIdIncidentsIncidentIdPostmortemPublish
# --postmortem shape: {notify_twitter?: bool, notify_subscribers?: bool, custom_tweet?: string}
export def "pages-incidents-postmortem-publish put" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --postmortem: record # shape: {notify_twitter?: bool, notify_subscribers?: bool, custom_tweet?: string}
]: any -> record<preview_key: string, body: string, body_updated_at: string, body_draft: string, body_draft_updated_at: string, published_at: string, notify_subscribers: bool, notify_twitter: bool, custom_tweet: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/postmortem/publish")
  let body = {postmortem: $postmortem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revert Postmortem
#
# PUT /pages/{page_id}/incidents/{incident_id}/postmortem/revert
# operationId: putPagesPageIdIncidentsIncidentIdPostmortemRevert
export def "pages-incidents-postmortem-revert put" [
  page_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<preview_key: string, body: string, body_updated_at: string, body_draft: string, body_draft_updated_at: string, published_at: string, notify_subscribers: bool, notify_twitter: bool, custom_tweet: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/incidents/($incident_id)/postmortem/revert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of components
#
# GET /pages/{page_id}/components
# operationId: getPagesPageIdComponents
export def "pages-components list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a component
#
# POST /pages/{page_id}/components
# operationId: postPagesPageIdComponents
# --component shape: {description?: string, status?: "operational"|"under_maintenance"|"degraded_performance"|"partial_outage"|"major_outage"|"", name?: string, only_show_if_degraded?: bool, group_id?: string, showcase?: bool, start_date?: string}
export def "pages-components post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component: record # shape: {description?: string, status?: "operational"|"under_maintenance"|"degraded_performance"|"partial_outage"|"major_outage"|"", name?: string, only_show_if_degraded?: bool, group_id?: string, showcase?: bool, start_date?: string}
]: any -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components")
  let body = {component: $component} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a component
#
# DELETE /pages/{page_id}/components/{component_id}
# operationId: deletePagesPageIdComponentsComponentId
export def "pages-components delete" [
  page_id: string
  component_id: string
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
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a component
#
# GET /pages/{page_id}/components/{component_id}
# operationId: getPagesPageIdComponentsComponentId
export def "pages-components get" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a component
#
# PATCH /pages/{page_id}/components/{component_id}
# operationId: patchPagesPageIdComponentsComponentId
# --component shape: {description?: string, status?: "operational"|"under_maintenance"|"degraded_performance"|"partial_outage"|"major_outage"|"", name?: string, only_show_if_degraded?: bool, group_id?: string, showcase?: bool, start_date?: string}
export def "pages-components patch" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component: record # shape: {description?: string, status?: "operational"|"under_maintenance"|"degraded_performance"|"partial_outage"|"major_outage"|"", name?: string, only_show_if_degraded?: bool, group_id?: string, showcase?: bool, start_date?: string}
]: any -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)")
  let body = {component: $component} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a component
#
# PUT /pages/{page_id}/components/{component_id}
# operationId: putPagesPageIdComponentsComponentId
# --component shape: {description?: string, status?: "operational"|"under_maintenance"|"degraded_performance"|"partial_outage"|"major_outage"|"", name?: string, only_show_if_degraded?: bool, group_id?: string, showcase?: bool, start_date?: string}
export def "pages-components put" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --component: record # shape: {description?: string, status?: "operational"|"under_maintenance"|"degraded_performance"|"partial_outage"|"major_outage"|"", name?: string, only_show_if_degraded?: bool, group_id?: string, showcase?: bool, start_date?: string}
]: any -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)")
  let body = {component: $component} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get uptime data for a component
#
# GET /pages/{page_id}/components/{component_id}/uptime
# operationId: getPagesPageIdComponentsComponentIdUptime
export def "pages-components-uptime get" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<range_start: string, range_end: string, uptime_percentage: float, major_outage: int, partial_outage: int, warnings: string, id: string, name: string, related_events: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)/uptime")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove page access users from component
#
# DELETE /pages/{page_id}/components/{component_id}/page_access_users
# operationId: deletePagesPageIdComponentsComponentIdPageAccessUsers
export def "pages-components-page-access-users delete" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)/page_access_users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add page access users to a component
#
# POST /pages/{page_id}/components/{component_id}/page_access_users
# operationId: postPagesPageIdComponentsComponentIdPageAccessUsers
export def "pages-components-page-access-users post" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  page_access_user_ids: list # List of page access users to add to component
]: any -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)/page_access_users")
  let body = {page_access_user_ids: $page_access_user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove page access groups from a component
#
# DELETE /pages/{page_id}/components/{component_id}/page_access_groups
# operationId: deletePagesPageIdComponentsComponentIdPageAccessGroups
export def "pages-components-page-access-groups delete" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)/page_access_groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add page access groups to a component
#
# POST /pages/{page_id}/components/{component_id}/page_access_groups
# operationId: postPagesPageIdComponentsComponentIdPageAccessGroups
export def "pages-components-page-access-groups post" [
  page_id: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, group_id: string, created_at: string, updated_at: string, group: bool, name: string, description: string, position: int, status: string, showcase: bool, only_show_if_degraded: bool, automation_email: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/components/($component_id)/page_access_groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of component groups
#
# GET /pages/{page_id}/component-groups
# operationId: getPagesPageIdComponentGroups
export def "pages-component-groups list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, page_id: string, name: string, description: string, components: string, position: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/component-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a component group
#
# POST /pages/{page_id}/component-groups
# operationId: postPagesPageIdComponentGroups
# --component_group shape: {components: list, name: string}
export def "pages-component-groups post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the component group.
  --component-group: record # shape: {components: list, name: string}
]: any -> record<id: string, page_id: string, name: string, description: string, components: string, position: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/component-groups")
  let body = {description: $description, component_group: $component_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a component group
#
# DELETE /pages/{page_id}/component-groups/{id}
# operationId: deletePagesPageIdComponentGroupsId
export def "pages-component-groups delete" [
  page_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, name: string, description: string, components: string, position: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/component-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a component group
#
# GET /pages/{page_id}/component-groups/{id}
# operationId: getPagesPageIdComponentGroupsId
export def "pages-component-groups get" [
  page_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, page_id: string, name: string, description: string, components: string, position: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/component-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a component group
#
# PATCH /pages/{page_id}/component-groups/{id}
# operationId: patchPagesPageIdComponentGroupsId
# --component_group shape: {components: list, name: string}
export def "pages-component-groups patch" [
  page_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Updated description of the component group.
  --component-group: record # shape: {components: list, name: string}
]: any -> record<id: string, page_id: string, name: string, description: string, components: string, position: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/component-groups/($id)")
  let body = {description: $description, component_group: $component_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a component group
#
# PUT /pages/{page_id}/component-groups/{id}
# operationId: putPagesPageIdComponentGroupsId
# --component_group shape: {components: list, name: string}
export def "pages-component-groups put" [
  page_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Updated description of the component group.
  --component-group: record # shape: {components: list, name: string}
]: any -> record<id: string, page_id: string, name: string, description: string, components: string, position: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/component-groups/($id)")
  let body = {description: $description, component_group: $component_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get uptime data for a component group
#
# GET /pages/{page_id}/component-groups/{id}/uptime
# operationId: getPagesPageIdComponentGroupsIdUptime
export def "pages-component-groups-uptime get" [
  page_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<range_start: string, range_end: string, uptime_percentage: float, major_outage: int, partial_outage: int, warnings: string, id: string, name: string, related_events: record<component_id: string, incidents: record<id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/component-groups/($id)/uptime")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add data points to metrics
#
# POST /pages/{page_id}/metrics/data
# operationId: postPagesPageIdMetricsData
# --data shape: {metric_id?: list}
export def "pages-metrics-data post-by-page_id" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Add data points to metrics (e.g. {metric_id: [{value: 6.0274563, timestamp: 0}, {value: 6.0274563, timestamp: 0}]}) — shape: {metric_id?: list}
]: any -> record<metric_id: table<timestamp: int, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/data")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of metrics
#
# GET /pages/{page_id}/metrics
# operationId: getPagesPageIdMetrics
export def "pages-metrics list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a metric
#
# DELETE /pages/{page_id}/metrics/{metric_id}
# operationId: deletePagesPageIdMetricsMetricId
export def "pages-metrics delete" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/($metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a metric
#
# GET /pages/{page_id}/metrics/{metric_id}
# operationId: getPagesPageIdMetricsMetricId
export def "pages-metrics get" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/($metric_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a metric
#
# PATCH /pages/{page_id}/metrics/{metric_id}
# operationId: patchPagesPageIdMetricsMetricId
# --metric shape: {name?: string, metric_identifier?: string}
export def "pages-metrics patch" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric: record # shape: {name?: string, metric_identifier?: string}
]: any -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/($metric_id)")
  let body = {metric: $metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a metric
#
# PUT /pages/{page_id}/metrics/{metric_id}
# operationId: putPagesPageIdMetricsMetricId
# --metric shape: {name?: string, metric_identifier?: string}
export def "pages-metrics put" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric: record # shape: {name?: string, metric_identifier?: string}
]: any -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/($metric_id)")
  let body = {metric: $metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset data for a metric
#
# DELETE /pages/{page_id}/metrics/{metric_id}/data
# operationId: deletePagesPageIdMetricsMetricIdData
export def "pages-metrics-data delete" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/($metric_id)/data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add data to a metric
#
# POST /pages/{page_id}/metrics/{metric_id}/data
# operationId: postPagesPageIdMetricsMetricIdData
# --data shape: {timestamp?: int, value?: float}
export def "pages-metrics-data post-by-page_id-metric_id" [
  page_id: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {timestamp?: int, value?: float}
]: any -> record<data: record<timestamp: int, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics/($metric_id)/data")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of metric providers
#
# GET /pages/{page_id}/metrics_providers
# operationId: getPagesPageIdMetricsProviders
export def "pages-metrics-providers list" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, type: string, disabled: bool, metric_base_uri: string, last_revalidated_at: string, created_at: string, updated_at: string, page_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a metric provider
#
# POST /pages/{page_id}/metrics_providers
# operationId: postPagesPageIdMetricsProviders
# --metrics_provider shape: {email?: string, password?: string, api_key?: string, api_token?: string, application_key?: string, type?: string, metric_base_uri?: string}
export def "pages-metrics-providers post" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metrics-provider: record # shape: {email?: string, password?: string, api_key?: string, api_token?: string, application_key?: string, type?: string, metric_base_uri?: string}
]: any -> record<id: string, type: string, disabled: bool, metric_base_uri: string, last_revalidated_at: string, created_at: string, updated_at: string, page_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers")
  let body = {metrics_provider: $metrics_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a metric provider
#
# DELETE /pages/{page_id}/metrics_providers/{metrics_provider_id}
# operationId: deletePagesPageIdMetricsProvidersMetricsProviderId
export def "pages-metrics-providers delete" [
  page_id: string
  metrics_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, disabled: bool, metric_base_uri: string, last_revalidated_at: string, created_at: string, updated_at: string, page_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers/($metrics_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a metric provider
#
# GET /pages/{page_id}/metrics_providers/{metrics_provider_id}
# operationId: getPagesPageIdMetricsProvidersMetricsProviderId
export def "pages-metrics-providers get" [
  page_id: string
  metrics_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, disabled: bool, metric_base_uri: string, last_revalidated_at: string, created_at: string, updated_at: string, page_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers/($metrics_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a metric provider
#
# PATCH /pages/{page_id}/metrics_providers/{metrics_provider_id}
# operationId: patchPagesPageIdMetricsProvidersMetricsProviderId
# --metrics_provider shape: {type?: string, metric_base_uri?: string}
export def "pages-metrics-providers patch" [
  page_id: string
  metrics_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metrics-provider: record # shape: {type?: string, metric_base_uri?: string}
]: any -> record<id: string, type: string, disabled: bool, metric_base_uri: string, last_revalidated_at: string, created_at: string, updated_at: string, page_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers/($metrics_provider_id)")
  let body = {metrics_provider: $metrics_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a metric provider
#
# PUT /pages/{page_id}/metrics_providers/{metrics_provider_id}
# operationId: putPagesPageIdMetricsProvidersMetricsProviderId
# --metrics_provider shape: {type?: string, metric_base_uri?: string}
export def "pages-metrics-providers put" [
  page_id: string
  metrics_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metrics-provider: record # shape: {type?: string, metric_base_uri?: string}
]: any -> record<id: string, type: string, disabled: bool, metric_base_uri: string, last_revalidated_at: string, created_at: string, updated_at: string, page_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers/($metrics_provider_id)")
  let body = {metrics_provider: $metrics_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List metrics for a metric provider
#
# GET /pages/{page_id}/metrics_providers/{metrics_provider_id}/metrics
# operationId: getPagesPageIdMetricsProvidersMetricsProviderIdMetrics
export def "pages-metrics-providers-metrics get" [
  page_id: string
  metrics_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers/($metrics_provider_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a metric for a metric provider
#
# POST /pages/{page_id}/metrics_providers/{metrics_provider_id}/metrics
# operationId: postPagesPageIdMetricsProvidersMetricsProviderIdMetrics
# --metric shape: {name?: string, metric_identifier?: string, transform?: string, suffix?: string, y_axis_min?: int, y_axis_max?: int, y_axis_hidden?: bool, display?: bool, decimal_places?: int, tooltip_description?: string}
export def "pages-metrics-providers-metrics post" [
  page_id: string
  metrics_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric: record # shape: {name?: string, metric_identifier?: string, transform?: string, suffix?: string, y_axis_min?: int, y_axis_max?: int, y_axis_hidden?: bool, display?: bool, decimal_places?: int, tooltip_description?: string}
]: any -> record<id: string, metrics_provider_id: string, metric_identifier: string, name: string, display: bool, tooltip_description: string, backfilled: bool, y_axis_min: float, y_axis_max: float, y_axis_hidden: bool, suffix: string, decimal_places: int, most_recent_data_at: string, created_at: string, updated_at: string, last_fetched_at: string, backfill_percentage: int, reference_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/metrics_providers/($metrics_provider_id)/metrics")
  let body = {metric: $metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status embed config settings
#
# GET /pages/{page_id}/status_embed_config
# operationId: getPagesPageIdStatusEmbedConfig
export def "pages-status-embed-config get" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page_id: string, position: string, incident_background_color: string, incident_text_color: string, maintenance_background_color: string, maintenance_text_color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/status_embed_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update status embed config settings
#
# PATCH /pages/{page_id}/status_embed_config
# operationId: patchPagesPageIdStatusEmbedConfig
# --status_embed_config shape: {position?: string, incident_background_color?: string, incident_text_color?: string, maintenance_background_color?: string, maintenance_text_color?: string}
export def "pages-status-embed-config patch" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-embed-config: record # shape: {position?: string, incident_background_color?: string, incident_text_color?: string, maintenance_background_color?: string, maintenance_text_color?: string}
]: any -> record<page_id: string, position: string, incident_background_color: string, incident_text_color: string, maintenance_background_color: string, maintenance_text_color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/status_embed_config")
  let body = {status_embed_config: $status_embed_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update status embed config settings
#
# PUT /pages/{page_id}/status_embed_config
# operationId: putPagesPageIdStatusEmbedConfig
# --status_embed_config shape: {position?: string, incident_background_color?: string, incident_text_color?: string, maintenance_background_color?: string, maintenance_text_color?: string}
export def "pages-status-embed-config put" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-embed-config: record # shape: {position?: string, incident_background_color?: string, incident_text_color?: string, maintenance_background_color?: string, maintenance_text_color?: string}
]: any -> record<page_id: string, position: string, incident_background_color: string, incident_text_color: string, maintenance_background_color: string, maintenance_text_color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/status_embed_config")
  let body = {status_embed_config: $status_embed_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's permissions
#
# GET /organizations/{organization_id}/permissions/{user_id}
# operationId: getOrganizationsOrganizationIdPermissionsUserId
export def "organizations-permissions get" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<user_id: string, pages: record<page_id: string, page_configuration: bool, incident_manager: bool, maintenance_manager: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/permissions/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's role permissions
#
# PUT /organizations/{organization_id}/permissions/{user_id}
# operationId: putOrganizationsOrganizationIdPermissionsUserId
# --pages shape: {page_id?: record}
export def "organizations-permissions put" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pages: record # shape: {page_id?: record}
]: any -> record<data: record<user_id: string, pages: record<page_id: string, page_configuration: bool, incident_manager: bool, maintenance_manager: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/permissions/($user_id)")
  let body = {pages: $pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /organizations/{organization_id}/users/{user_id}
# operationId: deleteOrganizationsOrganizationIdUsersUserId
export def "organizations-users delete" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, organization_id: string, email: string, first_name: string, last_name: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of users
#
# GET /organizations/{organization_id}/users
# operationId: getOrganizationsOrganizationIdUsers
export def "organizations-users get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page offset to fetch. Beginning February 28, 2023, this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
  --per-page: int # Number of results to return per page. Beginning February 28, 2023, a default and maximum limit of 100 will be imposed and this endpoint will return paginated data even if this query parameter is not provided. (format: int32)
]: nothing -> table<id: string, organization_id: string, email: string, first_name: string, last_name: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /organizations/{organization_id}/users
# operationId: postOrganizationsOrganizationIdUsers
# --user shape: {email?: string, password?: string, first_name?: string, last_name?: string}
export def "organizations-users post" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user: record # shape: {email?: string, password?: string, first_name?: string, last_name?: string}
]: any -> record<id: string, organization_id: string, email: string, first_name: string, last_name: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/users")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
